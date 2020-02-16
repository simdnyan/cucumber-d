module gherkin.scenario;

import std.range : empty;
import std.typecons : Nullable;

import asdf : serializationIgnore, serializationIgnoreOutIf, serializationTransformOut;
import gherkin.base : Base;
import gherkin.comment : Comment;
import gherkin.datatable : TableRow;
import gherkin.location : Location;
import gherkin.step : Step;
import gherkin.tag : Tag;

alias Background = Scenario;

///
class Scenario : Base
{
    ///
    @serializationIgnore bool isBackground;
    ///
    @serializationIgnoreOutIf!`a.isNull`@serializationTransformOut!`a.get` Nullable!string id;
    ///
    @serializationIgnoreOutIf!`a.empty` Step[] steps;
    ///
    @serializationIgnoreOutIf!`a.empty` string description;
    ///
    @serializationIgnoreOutIf!`a.empty` Examples[] examples;
    ///
    @serializationIgnoreOutIf!`a.empty` Tag[] tags;
    ///
    @serializationIgnore Comment[] comments;
    ///
    @serializationIgnore bool isScenarioOutline;
    ///
    @serializationIgnore string uri;

    ///
    this(string keyword, string name, Location location, bool isBackground,
            string uri, ref Comment[] comments)
    {
        super(keyword, name, location);
        this.isBackground = isBackground;
        this.uri = uri;
        this.comments = comments.dup;
        comments = [];
        this.description = "";
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
    @serializationIgnoreOutIf!`a.empty` string description;
    ///
    @serializationIgnore Comment[] comments;
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
        this.comments = rhs.comments.dup;
    }

    ///
    this(string keyword, string name, Location location, TableRow[] tableRows,
            string description, ref Comment[] comments)
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
        this.comments = comments.dup;
        comments = [];
    }
}
