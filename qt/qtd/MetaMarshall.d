module qt.qtd.MetaMarshall;

import std.traits;

// shouldn't be here

string __toString(long v)
{
    if (v == 0)
        return "0";

    string ret;

    bool neg;
    if (v < 0)
    {
        neg = true;
        v = -v;
    }

    while (v != 0)
    {
        ret = cast(char)(v % 10 + '0') ~ ret;
        v = cast(long)(v / 10);
    }

    if (neg)
        ret = "-" ~ ret;

    return ret;
}

template isQObjectType(T) // is a QObject type that belongs to the library
{
    enum isQObjectType = is(T.__isQObjectType);
}

template isObjectType(T) // is a Qt Object type that belongs to the library
{
    enum isObjectType = is(T.__isObjectType);
}

template isValueType(T) // is a Qt Value type that belongs to the library
{
    enum isValueType = is(T.__isValueType);
}

template isNativeType(T) // type that doesn't require conversion i.e. is the same in C++ and D
{
    enum isNativeType = isNumeric!T || is(T == bool) || is(T == struct);
}

template isStringType(T) // string type
{
    enum isStringType = is(T == string);
}

// converts an argumnent from C++ to D in qt_metacall
string metaCallArgument(T)(string ptr)
{
    static if (isQObjectType!T || isObjectType!T)
        return T.stringof ~ ".__getObject(*cast(void**)(" ~ ptr ~ "))";
    else static if (isNativeType!T)
        return "*(cast(" ~ T.stringof ~ "*)" ~ ptr ~ ")";
    else static if (isStringType!T)
        return "QStringUtil.toNativeString(" ~ ptr ~ ")";
    else
        return "*(cast(" ~ T.stringof ~ "*)" ~ ptr ~ ")";
        //res = T.stringof;
}

// converts a D argument type to C++ for registering in Qt meta system
string qtDeclArg(T)()
{
    static if (isQObjectType!T || isObjectType!T)
        return T.stringof ~ "*";
    else static if (isStringType!T)
        return "QString";
    else static if (isNativeType!T)
        return Unqual!T.stringof;
    else
        return T.stringof;
}

// converts an argument from D to C++ in a signal emitter
string convertSignalArgument(T)(string arg)
{
    static if (isQObjectType!T || isObjectType!T)
        return arg ~ ".__nativeId";
    else static if (isStringType!T)
        return "_qt" ~ arg;
    else static if (isNativeType!T)
        return arg;
    else
        return arg;
}

string prepareSignalArguments(Args...)()
{
    string res;
    foreach(i, _; Args)
        static if (isStringType!(Args[i]))
            res ~= "auto _qt_t" ~ __toString(i) ~ " = QString(_t" ~ __toString(i) ~ ");\n";
    return res;
}
