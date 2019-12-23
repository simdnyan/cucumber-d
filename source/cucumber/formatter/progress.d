module cucumber.formatter.progress;

import std.stdio : write, writeln;

import cucumber.formatter.base : Formatter;
import cucumber.formatter.color : colors, noColors;
import cucumber.result : Result, RunResult, ScenarioResult, StepResult;
import gherkin : Feature, Scenario, Step, Examples, TableRow, Comment;

///
class Progress : Formatter
{
    private bool noColor;
    private bool noSnippets;
    private bool noSource;

    ///
    this(bool noColor, bool noSnippets, bool noSource)
    {
        this.noColor = noColor;
        this.noSnippets = noSnippets;
        this.noSource = noSource;
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
    override void scenarioOutline(ref Scenario scenario)
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
        write(color(stepResult.result), progressSymbol(stepResult.result), color("reset"));
    }

    ///
    override void emptyLine()
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
        writeln("\n");
        runResult(result);
    }

private:
    string progressSymbol(string result)
    {
        immutable auto progressSymbols = [
            "failed" : `F`, "skipped" : `-`, "undefined" : `U`, "passed" : `.`
        ];
        return progressSymbols[result];
    }
}
