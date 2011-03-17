/**
 *
 *  Copyright: Copyright QtD Team, 2008-2009
 *  Authors: Max Samukha, Eldar Insafutdinov
 *  License: <a href="http://www.boost.org/LICENSE_1_0.txt>Boost License 1.0</a>
 *
 *  Copyright QtD Team, 2008-2009
 *  Distributed under the Boost Software License, Version 1.0.
 *  (See accompanying file boost-license-1.0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
 *
 */
module qtd.Signal;

import core.stdc.stdlib : crealloc = realloc, cfree = free;
import core.stdc.string : memmove;
import std.string : strip;

import
    core.thread,
    core.exception,

    std.typetuple,
    std.conv,
    std.traits,

    qt.QGlobal,
    qtd.String,
    qtd.Marshal,
    qtd.meta.Compiletime,
    qtd.ctfe.Format;

/** The beast that takes string representation of function arguments
  * and returns an array of default values it doesn't check if arguments
  * without default values follow the arguments with default values for
  * simplicity. It is done by mixing in a delegate alias.
  */
string[] defaultValues(string signature)
{
    int braces = 0;
    bool inDefaultValue = false;
    bool inStringLiteral = false;
    string[] res;
    sizediff_t startValue = 0;

    if(strip(signature).length == 0)
        return res;

    foreach (i,c; signature)
    {
        if(!inStringLiteral)
        {
            if(c == '{' || c =='(')
                braces++;
            else if(c == '}' || c ==')')
                braces--;
        }

        if(c == '\"' || c == '\'')
        {
            if (inStringLiteral)
            {
                if(signature[i-1] != '\\')
                    inStringLiteral = false;
            }
            else
            {
                inStringLiteral = true;
            }
        }

        if (!inStringLiteral && braces == 0)
        {
            if(c == '=') // found default value
            {
                inDefaultValue = true;
                startValue = i+1;
            }
            else if(c == ',') // next function argument
            {
                if (inDefaultValue)
                {
                    res ~= signature[startValue..i];
                    inDefaultValue = false;
                }
            }
        }
    }

    if (inDefaultValue)
        res ~= signature[startValue..$];

    return res;
}

/**
    Generates D-to-C++ conversion code for signals.
 */
string genConvToCpp(uint argIndex)
{
    string res = format_ctfe(q{

        static if (isStringType!(Args[${0}]))
        {
           auto _tmp${0} = QString(_t${0});
           _a[${0}] = cast(void*)&_tmp${0};
        }
        else static if (isQObjectType!(Args[${0}]) || isObjectType!(Args[${0}]))
        {
            void* _tmp${0} = _t${0} ? _t${0}.qtdNativeId : null;
            _a[${0}] =  &_tmp${0};
        }
        else static if (isValueType!(Args[${0}]))
           _a[${0}] = _t${0}.qtdNativeId;
        else
           _a[${0}] = cast(void*)&_t${0};

    }, argIndex);

    return res;
}

string genSignalEmitter(SignalKind signalKind, string name, uint localIndex, uint argCount)
{
    string res;

    // signature
    //
    if (signalKind != SignalKind.BindQtSignal)
        res ~= "protected ";

    res ~= "Args[0] " ~ name;

    if (signalKind == SignalKind.BindQtSignal)
        res ~= "_emit";

    res ~= "(";

    foreach (i; 1..argCount)
    {
        auto iStr = to!string(i);
        if (i > 1)
            res ~= ", ";
        res ~= "Args[" ~ iStr ~ "] _t" ~ iStr;
    }

    res ~= ") {\n";

    // body
    //
    res ~= "    void*[" ~ to!string(argCount) ~ "] _a;\n";
    foreach (i; 1..argCount)
        res ~= genConvToCpp(i);

    res  ~= "    QMetaObject.activate(this, typeof(this).staticMetaObject, "
        ~ to!string(localIndex) ~ ", _a.ptr);\n";

    return res ~= "}\n";
}

// BUG: parameter storage classes are not supported yet
mixin template SignalEmitter(SignalKind signalKind, int localIndex)
{
    import std.traits;

    alias signals[localIndex] signal;
    alias TypeTuple!(ReturnType!(signal), ParameterTypeTuple!(signal)) Args;

    /+
    pragma(msg, genSignalEmitter(signalKind,
        methodName!signal,
        localIndex,
        Args.length));
    +/

    mixin (genSignalEmitter(signalKind,
        methodName!signal,
        localIndex,
        Args.length));
}
/** ---------------- */


enum SignalKind
{
    BindQtSignal,
    NewSignal,
    NewSlot
}

string signature(T...)(string name)
{
    string res = name ~ "(";
    foreach(i, _; T)
    {
        if(i > 0)
            res ~= ",";
        static if (isNativeType!(T[i]))
            res ~= Unqual!(T[i]).stringof;
        else
            res ~= T[i].stringof;
    }
    res ~= ")";
    return res;
}

// ------------------------------------------------------------------

string[] getSymbols(C)(string prefix)
{
    string[] result;
    foreach(s; __traits(derivedMembers, C))
    {
        if(startsWith(s, prefix))
            result ~= s;
    }
    return result;
}

string removePrefix(string source)
{
    foreach (i, c; source)
    {
        if (c == '_')
            return source[i+1..$];
    }
    return source;
}

// recursive search in the static meta-information
template findSymbolsImpl2(C, alias signals, int id)
{
    alias qtd.meta.Compiletime.Alias!(__traits(getOverloads, C, signals[id])) current;
    static if (signals.length - id - 1 > 0)
        alias TypeTuple!(current, findSymbolsImpl2!(C, signals, id + 1).result) result;
    else
        alias TypeTuple!(current) result;
}

template findSymbols2(C, string prefix)
{
    enum signals = getSymbols!(C)(prefix);
    static if (signals)
        alias findSymbolsImpl2!(C, signals, 0).result result;
    else
        alias TypeTuple!() result;
}

template findSignals(C)
{
    alias findSymbols2!(C, "signal_").result findSignals;
}

template findSlots(C)
{
    alias findSymbols2!(C, "slot_").result findSlots;
}

template methodName(alias method)
{
    enum methodName = removePrefix(__traits(identifier, method));
}
