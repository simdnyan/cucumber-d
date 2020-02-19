module gherkin.feature;

import std.algorithm : map;
import std.array : array;
import std.typecons : Nullable;

import asdf : serializationIgnore, serializationIgnoreOutIf;
import gherkin.base : Base;
import gherkin.comment : Comment;
import gherkin.document : GherkinDocument;
import gherkin.location : Location;
import gherkin.scenario : Scenario;
import gherkin.tag : Tag;

///
class Feature : Base
{
    ///
    @serializationIgnore Scenario[] scenarios;
    ///
    @serializationIgnore Nullable!Scenario background;
    ///
    @serializationIgnoreOutIf!`a.empty` string description;
    ///
    @serializationIgnoreOutIf!`a.empty` Tag[] tags;
    ///
    @serializationIgnore Comment[] comments;
    ///
    string language = "en";
    ///
    @serializationIgnore string uri;

    ///
    this(string keyword, string name, Location location, string uri, ref Comment[] comments)
    {
        super(keyword, name, location);
        this.uri = uri;
        this.comments = comments.dup;
        comments = [];
        this.description = "";
    }

    ///
    @property @serializationIgnoreOutIf!`a.empty` Child[] children()
    {
        Child[] result;
        if (!background.isNull)
        {
            result ~= Child(background.get);
        }
        result ~= scenarios.map!(s => Child(s)).array;

        return result;
    }

    private struct Child
    {
        @serializationIgnore Scenario child;

        @property @serializationIgnoreOutIf!`!a.isBackground` Scenario background()
        {
            return child;
        }

        @property @serializationIgnoreOutIf!`a.isBackground` Scenario scenario()
        {
            return child;
        }
    }
}
