module gherkin.step;

import std.typecons : Nullable;

import asdf : serializationIgnoreOutIf, serializationIgnoreOut;
import gherkin.datatable : DataTable;
import gherkin.docstring : DocString;
import gherkin.location : Location;
import gherkin.scenario : Scenario;

///
struct Step
{
    ///
    string keyword;
    ///
    string text;
    ///
    Location location;
    ///
    @serializationIgnoreOut Scenario parent;
    ///
    string id;
    ///
    @serializationIgnoreOutIf!`a.isNull` Nullable!DocString docString;
    ///
    @serializationIgnoreOutIf!`a.isNull` Nullable!DataTable dataTable;
}
