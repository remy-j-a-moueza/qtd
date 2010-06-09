module qtd.QMetaTypeImpl;

import
    qt.core.Qt,
    qt.core.QDataStream,
    qtd.QtdObject;

// TODO: remove
import std.stdio;

private struct DArrayToC
{
    void[] array;
}

/**
 */
template MetaTypeOps(T)
{
    static void* construct(void* copy)
    {
        static assert (is(T : Object));
        return cast(void*)new T(cast(T)copy);
    }

    static void destroy(void* ptr)
    {
        (cast(T)ptr).dispose();
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

/**
 */
int qRegisterMetaType(T, alias ops = MetaTypeOps)(string name = null)
{
    if (!name.length)
        name = typeid(T).toString; //TODO: use compile time full name?

    alias ops!T.construct construct;
    alias ops!T.destroy destroy;

    // TODO: only GNU C++
    extern(C) static void ctorShim()
    {
        asm
        {
            naked;
            push   EBP;
            mov    EBP, ESP;
            mov    EAX, 0x8[EBP];
            call   construct;
            leave;
            ret;
        }
    }

    extern(C) static void dtorShim()
    {
        asm
        {
            naked;
            push   EBP;
            mov    EBP, ESP;
            mov    EAX, 0x8[EBP];
            call   destroy;
            leave;
            ret;
        }
    }

    return qtd_registerType(toStringz(name), &dtorShim, &ctorShim);
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

