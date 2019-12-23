module gherkin.document;

import std.json : JSONValue, parseJSON;
import std.range : empty;
import std.typecons : Nullable;

import asdf : serializeToJson;
import gherkin.comment : Comment;
import gherkin.feature : Feature;

///
struct GherkinDocument
{
    ///
    string uri;
    ///
    string[] document;
    ///
    Nullable!Feature feature;
    ///
    Comment[] comments;

    ///
    JSONValue toJSON() const
    {
        auto json = JSONValue(["uri": JSONValue(uri)]);

        if (!feature.isNull)
        {
            json["feature"] = feature.get.toJSON();
        }

        if (!comments.empty)
        {
            json["comments"] = parseJSON(serializeToJson(comments));
        }

        return JSONValue(["gherkinDocument": json]);
    }
}
