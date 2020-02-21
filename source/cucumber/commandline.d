module cucumber.commandline;

import std.getopt;

import cucumber.formatter;
import cucumber.result : RunResult;
import cucumber.runner : CucumberRunner;
import gherkin : GherkinDocument, Parser, getFeatureFiles;

/**
 * CucumberCommandLine
 */
class CucumberCommandline
{
    /**
     * run
     *
     * Returns:
     *   exit code
     */
    int run(ModuleNames...)(string[] args)
    {
        string require;
        string format;
        bool dryRun;
        bool noColor;
        bool quiet;
        bool noSnippets;
        bool noSource;
        bool strict;
        // dfmt off
        auto opts = getopt(args,
                std.getopt.config.caseSensitive,
                "r|require", "Implemented for compatibility. Do nothing.",
                &require,
                "d|dry-run", "Invokes formatters without executing the steps.",
                &dryRun,
                "f|format", "How to format features (Default: pretty). Available formats:
                   json        : Prints the feature as JSON
                   json_pretty : Prints the feature as prettified JSON
                   pretty      : Prints the feature as is - in colours.
                   progress    : Prints one character per scenario.",
                &format,
                "no-color", "Whether or not to use ANSI color in the output.",
                &noColor,
                "i|no-snippets", "Don't print snippets for pending steps.",
                &noSnippets,
                "s|no-source", "Don't print the file and line of the step definition with the steps.",
                &noSource,
                "q|quiet", "Alias for --no-snippets --no-source.",
                &quiet,
                "S|strict", "Fail if there are any strict affected results.",
                &strict,
                std.getopt.config.passThrough);
        // dfmt on
        noSnippets |= quiet;
        noSource |= quiet;

        if (opts.helpWanted)
        {
            defaultGetoptPrinter("Usage: cucumber [options]", opts.options);
            return 0;
        }

        Formatter formatter;
        switch (format)
        {
        case "json":
            formatter = new Json(noColor, noSnippets, noSource);
            break;
        case "json_pretty":
            formatter = new Json(noColor, noSnippets, noSource, true);
            break;
        case "progress":
            formatter = new Progress(noColor, noSnippets, noSource);
            break;
        case "pretty":
        default:
            formatter = new Pretty(noColor, noSnippets, noSource);
        }
        auto runner = new CucumberRunner(formatter, dryRun);
        auto featureFiles = getFeatureFiles(args);
        RunResult result;

        foreach (featureFile; featureFiles)
        {
            // TODO: Throw No such file error if file does not exit
            auto gherkinDocument = Parser.parseFromFile(featureFile);

            result += runner.runFeature!ModuleNames(gherkinDocument);
        }

        formatter.summarizeResult(result);

        immutable auto scenarioResultSummary = result.resultSummaries["scenario"];
        if (strict)
        {
            return scenarioResultSummary.passed == scenarioResultSummary.total ? 0 : 1;
        }
        return scenarioResultSummary.failed == 0 ? 0 : 1;
    }
}
