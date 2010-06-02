module qtd.Core;

import
    qtd.ctfe.Format,
    std.stdio;

T static_cast(T, U)(U obj)
{
    return cast(T)cast(void*)obj;
}

enum qtdExtern = "extern (C)";

extern(C) alias void function() VoidFunc;
extern(C) void qtd_initCore();

immutable Object qtdMoLock;

static this()
{
    qtdMoLock = cast(immutable)new Object;
    qtd_initCore();
}

/**
    Defines a function that can be called from QtD C++ libraries,
    which will register the function with the DLL at program startup.
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
