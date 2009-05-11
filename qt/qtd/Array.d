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
module qt.qtd.Array;

version (Tango)
    import tango.stdc.string;
else
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