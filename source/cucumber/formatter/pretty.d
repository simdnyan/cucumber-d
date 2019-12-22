module cucumber.formatter.pretty;

import std.algorithm : max;
import std.algorithm.iteration : filter, map;
import std.array : array, empty, join;
import std.conv : to;
import std.range : repeat, walkLength;
import std.stdio : write, writef, writefln, writeln;
import std.string : leftJustifier, split;
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
        if (scenario.isScenarioOutline)
        {
            return;
        }
        base(scenario, "  ");
    }

    ///
    override void scenarioOutline(ref Scenario scenario)
    {
        base(scenario, "  ");
        foreach (step; scenario.steps)
        {
            this.step(step, SKIPPED,
                    scenario.parent.parent.uri ~ `:` ~ step.location.line.to!string);
        }
        writeln;
    }

    ///
    override void examples(Examples examples)
    {
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
        if (step.parent.isScenarioOutline)
        {
            return;
        }

        this.step(step, stepResult.result, stepResult.location);
        if (!step.docString.isNull)
        {
            with (step.docString.get)
            {
                writeln("      ", color(stepResult.result), delimiter);
                writeln(content.split("\n").map!(x => "      " ~ x).array.join("\n"));
                writeln("      ", delimiter, color("reset"));
            }
        }
        if (!step.dataTable.isNull)
        {
            foreach (row; step.dataTable.get.rows)
            {
                tableRow(row, step.dataTable.get.rows, SKIPPED);
            }
        }
        if (stepResult.isFailed)
        {
            error(stepResult.exception, "    ");
        }
    }

    ///
    override void emptyLine()
    {
        writeln;
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
                auto text = "cucumber " ~ featureResult.feature.parent.uri ~ ":"
                    ~ scenarioResult.scenario.location.line.to!string;
                auto source = scenarioResult.scenario.keyword ~ `: ` ~ (scenarioResult.scenario.name.isNull
                        ? `` : scenarioResult.scenario.name.get);
                if (!scenarioResult.exampleNumber.isNull)
                {
                    source ~= ", Examples (#" ~ scenarioResult.exampleNumber.get.to!string ~ `)`;
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

    void base(T)(T element, string extraIndent = "")
    {
        with (element)
        {
            if (!tags.empty)
            {
                writeln(extraIndent, color("skipped"), tags.map!(t => t.name)
                        .join(" "), color("reset"));
            }
            string line = extraIndent ~ keyword ~ ": ";
            static if (is(typeof(name) == Nullable!string))
            {
                line ~= name.isNull ? `` : name.get;
            }
            else static if (is(typeof(element) == Step))
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
                    write(color("gray"), " # ", element.parent.parent.uri, `:`,
                            element.location.line.to!string, color("reset"));
                }
            }
            else
            {
                write(line);
            }
            writeln;
            if (!description.isNull)
            {
                writeln(extraIndent, description);
            }
        }
    }

    void step(Step step, string resultColor, string location)
    {
        setScenarioStringLength(step.parent);
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
    }

    void setScenarioStringLength(ref Scenario scenario)
    {
        if (this.runningScenario == scenario)
        {
            return;
        }
        scenarioStringLength = scenario.keyword.walkLength + (scenario.name.isNull
                ? 0 : scenario.name.get.walkLength);
        foreach (step; scenario.steps)
        {
            auto stepStringLength = (step.keyword ~ (step.text)).walkLength;
            scenarioStringLength = max(scenarioStringLength, stepStringLength);
        }
        this.runningScenario = scenario;
    }

    void setCellSize(TableRow[] rows)
    {
        this.table = rows;
        cellSizes = 0LU.repeat(rows.length).array;
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
                cellString = color(resultColor) ~
                        cell.value.leftJustifier(cellSizes[i]).to!string ~ color("reset");
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
