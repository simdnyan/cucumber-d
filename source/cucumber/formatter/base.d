module cucumber.formatter.base;

import std.array : join;
import std.string : format;
import std.stdio : write, writeln;
import std.typecons : tuple;

import cucumber.result : Result, ResultSummary, RunResult, ScenarioResult, StepResult;
import gherkin : Feature, Scenario, Step, Examples, TableRow, Comment;

///
interface Formatter
{
    ///
    void feature(Feature);

    ///
    void scenario(ref Scenario);

    ///
    void examples(Examples);

    ///
    void tableRow(TableRow, ref TableRow[], string);

    ///
    void tableRow(TableRow, ref TableRow[], ScenarioResult);

    ///
    void step(Step, StepResult);

    ///
    void comment(Comment);

    ///
    void summarizeResult(RunResult);

    ///
    string color(string);

    ///
    final string resultSummary(ResultSummary summary)
    {
        string[] result;
        foreach (t; [
                tuple("failed", summary.failed), tuple("skipped", summary.skipped),
                tuple("undefined", summary.undefined),
                tuple("passed", summary.passed)
            ])
        {
            if (t[1] > 0)
            {
                result ~= "%s%d %s%s".format(color(t[0]), t[1], t[0], color("reset"));
            }
        }
        return result.join(", ");
    }

    ///
    final void runResult(RunResult runResult)
    {
        string result;
        foreach (k, v; runResult.resultSummaries)
        {
            result ~= "%s %s".format(v.total, k);
            if (v.total > 0)
            {
                result ~= " (%s)".format(resultSummary(v));
            }
            result ~= "\n";
        }
        result ~= runResult.time.toString();

        writeln(result);
    }
}
