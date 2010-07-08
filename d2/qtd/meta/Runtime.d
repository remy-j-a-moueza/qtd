/**************************************************************************
    Copyright: Copyright Max Samukha, 2010
    Authors: Max Samukha
    License: Boost Software License 1.0
**************************************************************************/
module qtd.meta.Runtime;

import
    qtd.meta.Compiletime,

    std.typetuple,
    std.conv,
    std.stdio,
    std.traits,
    std.variant;

import std.range : isForwardRange, isRandomAccessRange;

/**
    Object to lock on when accessing thread-shared meta-objects.
 */
immutable Object metaLock;
shared static this()
{
    metaLock = cast(immutable)new Object;
}

/**
    IDs of the built-in basic types.
*/
enum BasicTypeId
{
    ///
    void_,
    ///
    bool_,
    ///
    byte_,
    ///
    ubyte_,
    ///
    short_,
    ///
    ushort_,
    ///
    int_,
    ///
    uint_,
    ///
    long_,
    ///
    ulong_,
    ///
    cent_,
    ///
    ucent_,
    ///
    float_,
    ///
    double_,
    ///
    real_,
    ///
    ifloat_,
    ///
    idouble_,
    ///
    ireal_,
    ///
    cfloat_,
    ///
    cdouble_,
    ///
    creal_,
    ///
    char_,
    ///
    wchar_,
    ///
    dchar_
}

/**
    Thrown on meta-system errors.
*/
class MetaException : Exception
{
    this(string msg)
    {
        super(msg);
    }
}

/**
    All meta-object classes inherit from this base class.
 */
abstract class MetaBase
{
    alias typeof(this) This;

    string name;
    MetaAttribute[] attributes;

    protected MetaBase[] members_;

    template createImpl(M : This)
    {
        static M createImpl(alias symbol)()
        {
            auto m = new M;
            m.construct!symbol;
            return m;
        }
    }

    private void createAttrs(alias symbol)()
    {
        alias GetAttributes!symbol attrs;
        enum len = attrs.length; // COMPILER BUG
        foreach (i, _; Repeat!(void, len))
        {
            alias TypeTuple!(attrs[i].tuple) attr;
            // if the third element of the attribute data is a MetaAttribute subclass,
            // use that to create the attribute instance.
            static if (attr.length > 2 && (is(attr[2] : MetaAttribute)))
            {
                alias attr[2] MA;
                alias TypeTuple!(attr[0..2], attr[3..$]) args;
                attributes ~= MA /*COMPILER BUG: tuple element as tuple*/[0].create(args);
            }
        }
    }

    protected void construct(alias symbol)()
    {
        name = symbol.stringof;
        createAttrs!symbol;
    }

    static struct MembersRange
    {
        private MetaBase[] members_;

        @property
        MetaBase front()
        {
            return members_[0];
        }

        @property
        bool empty()
        {
            return members_.length == 0;
        }

        @property
        MembersRange save()
        {
            return this;
        }

        @property
        MetaBase back()
        {
            return members_[$ - 1];
        }

        void popFront()
        {
            members_ = members_[1..$];
        }

        void popBack()
        {
            members_ = members_[0..$ - 1];
        }

        MetaBase opIndex(size_t i)
        {
            return members_[i];
        }

        @property
        size_t length()
        {
            return members_.length;
        }
    }

    /**
        Returns a random access range of members of the class described by this meta-object.
     */
    @property
    MembersRange members()
    {
        return MembersRange(members_);
    }
}

version (QtdUnittest) unittest
{
    static assert(isRandomAccessRange!(MetaBase.MembersRange));
}

/**
    Base class for run-time attributes.
 */
abstract class MetaAttribute
{
    string name;
    AttributeOptions options;

    this(string name, AttributeOptions opts)
    {
        this.name = name;
        options = opts;
    }
}

abstract class MetaType : MetaBase
{
}

abstract class MetaAggregate : MetaType
{
}

class MetaClass : MetaAggregate
{
    alias typeof(this) This;

    private
    {
        This base_;
        This firstDerived_;
        This next_;
        ClassInfo classInfo_;
    }

    alias createImpl!This create;

    static struct AllMembersRange
    {
        private
        {
            This metaClass_;
            MetaBase[] members_;

            void skipEmpty()
            {
                while (!metaClass_.members_.length)
                {
                    metaClass_ = metaClass_.base_;
                    if (!metaClass_)
                        return;
                }

                members_ = metaClass_.members_;
            }
        }

        this(This metaClass)
        {
            metaClass_ = metaClass;
            skipEmpty();
        }

        @property
        MetaBase front()
        {
            return members_[0];
        }

        @property
        bool empty()
        {
            return members_.length == 0;
        }

        @property
        AllMembersRange save()
        {
            return this;
        }

        void popFront()
        {
            members_ = members_[1..$];
            if (!members_.length)
            {
                metaClass_ = metaClass_.base_;
                if (metaClass_)
                    skipEmpty();
            }
        }
    }

    /**
        Returns a forward range of members of the class described by this meta-object,
        including base class members.
     */
    @property
    AllMembersRange allMembers()
    {
        return AllMembersRange(this);
    }

    /**
        Returns the meta-object of the base class.
     */
    @property
    This base()
    {
        return base_;
    }

    /**
        Returns the next meta-object on this level of the inheritance hierarchy.
     */
    @property
    This next()
    {
        return next_;
    }

    /**
        Returns the meta-object for the first derived class.
     */
    @property
    This firstDerived()
    {
        return firstDerived_;
    }

    /**
        D class info.
     */
    @property
    ClassInfo classInfo()
    {
        return classInfo_;
    }


    /* internal */ void construct(T : Object)()
    {
        super.construct!T();
        classInfo_ = T.classinfo;
        static if (!is(T == Object))
        {
            alias BaseClassesTuple!(T)[0] Base;
            base_ = meta!Base;

            next_ = base_.firstDerived_;
            base_.firstDerived_ = this;
        }
    }

    /**
     */
    override string toString() const
    {
        return "MetaClass for " ~ classInfo_.name;
    }
}

version (QtdUnittest) unittest
{
    static assert (isForwardRange!(MetaClass.AllMembersRange));
}

class MetaStruct : MetaAggregate
{
    alias typeof(this) This;
    alias createImpl!This create;
}

/**
 */
@property
M meta(alias symbol, M : MetaBase)()
{
    __gshared static M sharedM;
    static M m;

    if (!m)
    {
        synchronized(metaLock)
        {
            if (!sharedM)
                sharedM = M.create!symbol;
        }
        m = sharedM;
    }

    return m;
}

/**
 */
// only classes and structs for now
@property
auto meta(T)()
{
    static if (is(T.Meta))
        return meta!(T, T.Meta);
    else static if (is(T == class))
        return meta!(T, MetaClass);
    else static if (is(T == struct))
        return meta!(T, MetaStruct);
    else
        static assert(false, "No meta-object for symbol " ~ T.stringof);
}

/**
    A run-time attribute implementation that stores the attribute data in an
    array of variants.
 */
class MetaVariantAttribute : MetaAttribute
{
    alias typeof(this) This;

    Variant[] values;

    private this(string name, AttributeOptions opts)
    {
        super(name, opts);
    }

    static MetaVariantAttribute create(A...)(string name, AttributeOptions opts, A args)
    {
        auto ret = new This(name, opts);

        foreach(i, _; A)
            ret.values ~= Variant(args[i]);

        return ret;
    }
}

/**
    A run-time attribute implementation that stores the attribute data in an
    assiciative array of variants.
 */
class MetaVariantDictAttribute : MetaAttribute
{
    Variant[string] values;
    alias typeof(this) This;

    private this(string name, AttributeOptions opts)
    {
        super(name, opts);
    }

    static This create(A...)(string name, AttributeOptions opts, A args)
    {
        auto ret = new This(name, opts);
        foreach(i, _; A)
            ret.values[args[i]] = Variant(args[i + 1]); // PHOBOS BUG: phobos asserts on this

        return ret;
    }
}

version(QtdUnittest) unittest
{
    enum x = 42;
    static void foo() {}

    static class C
    {

        mixin InnerAttribute!("variantAttribute", MetaVariantAttribute, "22", x, 33);

        /+ PHOBOS BUG: variant is unusable with AAs
        mixin InnerAttribute!("variantDictAttribute", MetaVariantDictAttribute,
            "a", "33",
            "b", 44,
            "c", x
            );
        +/
    }

    auto attrs = meta!(C).attributes;
    assert(attrs.length == 1);
    auto attr = cast(MetaVariantAttribute)attrs[0];

    assert(attr.name == "variantAttribute");
    assert(attr.values[0] == "22");
    assert(attr.values[1] == x);
    assert(attr.values[2] == 33);

    /+

    auto attr2 = cast(MetaVariantDictAttribute) attrs[1];
    assert(attr2.name == "variantDictAttribute");
    //assert(attr2.values["a"] == "33");
    //assert(attr2.values["b"] == 44);
    //assert(attr2.values["c"] == x);
    +/
}
