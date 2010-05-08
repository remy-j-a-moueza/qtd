module qt.qtd.MetaMarshall;

import std.traits;

import qt.qtd.Meta;

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

template isQtType(T)
{
    mixin ("enum isQtType = is(T.__isQtType_" ~ T.stringof ~ ");");
}
/*
template isQtType(T)
{
    enum isQtType = isQObjectType!(T) || isObjectType!(T) || isValueType!(T) || is(T.__isQtType);
}
*/
template isNativeType(T) // type that doesn't require conversion i.e. is the same in C++ and D
{
    enum isNativeType = isNumeric!T || is(T == bool) || is(T == struct);
}

template isStringType(T) // string type
{
    enum isStringType = is(T == string);
}

template isQList(T)
{
    enum isQList = ctfeStartsWith(Unqual!(T).stringof, "QList!");
}

// returns full name of enum:
// for Qt enum it is in the form of QPaintDevice::PaintDeviceMetric
// for pure D enums it is Foo.Bar
template enumFullName(T)
{
    static if(!isModule(__traits(parent, T).stringof))
    {
        static if(isQtType!(__traits(parent, T)))
            enum enumFullName = qualifiedCppName!T;
        else
            enum enumFullName = qualifiedDName!T;
    }
    else
        enum enumFullName = qualifiedDName!T;
            
}

// converts an argumnent from C++ to D in qt_metacall
string metaCallArgument(T)(string ptr)
{
    static if (isQObjectType!T || isObjectType!T)
        return T.stringof ~ ".__getObject(*cast(void**)(" ~ ptr ~ "))";
    else static if (isValueType!T)
        return "new " ~ T.stringof ~ "(" ~ T.stringof ~ ".__constructNativeCopy(" ~ ptr ~ "))";
    else static if (isNativeType!T)
        return "*(cast(" ~ T.stringof ~ "*)" ~ ptr ~ ")";
    else static if (isStringType!T)
        return "QStringUtil.toNativeString(" ~ ptr ~ ")";
    else static if (is(T == enum))
        return "*(cast(" ~ qualifiedDName!T ~ "*)" ~ ptr ~ ")";
    else
        return "*(cast(" ~ T.stringof ~ "*)" ~ ptr ~ ")";
        //res = T.stringof;
}

// converts a D argument type to C++ for registering in Qt meta system
string qtDeclArg(T)()
{
    static if (isQObjectType!T || isObjectType!T)
        return T.stringof ~ "*";
    else static if (isValueType!T)
        return T.stringof;
    else static if (isStringType!T)
        return "QString";
    else static if (isQList!T)
    {
        alias templateParam!T ElementType;
        static if (is(ElementType == string))
            return "QStringList";
        else
            return "QList<" ~ qtDeclArg!(templateParam!T)() ~ ">";
    }
    else static if (is(T == enum))
        return enumFullName!T;
    else static if (isNativeType!T)
        return Unqual!T.stringof;
    else
        return T.stringof;
}

// converts an argument from D to C++ in a signal emitter
string convertSignalArgument(T)(string arg)
{
    static if (isQObjectType!T || isObjectType!T)
        return arg ~ " ? " "&" ~ arg ~ ".__nativeId : cast(void**) &" ~ arg; // since it is a pointer type check arg for null
    else static if (isValueType!T)
        return arg ~ ".__nativeId";
    else static if (isStringType!T)
        return "&_qt" ~ arg;
    else static if (isNativeType!T)
        return "&" ~ arg;
    else
        return "&" ~ arg;
}

string prepareSignalArguments(Args...)()
{
    string res;
    foreach(i, _; Args)
        static if (isStringType!(Args[i]))
            res ~= "auto _qt_t" ~ __toString(i) ~ " = QString(_t" ~ __toString(i) ~ ");\n";
    return res;
}
