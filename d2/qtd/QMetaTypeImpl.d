module qtd.QMetaTypeImpl;

import
    std.traits,
    core.memory,
    core.exception,
    qt.core.Qt,
    qt.core.QDataStream,
    qt.core.QMetaType,
    qtd.QtdObject;

// TODO: remove
import std.stdio;
import std.conv;

private struct DArrayToC
{
    void[] array;
}

/**
 */
template MetaTypeOps(T)
{
    // Note that in case of byref objects we follow Qt's convention and
    // allocate/copy references, not objects.
    static void* construct(void* copy)
    {
        auto T* p = cast(T*)GC.malloc(T.sizeof);
        if (!p)
            onOutOfMemoryError();

        if (copy)
            *p = *cast(T*)copy;
        else
        {
            static if (!is(T == class) && __traits(compiles, T()))
                *p = T();
            else static if (isAssociativeArray!T)
            {
                // COMPILER BUG: need to special-case this because AA.init is broken.
                // Consequently, no custom AA init values are supported.
                *p = null;
            }
            else
                *p = T.init;
        }

        return p;
    }

    static void destroy(void* ptr)
    {
        // Run destructors for value types. Let the GC reclaim the memory.
        static if (is(T == struct) && __traits(compiles, T.__dtor))
            (cast(T*)ptr).__dtor;
    }
}

/**
 */
template MetaTypeStreamOps(T)
{
    void save(QDataStream ds, const void* data)
    {
        writeln("Saving ", ds.__nativeId, " ", data);
    }

    void load(QDataStream ds, void* data)
    {
        writeln("Loading ", ds.__nativeId, " ", data);
    }
}

// TODO: only GNU C++ is supported
private template typeOpShim(alias op)
{
    extern(C) void typeOpShim()
    {
        asm
        {
            naked;
            push   EBP;
            mov    EBP, ESP;
            mov    EAX, 0x8[EBP];
            call   op;
            leave;
            ret;
        }
    }
}

/**
 */
int qRegisterMetaType(T, alias ops = MetaTypeOps)(string name = null)
{
    if (!name.length)
        name = typeid(T).toString; //TODO: use compile time full name

    return qtd_registerType(toStringz(name), &typeOpShim!(ops!T.destroy), &typeOpShim!(ops!T.construct));
}

version (QtdUnittest)
{
    unittest
    {
        static class A
        {
            int x;
        }

        static struct S
        {
            int x;

            static S* dtorCalled;

            static S opCall(int x = 31)
            {
                S s;
                s.x = x;
                return s;
            }

            ~this()
            {
                dtorCalled = &this;
            }
        }

        static void test(T)(T val, string typeName = null)
        {
            int id = qRegisterMetaType!T(typeName);
            assert(id > 0);
            auto p = cast(T*)QMetaType.construct(id, null);

            assert(*p is T.init);
            QMetaType.destroy(id, p);

            p = cast(T*)QMetaType.construct(id, &val);
            assert(p !is &val);
            assert(*p == val);
            QMetaType.destroy(id, p);
        }

        test(42, "d_int");
        test(new A);
        test([1, 2, 3]);

        int sId = qRegisterMetaType!S();
        int saId = qRegisterMetaType!(int[3])();
        int aaId = qRegisterMetaType!(int[int])();

        // structs
        auto s = S(42);

        auto ps1 = cast(S*)QMetaType.construct(sId, null);
        assert(ps1.x == 31);

        auto ps2 = cast(S*)QMetaType.construct(sId, &s);
        assert(ps2 !is &s);
        assert(ps2.x == 42);

        QMetaType.destroy(sId, ps1);
        assert(S.dtorCalled is ps1);

        QMetaType.destroy(sId, ps2);
        assert(S.dtorCalled is ps2);

        // static arrays
        int sa[3] = [42, 43, 44];
        auto psa = cast(int[3]*)QMetaType.construct(saId, null);
        assert(*psa == [0, 0, 0] /* int[3].init */);
        QMetaType.destroy(saId, psa);

        auto psa2 = cast(int[3]*)QMetaType.construct(saId, &sa);
        assert(psa2 !is &sa);
        assert(*psa2 == sa);

        // associative arrays
        int[int] aa = [1: 42, 2: 43, 3: 44];
        auto paa = cast(int[int]*)QMetaType.construct(aaId, null);
        // COMPILER BUG: AA.init is broken
        // assert (*paa == (int[int]).init);
        assert(!(*paa).length);
        QMetaType.destroy(aaId, paa);

        auto paa2 = cast(int[int]*)QMetaType.construct(aaId, &aa);
        assert(paa2 !is &aa);
        assert(*paa2 == aa);
        QMetaType.destroy(aaId, paa);
    }
}


// COMPILER BUG: cannot put this inside qRegisterMetaTypeStreamOperators
// COMPILER BUG 2: cannot use extern(C) with templated functions: extern(C) void foo(T)(){}
private template streamOpShim(alias op)
{
    extern(C) void streamOpShim()
    {
        asm
        {
            naked;
            push   EBP;
            mov    EBP, ESP;
            mov    EAX, 0x8[EBP];
            push   EAX;
            mov    EAX, 0xC[EBP];
            call   op;
            leave;
            ret;
        }
    }
}

/**
 */
void qRegisterMetaTypeStreamOperators(T, alias ops = MetaTypeStreamOps)(string name = null)
{
    if (!name.length)
        name = typeid(T).toString;

    static void save(void* ds, const void* data)
    {
        scope dataStream = new QDataStream(ds, QtdObjectFlags.nativeOwnership);
        ops!T.save(dataStream, data);
    }

    static void load(void* ds, void* data)
    {
        scope dataStream = new QDataStream(ds, QtdObjectFlags.nativeOwnership);
        ops!T.load(dataStream, data);
    }

    qtd_registerStreamOperators(toStringz(name), &streamOpShim!save, &streamOpShim!load);
}

/**
 */
private extern(C)
{
    void qtd_registerStreamOperators(in char *typeName, VoidFunc saveOp, VoidFunc loadOp);
    int qtd_registerType(in char* namePtr, VoidFunc ctor, VoidFunc dtor);
    int qtd_QMetaType_type_nativepointerchar(in char* typeName0);
}

