module gherkin.base;

import asdf : serializationIgnoreOutIf;
import gherkin.location;

///
abstract class Base
{
    ///
    string keyword;
    ///
    @serializationIgnoreOutIf!`a.empty` string name;
    ///
    Location location;

    ///
    this(string keyword, string name, Location location)
    {
        this.keyword = keyword;
        this.location = location;
        this.name = name;
    }
}
