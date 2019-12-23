module gherkin.docstring;

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
}
