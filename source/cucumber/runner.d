module cucumber.runner;

import std.algorithm : each, filter;
import std.array : empty;
import std.conv : to;
import std.datetime.stopwatch : StopWatch, AutoStart;
import std.range : zip;
import std.string : replace, toLower, tr;
import std.typecons : Nullable;

import cucumber.formatter;
import cucumber.reflection : findMatch, MatchResult;
import cucumber.result : FAILED, SKIPPED, UNDEFINED, PASSED, Result,
    FeatureResult, ScenarioResult, StepResult, createId;
import gherkin : GherkinDocument, Feature, Background, Scenario, Step, Tag, Comment;

/**
 * Cucumber Feature Runner
 */
class CucumberRunner
{
private:
    GherkinDocument document;
    Formatter formatter;
    bool dryRun;
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

        if (!feature.scenarios.empty)
        {
            formatter.feature(feature);
        }

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
                runScenarioOutline!ModuleNames(feature, scenario, feature.background).each!(
                        r => featureResult += r);
            }
            else
            {
                auto scenarioResults = runScenario!ModuleNames(feature,
                        scenario, feature.background);
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
    ScenarioResult[] runScenarioOutline(ModuleNames...)(Feature feature,
            Scenario scenario, Nullable!Scenario background)
    {
        ScenarioResult[] results;

        if (scenario.examples.empty || (scenario.steps.empty && background.isNull))
        {
            return results;
        }

        if (!scenario.steps.empty)
        {
            formatter.scenario(scenario);
            foreach (step; scenario.steps)
            {
                formatter.step(step, StepResult(step,
                        scenario.uri ~ `:` ~ step.location.line.to!string, SKIPPED));
            }
        }

        foreach (examples; scenario.examples)
        {
            if (!examples.tableBody.empty && !scenario.steps.empty)
            {
                formatter.examples(examples);
            }
            if (examples.tableHeader.empty)
            {
                continue;
            }

            auto table = examples.tableBody ~ examples.tableHeader;
            if (!examples.tableBody.empty && !scenario.steps.empty)
            {
                formatter.tableRow(examples.tableHeader, table, "skipped");
            }

            foreach (i, row; examples.tableBody)
            {
                string[string] examplesValues = null;
                foreach (example; zip(examples.tableHeader.cells, row.cells))
                {
                    examplesValues[example[0].value] = example[1].value;
                }

                auto _scenario = new Scenario(scenario.keyword, scenario.name,
                        row.location, false, scenario.uri, scenario.comments);
                _scenario.tags = scenario.tags ~ examples.tags;
                _scenario.comments ~= examples.comments ~ row.comments;
                _scenario.description = scenario.description;
                _scenario.isScenarioOutline = true;
                foreach (step; scenario.steps)
                {
                    auto _step = step;
                    _step.isScenarioOutline = true;
                    foreach (k, v; examplesValues)
                    {
                        _step.replace(`<` ~ k ~ `>`, v);
                    }
                    _scenario.steps ~= _step;
                }

                auto result = runScenario!ModuleNames(feature, _scenario, background);

                auto id = createId(feature.name) ~ `;` ~ createId(scenario.name);
                id ~= `;` ~ createId(examples.name);
                id ~= `;` ~ (i + 2).to!string;
                result[1].id = id;
                result[1].exampleNumber = i + 2;

                if (!background.isNull)
                {
                    results ~= result[0];
                }
                results ~= result[1];
                if (!scenario.steps.empty)
                {
                    formatter.tableRow(row, table, result[1]);
                }
            }
        }

        return results;
    }

    ///
    ScenarioResult[] runScenario(ModuleNames...)(Feature feature,
            Scenario scenario, Nullable!Scenario background)
    {
        ScenarioResult backgroundResult;
        auto result = ScenarioResult(scenario, scenario.uri ~ `:`
                ~ scenario.location.line.to!string);

        if (!background.isNull)
        {
            Nullable!Scenario nullScenario;
            backgroundResult = runScenario!ModuleNames(feature, background.get, nullScenario)[1];
            this.isFirstBackground = false;
            result.result = backgroundResult.result;
        }

        if ((!scenario.isBackground || this.isFirstBackground)
                && !scenario.isScenarioOutline && !scenario.steps.empty)
        {
            formatter.scenario(scenario);
            // Output failed steps in Background
            backgroundResult.stepResults
                .filter!(r => r.isFailed)
                .each!(r => formatter.step(r.step, r));
        }

        if (!scenario.isBackground)
        {
            auto id = createId(feature.name) ~ `;` ~ createId(scenario.name);
            result.id = id;
            result.scenarioTags = feature.tags ~ scenario.tags;
        }

        foreach (step; scenario.steps)
        {
            StepResult stepResult;

            if (result.isPassed)
            {
                stepResult = runStep!ModuleNames(step);
            }
            else
            {
                stepResult = runStep!ModuleNames(step, true);
                stepResult.result = stepResult.isUndefined ? UNDEFINED : SKIPPED;
            }
            stepResult.location = scenario.uri ~ `:` ~ (scenario.isScenarioOutline
                    ? scenario.location.line : step.location.line).to!string;

            result += stepResult;

            if ((!scenario.isBackground || this.isFirstBackground) && !scenario.isScenarioOutline)
            {
                formatter.step(step, stepResult);
            }
        }

        return [backgroundResult, result];
    }

    ///
    StepResult runStep(ModuleNames...)(Step step, bool skip = false)
    {
        auto result = StepResult(step);
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
}
