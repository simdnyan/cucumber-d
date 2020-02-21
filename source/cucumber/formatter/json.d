module cucumber.formatter.json;

import std.array : empty;
import std.stdio : write;
import std.json : toJSON, parseJSON;

import asdf : serializeToJson, serializeToJsonPretty;

import cucumber.formatter.base : Formatter;
import cucumber.formatter.color : colors, noColors;
import cucumber.result : Result, RunResult, ScenarioResult, StepResult;
import gherkin : Feature, Scenario, Step, Examples, TableRow, Comment;

///
class Json : Formatter
{
    private bool noColor;
    private bool noSnippets;
    private bool noSource;
    private bool pretty;

    ///
    this(bool noColor, bool noSnippets, bool noSource, bool pretty = false)
    {
        this.noColor = noColor;
        this.noSnippets = noSnippets;
        this.noSource = noSource;
        this.pretty = pretty;
    }

    ///
    override string color(string result)
    {
        return noColor ? noColors[result] : colors[result];
    }

    ///
    override void feature(Feature feature)
    {
        // do nothing
    }

    ///
    override void scenario(ref Scenario scenario)
    {
        // do nothing
    }

    ///
    override void examples(Examples examples)
    {
        // do nothing
    }

    ///
    override void tableRow(TableRow tableRow, ref TableRow[] table, string color)
    {
        // do nothing
    }

    ///
    override void tableRow(TableRow tableRow, ref TableRow[] table, ScenarioResult scenarioResult)
    {
        // do nothing
    }

    ///
    override void step(Step step, StepResult stepResult)
    {
        // do nothing
    }

    ///
    override void comment(Comment comment)
    {
        // do nothing
    }

    ///
    override void summarizeResult(RunResult result)
    {
        if (result.featureResults.length == 0)
        {
            if (pretty)
            {
                "[\n\n]".write;
            }
            else
            {
                "[]".write;
            }
        }
        if (pretty)
        {
            result.featureResults.serializeToJsonPretty!"  ".write;
        }
        else
        {
            result.featureResults.serializeToJson.write;
        }
    }
}

unittest
{
    import std.algorithm : canFind;
    import std.file : readText;
    import std.json : parseJSON;
    import std.path : baseName, dirName;
    import std.string : replace;
    import unit_threaded.assertions : should;
    import cucumber.runner : CucumberRunner;
    import gherkin.util : getFeatureFiles;
    import gherkin.parser : Parser;

    const auto ignoredFeatureFiles = [
        // dfmt off
        "complex_background", // Rule included
        "i18n_emoji",
        "i18n_fr",
        "i18n_no",
        "minimal-example", // Example (related to Rule) included
        "padded_example", // Cucumber-Ruby Scenario Outline issue
        "rule",
        "rule_without_name_and_description",
        "scenario_outline", // Cucumber-Ruby Scenario Outline issue
        "spaces_in_language",
        // dfmt on
    ];

    foreach (featureFile; getFeatureFiles([
                ``, "gherkin-d/cucumber/gherkin/testdata/good/"
            ]))
    {
        if (ignoredFeatureFiles.canFind(baseName(featureFile, ".feature")))
        {
            continue;
        }
        auto gherkinDocument = Parser.parseFromFile(featureFile);
        auto formatter = new Json(true, true, true);
        auto runner = new CucumberRunner(formatter, true);
        RunResult result;
        result += runner.runFeature!"cucumber.formatter.json"(gherkinDocument);
        string actual = result.featureResults.serializeToJson;
        if (result.featureResults.empty)
        {
            actual = "[]";
        }

        parseJSON(actual).should == parseJSON(
                readText("testdata/formatter/json/" ~ baseName(featureFile) ~ `.json`));
    }
}
