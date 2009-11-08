/**
 * Tuple-related stuff.
 * 
 * Authors: Daniel Keep <daniel.keep@gmail.com>
 * Copyright: See LICENSE.
 */
module qt.qtd.util.Tuple;

import std.typetuple;

/**
 * Sequence can be used to generate a tuple of integer values.  It can be
 * used in one of three forms:
 *
 * -----
 *  Sequence!(6)     // ==> (0, 1, 2, 3, 4, 5)
 *  Sequence!(1,6)   // ==> (1, 2, 3, 4, 5)
 *  Sequence!(1,6,2) // ==> (1, 3, 5)
 * -----
 */

template Sequence(int max)
{
    static if( max <= 0 )
        alias TypeTuple!() Sequence;
    else
        alias TypeTuple!(Sequence!(max-1), max-1) Sequence;
}

/// ditto

template Sequence(int min, int max)
{
    static if( max <= min )
        alias TypeTuple!() Sequence;
    else
        alias TypeTuple!(Sequence!(min, max-1), max-1) Sequence;
}

/// ditto

template Sequence(int min, int max, int stride)
{
    static if( min >= max )
        alias TypeTuple!() Sequence;
    else
        alias TypeTuple!(min, Sequence!(min+stride, max, stride)) Sequence;
}

version( Unittest )
{
    static assert( Sequence!(3)[0] == 0 );
    static assert( Sequence!(3)[1] == 1 );
    static assert( Sequence!(3)[2] == 2 );
    static assert( Sequence!(3).length == 3 );

    static assert( Sequence!(1, 3)[0] == 1 );
    static assert( Sequence!(1, 3)[1] == 2 );
    static assert( Sequence!(1, 3).length == 2 );

    static assert( Sequence!(1, 5, 2)[0] == 1 );
    static assert( Sequence!(1, 5, 2)[1] == 3 );
    static assert( Sequence!(1, 5, 2).length == 2 );
}
