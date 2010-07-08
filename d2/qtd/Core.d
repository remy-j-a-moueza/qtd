module qtd.Core;

import
    qtd.ctfe.Format,
    std.traits;

/**
    Casts T to U, bypassing dynamic cast checks
 */
T static_cast(T, U)(U obj)
{
    return cast(T)cast(void*)obj;
}

/**
    Strips qualifiers off the argument.
 */
auto ref unqual(T)(auto ref T v)
{
    static if (__traits(isRef, v))
    {
        auto p = cast(Unqual!(T)*)&v;
        return *p;
    }
    else
        return cast(Unqual!T)v;
}

/**
    Just an alias to the type T. Useful for declarations
    with anonymous types.
 */
template Type(T)
{
    alias T Type;
}

enum qtdExtern = "extern (C)";

extern(C) alias void function() VoidFunc;
extern(C) void qtdInitCore();

static this()
{
    qtdInitCore();
}

/**
    Defines a function that can be called from QtD C++ libraries.
    The function will be automatically
    registered with the DLL at program startup.
 */
string qtdExport(string retType, string name, string args, string funcBody)
{
    string ret;
    version (cpp_shared) // TODO: cpp_shared implies Windows, which is not correct
    {
        // TODO: hackery to workaround a dmd/optlink bug corrupting symbol names
        // when a direct function pointer export is used
        ret ~= format_ctfe(
            "    ${4} ${0} qtd_export_${1}(${2}) { ${3} }\n"
            "    ${4} export void qtd_set_${1}(VoidFunc func);\n"
            "    static this() { qtd_set_${1}(cast(VoidFunc)&qtd_export_${1}); }\n",
            retType, name, args, funcBody, qtdExtern);
    }
    else
    {
        ret = format_ctfe(
            "${4} ${0} qtd_${1}(${2}) { ${3} }\n",
            retType, name, args, funcBody, qtdExtern);
    }

    return ret;
}
