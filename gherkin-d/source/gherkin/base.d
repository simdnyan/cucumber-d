module gherkin.base;

import std.json : parseJSON, JSONValue;
import std.string : empty;
import std.typecons : Nullable;

import asdf : serializeToJson;
import gherkin.location;

///
abstract class Base
{
    ///
    string keyword;
    ///
    Nullable!string name;
    ///
    Location location;

    ///
    this(string keyword, string name, Location location)
    {
        this.keyword = keyword;
        this.location = location;
        if (!name.empty)
        {
            this.name = name;
        }
    }

    ///
    JSONValue toJSON() const
    {
        auto json = JSONValue([
                "keyword": JSONValue(keyword),
                "location": parseJSON(serializeToJson(location))
                ]);
        if (!name.isNull)
        {
            json["name"] = JSONValue(name.get);
        }

        return json;
    }
}
