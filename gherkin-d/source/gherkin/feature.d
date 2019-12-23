module gherkin.feature;

import std.algorithm : map;
import std.array : array;
import std.json : JSONValue, parseJSON;
import std.range : empty;
import std.typecons : Nullable;

import asdf : serializeToJson;
import gherkin.base : Base;
import gherkin.document : GherkinDocument;
import gherkin.location : Location;
import gherkin.scenario : Scenario;
import gherkin.tag : Tag;

///
class Feature : Base
{
    ///
    Scenario[] scenarios;
    ///
    Nullable!Scenario background;
    ///
    Nullable!string description;
    ///
    Tag[] tags;
    ///
    string language = "en";
    ///
    GherkinDocument parent;

    ///
    this(string keyword, string name, Location location, ref GherkinDocument parent)
    {
        super(keyword, name, location);
        this.parent = parent;
    }

    override JSONValue toJSON() const
    {
        auto json = super.toJSON;
        JSONValue[] children = [];
        json["language"] = JSONValue(language);

        if (!background.isNull)
        {
            children ~= JSONValue(["background": background.get.toJSON]);
        }
        if (!scenarios.empty)
        {
            children ~= scenarios.map!(x => JSONValue(["scenario": x.toJSON])).array;
        }
        if (!children.empty)
        {
            json["children"] = children;
        }
        if (!description.isNull)
        {
            json["description"] = parseJSON(serializeToJson(description.get));
        }
        if (!tags.empty)
        {
            json["tags"] = parseJSON(serializeToJson(tags));
        }

        return json;
    }
}
