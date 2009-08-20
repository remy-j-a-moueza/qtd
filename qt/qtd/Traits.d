module qt.qtd.Traits;

version (D_Version2)
{
    public import std.traits;
}
else
{
    public import tango.core.Traits : BaseTypeTuple = BaseTypeTupleOf;
}
