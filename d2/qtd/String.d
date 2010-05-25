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

module qtd.String;

import core.stdc.string;
import std.utf : toUTF8;

alias immutable(char)* stringz;
alias const(char)* cstringz;

/**
 */
static char** toStringzArray(string[] args)
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

/**
 */
bool isDigit(char s)
{
    return (s >= '0' && s <= '9');
}

/**
 */
bool isOctalChar(char s)
{
    return (s >= '0' && s <= '7');
}

/**
 */
bool isHexChar(char s)
{
    return ((s >= 'a' && s <= 'f')
            || (s >= 'A' && s <= 'F')
            || (s >= '0' && s <= '9')
       );
}

/**
 */
string fromStringz(const (char) *s)
{
    return s ? s[0 .. strlen(s)].idup : cast(string)null;
}

extern(C) void qtd_toUtf8(wchar* arr, uint size, string* str)
{
    *str = toUTF8(arr[0..size]);
}



