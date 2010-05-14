module qt.qtd.Meta;

import std.traits;
import std.typetuple;
import std.string;

// Various compile time utilities

public bool ctfeStartsWith(T)(T[] source, T[] pattern)
{
    return source.length >= pattern.length && source[0 .. pattern.length] == pattern[];
}

// compile-time toString, maybe to!string is already working in CT
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

// returns the type of a template parameter if there is one
template templateParam(U : V!(U), alias V)
{
    alias U templateParam;
}

// to workaround buggy foreach, returns a tuple of Ts of size I
template Repeat(T, int I)
{
    static if (!I) alias TypeTuple!() Repeat;
    else alias TypeTuple!(T, Repeat!(T, I - 1)) Repeat;
}

//returns number of required function arguments, optional arguments excluded
int requiredArgCount(alias fn)() {
    alias ParameterTypeTuple!(typeof(&fn)) P;
    P p;
    static if (P.length == 0)
        return 0;
    
    foreach(i, _; P)
    {
        static if (!__traits(compiles, fn(p[0..$-i-1])))
        {
            return p.length - i;
        }
    }
    return 0;
}

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

uint isModule(string str)
{
    return startsWith(str, "module ");
}

template qualifiedCppName(T)
{
    static if(!isModule(__traits(parent, T).stringof))
        enum qualifiedCppName = qualifiedCppName!(__traits(parent, T)) ~ "::" ~ T.stringof;
    else
        enum qualifiedCppName = T.stringof;
}

template qualifiedDName(T)
{
    static if (!isModule(__traits(parent, T).stringof))
        enum qualifiedDName = qualifiedDName!(__traits(parent, T)) ~ "." ~ T.stringof;
    else
        enum qualifiedDName = T.stringof;
}

template fullDName(T)
{
    static if (is(T == enum))
        enum fullDName = qualifiedDName!T;
    else
        enum fullDName = T.stringof;
}
