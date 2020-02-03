module gherkin.scenario;

import std.json : JSONValue, parseJSON;
import std.range : empty;
import std.typecons : Nullable;

import asdf : serializationIgnore, serializationIgnoreOutIf, serializationTransformOut;
import gherkin.base : Base;
import gherkin.comment : Comment;
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
    @serializationIgnore Feature parent;
    ///
    @serializationIgnore bool isBackground;
    ///
    @serializationIgnoreOutIf!`a.isNull`@serializationTransformOut!`a.get` Nullable!string id;
    ///
    @serializationIgnoreOutIf!`a.empty` Step[] steps;
    ///
    @serializationIgnoreOutIf!`a.isNull`@serializationTransformOut!`a.get` Nullable!string description;
    ///
    @serializationIgnoreOutIf!`a.empty` Examples[] examples;
    ///
    @serializationIgnoreOutIf!`a.empty` Tag[] tags;
    ///
    @serializationIgnore Comment[] comments;
    ///
    @serializationIgnore bool isScenarioOutline;

    ///
    this(string keyword, string name, Location location, Feature parent, bool isBackground)
    {
        super(keyword, name, location);
        this.parent = parent;
        this.isBackground = isBackground;
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
    @serializationIgnoreOutIf!`a.empty` TableRow tableHeader;
    ///
    @serializationIgnoreOutIf!`a.empty` TableRow[] tableBody;
    ///
    @serializationIgnoreOutIf!`a.isNull`@serializationTransformOut!`a.get` Nullable!string description;
    ///
    @serializationIgnoreOutIf!`a.empty` Tag[] tags;

    ///
    this(ref return scope Examples rhs)
    {
        this.keyword = rhs.keyword;
        this.name = rhs.name;
        this.location = rhs.location;
        this.tableHeader = rhs.tableHeader;
        this.tableBody = rhs.tableBody.dup;
        this.description = rhs.description;
        this.tags = rhs.tags.dup;
    }

    ///
    this(string keyword, string name, Location location, TableRow[] tableRows,
            Nullable!string description)
    {
        this.keyword = keyword;
        this.name = name;
        this.location = location;
        if (!tableRows.empty)
        {
            this.tableHeader = tableRows[0];
            if (tableRows.length > 1)
            {
                this.tableBody = tableRows.dup[1 .. $];
            }
        }
        this.description = description;
    }
}
