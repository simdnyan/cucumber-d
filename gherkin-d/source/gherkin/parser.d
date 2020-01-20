module gherkin.parser;

import std.algorithm.searching : startsWith;
import std.array : array, empty, join;
import std.algorithm : map;
import std.conv : to;
import std.range : back, popBack, repeat, walkLength;
import std.regex : ctRegex, replace, split;
import std.string : chomp, replace, split, strip, stripLeft;
import std.stdio : File;
import std.typecons : Nullable;

import gherkin;

///
enum Token
{
    Language,
    Feature,
    Scenario,
    Background,
    Step,
    Examples,
    DocString,
    Other,
    TableRow,
    Comment,
    Tag,
    EmptyLine,
    Null
}

///
struct LineToken
{
    ///
    Token token;
    ///
    string keyword;
    ///
    string text;
    ///
    Location location;
}

///
class Parser
{
    ///
    static GherkinDocument parse(string[] documentStrings, string uri)
    {
        ulong lineNumber;
        ulong id;
        Tag[] tags;
        auto document = GherkinDocument(uri, documentStrings);

        LineToken getToken(string line, ulong lineNumber) //, Token[] tokenStack)
        {
            immutable Token[string] tokenStrings = [
                "#language:" : Token.Language, "Feature:" : Token.Feature,
                "Scenario:" : Token.Scenario, "Example:" : Token.Scenario,
                "Scenario Outline:" : Token.Scenario,
                "Background:" : Token.Background, "Given " : Token.Step,
                "When " : Token.Step, "Then " : Token.Step, "And " : Token.Step,
                "But " : Token.Step, "* " : Token.Step, "@" : Token.Tag,
                "Examples:" : Token.Examples, "#" : Token.Comment,
                `"""` : Token.DocString, "```" : Token.DocString,
                "|" : Token.TableRow
            ];

            auto strippedLine = line.stripLeft;
            auto indent = line.length - strippedLine.length;
            auto token = Token.Other;
            auto location = Location(indent + 1, lineNumber + 1);
            string text;
            string keyword;

            if (line.strip.length == 0)
            {
                token = token.EmptyLine;
            }
            else
            {
                foreach (t; tokenStrings.byKeyValue)
                {
                    if (strippedLine.startsWith(t.key))
                    {
                        token = t.value;
                        keyword = t.key;
                        text = line[indent + keyword.walkLength .. $];
                        if (token == Token.Comment)
                        {
                            location.column = 1;
                        }
                        break;
                    }
                }
            }

            return LineToken(token, keyword, text, location);
        }

        void parseTag(LineToken token)
        {
            immutable auto line = documentStrings[lineNumber];
            immutable auto strippedLine = line.strip;
            immutable auto tagStrings = strippedLine.split(" ");

            auto column = token.location.column;
            foreach (tagString; tagStrings)
            {
                if (!tagString.empty)
                {
                    tags ~= Tag(tagString, Location(column, lineNumber + 1));
                }
                column += tagString.walkLength + 1;
            }
        }

        DocString parseDocString(LineToken token)
        {
            string[] content;
            auto line = documentStrings[lineNumber];
            auto indent = token.location.column - 1;
            auto indentSpaces = ' '.repeat(token.location.column - 1);
            auto separator = token.keyword;
            auto contentType = token.text;

            while (++lineNumber < documentStrings.length)
            {
                line = documentStrings[lineNumber];
                auto lineToken = getToken(line, lineNumber);
                switch (lineToken.token)
                {
                case Token.Comment:
                    document.comments ~= Comment(line, lineToken.location);
                    break;
                case Token.DocString:
                    if (line.stripLeft == separator)
                    {
                        return DocString(content.join("\n"), contentType,
                                separator, token.location);
                    }
                    goto default;
                default:
                    if (line.startsWith(indentSpaces))
                    {
                        content ~= line[indent .. $].replace("\\\"", `"`);
                    }
                    else
                    {
                        content ~= line.stripLeft.replace("\\\"", `"`);
                    }
                }
            }
            assert(0);
        }

        TableRow[] parseTableRows()
        {
            TableRow[] tableRows;
            while (lineNumber < documentStrings.length)
            {
                auto line = documentStrings[lineNumber];
                auto lineToken = getToken(line, lineNumber);
                switch (lineToken.token)
                {
                case Token.TableRow:
                    const auto cellStrings = line.replace(ctRegex!(`\|\s*$`),
                            ``).split(ctRegex!(`(?<!\\)\|`));
                    auto column = cellStrings[0].walkLength + 1;
                    auto row = TableRow((id++).to!string, [], Location(column, lineNumber + 1));
                    foreach (cellString; cellStrings[1 .. $])
                    {
                        string value;
                        string strippedCellString = cellString.strip;
                        ulong i;
                        while (i < strippedCellString.length)
                        {
                            auto c = strippedCellString[i].to!string;
                            i++;
                            if (c == `\` && i < strippedCellString.length)
                            {
                                c = strippedCellString[i].to!string;
                                i++;
                                if (c == `n`)
                                {
                                    c = "\n";
                                }
                                else if (c != `|` && c != `\`)
                                {
                                    value ~= "\\";
                                }
                            }
                            value ~= c;
                        }
                        row.cells ~= Cell(value, Location(column + (cellString.walkLength - cellString.stripLeft()
                                .walkLength) + 1, lineNumber + 1));
                        column += cellString.walkLength + 1;
                    }
                    tableRows ~= row;
                    break;
                case Token.EmptyLine:
                    break;
                case Token.Comment:
                    document.comments ~= Comment(line, lineToken.location);
                    break;
                default:
                    lineNumber--;
                    return tableRows;
                }

                lineNumber++;
            }
            return tableRows;
        }

        Step parseStep(LineToken token, Scenario parent)
        {
            auto line = documentStrings[lineNumber];
            Step step = Step(token.keyword, token.text, token.location, parent);

            while (++lineNumber < documentStrings.length)
            {
                line = documentStrings[lineNumber];
                auto lineToken = getToken(line, lineNumber);
                switch (lineToken.token)
                {
                case Token.DocString:
                    step.docString = parseDocString(lineToken);
                    break;
                case Token.TableRow:
                    step.dataTable = DataTable(parseTableRows(),
                            lineToken.location);
                    break;
                case Token.Comment:
                    document.comments ~= Comment(line, lineToken.location);
                    break;
                case Token.EmptyLine:
                    break;
                default:
                    lineNumber--;
                    step.id = (id++).to!string;
                    return step;
                }
            }
            step.id = (id++).to!string;
            return step;
        }

        string parseDescription()
        {
            auto line = documentStrings[lineNumber];
            string[] descriptions = [line];

            string[] stripTail(string[] descriptions)
            {
                while (!descriptions.empty)
                {
                    if (descriptions.back.length > 0)
                    {
                        break;
                    }
                    descriptions.popBack;
                }
                return descriptions;
            }

            while (++lineNumber < documentStrings.length)
            {
                line = documentStrings[lineNumber];
                auto lineToken = getToken(line, lineNumber);
                switch (lineToken.token)
                {
                case Token.Comment:
                    document.comments ~= Comment(line, lineToken.location);
                    break;
                case Token.EmptyLine:
                case Token.Other:
                    descriptions ~= line.replace("\\\\", `\`);
                    break;
                default:
                    lineNumber--;
                    return stripTail(descriptions).join("\n");
                }
            }

            return stripTail(descriptions).join("\n");
        }

        Examples parseExamples(LineToken token)
        {
            auto line = documentStrings[lineNumber];
            TableRow[] tableRows;
            Nullable!string description;
            Tag[] examplesTags;
            if (!tags.empty)
            {
                examplesTags = tags;
                tags = [];
            }

            Examples finalize()
            {
                auto examples = Examples(token.keyword[0 .. $ - 1],
                        token.text.stripLeft, token.location, tableRows, description);
                foreach (i, tag; examplesTags)
                {
                    tag.id = (id++).to!string;
                    examples.tags ~= tag;
                }

                return examples;
            }

            while (++lineNumber < documentStrings.length)
            {
                line = documentStrings[lineNumber];
                auto lineToken = getToken(line, lineNumber);
                switch (lineToken.token)
                {
                case Token.TableRow:
                    tableRows = parseTableRows();
                    break;
                case Token.Comment:
                    document.comments ~= Comment(line, lineToken.location);
                    break;
                case Token.Other:
                    description = parseDescription();
                    break;
                case Token.EmptyLine:
                    break;
                default:
                    lineNumber--;
                    return finalize;
                }
            }

            return finalize;
        }

        Scenario parseScenario(LineToken token, Feature feature)
        {
            auto line = documentStrings[lineNumber];
            auto scenario = new Scenario(token.keyword[0 .. $ - 1], token.text.stripLeft,
                    token.location, feature, token.token == Token.Background);
            if (!tags.empty)
            {
                scenario.tags = tags;
                tags = [];
            }

            void update_ids()
            {
                foreach (i, tag; scenario.tags)
                {
                    scenario.tags[i].id = (id++).to!string;
                }
                if (token.token != Token.Background)
                    scenario.id = (id++).to!string;
            }

            while (++lineNumber < documentStrings.length)
            {
                line = documentStrings[lineNumber];
                auto lineToken = getToken(line, lineNumber);
                switch (lineToken.token)
                {
                case Token.Step:
                    scenario.steps ~= parseStep(lineToken, scenario);
                    break;
                case Token.Examples:
                    scenario.examples ~= parseExamples(lineToken);
                    scenario.isScenarioOutline = true;
                    break;
                case Token.Tag:
                    parseTag(lineToken);
                    break;
                case Token.Other:
                    scenario.description = parseDescription();
                    break;
                case Token.Comment:
                    document.comments ~= Comment(line, lineToken.location);
                    break;
                case Token.EmptyLine:
                    break;
                default:
                    update_ids();
                    lineNumber--;
                    return scenario;
                }
            }
            update_ids();
            return scenario;
        }

        Feature parseFeature(LineToken token, GherkinDocument document)
        {
            auto line = documentStrings[lineNumber];
            auto feature = new Feature(token.keyword[0 .. $ - 1],
                    token.text.stripLeft, token.location, document);
            if (!tags.empty)
            {
                feature.tags = tags;
                tags = [];
            }

            while (++lineNumber < documentStrings.length)
            {
                line = documentStrings[lineNumber];
                auto lineToken = getToken(line, lineNumber);
                switch (lineToken.token)
                {
                case Token.Background:
                    feature.background = parseScenario(lineToken, feature);
                    break;
                case Token.Scenario:
                    feature.scenarios ~= parseScenario(lineToken, feature);
                    break;
                case Token.Other:
                    feature.description = parseDescription();
                    break;
                case Token.Tag:
                    parseTag(lineToken);
                    break;
                case Token.Comment:
                    document.comments ~= Comment(line, lineToken.location);
                    break;
                case Token.EmptyLine:
                    break;
                default:
                    // do nothing
                }
            }
            foreach (i, tag; feature.tags)
            {
                feature.tags[i].id = (id++).to!string;
            }
            return feature;
        }

        GherkinDocument parseDocument()
        {
            string language = "en";

            while (lineNumber < documentStrings.length)
            {
                auto line = documentStrings[lineNumber];
                auto lineToken = getToken(line, lineNumber);
                switch (lineToken.token)
                {
                case Token.Language:
                    language = lineToken.text.strip;
                    break;
                case Token.Feature:
                    document.feature = parseFeature(lineToken, document);
                    break;
                case Token.Tag:
                    parseTag(lineToken);
                    break;
                case Token.Comment:
                    document.comments ~= Comment(line, lineToken.location);
                    break;
                case Token.EmptyLine:
                    break;
                default:
                    //do nothing
                }
                lineNumber++;
            }

            if (!document.feature.isNull)
            {
                document.feature.get.language = language;
            }

            return document;
        }

        return parseDocument;
    }

    ///
    static GherkinDocument parseFromFile(string uri)
    {
        static string nbsp = "\xc2\xa0";

        auto file = File(uri, "r");
        return parse(file.byLine.map!(x => x.to!string.chomp.replace(nbsp, ` `)).array, uri);
    }

    unittest
    {
        import std.algorithm : canFind;
        import std.file : readText;
        import std.json : parseJSON;
        import std.path : baseName;
        import std.string : replace;
        import unit_threaded.assertions : should;

        import glob : glob;

        const auto ignoredFeatureFiles = [
            // dfmt off
            // good
            "complex_background",
            "i18n_emoji",
            "i18n_fr",
            "i18n_no",
            "rule",
            "rule_without_name_and_description",
            "spaces_in_language",
            // bad
            "inconsistent_cell_count",
            "invalid_language",
            "multiple_parser_errors",
            "not_gherkin",
            "single_parser_error",
            "unexpected_eof"
            // dfmt on
        ];

        foreach (featureFile; glob(`cucumber/gherkin/testdata/*/*.feature`))
        {
            if (ignoredFeatureFiles.canFind(baseName(featureFile, ".feature")))
            {
                continue;
            }
            immutable auto expected = parseJSON(readText(featureFile ~ `.ast.ndjson`));
            auto actual = parseFromFile(featureFile);

            actual.uri = actual.uri.replace("cucumber/gherkin/", "");
            actual.toJSON.should == expected;
        }
    }
}
