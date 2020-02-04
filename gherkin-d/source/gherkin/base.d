module gherkin.base;

import std.json : parseJSON, JSONValue;
import std.string : empty;
import std.typecons : Nullable;

import asdf : serializationIgnoreOutIf, serializationTransformOut, serializeToJson;
import gherkin.location;

///
abstract class Base
{
    ///
    string keyword;
    ///
    @serializationIgnoreOutIf!`a.isNull`@serializationTransformOut!`a.get` Nullable!string name;
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
    string getName()
    {
        return name.isNull ? `` : name.get;
    }
}
