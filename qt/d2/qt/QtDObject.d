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

module qt.QtDObject;

//import tango.util.container.HashMap;
import qt.Signal;

package class QtDObject
{
//    public final const(void*) nativeId() const { return native__id; }
    public final void* nativeId() { return native__id; }

    public final void nativeId(void *native_id) { native__id = native_id; }

    private void* native__id = null;

    mixin SignalHandlerOps;

    public this()
    {
        /* intentionally empty */
    }

    package this(void* native_id, bool no_real_delete = false)
    {
        native__id = native_id;
/*		auto qObj = cast(QObject) this;
		if (qObj is null)
		    register(native__id);*/
        __no_real_delete = no_real_delete;
    }
/*
	~this() {
	    unregister(native__id);
	}
*/
    // this flag controls if D object when destroying should or shouldn't delete real C++ object
	public bool __no_real_delete = false;

    package void __free_native_resources();


	/*          hash table of Object instances            */
/*    private static HashMap!(void*, Object) _map;

	static this() {
        _map = new HashMap!(void*, Object);
	}

	package static void register(void* qt_object, Object d_object) {
	    _map.add(qt_object, d_object);
	}

	package static void unregister(void* qt_object) {
	    _map.removeKey(qt_object);
	}

	package static Object lookup(void* qt_object) {
	    return _map[qt_object];
	}
	*/
}