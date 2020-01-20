module gherkin.datatable;

import std.array : array, empty, replace;

import asdf : serializationIgnore, serializationIgnoreOutIf;
import gherkin.location : Location;

///
struct Cell
{
    ///
    @serializationIgnoreOutIf!`a.empty` string value;
    ///
    Location location;

    ///
    void replace(string from, string to)
    {
        this.value = this.value.replace(from, to);
    }
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

    ///
    @serializationIgnore @property bool empty() const
    {
        return cells.empty;
    }

    ///
    void replace(string from, string to)
    {
        foreach (ref cell; this.cells)
        {
            cell.replace(from, to);
        }
    }

    ///
    this(ref return scope TableRow rhs)
    {
        this.id = rhs.id;
        this.cells = rhs.cells.array.dup;
        this.location = rhs.location;
    }

    ///
    this(ref return scope inout TableRow rhs) inout
    {
        foreach (i, ref inout field; rhs.tupleof)
        {
            this.tupleof[i] = field;
        }
    }

    ///
    this(string id, Cell[] cells, Location location)
    {
        this.id = id;
        this.cells = cells.array.dup;
        this.location = location;
    }
}

///
struct DataTable
{
    ///
    TableRow[] rows;
    ///
    Location location;

    ///
    @serializationIgnore @property bool empty() const
    {
        return rows.empty;
    }

    ///
    void replace(string from, string to)
    {
        foreach (ref tableRow; this.rows)
        {
            tableRow.replace(from, to);
        }
    }

    ///
    this(ref return scope DataTable rhs)
    {
        this.rows = rhs.rows.array.dup;
        this.location = rhs.location;
    }

    ///
    this(ref return scope inout DataTable rhs) inout
    {
        foreach (i, ref inout field; rhs.tupleof)
        {
            this.tupleof[i] = field;
        }
    }

    ///
    this(TableRow[] rows, Location location)
    {
        this.rows = rows.array.dup;
        this.location = location;
    }
}
