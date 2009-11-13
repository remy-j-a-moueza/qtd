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
module qt.Signal;

public import qt.QGlobal;
import qt.qtd.MetaMarshall;

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
    std.string,
    std.metastrings;

   
// returns name, arguments or tuple of the function depending on type parameter
enum {_Name, _Tuple, _Args}
string getFunc(int type)(string fullName)
{
    int pos = 0;
    foreach(i, c; fullName)
        if (c == '(')
            static if (type == _Tuple)
                return fullName[i..$];
            else if (type == _Name)
                return fullName[0..i];
            else if (type == _Args)
                for(int j = fullName.length-1;; j--)
                    if(fullName[j] == ')')
                        return fullName[i+1 .. j];
    return null;
}

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

/**
    New implementation.
*/



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
    alias source[3 .. $] MetaEntryArgs; // arguments-tuple starts from the fourth position
}

template TupleWrapper(A...) { alias A at; }

template isDg(Dg)
{
    enum isDg = is(Dg == delegate);
}

template isFn(Fn)
{
    enum isFn = is(typeof(*Fn.init) == function);
}

template isFnOrDg(Dg)
{
    enum isFnOrDg = isFn!(Dg) || isDg!(Dg);
}

string joinArgs(A...)()
{
    string res = "";
    static if(A.length)
    {
        res = A[0].stringof;
        foreach(k; A[1..$])
            res ~= "," ~ k.stringof;
    }
    return res;
}

template SlotPred(T1, T2)
{
    enum SlotPred = is(T1 : T2);
}

template CheckSlot(alias Needle, alias Source)
{
    static if(Needle.at.length <= Source.at.length)
        enum CheckSlot = CheckArgs!(Needle, Source, SlotPred, 0).value;
    else
        enum CheckSlot = false;
}

template SignalPred(T1, T2)
{
    enum SignalPred = is(T1 == T2);
}

template CheckSignal(alias Needle, alias Source)
{
    static if(Needle.at.length == Source.at.length)
        enum CheckSignal = CheckArgs!(Needle, Source, SignalPred, 0).value;
    else
        enum CheckSignal = false;
}

template CheckArgs(alias Needle, alias Source, alias pred, int i)
{
    static if (i < Needle.at.length)
    {
        static if (pred!(Needle.at[i], Source.at[i]))
            enum value = CheckArgs!(Needle, Source, pred, i + 1).value;
        else
            enum value = false;
    }
    else
    {
        enum value = true;
    }
}

template SigByNamePred(string name, SlotArgs...)
{
    template SigByNamePred(source...)
    {
        static if (source[0] == name) // only instantiate CheckSlot if names match
            enum SigByNamePred = CheckSlot!(TupleWrapper!(SlotArgs), TupleWrapper!(source[2 .. $]));
        else
            enum SigByNamePred = false;
    }
}

template SigBySignPred(string name, SigArgs...)
{
    template SigBySignPred(source...)
    {
        static if (source[0] == name) // only instantiate CheckSignal if names match
            enum SigBySignPred = CheckSignal!(TupleWrapper!(SigArgs), TupleWrapper!(source[2 .. $]));
        else
            enum SigBySignPred = false;
    }
}

template ByOwner(Owner)
{
    template ByOwner(source...)
    {
        enum ByOwner = is(MetaEntryOwner!source == Owner);
    }
}

template staticSymbolName(string prefix, int id)
{
    const string staticSymbolName = prefix ~ ToString!(id);
}

template signatureString(string name, A...)
{
    const string signatureString = name ~ "(" ~ joinArgs!(A) ~ ")";
}

// recursive search in the static meta-information
template findSymbolImpl(string prefix, C, int id, alias pred)
{
    static if ( is(typeof(mixin("C." ~ staticSymbolName!(prefix, id)))) )
    {
        mixin ("alias C." ~ staticSymbolName!(prefix, id) ~ " current;");
        static if (pred!current)
            alias current result;
        else
            alias findSymbolImpl!(prefix, C, id + 1, pred).result result;
    }
    else
    {
        alias void result;
    }
}

template findSymbol(string prefix, C, alias pred)
{
    alias findSymbolImpl!(prefix, C, 0, pred).result findSymbol;
}

template findSignal(C, string name, Receiver, SigArgs...)
{
    alias TupleWrapper!(ParameterTypeTuple!Receiver) SlotArgsWr;
    static if (SigArgs.length > 0)
    {
        alias findSymbol!(signalPrefix, C, SigBySignPred!(name, SigArgs)) result;
        static if (is(result == void))
            static assert(0, "Signal " ~ name ~ "(" ~ joinArgs!SigArgs() ~ ") was not found.");
        else
            static if (!CheckSlot!(SlotArgsWr, TupleWrapper!(result[2 .. $])))
                static assert(0, "Signature of slot is incompatible with signal " ~ name ~ ".");
    }
    else
    {
        alias findSymbol!(signalPrefix, C, SigByNamePred!(name, SlotArgsWr.at)) result;
        static if (is(result == void))
            static assert(0, "Signal " ~ name ~ " was not found.");
    }
}

// recursive search in the static meta-information
template findSymbolsImpl(string prefix, C, int id, alias pred)
{
    static if ( is(typeof(mixin("C." ~ staticSymbolName!(prefix, id)))) )
    {
        mixin ("alias C." ~ staticSymbolName!(prefix, id) ~ " current;");
        static if (pred!current) {
            alias TupleWrapper!current subres;
//                    pragma(msg, toStringNow!id ~ " " ~ subres.stringof);
        } else
            alias TypeTuple!() subres;
        alias TypeTuple!(subres, findSymbolsImpl!(prefix, C, id + 1, pred).result) result;
    }
    else
    {
        alias TypeTuple!() result;
    }
}

template findSymbols(string prefix, C, alias pred)
{
    alias findSymbolsImpl!(prefix, C, 0, pred).result findSymbols;
}

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

string convertSignalArguments(Args...)()
{
//        void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };

    string res = "void*[" ~ __toString(Args.length+1) ~ "] _a = [null";
    foreach(i, _; Args)
        res ~= ", " ~ "cast(void*) &" ~ convertSignalArgument!(Args[i])("_t" ~ __toString(i));
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

template BindQtSignal(string fullName)
{
    mixin MetaMethodImpl!(signalPrefix, 0, fullName, SignalType.BindQtSignal);
}

template Signal(string fullName)
{
    mixin MetaMethodImpl!(signalPrefix, 0, fullName, SignalType.NewSignal);
}

template Slot(string fullName)
{
    mixin MetaMethodImpl!(slotPrefix, 0, fullName, SignalType.NewSlot);
}

template SignalImpl(int index, string fullName, SignalType signalType)
{
    static if (is(typeof(mixin(typeof(this).stringof ~ "." ~ signalPrefix ~ ToString!(index)))))
        mixin SignalImpl!(index + 1, fullName, signalType);
    else
    {
//        pragma(msg, "alias void delegate" ~ getFunc!_Tuple(fullName) ~ " Dg;");
        mixin("alias void delegate" ~ getFunc!_Tuple(fullName) ~ " Dg;");
        alias ParameterTypeTuple!(Dg) ArgTypes;
        enum args = getFunc!_Args(fullName);
        enum defVals = defaultValues(args);
        enum defValsLength = defaultValuesLength(defVals);

//        pragma (msg, SignalEmitter!(ArgTypes)(SignalType.NewSignal, getFunc!_Name(fullName), defVals, index));
        mixin InsertMetaSignal!(fullName, index, defValsLength, ArgTypes);
//        pragma (msg, ctfe_meta_signal!(ArgTypes)(fullName, index, defValsLength));
    }
}
template MetaMethodImpl(string metaPrefix, int index, string fullName, SignalType signalType)
{
    static if (is(typeof(mixin(typeof(this).stringof ~ "." ~ metaPrefix ~ toStringNow!(index)))))
    {
        mixin MetaMethodImpl!(metaPrefix, index + 1, fullName, signalType);
    }
    else
    {
        mixin("alias void delegate" ~ getFunc!_Tuple(fullName) ~ " Dg;");
        alias ParameterTypeTuple!(Dg) ArgTypes;
        enum args = getFunc!_Args(fullName);
        enum defVals = defaultValues(args);
        enum defValsLength = defaultValuesLength(defVals);
        
        static if (metaPrefix == signalPrefix)
        {
            // calculating local index of the signal
            static if (typeof(this).stringof == "QObject")
                enum localIndex = index;
            else
                mixin ("enum localIndex = index - 1 - lastSignalIndex_" ~ (typeof(super)).stringof ~ ";");
            
            static if (signalType == SignalType.NewSignal)
            {
//                pragma (msg, SignalEmitter!(ArgTypes)(SignalType.NewSignal, getFunc!_Name(fullName), defVals, localIndex));
                mixin (SignalEmitter!(ArgTypes)(SignalType.NewSignal, getFunc!_Name(fullName), defVals, localIndex));
            }
        }
        mixin InsertMetaMethod!(fullName, metaPrefix, index, defValsLength, ArgTypes);
//        pragma (msg, ctfe_meta_signal!(ArgTypes)(fullName, index, defValsLength));
    }
}
template InsertMetaMethod(string fullName, string metaPrefix, int index, int defValsCount, ArgTypes...)
{
    static if(defValsCount >= 0)
        mixin("public alias TypeTuple!(\"" ~ getFunc!_Name(fullName) ~ "\", index, typeof(this), ArgTypes) " ~ metaPrefix ~ toStringNow!(index) ~ ";");
    static if(defValsCount > 0)
        mixin InsertMetaMethod!(fullName, metaPrefix, index+1, defValsCount-1, ArgTypes[0..$-1]);
}


string signature_impl(T...)(string name)
{
    string res = name ~ "(";
    foreach(i, _; T)
    {
        if(i > 0)
            res ~= ",";
        res ~= T[i].stringof;
    }
    res ~= ")";
    return res;
}

template signature(string name, T...)
{
    enum signature = signature_impl!(T)(name);
}

template lastSignalIndex(T)
{
    static if (T.stringof == "QObject")
        enum lastSignalIndex = lastSignalIndexImpl!(T, 0);
    else
        mixin ("enum lastSignalIndex = lastSignalIndexImpl!(T, " ~ "T.lastSignalIndex_" ~ (BaseClassesTuple!(T)[0]).stringof ~ ");");
}

template lastSignalIndexImpl(T, int index)
{
    static if (is(typeof(mixin("T." ~ signalPrefix ~ toStringNow!(index)))))
        enum lastSignalIndexImpl = lastSignalIndexImpl!(T, index + 1);
    else
        enum lastSignalIndexImpl = index - 1;
}