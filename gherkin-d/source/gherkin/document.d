module gherkin.document;

import std.typecons : Nullable;

import asdf : serializationIgnore, serializationIgnoreOutIf, serializationTransformOut;
import gherkin.comment : Comment;
import gherkin.feature : Feature;

///
struct GherkinDocument
{
    ///
    string uri;
    ///
    @serializationIgnore string[] document;
    ///
    @serializationIgnoreOutIf!`a.isNull`@serializationTransformOut!`a.get` Nullable!Feature feature;
    ///
    @serializationIgnoreOutIf!`a.empty` Comment[] comments;
}
