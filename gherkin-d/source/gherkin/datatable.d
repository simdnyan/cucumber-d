module gherkin.datatable;

import asdf : serializationIgnoreOutIf;
import gherkin.location : Location;

///
struct Cell
{
    ///
    @serializationIgnoreOutIf!`a.empty` string value;
    ///
    Location location;
}

///
struct TableRow
{
    ///
    string id;
    ///
    Cell[] cells;
    ///
    Location location;
}

///
struct DataTable
{
    ///
    TableRow[] rows;
    ///
    Location location;
}
