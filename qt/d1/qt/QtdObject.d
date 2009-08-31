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

module qt.QtdObject;

import qt.Signal;
//import tango.io.Stdout;

enum QtdObjectFlags : ubyte
{
    none,
    nativeOwnership           = 0x1,
    dOwnership                = 0x2,
    dynamicEntity             = 0x4
    //gcManaged               = 0x4
}

package abstract class QtdObject
{
    protected QtdObjectFlags __flags_;
    void* __nativeId;

    mixin SignalHandlerOps;

    this(void* nativeId, QtdObjectFlags flags = QtdObjectFlags.none)
    {
        //Stdout.formatln("Created D object {} {:x}", nativeId, flags).newline;
        __nativeId = nativeId;
        __flags_ = flags;
    }

    final QtdObjectFlags __flags()
    {
        return __flags_;
    }

    /+ final +/ void __setFlags(QtdObjectFlags flags, bool value)
    {
        if (value)
            __flags_ |= flags;
        else
            __flags_ &= ~flags;
    }

    // COMPILER BUG: 3206
    protected void __deleteNative()
    {
        assert(false);
    }

    ~this()
    {
        //Stdout.formatln("Deleting D object {}", __nativeId);
        if (!(__flags_ & QtdObjectFlags.nativeOwnership))
        {
            // avoid deleting D object twice.
            //Stdout.formatln("About to delete native object {}", __nativeId);
            __flags_ |= QtdObjectFlags.dOwnership;
            __deleteNative;
        }
        //Stdout.formatln("Deleted native D object {}", __nativeId);
    }
}