/**
 *
 *  Copyright: Copyright QtD Team, 2008-2009
 *  License: <a href="http://www.boost.org/LICENSE_1_0.txt>Boost License 1.0</a>
 *
 *  Copyright QtD Team, 2008-2009
 *  Distributed under the Boost Software License, Version 1.0.
 *  (See accompanying file boost-license-1.0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
 *
 */

module qt.qtd.Str;

version (Tango)
{
    public import tango.text.convert.Utf : toUTF8 = toString;
    alias char[] string;
}
else
{
    import std.utf : toUTF8;
}

version(D_Version2) {
    private import core.sys.posix.stdio;
    private import core.stdc.string;

    version = druntime;
}

public static char** toStringzArray(string[] args)
{
    if ( args is null )
    {
        return null;
    }
    char** argv = (new char*[args.length]).ptr;
    int argc = 0;
    foreach (string p; args)
    {
        argv[argc++] = cast(char*)(p.dup~'\0');
    }
    argv[argc] = null;
        
    return argv;
}

version(Tango) {
    import tango.stdc.stringz : toStringz, fromStringz;
}


public string fromStringz(const (char) *s)
{
    return s ? s[0 .. strlen(s)].idup : cast(string)null;
}

version(Windows)
{
    export extern(C) void _d_toUtf8(wchar* arr, uint size, string* str)
    {
        *str = toUTF8(arr[0..size]);
    }
}
else
{
    extern(C) void _d_toUtf8(wchar* arr, uint size, string* str)
    {
        *str = toUTF8(arr[0..size]);
    }
}

