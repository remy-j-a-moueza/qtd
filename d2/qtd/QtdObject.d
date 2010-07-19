/**
*
*  Copyright: Copyright QtD Team, 2008-2010
*  License: Boost License 1.0
*  Authors: Max Samukha, Eldar Insafutdinov
*
*/

module qtd.QtdObject;

import
    core.memory,
    std.bitmanip,
    qtd.Core,
    qtd.Debug,
    qtd.meta.Runtime;

/**
    QtdObject initialization options.
 */
enum QtdObjectInitFlags
{
    none,
    /// The wrapper is being created by user code.
    createdByD              = 0x1,
    /// The wrapper is being created with native ownership.
    nativeOwnership         = 0x2,
    /// The wrapper is allocated on stack.
    onStack                 = 0x4
}

/**
 */
enum QtdObjectOwnership
{
    ///
    native,
    ///
    d
}

/**
 */
struct QtdObjectFlags
{
    mixin (bitfields!(
        bool, "nativeDeleteDisabled"        , 1,
        bool, "wrapperDeleteDisabled"       , 1,
        bool, "createdByD"                  , 1,
        bool, "pinned"                      , 1,
        bool, "isQObject"                   , 1,
        bool, "polymorphic"                 , 1,
        bool, "onStack"                     , 1,
        int , "reserved"                    , 1
    ));
}


/* package */ abstract class QtdObject
{
    alias typeof(this) This;

    private
    {
        void* _nativeId;
        This _next;
        This _prev;
        __gshared static This _root;
    }

    protected QtdObjectFlags _flags;

    /**
     */
    @property QtdObjectFlags qtdFlags()
    {
        return _flags;
    }

    /**
     */
    @property final const
    {
        void* qtdNativeId()
        {
            return cast(void*)_nativeId;
        }

        void qtdNativeId(void* v)
        {
            unqual(_nativeId) = v;
        }
    }

    this(void* nativeId, QtdObjectInitFlags initFlags = QtdObjectInitFlags.none)
    {
        _nativeId = nativeId;

        if (initFlags & QtdObjectInitFlags.createdByD)
            _flags.createdByD = true;

        if (initFlags & QtdObjectInitFlags.nativeOwnership)
            qtdSetOwnership(QtdObjectOwnership.native);

        if (initFlags & QtdObjectInitFlags.onStack)
        {
            //assert(!_flags.isQObject);
            assert(!(initFlags & QtdObjectInitFlags.nativeOwnership));

            _flags.nativeDeleteDisabled = true;
            _flags.wrapperDeleteDisabled = true;
        }

        mixin(debugHandler("onWrapperConstructed", "this"));
    }

    /**
        Disables GC for this object;
     */
    final void qtdPin() const
    {
        assert(!_flags.pinned);
        //GC.addRoot(cast(void*)this);

        auto obj = unqual(this);

        obj._next = _root;
        _root = obj;
        if (_next)
            obj._next._prev = obj;

        obj._flags.pinned = true;
    }

    /**
        Multiple wrappers for a single native object may exist.
        This function is used to test that this and the other wrapper point
        to the same native object (identity test).

        Note that wrappers for QObject instances and instances of classes
        derived from QObject are always unique, therefore
        the 'is' operator can be used instead of this function.
     */
    final bool isSame(const(QtdObject) other) const
    {
        return other !is null && (other is this || other.qtdNativeId == qtdNativeId);
    }

    /**
        Enables GC for this object.
     */
    final void qtdUnpin() const
    {
        assert(_flags.pinned);
        //GC.removeRoot(cast(void*)this);

        auto obj = unqual(this);
        if (_prev)
            obj._prev._next = obj._next;
        else
            _root = obj._next;

        if (_next)
            obj._next._prev = obj._prev;

        obj._flags.pinned = false;
    }

    /**
        Sets the ownership of this object.
        Setting the same ownership twice results in undefined behavior.
     */
    void qtdSetOwnership(QtdObjectOwnership own) const
    {
        if (_flags.isQObject)
            return;

        assert(!_flags.onStack);
        auto obj = unqual(this);

        if (own == QtdObjectOwnership.native)
        {
            if (_flags.polymorphic && _flags.createdByD)
                qtdPin();
            else
            {
                assert (!obj._flags.nativeDeleteDisabled);
                obj._flags.nativeDeleteDisabled = true;
            }
        }
        else if (own == QtdObjectOwnership.d)
        {
            if (_flags.polymorphic && _flags.createdByD)
                qtdUnpin();
            else
            {
                assert(obj._flags.nativeDeleteDisabled);
                obj._flags.nativeDeleteDisabled = false;
            }
        }
        else
            assert(false);

        mixin(debugHandler("onObjectOwnershipChanged", "obj"));
    }    
    
    // COMPILER BUG: 3206
    protected void qtdDeleteNative()
    {
        assert(false);
    }

    ~this()
    {
        mixin(debugHandler("onWrapperDestruction", "this"));

        if (!_flags.nativeDeleteDisabled)
        {
            // avoid deleting D object twice.
            _flags.wrapperDeleteDisabled = true;
            qtdDeleteNative;

            mixin(debugHandler("onNativeDeleted", "this"));
        }

        if (_flags.pinned)
            qtdUnpin();

        mixin(debugHandler("onWrapperDestroyed", "this"));
    }
}

/* package */ abstract class PolymorphicObject : QtdObject
{
    this(void* nativeId, QtdObjectInitFlags initFlags = QtdObjectInitFlags.none)
    {
        _flags.polymorphic = true;
        super(nativeId, initFlags); 
    }
    
    abstract QtdMetaClass metaObject();
}

/**
    Base class for polymorphic non-QObjects (TBD).
 */
/* package */ abstract class NonQObject : PolymorphicObject
{
    alias NonQObjectMetaClass Meta;

    this(void* nativeId, QtdObjectInitFlags initFlags)
    {
        super(nativeId, initFlags);
    }
    
    override abstract Meta metaObject();
}

/**
    Base class for QtD meta-object classes.
 */
abstract class QtdMetaClass : MetaClass
{
    alias QtdObject function(void* nativeId, QtdObjectInitFlags initFlags) CreateWrapper;

    private void* _nativeId;
    protected CreateWrapper _createWrapper;

    this() {}

    /**
     */
    @property void* nativeId()
    {
        return _nativeId;
    }

    void construct(T)()
    {
        super.construct!T();
        _nativeId = T.qtdNativeStaticMetaObject();
        _createWrapper = &T.qtdCreateWrapper;
    }

    abstract QtdObject getWrapper(void* nativeId, QtdObjectInitFlags initFlags = QtdObjectInitFlags.none);
}

/**
    Meta-object class for non-QObject polymorphic classes.
 */
final class NonQObjectMetaClass : QtdMetaClass
{
    alias typeof(this) This;
    alias createImpl!This create;

    @property override This next()
    {
        return static_cast!This(super.next);
    }

    @property override This firstDerived()
    {
        return static_cast!This(super.firstDerived);
    }

    override QtdObject getWrapper(void* nativeId, QtdObjectInitFlags initFlags)
    {
        // traverse the inheritance tree to find a matching meta-object.
        // if the exact match is not found, return the closest base.
        This lookUp(This mo)
        {
            if (!qtdTypeInfosEqual(mo.nativeId, nativeId))
            {
                for (auto mo2 = mo.firstDerived; mo2 !is null; mo2 = mo2.next)
                {
                    mo2 = lookUp(mo2);
                    if (mo != mo2)
                        break;
                }
            }
            return mo;
        }

        auto mo = lookUp(this);
        return static_cast!NonQObject(mo._createWrapper(nativeId, initFlags));
    }
}

extern(C) bool qtdTypeInfosEqual(void* info1, void* info2);

mixin(qtdExport("void", "QtdObject_delete", "void* dId",
    q{
        auto obj = cast(QtdObject)dId;

        mixin(debugHandler("onDeletingWrapperFromNative", "obj"));

        if (!obj._flags.wrapperDeleteDisabled)
        {
            // Avoid deleting native object twice
            obj._flags.nativeDeleteDisabled = true;
            delete obj;
        }
    }));
