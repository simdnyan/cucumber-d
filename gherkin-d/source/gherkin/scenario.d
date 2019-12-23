module gherkin.scenario;

import std.json : JSONValue, parseJSON;
import std.range : empty;
import std.typecons : Nullable;

import asdf : serializationIgnoreOutIf, serializationTransformOut, serializeToJson;
import gherkin.base : Base;
import gherkin.datatable : TableRow;
import gherkin.feature : Feature;
import gherkin.location : Location;
import gherkin.step : Step;
import gherkin.tag : Tag;

alias Background = Scenario;

///
class Scenario : Base
{
    ///
    Feature parent;
    ///
    bool isBackground;
    ///
    Nullable!string id;
    ///
    Step[] steps;
    ///
    Nullable!string description;
    ///
    Examples[] examples;
    ///
    Tag[] tags;
    ///
    bool isScenarioOutline;

    ///
    this(string keyword, string name, Location location, Feature parent, bool isBackground)
    {
        super(keyword, name, location);
        this.parent = parent;
        this.isBackground = isBackground;
    }

    ///
    override JSONValue toJSON() const
    {
        auto json = super.toJSON;

        if (!id.isNull)
        {
            json["id"] = JSONValue(id.get);
        }
        if (!steps.empty)
        {
            json["steps"] = parseJSON(serializeToJson(steps));
        }
        if (!description.isNull)
        {
            json["description"] = parseJSON(serializeToJson(description.get));
        }
        if (!examples.empty)
        {
            json["examples"] = parseJSON(serializeToJson(examples));
        }
        if (!tags.empty)
        {
            json["tags"] = parseJSON(serializeToJson(tags));
        }

        return json;
    }
}

///
struct Examples
{
    ///
    string keyword;
    ///
    @serializationIgnoreOutIf!`a.empty` string name;
    ///
    Location location;
    ///
    @serializationIgnoreOutIf!`a.isNull`@serializationTransformOut!`a.get` Nullable!TableRow tableHeader;
    ///
    @serializationIgnoreOutIf!`a.empty` TableRow[] tableBody;
    ///
    @serializationIgnoreOutIf!`a.isNull`@serializationTransformOut!`a.get` Nullable!string description;
    ///
    @serializationIgnoreOutIf!`a.empty` Tag[] tags;
}
