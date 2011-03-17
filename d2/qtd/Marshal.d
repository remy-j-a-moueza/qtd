module qtd.Marshal;

import
    std.traits,
    qtd.meta.Compiletime,
    qtd.String,
    qtd.ctfe.Format;


template isQObjectType(T) //
{
    enum isQObjectType = is(T.__isQObjectType);
}

template isObjectType(T)
{
    enum isObjectType = is(T.__isObjectType);
}

template isValueType(T)
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
template isNativeType(T)
{
    enum isNativeType = isNumeric!T || is(T == bool) || is(T == struct);
}

template isStringType(T) // string type
{
    enum isStringType = is(T == string);
}

template isQList(T)
{
    enum isQList = startsWith(Unqual!(T).stringof, "QList!"); //hack
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
        static if (is(T.ElementType == string))
            return "QStringList";
        else
            return "QList<" ~ qtDeclArg!(T.ElementType)() ~ ">";
    }
    else static if (is(T == enum))
        return enumFullName!T;
    else static if (isNativeType!T)
        return Unqual!T.stringof;
    else
        return T.stringof;
}

/**
    Generates C++-to-D conversion code for the
    argument argIndex.
 */
string generateConvToD(size_t argIndex)
{
    string res = format_ctfe(q{

        static if (isQObjectType!(Args[${0}]) || isObjectType!(Args[${0}]))
            auto _out${0} = Args[${0}].__getObject(*cast(void**)_a[${0}]);
        else static if (isValueType!(Args[${0}]))
        {
            // COMPILER BUG: 'new' chokes on Args[argIndex], hence the alias
            alias Args[${0}] Args${0};
            auto _out${0} = new Args${0}(Args[${0}].__constructNativeCopy(_a[${0}]));
        }
        else static if (isStringType!(Args[${0}]))
            auto _out${0} = QStringUtil.toNativeString(_a[${0}]);
        else
        {
            auto _out${0} = *cast(Args[${0}]*)_a[${0}];
        }

    }, argIndex);

    return res;
}

