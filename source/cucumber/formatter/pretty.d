module cucumber.formatter.pretty;

import std.algorithm : max;
import std.algorithm.iteration : each, filter, map;
import std.array : array, empty, join;
import std.conv : to;
import std.range : repeat, walkLength;
import std.stdio : write, writef, writefln, writeln;
import std.string : leftJustifier, split, stripLeft;
import std.typecons : Nullable;

import cucumber.formatter.base : Formatter;
import cucumber.formatter.color : colors, noColors;
import cucumber.result : FAILED, SKIPPED, UNDEFINED, PASSED, Result, RunResult,
    ScenarioResult, StepResult;
import gherkin : Feature, Scenario, Step, Examples, TableRow, Comment, Cell;

///
class Pretty : Formatter
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
        base(feature);
    }

    ///
    override void scenario(ref Scenario scenario)
    {
        writeln();
        base(scenario, "  ");
    }

    ///
    override void examples(Examples examples)
    {
        writeln();
        base(examples, "    ");
    }

    ///
    override void tableRow(TableRow tableRow, ref TableRow[] table, string resultColor)
    {
        if (this.table != table)
        {
            setCellSize(table);
        }
        writeln("      ", justifyCells(tableRow.cells, resultColor));
    }

    ///
    override void tableRow(TableRow tableRow, ref TableRow[] table, ScenarioResult scenarioResult)
    {
        tableRow.comments.each!(c => comment(c, "      "));
        with (scenarioResult)
        {
            this.tableRow(tableRow, table,
                    (stepResults.filter!(r => r.isUndefined).empty) ? result : UNDEFINED);
            foreach (stepResult; stepResults)
            {
                error(stepResult.exception, "      ");
            }
        }
    }

    ///
    override void step(Step step, StepResult stepResult)
    {
        this.step(step, stepResult.result, stepResult.location);

        if (stepResult.isFailed)
        {
            error(stepResult.exception, "    ");
        }
    }

    ///
    override void comment(Comment comment)
    {
        writeln(comment.text);
    }

    ///
    override void summarizeResult(RunResult result)
    {
        struct FailingScenario
        {
            string text;
            string source;
        }

        FailingScenario[] failingScenarios;
        ulong maxLength;
        foreach (featureResult; result.featureResults)
        {
            foreach (scenarioResult; featureResult.scenarioResults.filter!(x => x.isFailed))
            {
                auto text = "cucumber " ~ featureResult.feature.uri ~ ":"
                    ~ scenarioResult.scenario.location.line.to!string;
                auto source = scenarioResult.scenario.keyword ~ `: ` ~ (
                        scenarioResult.scenario.name);
                if (!scenarioResult.exampleNumber > 0)
                {
                    source ~= ", Examples (#" ~ scenarioResult.exampleNumber.to!string ~ `)`;
                }

                auto failingScenario = FailingScenario(text, source);
                maxLength = max(maxLength, failingScenario.text.walkLength);
                failingScenarios ~= failingScenario;
            }
        }

        if (!failingScenarios.empty)
        {
            writeln(color("failed"), "Failing Scenarios:", color("reset"));

            foreach (failingScenario; failingScenarios)
            {
                if (noSource)
                {
                    writeln(color("failed"), failingScenario.text, color("reset"));
                }
                else
                {
                    writeln(color("failed"), leftJustifier(failingScenario.text, maxLength + 1),
                            color("reset"), color("gray"), "# ",
                            failingScenario.source, color("reset"));
                }
            }
            writeln;
        }
        runResult(result);
    }

private:

    Scenario runningScenario;
    TableRow[] table;
    ulong scenarioStringLength;
    ulong[] cellSizes;

    void comment(Comment comment, string extraIndent = "")
    {
        writeln(extraIndent ~ comment.text.stripLeft);
    }

    void base(T)(T element, string extraIndent = "")
    {
        with (element)
        {
            comments.each!(c => comment(c, extraIndent));
            if (!tags.empty)
            {
                writeln(extraIndent, color("skipped"), tags.map!(t => t.name)
                        .join(" "), color("reset"));
            }
            string line = extraIndent ~ keyword ~ ": ";
            static if (is(typeof(element) == Step))
            {
                line ~= text;
            }
            else
            {
                line ~= name;
            }
            static if (is(typeof(element) == Scenario))
            {
                setScenarioStringLength(element);
                if (noSource)
                {
                    write(line);
                }
                else
                {
                    write(leftJustifier(line, scenarioStringLength + 4));
                    write(color("gray"), " # ", element.uri, `:`,
                            element.location.line.to!string, color("reset"));
                }
            }
            else
            {
                write(line);
            }
            writeln;
            if (!description.empty)
            {
                writeln(extraIndent, description);
            }
        }
    }

    void step(Step step, string resultColor, string location)
    {
        step.comments.each!(c => comment(c, "      "));
        if (noSource)
        {
            write("    ", color(resultColor), step.keyword ~ step.text, color("reset"));
        }
        else
        {
            write("    ", color(resultColor), leftJustifier(step.keyword ~ step.text,
                    scenarioStringLength), color("reset"));
            write(color("gray"), " # ", location, color("reset"));
        }
        writeln;
        if (!step.docString.isNull)
        {
            with (step.docString.get)
            {
                writeln("      ", color(resultColor), delimiter);
                writeln(content.split("\n").map!(x => "      " ~ x).array.join("\n"));
                writeln("      ", delimiter, color("reset"));
            }
        }
        if (!step.dataTable.empty)
        {
            foreach (row; step.dataTable.rows)
            {
                tableRow(row, step.dataTable.rows, SKIPPED);
            }
        }
    }

    void setScenarioStringLength(ref Scenario scenario)
    {
        if (this.runningScenario == scenario)
        {
            return;
        }
        scenarioStringLength = scenario.keyword.walkLength + scenario.name.walkLength;
        foreach (step; scenario.steps)
        {
            auto stepStringLength = (step.keyword ~ (step.text)).walkLength;
            scenarioStringLength = max(scenarioStringLength, stepStringLength);
        }
        this.runningScenario = scenario;
    }

    void setCellSize(TableRow[] rows)
    {
        if (rows.empty)
        {
            return;
        }
        this.table = rows;
        cellSizes = 0LU.repeat(rows[0].cells.length).array;
        foreach (i, row; rows)
        {
            foreach (j, cell; row.cells)
            {
                if (!cell.value.empty)
                {
                    cellSizes[j] = max(cellSizes[j], cell.value.walkLength);
                }
            }
        }
    }

    string justifyCells(Cell[] cells, string resultColor)
    {
        string[] cellStrings;
        foreach (i, cell; cells)
        {
            string cellString;
            if (!cell.value.empty)
            {
                cellString = color(resultColor) ~ cell.value.leftJustifier(cellSizes[i])
                    .to!string ~ color("reset");
            }
            cellStrings ~= cellString;
        }
        return "| " ~ cellStrings.join(" | ") ~ " |";
    }

    void error(Nullable!Exception exception, string extraIndent = "")
    {
        if (exception.isNull)
        {
            return;
        }
        string message = exception.get.message.split("\n")
            .map!(l => extraIndent ~ l).array.join("\n");
        writefln("%s%s%s", color("failed"), message, color("reset"));
    }
}
