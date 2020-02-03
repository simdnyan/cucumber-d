module cucumber.result;

import core.time : Duration;
import std.algorithm : map;
import std.algorithm.iteration : filter;
import std.array : array, empty;
import std.conv : to;
import std.json : JSONValue, parseJSON;
import std.string : format, strip, toLower, tr;
import std.typecons : Nullable;

import asdf : serializationIgnoreOut, serializationIgnoreOutIf,
    serializationKeyOut, serializationTransformOut;
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
mixin template property(string parent, string type, string key)
{
    mixin("@property %s %s() const { return %s.%s; }".format(type, key, parent, key));
}

///
mixin template property(string parent, string type, string key, string field)
{
    mixin("@property %s %s() const { return %s.%s; }".format(type, key, parent, field));
}

///
mixin template nullableProperty(string parent, string type, string key)
{
    mixin("@property %s %s() const { return %s.%s.isNull ? `` :  %s.%s.get; }".format(type,
            key, parent, key, parent, key));
}

///
string createId(Nullable!string name)
{
    return name.isNull ? `` : name.get.toLower.tr(` `, `-`);
}

///
struct Comment
{
    ///
    string value;
    ///
    ulong line;
}

///
struct Tag
{
    ///
    string name;
    ///
    ulong line;
}

///
struct Row
{
    ///
    string[] cells;
}

///
struct DocString
{
    ///
    string value;
    ///
    @serializationKeyOut("content_type") string contentType;
    ///
    ulong line;
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
            if (val.scenarioResults.empty)
            {
                return this;
            }
            this.featureResults ~= val;
            this.time += val.time;
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
    @serializationIgnoreOut Feature feature;
    ///
    @serializationIgnoreOut Result result = Result.PASSED;
    ///
    @serializationIgnoreOut ScenarioResult[] scenarioResults;
    ///
    @serializationIgnoreOut Duration time;
    ///
    @serializationIgnoreOut ResultSummary resultSummary;

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
            if (!val.scenario.isBackground)
            {
                this.resultSummary += ResultSummary(val.result);
            }
            return this;
        }
        assert(0);
    }

    mixin property!("feature.parent", "string", "uri");

    ///
    @property string id()
    {
        return createId(feature.name);
    }

    mixin property!("feature", "string", "keyword");
    mixin nullableProperty!("feature", "string", "name");
    mixin nullableProperty!("feature", "string", "description");
    mixin property!("feature.location", "ulong", "line");

    ///
    @property @serializationIgnoreOutIf!`a.empty` Tag[] tags()
    {
        return feature.tags.map!(t => Tag(t.name, t.location.line)).array;
    }

    ///
    @property @serializationIgnoreOutIf!`a.empty` Comment[] comments()
    {
        return feature.comments.map!(c => Comment(c.text.strip, c.location.line)).array;
    }

    ///
    @property @serializationIgnoreOutIf!`a.empty` ScenarioResult[] elements()
    {
        return scenarioResults.filter!(r => !r.stepResults.empty || r.scenario.isBackground).array;
    }
}

///
struct ScenarioResult
{
    ///
    @serializationIgnoreOut Scenario scenario;
    ///
    @serializationIgnoreOut string location;
    ///
    @serializationIgnoreOut Result result = Result.PASSED;
    ///
    @serializationIgnoreOut StepResult[] stepResults;
    ///
    @serializationIgnoreOut Duration time;
    ///
    @serializationIgnoreOut ResultSummary resultSummary;
    ///
    @serializationIgnoreOut string exampleName;
    ///
    @serializationIgnoreOut ulong exampleNumber;

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

    ///
    @property @serializationTransformOut!`a.get`@serializationIgnoreOutIf!`a.isNull` Nullable!string id()
    {
        if (scenario.isBackground)
        {
            return Nullable!string();
        }
        auto id = createId(scenario.parent.name) ~ `;` ~ createId(scenario.name);
        if (!scenario.isScenarioOutline)
        {
            return Nullable!string(id);
        }
        id ~= `;` ~ createId(cast(Nullable!string) exampleName);
        id ~= `;` ~ (exampleNumber == 0 ? 0 : exampleNumber + 1).to!string;
        return Nullable!string(id);
    }

    mixin property!("scenario", "string", "keyword");
    mixin nullableProperty!("scenario", "string", "name");
    mixin nullableProperty!("scenario", "string", "description");
    mixin property!("scenario.location", "ulong", "line");

    ///
    @property string type()
    {
        return scenario.isBackground ? "background" : "scenario";
    }

    ///
    @property @serializationIgnoreOutIf!`a.empty` Comment[] comments()
    {
        return scenario.comments.map!(c => Comment(c.text.strip, c.location.line)).array;
    }

    ///
    @property @serializationIgnoreOutIf!`a.empty` Tag[] tags()
    {
        if (scenario.isBackground)
        {
            return [];
        }
        return scenario.parent.tags.map!(t => Tag(t.name, t.location.line))
            .array ~ scenario.tags.map!(t => Tag(t.name, t.location.line)).array;
    }

    ///
    @property @serializationIgnoreOutIf!`a.empty` StepResult[] steps()
    {
        return stepResults;
    }
}

///
struct StepResult
{
    ///
    @serializationIgnoreOut Step step;
    ///
    @serializationIgnoreOut string location;
    ///
    @serializationIgnoreOut Result result = Result.PASSED;
    ///
    @serializationIgnoreOut Duration time;
    ///
    @serializationIgnoreOut Nullable!Exception exception;

    mixin isResult;

    mixin property!("step", "string", "keyword");
    mixin property!("step", "string", "name", "text");
    mixin property!("step.location", "ulong", "line");

    ///
    @property @serializationIgnoreOutIf!`a.empty` Row[] rows()
    {
        return step.dataTable.rows.map!(r => Row(r.cells.map!(c => c.value.empty
                ? `` : c.value).array)).array;
    }

    ///
    @property @serializationIgnoreOutIf!`a.value.empty`@serializationKeyOut("doc_string")
    DocString docString()
    {
        if (step.docString.isNull)
        {
            return DocString();
        }
        with (step.docString.get)
        {
            return DocString(content, contentType, location.line);
        }
    }

    ///
    @property @serializationIgnoreOutIf!`a.empty` Comment[] comments()
    {
        return step.comments.map!(c => Comment(c.text.strip, c.location.line)).array;
    }

    ///
    @property Match match()
    {
        return Match(location);
    }

    ///
    @property @serializationKeyOut("result")
    ResultStatus resultStatus()
    {
        auto result = ResultStatus(result);

        if (this.isPassed || this.isFailed)
        {
            result.duration = time.total!"nsecs";
        }
        if (this.isFailed)
        {
            result.error_message = exception.get.message.to!string;
        }
        return result;
    }

    ///
    struct Match
    {
        ///
        string location;
    }

    ///
    struct ResultStatus
    {
        ///
        @serializationTransformOut!`a.toLower` Result status;
        ///
        @serializationIgnoreOutIf!`a.isNull`@serializationTransformOut!`a.get` Nullable!ulong duration;
        ///
        @serializationIgnoreOutIf!`a.isNull`@serializationTransformOut!`a.get` Nullable!string error_message;
    }
}
