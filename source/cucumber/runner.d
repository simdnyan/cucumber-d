module cucumber.runner;

import std.algorithm : each, filter;
import std.array : empty;
import std.conv : to;
import std.datetime.stopwatch : StopWatch, AutoStart;
import std.range : zip;
import std.string : replace;
import std.typecons : Nullable;

import cucumber.formatter;
import cucumber.reflection : findMatch, MatchResult;
import cucumber.result : FAILED, SKIPPED, UNDEFINED, PASSED, Result,
    FeatureResult, ScenarioResult, StepResult;
import gherkin : GherkinDocument, Background, Scenario, Step, Tag, Comment;

/**
 * Cucumber Feature Runner
 */
class CucumberRunner
{
private:
    GherkinDocument document;
    Formatter formatter;
    bool dryRun;
    ulong lineNumber;
    bool isFirstBackground = true;

public:
    ///
    this(Formatter formatter, bool dryRun)
    {
        this.formatter = formatter;
        this.dryRun = dryRun;
    }

    /**
      * Run GherkinDocument
      *
      * Params:
      *   gherkinDocument = Gherkin document to run
      */
    FeatureResult runFeature(ModuleNames...)(GherkinDocument gherkinDocument)
    {
        this.document = gherkinDocument;
        if (this.document.feature.isNull)
        {
            return FeatureResult();
        }

        auto feature = this.document.feature.get;
        auto featureResult = FeatureResult(feature);

        feature.comments = outputComments(feature.location.line);
        formatter.feature(feature);

        foreach (scenario; feature.scenarios)
        {
            if (scenario.steps.empty && feature.background.isNull)
            {
                continue;
            }
            if (scenario.isScenarioOutline)
            {
                if ((scenario.examples.empty || scenario.steps.empty) && feature.background.isNull)
                {
                    continue;
                }
                runScenarioOutline!ModuleNames(scenario, feature.background).each!(
                        r => featureResult += r);
            }
            else
            {
                auto scenarioResults = runScenario!ModuleNames(scenario, feature.background);
                if (!feature.background.isNull)
                {
                    featureResult += scenarioResults[0];
                }
                featureResult += scenarioResults[1];
            }
        }

        return featureResult;
    }

    ///
    ScenarioResult[] runScenarioOutline(ModuleNames...)(Scenario scenario,
            Nullable!Scenario background)
    {
        ScenarioResult[] results;

        scenario.comments = outputComments(scenario.location.line);
        formatter.scenario(scenario);
        foreach (step; scenario.steps)
        {
            step.comments = outputComments(step.location.line);
            formatter.step(step, StepResult(step,
                    scenario.parent.parent.uri ~ `:` ~ step.location.line.to!string, SKIPPED));
        }
        formatter.emptyLine();

        foreach (examples; scenario.examples)
        {
            auto examplesComments = outputComments(examples.location.line);
            formatter.examples(examples);
            if (examples.tableHeader.empty)
            {
                continue;
            }

            auto table = examples.tableBody ~ examples.tableHeader;
            outputComments(examples.tableHeader.location.line);
            formatter.tableRow(examples.tableHeader, table, "skipped");

            foreach (i, row; examples.tableBody)
            {
                string[string] examplesValues = null;
                foreach (example; zip(examples.tableHeader.cells, row.cells))
                {
                    examplesValues[example[0].value] = example[1].value;
                }

                auto _scenario = new Scenario(scenario.keyword,
                        scenario.getName, row.location, scenario.parent, false);
                _scenario.tags = scenario.tags ~ examples.tags;
                _scenario.comments = scenario.comments ~ examplesComments;
                _scenario.description = scenario.description;
                _scenario.isScenarioOutline = true;
                foreach (step; scenario.steps)
                {
                    auto _step = step;
                    _step.parent = _scenario;
                    foreach (k, v; examplesValues)
                    {
                        _step.replace(`<` ~ k ~ `>`, v);
                    }
                    _scenario.steps ~= _step;
                }

                auto result = runScenario!ModuleNames(_scenario, background);
                result[1].exampleNumber = i + 1;
                result[1].exampleName = examples.name;
                if (!background.isNull)
                {
                    results ~= result[0];
                }
                results ~= result[1];
                _scenario.comments ~= outputComments(row.location.line);
                formatter.tableRow(row, table, result[1]);
            }
            formatter.emptyLine();
        }

        return results;
    }

    ///
    ScenarioResult[] runScenario(ModuleNames...)(Scenario scenario, Nullable!Scenario background)
    {
        ScenarioResult backgroundResult;

        if (!background.isNull)
        {
            Nullable!Scenario nullScenario;
            backgroundResult = runScenario!ModuleNames(background.get, nullScenario)[1];
            if (isFirstBackground)
            {
                formatter.emptyLine();
            }
            this.isFirstBackground = false;
        }

        scenario.comments ~= outputComments(scenario.location.line);
        if (!scenario.isBackground || this.isFirstBackground)
        {
            if (!scenario.isScenarioOutline)
            {
                formatter.scenario(scenario);
                // Output failed steps in Background

                backgroundResult.stepResults
                    .filter!(r => r.isFailed)
                    .each!(r => formatter.step(r.step, r));
            }
        }

        auto result = ScenarioResult(scenario,
                this.document.uri ~ `:` ~ scenario.location.line.to!string);

        foreach (step; scenario.steps)
        {
            step.comments = outputComments(step.location.line);
            auto stepResult = StepResult(step);
            if (result.isPassed && backgroundResult.isPassed)
            {
                stepResult = runStep!ModuleNames(step);
            }
            else
            {
                stepResult = runStep!ModuleNames(step, true);
                stepResult.result = stepResult.isUndefined ? UNDEFINED : SKIPPED;
            }
            result += stepResult;

            if (!scenario.isBackground || this.isFirstBackground)
            {
                if (!scenario.isScenarioOutline)
                {
                    formatter.step(step, stepResult);
                }
            }
        }

        if (!scenario.isScenarioOutline && !scenario.isBackground)
        {
            formatter.emptyLine();
        }

        return [backgroundResult, result];
    }

    ///
    StepResult runStep(ModuleNames...)(Step step, bool skip = false)
    {

        //auto result = StepResult(step, this.document.uri ~ `:` ~ step.location.line.to!string);
        string location = this.document.uri ~ `:` ~ (step.parent.isScenarioOutline
                ? step.parent.location.line : step.location.line).to!string;
        auto result = StepResult(step, location);
        auto func = findMatch!ModuleNames(step.text);
        auto sw = StopWatch(AutoStart.yes);

        if (func)
        {
            result.location = func.source;
            if (skip)
            {
                result.result = SKIPPED;
            }
            else
            {
                try
                {
                    if (!step.docString.isNull)
                    {
                        func(step.docString.get);
                    }
                    else if (!step.dataTable.empty)
                    {
                        func(step.dataTable);
                    }
                    else
                    {
                        func();
                    }
                }
                catch (Exception e)
                {
                    result.result = FAILED;
                    result.exception = e;
                }
            }
        }
        else
        {
            result.result = UNDEFINED;
        }
        result.time = sw.peek();

        return result;
    }

    private Comment[] outputComments(ulong currentLine)
    {
        Comment[] comments;

        if (lineNumber > currentLine)
        {
            return comments;
        }
        foreach (comment; this.document.comments)
        {
            if (comment.location.line > lineNumber && comment.location.line < currentLine)
            {
                formatter.comment(comment);
                comments ~= comment;
            }
        }
        lineNumber = currentLine;
        return comments;
    }
}
