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
    int id = qRegisterMetaType!A();
    qRegisterMetaTypeStreamOperators!A();

    foreach (i; 0..10)
    {
        writeln("Iter ", i);

        void foo(int x, int y, int z)
        {
            auto a = new A("A" ~ to!string(i));
            auto b = cast(A)QMetaType.construct(id, cast(void*)a);
            writeln(b.name);

            QMetaType.destroy(id, cast(void*)a);
            QMetaType.destroy(id, cast(void*)b);

            scope ds = new QDataStream(cast(void*)3, QtdObjectFlags.nativeOwnership);
            QMetaType.save(ds, id, cast(void*)i);
            QMetaType.load(ds, id, cast(void*)i);
            writeln("Done iterating ", x, " ", y, " ", z);
        }

        foo(i + 1, i + 2, i + 3);
    }
    /+

    writeln("Great!");


    writeln("Even greater!");
    +/

}
