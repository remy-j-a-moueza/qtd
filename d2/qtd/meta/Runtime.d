/**************************************************************************
    Copyright: Copyright Max Samukha, 2010
    Authors: Max Samukha
    License: Boost Software License 1.0
**************************************************************************/
module qtd.meta.Runtime;
//TODO: Probably replace switch dispatch with pointer dispatch
//and leave switch dispatch only in C interface

import
    qtd.meta.Compiletime,

    std.typetuple,
    std.conv,
    std.variant,
    core.sync.rwmutex;

private __gshared ReadWriteMutex lock;
shared static this()
{
    lock = new ReadWriteMutex;
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

abstract class Meta
{
    alias typeof(this) This;

    string name;
    MetaAttribute[] attributes;
    Meta[] members;

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
                attributes ~= MA /*COMPILER BUG: tuple element as tuple*/[0].create!args();
            }
        }
    }

    protected void construct(alias symbol)()
    {
        createAttrs!symbol;
    }
}

/**
    Base class for run time attributes.
 */
abstract class MetaAttribute
{
    alias typeof(this) This;

    string name;
    AttributeOptions options;

    This create(string name, AttributeOptions opts, A...)()
    {
        auto ma = new This;
        ma.construct!(name, opts, A)();
        return ma;
    }

    void construct(string name, AttributeOptions opts)()
    {
        this.name = name;
        options = opts;
    }
}

abstract class MetaType : Meta
{
}

abstract class MetaAggregate : MetaType
{
}

class MetaClass : MetaAggregate
{
    alias typeof(this) This;
    alias createImpl!This create;
}

class MetaStruct : MetaAggregate
{
    alias typeof(this) This;
    alias createImpl!This create;
}

@property
auto meta(alias symbol, M : Meta)()
{
    __gshared static M m;

    {
        lock.reader.lock;
        scope(exit)
            lock.reader.unlock;
        if (m)
            return m;
    }

    lock.writer.lock;
    scope(exit)
        lock.writer.unlock;

    if (!m)
        m = M.create!symbol;
    return m;
}

// only classes and structs for now
@property
auto meta(T)()
{
    static if (is(typeof(T.staticMetaObject)))
        return T.staticMetaObject;
    else static if (is(T == class))
        return meta!(T, MetaClass);
    else static if (is(T == struct))
        return meta!(T, MetaStruct);
    else
        static assert(false, "No meta object for symbol " ~ T.stringof);
}

/**
    A run time attribute implementation that stores the attribute data in an
    array of variants.
 */
class MetaVariantAttribute : MetaAttribute
{
    Variant[] values;

    private this()
    {
    }

    static MetaVariantAttribute create(string category, AttributeOptions opts, A...)()
    {
        auto ret = new MetaVariantAttribute;
        ret.construct!(category, opts)();
        foreach(i, _; A)
        {
            static if (__traits(compiles, { ret.values ~= Variant(A[i]); } ))
                ret.values ~= Variant(A[i]);
        }
        return ret;
    }
}

/**
    A run time attribute implementation that stores the attribute data in an
    assiciative array of variants.
 */
class MetaVariantDictAttribute : MetaAttribute
{
    Variant[string] values;
    alias typeof(this) This;

    private this()
    {
    }

    static This create(string category, AttributeOptions opts, A...)()
    {
        auto ret = new This;
        ret.construct!(category, opts)();
        foreach(i, _; A)
        {
            static if (i % 2 == 0 && __traits(compiles, { ret.values[A[i]] = Variant(A[i + 1]); } ))
                ret.values[A[i]] = Variant(A[i + 1]); // PHOBOS BUG: phobos asserts on this
        }
        return ret;
    }
}

version (QtdUnittest)
{
    unittest
    {
        static void foo() {}

        static class C
        {
            mixin InnerAttribute!("variantAttribute", MetaVariantAttribute, "22", foo, 33);
            mixin InnerAttribute!("variantDictAttribute", MetaVariantDictAttribute,
                //"a", "33", // PHOBOS BUG: variant is unusable with AAs
                "b", foo
                //"c", 44
                );
        }

        auto attrs = meta!(C).attributes;
        assert(attrs.length == 2);
        auto attr = cast(MetaVariantAttribute)attrs[0];

        assert(attr.name == "variantAttribute");
        assert(attr.values[0] == "22");
        assert(attr.values[1] == 33);

        auto attr2 = cast(MetaVariantDictAttribute) attrs[1];
        assert(attr2.name == "variantDictAttribute");
        //assert(attr2.values["a"] == "33");
        //assert(attr2.values["c"] == 44);
    }
}