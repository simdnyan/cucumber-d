module gherkin.tag;

import gherkin.location : Location;

///
struct Tag
{
    ///
    string name;
    ///
    Location location;
    ///
    string id;
}
