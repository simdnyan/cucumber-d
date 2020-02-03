module gherkin.app;

import std.getopt;
import std.json : JSONValue, parseJSON;
import std.stdio : writeln;

import asdf : serializeToJson;
import gherkin.parser : Parser;
import gherkin.util : getFeatureFiles;

void main(string[] args)
{
    bool noAst;

    // dfmt off
    auto opts = getopt(
            args,
            "no-ast", "Don't print ast messages",
            &noAst,
            std.getopt.config.passThrough
            );
    // dfmt on

    if (opts.helpWanted)
    {
        defaultGetoptPrinter("Usage: gherkin [options]", opts.options);
        return;
    }

    auto featureFiles = getFeatureFiles(args);
    foreach (featureFile; featureFiles)
    {
        const auto document = Parser.parseFromFile(featureFile);
        if (!noAst)
        {
            JSONValue(["gherkinDocument": parseJSON(document.serializeToJson)]).writeln;
        }
    }
}
