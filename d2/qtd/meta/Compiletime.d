/**************************************************************************
    Copyright: QtD Team, 2010
    Authors: Max Samukha, Eldar Insafutdinov
    License: Boost Software License 1.0
**************************************************************************/
module qtd.meta.Compiletime;

import
    qtd.String,
    std.traits,
    std.conv,
    std.variant,
    std.typetuple;

/**
 */
enum standardNamespace = "qtd";

template Alias(A...) if (A.length == 1)
{
    static if (__traits(compiles, { alias A[0] x; }))
        alias A[0] Alias;
    else
        enum Alias = A[0];
}

/**
    Encapsulates a static tuple. Useful for preventing tuples from
    flattening when they are passed to a variadic template.
*/
template TypeTupleWrapper(A...)
{
    alias A tuple;
}


/**
    Returns a tuple with T repeated count times.
 */
// TODO: generalize to accept any symbol
template Repeat(T, size_t count)
{
    static if (count)
        alias TypeTuple!(count, Repeat!(T, count - 1)) Repeat;
    else
        alias TypeTuple!() Repeat;
}

/**
    Returns the required number of function arguments, optional arguments excluded
 */
int requiredArgCount(alias fn)() {
    alias ParameterTypeTuple!(typeof(&fn)) P;
    P p;
    static if (P.length == 0)
        return 0;

    foreach(i, _; P)
    {
        static if (!__traits(compiles, fn(p[0..$-i-1])))
        {
            return p.length - i;
        }
    }
    return 0;
}

/**
    Returns true if is a delegate type.
 */
template isDelegate(T)
{
    enum isDelegate = is(T == delegate);
}

/**
    Returns true if T is a function pointer type.
 */
template isFunctionPointer(T)
{
    enum isFuntionPointer = is(typeof(*T.init) == function);
}

/**
    Returns true if entity is a function or function type.
*/
template isFunction(alias entity)
{
    static if (is(entity))
        alias isFunction!(entity, void) isFunction;
    else
        enum isFunction = is(typeof(entity) == function);
}

template isFunction(T, Dummy = void)
{
    enum isFunction = is(T == function);
}


//TODO: hack
uint isModule(string str)
{
    return startsWith(str, "module ");
}


template qualifiedCppName(T)
{
    static if(!isModule(__traits(parent, T).stringof))
        enum qualifiedCppName = qualifiedCppName!(__traits(parent, T)) ~ "::" ~ T.stringof;
    else
        enum qualifiedCppName = T.stringof;
}

template qualifiedName(T)
{
    static if (!isModule(__traits(parent, T).stringof))
        enum qualifiedName = qualifiedName!(__traits(parent, T)) ~ "." ~ T.stringof;
    else
        enum qualifiedName = T.stringof;
}

template fullName(T)
{
    static if (is(T == enum))
        enum fullName = qualifiedName!T;
    else
        enum fullName = T.stringof;
}

/**
 */
enum AttributeOptions
{
    /**
     */
    none,

    /**
        Allows multiple equally named attributes to be associated with the symbol.
     */
    allowMultiple                = 0x0000_0001,

    /* internal */ inner         = 0x0000_0002,
}

/**
    When mixed in an aggregate, converts a compile-time tuple to
    members of that aggregate.
 */
mixin template tupleToMembers(string nameSpace, size_t index, A...)
{
    static if (index < A.length)
    {
        enum indexStr = to!string(index);

        static if (is(typeof( { typeof(A[index]) x; }() )))
            mixin("typeof(A[" ~ indexStr ~ "]) " ~ nameSpace ~ indexStr ~ " = A[" ~ indexStr ~"];\n");
        else
            mixin("alias Alias!(A[" ~ indexStr ~ "]) " ~ nameSpace ~ indexStr ~ ";\n");

        mixin tupleToMembers!(nameSpace, index + 1, A);
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
            mixin tupleToMembers!("member", 0,
                int,
                "a",
                22,
                foo);
        }

        static assert(is(S.member0 == int));
        S s;
        assert(s.member1 == "a");
        assert(s.member2 == 22);
        assert(S.member3() == 42);
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

    The example above associates the string "B" with class A under the attribute name "someAttribute".
    Multiple attributes with the same name can be associated with a single declaration.

----
class A
{
}
mixin Attribute!(C, "someAttribute", "B");
mixin Attribute!(C, "someAttribute", AttributeOptions.allowMultiple, "C");
----

    Attributes can be accessed at compile-time as follows:

----
alias GetAttributes!(C, "someAttribute") attrs;
----

    GetAttribute returns a static tuple, which contains "someAttribute" attributes in the form
    of TypeTupleWrapper instances. The wrapped tuples have the following layout:

    [0] - attribute name
    [1] - attribute options
    [2..$] - attribute data

----
alias attrs[0] attr0;
alias attrs[1] attr1;

static assert(attrs0.tuple[0] == "someAttribute" && attrs0.tuple[2] == "B");
static assert(attrs1.tuple[0] == "someAttribute" && attrs1.tuple[2] == "C");
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
    // prints names of all attributes associated with class A
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
    import std.typetuple;

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
    {
        mixin ("alias TypeTuple!(attrClass, opts, A) " ~ attrId ~ ";");
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

/**
    Returns a valid D identifier uniquely
    identifying symbol in its container.
 */
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

/**
    Predicate that always evaluates to true regardless of arguments.
 */
template truePred(A...)
{
    enum truePred = true;
}

private template attrNamePred(string name)
{
    template attrNamePred(A...)
    {
        enum attrNamePred = A[0] == name;
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
    matching the specified attribute name.
 */
template GetAttributes(alias symbol, string attrName)
{
    alias GetAttributes!(symbol, attrNamePred!attrName) GetAttributes;
}


template GetAttributesImpl(alias symbol, size_t index, alias pred)
{
    //pragma(msg, mixin("symbol." ~ attributeId!(symbol, index) ~ "_inner").stringof);
    static if (is(typeof(mixin("__traits(parent, symbol)." ~ attributeId!(symbol, index)))))
        mixin ("alias Alias!(__traits(parent, symbol))." ~ attributeId!(symbol, index) ~ " attr;");
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
    mixin template QtdCustomAttribute(alias symbol, A...)
    {
        mixin Attribute!(symbol, "QtdCustomAttribute", AttributeOptions.allowMultiple, A);
    }

    mixin template QtdCustomInnerAttribute(string name, alias value)
    {
        mixin InnerAttribute!("QtdCustomInnerAttribute", AttributeOptions.allowMultiple, name, value);
    }

    unittest
    {
        static class C
        {
            // inner C attributes
            mixin InnerAttribute!("Inner", 33); // generic
            mixin QtdCustomInnerAttribute!("version", 123);
            mixin QtdCustomInnerAttribute!("author", "James Bond");


            void foo() {};
            // foo attributes
            mixin Attribute!(foo, "SomeAttribute", 42);
            mixin QtdCustomAttribute!(foo, 1, 2);
            mixin QtdCustomAttribute!(foo, 3, 4);

            alias GetAttributes!(typeof(this), "Inner") innerAttrs;
            static assert(innerAttrs[0].tuple[0] == "Inner");
        }
        // outer C attribute
        mixin QtdCustomAttribute!(C, 24);

        alias GetAttributes!(C, "Inner") innerAttrs;
        static assert(innerAttrs[0].tuple[0] == "Inner" && innerAttrs[0].tuple[2] == 33);

        alias GetAttributes!(C, "QtdCustomInnerAttribute") ciAttrs;
        static assert(ciAttrs[0].tuple[2] == "version" && ciAttrs[0].tuple[3] == 123);

        /+ Fails on Windows but passes on Linux
        alias GetAttributes!(C.foo, "SomeAttribute") someAttr;
        static assert(someAttr.length == 1);
        static assert(someAttr[0].tuple[0] == "SomeAttribute");

        alias GetAttributes!(C.foo, "QtdCustomAttribute") myAttrs;

        //COMPILER BUG: cannot 'alias myAttrs[0].tuple myAttrs_0';

        static assert(myAttrs[0].tuple[0] == "QtdCustomAttribute");
        static assert(myAttrs[0].tuple[2] == 1 && myAttrs[0].tuple[3] == 2);

        static assert(myAttrs[1].tuple[0] == "QtdCustomAttribute");
        static assert(myAttrs[1].tuple[2] == 3 && myAttrs[1].tuple[3] == 4);
        +/

        /+ BUG: Fails: local declarations cannot be accessed as parent.localDecl
        alias GetAttributes!(C, "QtdCustomAttribute") myAttrs2;
        static assert(myAttrs2[0].tuple[0] == "QtdCustomAttribute");
        static assert(myAttrs2[0].tuple[1] == 24);
        +/

    }
}