module gherkin.docstring;

import std.array : replace;

import asdf : serializationIgnoreOutIf;
import gherkin.location : Location;

///
struct DocString
{
    ///
    string content;
    ///
    @serializationIgnoreOutIf!`a.empty` string contentType;
    ///
    string delimiter;
    ///
    Location location;

    ///
    void replace(string from, string to)
    {
        this.content = content.replace(from, to);
    }
}
