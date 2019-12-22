module cucumber.result;

import core.time : Duration;
import std.string : format;
import std.typecons : Nullable;

import gherkin : Feature, Scenario, Step;

///
enum Result
{
    FAILED = "failed",
    SKIPPED = "skipped",
    UNDEFINED = "undefined",
    PASSED = "passed"
}

alias FAILED = Result.FAILED;
alias SKIPPED = Result.SKIPPED;
alias UNDEFINED = Result.UNDEFINED;
alias PASSED = Result.PASSED;

///
mixin template isResult()
{
    mixin template isResult(string result)
    {
        import std.string : capitalize;
        import std.uni : toUpper;

        mixin("bool is%s() const { return this.result == Result.%s; }".format(result.capitalize,
                result.toUpper));
    }

    mixin isResult!"failed";
    mixin isResult!"skipped";
    mixin isResult!"undefined";
    mixin isResult!"passed";
}

///
struct ResultSummary
{
    ///
    ulong failed, skipped, undefined, passed;

    ///
    ulong total() const
    {
        return failed + skipped + undefined + passed;
    }

    ///
    this(Result result)
    {
        switch (result)
        {
        case Result.FAILED:
            this.failed = 1;
            break;
        case Result.SKIPPED:
            this.skipped = 1;
            break;
        case Result.UNDEFINED:
            this.undefined = 1;
            break;
        case Result.PASSED:
            this.passed = 1;
            break;
        default:
            // do nothing
        }
    }

    ///
    ResultSummary opOpAssign(string operator)(ResultSummary val)
    {
        if (operator == "+")
        {
            this.failed += val.failed;
            this.skipped += val.skipped;
            this.undefined += val.undefined;
            this.passed += val.passed;
            return this;
        }
        assert(0);
    }
}

///
struct RunResult
{
    ///
    int exitCode = 0;
    ///
    Duration time;
    ///
    ResultSummary[string] resultSummaries;
    ///
    FeatureResult[] featureResults;

    ///
    RunResult opOpAssign(string operator)(FeatureResult val)
    {
        if (operator == "+")
        {
            this.featureResults ~= val;
            this.time += val.time;
            if (!val.isPassed)
            {
                exitCode = 1;
            }
            if (!("scenarios" in resultSummaries))
                resultSummaries["scenarios"] = ResultSummary();
            if (!("steps" in resultSummaries))
                resultSummaries["steps"] = ResultSummary();

            resultSummaries["scenarios"] += val.resultSummary;
            foreach (scenarioResult; val.scenarioResults)
            {
                resultSummaries["steps"] += scenarioResult.resultSummary;
            }
            return this;
        }
        assert(0);
    }
}

///
struct FeatureResult
{
    ///
    Feature feature;
    ///
    Result result = Result.PASSED;
    ///
    ScenarioResult[] scenarioResults;
    ///
    Duration time;
    ///
    ResultSummary resultSummary;

    mixin isResult;

    ///
    FeatureResult opOpAssign(string operator)(ScenarioResult val)
    {
        if (operator == "+")
        {
            this.scenarioResults ~= val;
            this.time += val.time;
            if (!val.isPassed && this.isPassed)
            {
                this.result = Result.FAILED;
            }
            this.resultSummary += ResultSummary(val.result);
            return this;
        }
        assert(0);
    }
}

///
struct ScenarioResult
{
    ///
    Scenario scenario;
    ///
    string location;
    ///
    Result result = Result.PASSED;
    ///
    StepResult[] stepResults;
    ///
    Duration time;
    ///
    ResultSummary resultSummary;
    ///
    Nullable!ulong exampleNumber;

    mixin isResult;

    ///
    ScenarioResult opOpAssign(string operator)(StepResult val)
    {
        if (operator == "+")
        {
            this.stepResults ~= val;
            this.time += val.time;
            if (!val.isPassed && this.isPassed)
            {
                this.result = val.result;
            }
            this.resultSummary += ResultSummary(val.result);
            return this;
        }
        assert(0);
    }
}

///
struct StepResult
{
    ///
    Step step;
    ///
    string location;
    ///
    Result result = Result.PASSED;
    ///
    Duration time;
    ///
    Nullable!Exception exception;

    mixin isResult;
}
