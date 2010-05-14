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

    import tango.text.convert.Utf : toString;
public import tango.stdc.stringz : fromStringz;

    alias char[] string;
    alias wchar[] wstring;

alias char* stringz;
alias char* cstringz;

public static char** toStringzArray(char[][] args)
{
	if ( args is null )
	{
		return null;
	}
	char** argv = (new char*[args.length]).ptr;
	int argc = 0;
	foreach (char[] p; args)
	{
		argv[argc++] = cast(char*)(p.dup~'\0');
	}
	argv[argc] = null;

	return argv;
}
extern(C) void qtd_toUtf8(wchar* arr, uint size, string* str){
    *str = toString(arr[0..size]);
}


