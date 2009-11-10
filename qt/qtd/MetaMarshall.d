module qt.qtd.MetaMarshall;

import std.traits;

template isQObjectType(T) // is a QObject type that belongs to the library
{
    enum isQObjectType = is(T.__isQObjectType);
}

template isObjectType(T) // is a QObject type that belongs to the library
{
    enum isObjectType = is(T.__isObjectType);
}

template isValueType(T) // is a QObject type that belongs to the library
{
    enum isQObjectType = is(typeof(mixin("T." ~ "__isValueType")));
}

template isNativeType(T) // type that doesn't require conversion i.e. is the same in C++ and D
{
    enum isNativeType = isNumeric!T || is(T == bool);
}

// converts an argumnent from C++ to D in qt_metacall
string metaCallArgument(T)(string ptr)
{
    static if (isQObjectType!T)
        return T.stringof ~ ".__getObject(*cast(void**)(" ~ ptr ~ "))";
    else static if (isNativeType!T)
        return "*(cast(" ~ T.stringof ~ "*)" ~ ptr ~ ")";
    else
        return "*(cast(" ~ T.stringof ~ "*)" ~ ptr ~ ")";
        //res = T.stringof;
}

// converts a D argument type to C++ for registering in Qt meta system
string qtDeclArg(T)()
{
    static if (isQObjectType!T)
        return T.stringof ~ "*";
    else static if (isNativeType!T)
        return T.stringof;
    else
        return T.stringof;
}

// converts an argument from D to C++ in a signal emitter
string convertSignalArgument(T)(string arg)
{
    static if (isQObjectType!T)
        return arg ~ ".__nativeId";
    else static if (isNativeType!T)
        return arg;
    else
        return arg;
}
