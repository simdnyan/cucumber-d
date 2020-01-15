module gherkin.step;

import std.array : replace;
import std.typecons : Nullable;

import asdf : serializationIgnoreOutIf, serializationIgnoreOut;
import gherkin.comment : Comment;
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
    @serializationIgnoreOutIf!`a.empty` DataTable dataTable;
    ///
    @serializationIgnoreOut Comment[] comments;

    ///
    void replace(string from, string to)
    {
        this.text = this.text.replace(from, to);
        if (!this.dataTable.empty)
        {
            this.dataTable.replace(from, to);
        }
        if (!this.docString.isNull)
        {
            this.docString.get.replace(from, to);
        }
    }

    ///
    this(ref return scope inout Step rhs) inout
    {
        foreach (i, ref inout field; rhs.tupleof)
        {
            this.tupleof[i] = field;
        }
    }

    ///
    this(ref return scope Step rhs)
    {
        foreach (i, ref field; rhs.tupleof)
        {
            this.tupleof[i] = field;
        }
    }

    ///
    this(string keyword, string text, Location location, Scenario parent)
    {
        this.keyword = keyword;
        this.text = text;
        this.location = location;
        this.parent = parent;
    }
}
