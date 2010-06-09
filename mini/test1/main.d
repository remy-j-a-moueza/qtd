import qt.core.QMetaType;

import std.stdio;
import std.conv;
import qtd.QtdObject;

class A
{
    string name;

    this(A copy)
    {
        writeln("Creating new from ", copy.name);
        name = "Copy of " ~ copy.name;
    }

    this(string name)
    {
        this.name = name;
    }

    void dispose()
    {
        writeln("Disposing ", name);
    }
}

void main(string[] args)
{
}
