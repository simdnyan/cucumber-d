module cucumber.runner;

import std.algorithm : each, filter;
import std.conv : to;
import std.datetime.stopwatch : StopWatch, AutoStart;
import std.range : zip;
import std.string : replace;
import std.typecons : Nullable;

import cucumber.formatter;
import cucumber.reflection : findMatch, MatchResult;
import cucumber.result : FAILED, SKIPPED, UNDEFINED, PASSED, Result,
    FeatureResult, ScenarioResult, StepResult;
import gherkin : GherkinDocument, Background, Scenario, Step;

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

        outputComments(feature.location.line);
        formatter.feature(feature);

        foreach (scenario; feature.scenarios)
        {
            if (scenario.isScenarioOutline)
            {
                runScenarioOutline!ModuleNames(scenario, feature.background).each!(
                        r => featureResult += r);
            }
            else
            {
                featureResult += runScenario!ModuleNames(scenario, feature.background);
            }
        }

        return featureResult;
    }

    ///
    ScenarioResult[] runScenarioOutline(ModuleNames...)(Scenario scenario,
            Nullable!Scenario background)
    {
        ScenarioResult[] results;

        outputComments(scenario.location.line);
        formatter.scenarioOutline(scenario);

        foreach (examples; scenario.examples)
        {
            outputComments(examples.location.line);
            formatter.examples(examples);
            if (examples.tableHeader.isNull)
            {
                continue;
            }

            auto table = examples.tableBody ~ examples.tableHeader.get;
            outputComments(examples.tableHeader.get.location.line);
            formatter.tableRow(examples.tableHeader.get, table, "skipped");

            foreach (i, row; examples.tableBody)
            {
                ScenarioResult result;

                string[string] examplesValues = null;
                foreach (example; zip(examples.tableHeader.get.cells, row.cells))
                {
                    examplesValues[example[0].value] = example[1].value;
                }

                auto _scenario = new Scenario(scenario.keyword, scenario.name.isNull
                        ? `` : scenario.name.get, row.location, scenario.parent, false);
                _scenario.tags = scenario.tags;
                _scenario.isScenarioOutline = true;
                foreach (step; scenario.steps)
                {
                    auto _step = step;
                    foreach (k, v; examplesValues)
                    {
                        _step.text = _step.text.replace(`<` ~ k ~ `>`, v);
                    }
                    _scenario.steps ~= _step;
                }

                result = runScenario!ModuleNames(_scenario, background);
                result.exampleNumber = i + 1;
                results ~= result;
                outputComments(row.location.line);
                formatter.tableRow(row, table, result);
            }
            formatter.emptyLine();
        }

        return results;
    }

    ///
    ScenarioResult runScenario(ModuleNames...)(Scenario scenario, Nullable!Scenario background)
    {
        auto result = ScenarioResult(scenario,
                this.document.uri ~ `:` ~ scenario.location.line.to!string);

        if (!background.isNull)
        {
            Nullable!Scenario nullScenario;
            runScenario!ModuleNames(background.get, nullScenario).stepResults.each!(
                    r => result += r);
            if (isFirstBackground)
            {
                formatter.emptyLine();
            }
            this.isFirstBackground = false;
        }

        outputComments(scenario.location.line);
        if (!scenario.isBackground || this.isFirstBackground)
        {
            formatter.scenario(scenario);

            // Output failed steps in Background
            if (!scenario.isScenarioOutline)
            {
                result.stepResults
                    .filter!(r => r.isFailed)
                    .each!(r => formatter.step(r.step, r));
            }
        }

        foreach (step; scenario.steps)
        {
            auto stepResult = StepResult(step);
            if (result.isPassed)
            {
                stepResult = runStep!ModuleNames(step);
            }
            else
            {
                stepResult = runStep!ModuleNames(step, true);
                stepResult.result = stepResult.isUndefined ? UNDEFINED : SKIPPED;
            }
            result += stepResult;

            outputComments(step.location.line);
            if (!scenario.isBackground || this.isFirstBackground)
            {
                formatter.step(step, stepResult);
            }
        }

        if (!scenario.isScenarioOutline && !scenario.isBackground)
        {
            formatter.emptyLine();
        }

        return result;
    }

    ///
    StepResult runStep(ModuleNames...)(Step step, bool skip = false)
    {

        auto result = StepResult(step, this.document.uri ~ `:` ~ step.location.line.to!string);
        auto func = findMatch!ModuleNames(step.text);
        auto sw = StopWatch(AutoStart.yes);

        if (func)
        {
            result.location = func.source;
            if (skip || this.dryRun)
            {
                result.result = SKIPPED;
            }
            else
            {
                try
                {
                    func();
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

    private void outputComments(ulong currentLine)
    {
        if (lineNumber > currentLine)
        {
            return;
        }
        foreach (comment; this.document.comments)
        {
            if (comment.location.line > lineNumber && comment.location.line < currentLine)
            {
                formatter.comment(comment);
            }
        }
        lineNumber = currentLine;
    }
}
