/*********************************************************
    Copyright: QtD Team, 2010
    Authors: Max Samukha
    License: Boost Software License 1.0
*********************************************************/
module qtd.Attribute;

import
    lds.meta.compiletime,
    std.traits,
    std.conv,
    std.variant,
    std.typetuple;

enum standardNamespace = "qtd";

/**
 */
enum AttributeOptions
{
    /**
     */
    none,

    /**
        Allows multiple attributes of the same category to be associated with the symbol.
     */
    allowMultiple                = 0x0000_0001,

    /* internal */ inner         = 0x0000_0002,

    /**
        Specifies that the attribute data are in name-value form.
     */
    nameValue                    = 0x0000_0004
}

/**
    When mixed in an aggregate, converts a compile-time tuple to
    members of that aggregate.
 */
mixin template tupleToMembers!(string nameSpace, size_t index, A...)
{
    static if (index < A.length)
    {
        enum indexStr = to!string(index);

        static if (is(__traits(compiles, { struct { typeof(A[index]) x; } }() })))
            mixin("typeof(A[" ~ indexStr ~ "]) " ~ nameSpace ~  ~ " = A[" ~ indexStr ~"];\n" ~ next;
        else
            mixin("alias A[" ~ indexStr ~ "] " ~ nameSpace ~ indexStr ~ ";\n" ~ next;

        mixin tupleToFields!(nameSpace, index + 1, A);
    }
}

/**
    When mixed in an aggregate, converts a compile-time tuple of name-value pairs to
    members of that aggregate.
 */
mixin template NameValueTupleToFields(A...)
{

}

version (QtdUnittest)
{
    unittest
    {
        static int foo()
        {
            return 42;
        }

        static struct S
        {
            mixin TupleToFields!("field", 0,
                int,
                "a",
                22,
                foo);
        }

        static assert(is(S.field0 == int));
        S s;
        assert(s.field1 == "a");
        assert(s.field2 == "22");
        assert(S.foo() == 42);
    }
}

private template attributeId(alias symbol, uint index = 0)
{
    enum attributeId = standardNamespace ~ "_attr_" ~ uniqueId!symbol ~ "_" ~ to!string(index);
}

/**
    Attributes allow to associate arbitrary compile-time data
    with a declaration and optionaly make that data available at run-time.

----
class A
{
}
mixin Attribute!(C, "someAttribute", "B");
----

    The example above associates the string "B" with class A under the attribute category "someAttribute".
    Multiple data can be associated with an attribute category for a single declaration:

----
class A
{
}
mixin Attribute!(C, "someAttribute", "B");
mixin Attribute!(C, "someAttribute", AttributeOptions.allowMultiple, "C");
----

    Attributes of an attribute category can be accessed at compile-time:

----
alias GetAttributes!(C, "someAttribute") attrs;
----

    GetAttribute returns a compile time tuple, which contains "someAttribute" category attributes in the form
    of TypeTupleWrapper instances. The first element of the tuple wrapped in the TypeTupleWrapper
    contains the attribute category name, other elements contain the attrubute data.

----
alias attrs[0] attr0;
alias attrs[1] attr1;

static assert(attrs0.tuple[0] == "someAttribute" && attrs0.tuple[1] == "B");
static assert(attrs1.tuple[0] == "someAttribute" && attrs1.tuple[1] == "C");
----

    Attributes can be inserted inside the body of a declaration.
----
    class A
    {
        mixin Attribute!("someAttribute", "B");
    }
----

    Attributes can be made available at run time by means of the declaration's meta-object
----
    // prints category names of all attributes associated with class A
    auto a = new A;
    foreach (attr; a.metaObject.attributes)
        writeln(attr.name);
----

    Attributes can be specialized

----
mixin template DbFieldAttribute(alias prop, string columnName)
{
    mixin Attribute!(prop, "DbFieldAttribute", columnName);
}

class A
{
    int value;
    mixin DbFieldAttribute!(value, "Value");

    int anotherValue;
    mixin DbFieldAttribute!(anotherValue, "Value2");
}

assert(GetAttributes!(A.value, "DbFieldAttribute")[0].tuple[1] == "Value");
assert(GetAttributes!(A.anotherValue, "DbFieldAttribute")[0].tuple[1] == "Value2");
----

*/
mixin template Attribute(alias symbol, string attrClass, A...)
{
    mixin Attribute!(symbol, attrClass, AttributeOptions.none, A);
}

/// ditto
mixin template Attribute(alias symbol, string attrClass, AttributeOptions opts, A...)
{
    mixin AttributeImpl!(symbol, attrClass, opts, 0, A);
}


/// ditto
// TODO: probably make this an overload of Attribute
mixin template InnerAttribute(string attrClass, AttributeOptions opts, A...)
{
    // BUG: needs to be generalized to accept any parent
    mixin Attribute!(typeof(this), attrClass, opts | AttributeOptions.inner, A);
}

/// ditto
mixin template InnerAttribute(string attrClass, A...)
{
    mixin InnerAttribute!(attrClass, AttributeOptions.none, A);
}

private mixin template AttributeImpl(alias symbol, string attrClass, AttributeOptions opts, size_t index, A...)
{
    private enum attrId = attributeId!(symbol, index) ~ (opts & AttributeOptions.inner ? "_inner" : "");

    static if (is(typeof(mixin(attrId))))
    {
        mixin ("alias " ~ attrId ~ " attr;");
        static if (!(opts & AttributeOptions.allowMultiple))
        {
            static assert (attr[0] != attrClass, "Multiple " ~ attrClass ~ " attributes are not allowed for "
                ~ __traits(parent, symbol).stringof ~ "." ~ stringOf!symbol);
        }

        mixin AttributeImpl!(symbol, attrClass, opts, index + 1, A);
    }
    else
        mixin ("alias TypeTuple!(attrClass, A) " ~ attrId ~ ";");
}

/**
    Base class for run time attribute implementations
 */
abstract class MetaAttribute
{
}

/**
    A run-time attribute implementation that stores the attribute data in an
    array of variants.
 */
final class MetaVariantAttribute : MetaAttribute
{
    Variant[] values;

    private this()
    {
    }

    static MetaVariantAttribute create(string category, AttributeOptions opts, A...)()
    {
        auto ret = new MetaVariantAttribute;
        super.construct!(category, opts, A)();
        foreach(i, _; A)
        {
            static if (__traits(compiles, { ret.values ~= Variant(A[i]); }() ))
                ret.values ~= Variant(A[i]);
        }
        return ret;
    }
}

/**
    A run-time attribute implementation that stores the attribute data in an
    assiciative array of variants.
 */
final class MetaVariantDictAttribute : MetaAttribute
{
    Variant[string] values;

    private this()
    {
    }

    static MetaVariantAttribute create(string category, AttributeOptions opts, A...)()
    {
        auto ret = new MetaVariantAttribute;
        super.construct!(category, opts, A)();
        foreach(i, _; A)
        {
            static if (i % 2 == 0 && __traits(compiles, { ret.values[A[i]] = Variant(A[i + 1]); }() ))
                ret.values[A[i]] ~= Variant(A[i + 1]);
        }
        return ret;
    }
}


/**
    A run-time attribute implementation that stores the attribute data in
    typed fields named fieldN, where N is the index of the original attribute data element.
 */
abstract class MetaTypedAttribute : MetaAttribute
{
    private this() {}

    static class Impl(A) : typeof(this)
    {
        private this() {}

        mixin tupleToMembers!("field", 0, A);
    }

    static MetaAttribute create(string category, AttributeOptions opts, A...)()
    {
        auto ret = new Impl!A;
        super.construct(category, opts, A);
        return ret;
    }
}

/**
    A run-time attribute implementation that stores the attribute data in
    typed fields by interpreting the original attribute data as name-value pairs.
 */
abstract class MetaTypedDictAttribute : MetaAttribute
{
    private this() {}

    static class Impl(A) : typeof(this)
    {
        private this() {}

        mixin nameValueTupleToMembers!("", A);
    }

    static MetaAttribute create(string category, AttributeOptions opts, A...)()
    {
        auto ret = new Impl!A;
        super.construct(category, opts, A);
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
            mixin InnerAttribute!("someAttribute", MetaVariantAttribute, "22", foo, 33);
        }

        auto attr = cast(MetaVariantAttribute) meta!(C).attributes[0];
        assert(attr.name == "someAttribute");
        assert(attr.length == 2);
        assert(attr.values[0] == "22");
        assert(attr.values[1] == 33);
    }
}

private string stringOfFunction(alias symbol)()
{
    auto ptrType = typeof(&symbol).stringof;
    auto paramList = ParameterTypeTuple!(symbol).stringof;

    string result = ReturnType!(symbol).stringof ~ " " ~ __traits(identifier, symbol) ~ paramList;

    if (ptrType[$ - 1] != ')')
    {
        for (size_t i = ptrType.length - 2;; --i)
        {
            if (ptrType[i] == ')')
            {
                result ~= ptrType[i + 1..$];
                break;
            }
        }
    }

    return result;
}

/**
    String of any symbol, including functions
 */
template stringOf(alias symbol)
{
    static if (isFunction!symbol)
        enum stringOf = stringOfFunction!symbol;
    else
        enum stringOf = symbol.stringof;
}

/**
    Returns the string uniquely identifying the
    symbol in its container.
 */
template uniqueName(alias symbol)
{
    enum uniqueName = stringOf!symbol;
}

// TODO: works only for simple types. implement
/**
 *
 */
string uniqueIdImpl(string symbol)
{
    char[] r = symbol.dup;
    foreach (i, c; symbol)
    {
        if (c == '(' || c == ')' || c == ' ')
            r[i] = '_';
    }

    return cast(immutable)r;
}

template uniqueId(alias symbol)
{
    enum uniqueId = uniqueIdImpl(stringOf!symbol);
}

version (QtdUnittest)
{
    unittest
    {
        static class C
        {
            void foo() const {};
            bool bar(int) { return true; };
            int x;
            static assert (stringOf!foo == "void foo() const");
            static assert (uniqueName!foo == "void foo() const");
            static assert (stringOf!bar == "bool bar(int)");
            static assert (uniqueName!bar == "bool bar(int)");
            static assert (stringOf!x == "x");
            static assert (uniqueName!x == "x");
        }

        static assert (stringOf!(C.foo) == "void foo() const");
        static assert (uniqueName!(C.foo) == "void foo() const");
        static assert (stringOf!(C.bar) == "bool bar(int)");
        static assert (uniqueName!(C.bar) == "bool bar(int)");

        static assert (stringOf!(C.x) == "x");
        static assert (uniqueName!(C.x) == "x");
    }
}

template truePred(A...)
{
    enum truePred = true;
}

template attrCategoryPred(string name)
{
    template attrCategoryPred(A...)
    {
        enum attrCategoryPred = A[0] == name;
    }
}

/**
    Returns a compile-time tuple of attributes that
    match pred.
 */
template GetAttributes(alias symbol, alias pred = truePred)
{
    alias GetAttributesImpl!(symbol, 0, pred).result GetAttributes;
}

/**
    Returns a compile-time tuple of attributes
    matching the specified attribute category.
 */
template GetAttributes(alias symbol, string attrCategory)
{
    alias GetAttributes!(symbol, attrCategoryPred!attrCategory) GetAttributes;
}


template GetAttributesImpl(alias symbol, size_t index, alias pred)
{
    //pragma(msg, mixin("symbol." ~ attributeId!(symbol, index) ~ "_inner").stringof);
    static if (is(typeof(mixin("__traits(parent, symbol)." ~ attributeId!(symbol, index)))))
        mixin ("alias lds.meta.compiletime.Alias!(__traits(parent, symbol))." ~ attributeId!(symbol, index) ~ " attr;");
    else static if (is(typeof(mixin("symbol." ~ attributeId!(symbol, index) ~ "_inner"))))
        mixin ("alias symbol." ~ attributeId!(symbol, index) ~ "_inner attr;");

    static if (is(typeof(attr)))
    {
        alias GetAttributesImpl!(symbol, index + 1, pred).result next;

        static if (pred!attr)
            alias TypeTuple!(TypeTupleWrapper!attr, next) result;
        else
            alias next result;
    }
    else
        alias TypeTuple!() result;
}

version (QtdUnittest)
{
    mixin template MyAttribute(alias symbol, A...)
    {
        mixin Attribute!(symbol, "MyAttribute", AttributeOptions.allowMultiple, A);
    }

    mixin template ClassInfo(string name, alias value)
    {
        mixin InnerAttribute!("ClassInfo", AttributeOptions.allowMultiple, name, value);
    }

    unittest
    {
        static class C
        {
            // inner C attributes
            mixin InnerAttribute!("Inner", 33); // generic
            mixin ClassInfo!("version", 123);
            mixin ClassInfo!("author", "James Bond");


            void foo() {};
            // foo attributes
            mixin Attribute!(foo, "SomeAttribute", 42);
            mixin MyAttribute!(foo, 1, 2);
            mixin MyAttribute!(foo, 3, 4);

            alias GetAttributes!(typeof(this), "Inner") innerAttrs;
            static assert(innerAttrs[0].tuple[0] == "Inner");
        }
        // outer C attribute
        mixin MyAttribute!(C, 24);

        alias GetAttributes!(C, "Inner") innerAttrs;
        static assert(innerAttrs[0].tuple[0] == "Inner" && innerAttrs[0].tuple[1] == 33);

        alias GetAttributes!(C, "ClassInfo") ciAttrs;
        static assert(ciAttrs[0].tuple[1] == "version" && ciAttrs[0].tuple[2] == 123);

        alias GetAttributes!(C.foo, "SomeAttribute") someAttr;
        static assert(someAttr.length == 1);
        static assert(someAttr[0].tuple[0] == "SomeAttribute");

        alias GetAttributes!(C.foo, "MyAttribute") myAttrs;

        //COMPILER BUG: cannot 'alias myAttrs[0].tuple myAttrs_0';
        static assert(myAttrs[0].tuple[0] == "MyAttribute");
        static assert(myAttrs[0].tuple[1] == 1 && myAttrs[0].tuple[2] == 2);

        static assert(myAttrs[1].tuple[0] == "MyAttribute");
        static assert(myAttrs[1].tuple[1] == 3 && myAttrs[1].tuple[2] == 4);

        /+ BUG: Fails: local declarations cannot be accessed as parent.localDecl
        alias GetAttributes!(C, "MyAttribute") myAttrs2;
        static assert(myAttrs2[0].tuple[0] == "MyAttribute");
        static assert(myAttrs2[0].tuple[1] == 24);
        +/
    }
}