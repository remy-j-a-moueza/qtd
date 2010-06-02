/**
 *
 *  Copyright: Copyright QtD Team, 2008-2009
 *  Authors: Max Samukha
 *  License: <a href="http://www.boost.org/LICENSE_1_0.txt>Boost License 1.0</a>
 *
 *  Copyright QtD Team, 2008-2009
 *  Distributed under the Boost Software License, Version 1.0.
 *  (See accompanying file boost-license-1.0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
 *
 */
module qtd.Array;

import core.stdc.string;

void remove(T)(ref T[] haystack, T needle)
{
    foreach (i, e; haystack)
    {
        if (e == needle)
        {
            if (haystack.length > 1)
            {
                i++;
                memmove(haystack.ptr + i - 1, haystack.ptr + i, (haystack.length - i) * T.sizeof);
                haystack.length = haystack.length - 1;
            }
            else
                haystack.length = 0;

            break;
        }
    }
}

/**
    Allocates a dynamic array at compile time.
 */
T[] newArray(T)(size_t len, T[] from = [])
{
    if (len == from.length)
        return from;

    if (!from.length)
        from = [T.init];

    if (from.length < len)
        return newArray!T(len, from ~ from);

    return from[0..len];
}