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

public import qt.QGlobal;
import qtd.MetaMarshall;
import qtd.Meta;

import core.stdc.stdlib : crealloc = realloc, cfree = free;
import core.stdc.string : memmove;
import
    core.thread,
    core.exception,
    std.algorithm;

public import
    std.typetuple,
    std.traits,
    std.conv,
    std.metastrings;

public import std.string : strip, toStringz;
   
/** The beast that takes string representation of function arguments
  * and returns an array of default values it doesn't check if arguments
  * without default values follow the arguments with default values for
  * simplicity. It is done by mixing in an delegate alias.
  */
string[] defaultValues(string signature)
{
    int braces = 0;
    bool inDefaultValue = false;
    bool inStringLiteral = false;
    string[] res;
    int startValue = 0;
    
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

int defaultValuesLength(string[] defVals)
{
    return defVals.length;
}


// templates for extracting data from static meta-information of signals, slots or properties
// public alias TypeTuple!("name", index, OwnerClass, ArgTypes) __signal
template MetaEntryName(source...)
{
    enum MetaEntryName = source[0]; // name of the metaentry is the first element
}

template MetaEntryOwner(source...)
{
    alias TupleWrapper!(source[2]).at[0] MetaEntryOwner; // class that owns the property is the third
    // Compiler #BUG 3092 - evaluates MetaEntryOwner as a Tuple with one element
}

template MetaEntryArgs(source...)
{
    alias ParameterTypeTuple!(source[1]) MetaEntryArgs; // arguments-tuple starts from the fourth position
}

template TupleWrapper(A...) { alias A at; }

string convertSignalArguments(Args...)()
{
//        void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    // at least for string argument need to construct a QString value
    string res = prepareSignalArguments!(Args);
    
    res ~= "void*[" ~ __toString(Args.length+1) ~ "] _a = [null";
    foreach(i, _; Args)
        res ~= ", " ~ "cast(void*) (" ~ convertSignalArgument!(Args[i])("_t" ~ __toString(i)) ~ ")";
    res ~= "];\n";
    return res;
}

public string SignalEmitter(A...)(SignalType signalType, string name, string[] defVals, int localIndex)
{
    string fullArgs, args;
    int defValsLength = defVals.length;
    string argsConversion = "";
    string argsPtr = "null";
    static if (A.length)
    {
        while(A.length != defVals.length)
            defVals = "" ~ defVals;
        
        fullArgs = A[0].stringof ~ " _t0";
        if (defVals[0].length)
            fullArgs ~= " = " ~ defVals[0];
        args = "_t0";
        foreach(i, _; A[1..$])
        {
            fullArgs ~= ", " ~ A[i+1].stringof ~ " _t" ~ __toString(i+1);
            if (defVals[i+1].length)
                fullArgs ~= " = " ~ defVals[i+1];
            args ~= ", _t" ~ __toString(i+1);
        }
        // build up conversion of signal args from D to C++
        argsPtr = "_a.ptr";
        argsConversion = convertSignalArguments!(A)();
    }
    string attribute;
    string sigName = name;
    if (signalType == SignalType.BindQtSignal)
        name ~= "_emit";
    else
        attribute = "protected ";
    
    string indexArgs = __toString(localIndex);
    if(defValsLength > 0)
        indexArgs ~= ", " ~ __toString(localIndex+defValsLength);
    string str = attribute ~ "final void " ~ name ~ "(" ~ fullArgs ~ ") {\n" ~ argsConversion ~ "\n"
                           ~ "    QMetaObject.activate(this, typeof(this).staticMetaObject, " ~ indexArgs ~ ", " ~ argsPtr ~ ");\n"
                           ~ "}\n"; // ~
    return str;
}
/** ---------------- */


const string signalPrefix = "__signal";
const string slotPrefix = "__slot";

enum SignalType
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
    auto allSymbols = __traits(derivedMembers, C);
    foreach(s; allSymbols)
        if(ctfeStartsWith(s, prefix))
            result ~= s;
    return result;
}

string removePrefix(string source)
{
    foreach (i, c; source)
        if (c == '_')
            return source[i+1..$];
    return source;
}

template Alias(T...)
{
    alias T Alias;
}

// recursive search in the static meta-information
template findSymbolsImpl2(C, alias signals, int id)
{
    alias Alias!(__traits(getOverloads, C, signals[id])) current;
    static if (signals.length - id - 1 > 0)
        alias TypeTuple!(current, findSymbolsImpl2!(C, signals, id + 1).result) result;
    else
        alias current result;
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

/* commented out for future when we will implement default arguments
template metaMethods(alias func, int index, int defValsCount)
{
    static if(defValsCount >= 0) {
        alias TupleWrapper!(func, index) current;
//        pragma(msg, __traits(identifier, (current.at)[0]) ~ " " ~ typeof(&(current.at)[0]).stringof);
        alias metaMethods!(func, index+1, defValsCount-1).result next;
        alias TypeTuple!(current, next) result;
    }
    else
    {
        alias TypeTuple!() result;
    }
}
*/

template toMetaEntriesImpl(int id, Methods...)
{
    static if (Methods.length > id)
    {
        alias typeof(&Methods[id]) Fn;
//    commented out for future when we will implement default arguments
//        enum defValsLength = 0; //ParameterTypeTuple!(Fn).length - requiredArgCount!(Methods[id])();
//        pragma(msg, __traits(identifier, Methods[id]) ~ " " ~ typeof(&Methods[id]).stringof);
//        alias metaMethods!(Methods[id], 0, defValsLength).result subres;
        alias TupleWrapper!(removePrefix(__traits(identifier, Methods[id])), typeof(&Methods[id])) subres;
        alias TypeTuple!(subres, toMetaEntriesImpl!(id+1, Methods).result) result;
    }
    else
    {
        alias TypeTuple!() result;
    }
}

template toMetaEntries(Methods...)
{
    alias TupleWrapper!(toMetaEntriesImpl!(0, Methods).result) toMetaEntries;
}
