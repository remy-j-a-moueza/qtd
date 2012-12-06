module qt.core.QMetaObject;

import
    qt.QGlobal,
    qt.core.QObject,
    qtd.QtdObject,
    qtd.meta.Runtime,
    qtd.meta.Compiletime,
    qtd.Marshal,
    qtd.MOC,
    qtd.String,
    qtd.Signal,
    std.typetuple,
    std.traits,
    std.c.stdlib;

import std.string : indexOf;
import std.algorithm : filter;

class QMetaArgument : MetaBase
{
}

class QMetaMethod : MetaBase
{
    alias typeof(this) This;

//    QMetaArgument[]  arguments;
    string signature;
    int index;

    this(string signature, int index)
    {
        this.signature = signature;
        this.index = index;

        auto openBracket = indexOf(signature, '(');
        name = signature[0..openBracket];
    }

    string args() const
    {
        auto openBracket = indexOf(signature, '(');
        if(signature.length - openBracket - 2 > 0)
            return signature[openBracket + 1 .. $-1];
        else
            return "";
    }

    static M create(alias method, M : This)(uint index)
    {
        alias ParameterTypeTuple!method Args;
        return new M(.signature!(Args)(methodName!(method)), index);
    }
}

/**
 */
class QMetaSignal : QMetaMethod
{
    alias typeof(this) This;

    this(string signature, int indexOfMethod)
    {
        super(signature, indexOfMethod);
    }

    static This create(alias method)(uint index)
    {
        return typeof(super).create!(method, This)(index);
    }
}

class QMetaSlot : QMetaMethod
{
    alias typeof(this) This;

    this(string signature, int indexOfMethod)
    {
        super(signature, indexOfMethod);
    }

    static This create(alias method)(uint index)
    {
        return typeof(super).create!(method, This)(index);
    }
}



struct QMetaObjectNative
{
    QMetaObjectNative *superdata;
    immutable(char) *stringdata;
    const(uint) *data;
    void *extradata;
}

// COMPILER BUG: causes a forward reference error if placed inside QMetaObject
enum MetaCall
{
    InvokeMetaMethod,
    ReadProperty,
    WriteProperty,
    ResetProperty,
    QueryPropertyDesignable,
    QueryPropertyScriptable,
    QueryPropertyStored,
    QueryPropertyEditable,
    QueryPropertyUser,
    CreateInstance
}

/**
 */
final class QMetaObject : QtdMetaClass
{
    alias typeof(this) This;

    this() {}

    alias createImpl!This create;

    void construct(T : QObject)()
    {
        super.construct!T();

        static if (isQtType!T)
        {
            static if (is(T.ConcreteType))
                alias T.ConcreteType Concrete;
            else
                alias T Concrete;

            T._populateMetaInfo(this);
        }
        // create run time meta-objects for user-defined signals and slots
        else static if (is(typeof(T.methods)))
        {
            alias BaseClassesTuple!(T)[0] Base;
            int index = meta!(Base).methodCount;

            static if (T.signals.length)
            {
                foreach (signal; T.signals)
                {
                    addMethod(QMetaSignal.create!signal(index));
                    index++;
                }
            }

            static if (T.slots.length)
            {
                foreach (slot; T.slots)
                {
                    addMethod(QMetaSlot.create!slot(index));
                    index++;
                }
            }
        }
    }

    /**
     */
    @property
    override This next()
    {
        return static_cast!This(super.next);
    }

    /**
     */
    @property
    override This firstDerived()
    {
        return static_cast!This(super.firstDerived);
    }

    void addMethod(QMetaMethod method)
    {
        members_ ~= method;
    }

    /**
     */
    @property
    override This base()
    {
        return static_cast!This(super.base);
    }

    /**
     */
    @property
    QMetaObjectNative* nativeId()
    {
        return cast(QMetaObjectNative*)super.nativeId;
    }

    M lookUpMethod(M : QMetaMethod = QMetaMethod)(string signature)
    {
        foreach (method; allMembers)
        {
            if (auto m = cast(M)method)
            {
                if (m.signature == signature)
                    return m;
            }
        }
        return null;
    }

    // TODO: probably make this return a filtering range.
    auto lookUpMethodOverloads(M : QMetaMethod = QMetaMethod)(string name)
    {
        M[] methods;
        foreach (m; allMembers)
        {
            if (auto method = cast(M)m)
            {
                if (method.name == name)
                    methods ~= method;
            }
        }
        return methods;
    }

    private QMetaObject lookUpDerived(void*[] moIds)
    {
        assert (moIds.length >= 1);

        for (auto mo = firstDerived; mo !is null; mo = mo.next)
        {
            if (mo.nativeId == moIds[0])
            {
                if (moIds.length == 1) // exact match found
                    return mo;
                else // look deeper
                    return mo.lookUpDerived(moIds[1..$]);
            }
        }

        // no initialized wrapper that matches the native object.
        // use the base class wrapper
        return this;
    }

    override QObject getWrapper(void* nativeObjId, QtdObjectInitFlags initFlags = QtdObjectInitFlags.none)
    {
        QObject result;

        if (nativeObjId)
        {
            result = cast(QObject)qtd_get_d_qobject(nativeObjId);
            if (!result)
            {
                auto moId = qtd_QObject_metaObject(nativeObjId);
                auto nId = nativeId;
                if (nId == moId)
                     result = static_cast!QObject(_createWrapper(nativeObjId, initFlags));
                else
                {
                    // get native metaobjects for the entire derivation lattice
                    // up to, but not including, the current metaobject.
                    size_t moCount = 1;

                    for (void* tmp = moId;;)
                    {
                        tmp = qtd_QMetaObject_superClass(tmp);
                        assert(tmp);
                        if (tmp == nId)
                            break;
                        moCount++;
                    }

                    void*[] moIds = (cast(void**)alloca(moCount * (void*).sizeof))[0..moCount];

                    moIds[--moCount] = moId;
                    while (moCount > 0)
                        moIds[--moCount] = moId = qtd_QMetaObject_superClass(moId);

                    auto mo = lookUpDerived(moIds);
                    result = static_cast!QObject(mo._createWrapper(nativeObjId, initFlags));
                }
            }
        }

        return result;
    }

    static void activate(QObject sender, QMetaObject m, int local_signal_index, void **argv)
    {
        qtd_QMetaObject_activate_3(sender.qtdNativeId, m.nativeId, local_signal_index, argv);
    }

    static void activate(QObject sender, QMetaObject m, int from_local_signal_index, int to_local_signal_index, void **argv)
    {
        qtd_QMetaObject_activate_4(sender.qtdNativeId, m.nativeId, from_local_signal_index, to_local_signal_index, argv);
    }

    static bool connect(const QObject sender, int signal_index,
                        const QObject receiver, int method_index,
                        int type = 0, int *types = null)
    {
        return qtd_QMetaObject_connect(sender.qtdNativeId, signal_index, receiver.qtdNativeId, method_index, type, types);
    }

    int indexOfMethod_Cpp(string method)
    {
        return qtd_QMetaObject_indexOfMethod(nativeId, toStringz(method));
    }

    int methodCount()
    {
        return qtd_QMetaObject_methodCount(nativeId);
    }

    static void connectImpl(QObject sender, string signalString, QObject receiver, string methodString, int type)
    {
        QMetaSignal[] signals;
        QMetaMethod[] methods;
        QMetaSignal signal;
        QMetaMethod method;

        if(indexOf(signalString, '(') > 0)
            signal = sender.metaObject.lookUpMethod!QMetaSignal(signalString);
        else
            signals = sender.metaObject.lookUpMethodOverloads!QMetaSignal(signalString); // parameters not specified. Looking for a match

        if(indexOf(methodString, '(') > 0)
            method = receiver.metaObject.lookUpMethod(methodString);
        else
            methods = receiver.metaObject.lookUpMethodOverloads(methodString); // parameters not specified. Looking for a match

        if(!signal && !method)
        {
            Top:
            foreach(sig; signals)
            {
                foreach(meth; methods)
                {
                    if(startsWith(sig.args, meth.args))
                    {
                        signal = sig;
                        method = meth;
                        break Top;
                    }
                }
            }
        }
        else if (!signal)
        {
            foreach(sig; signals)
                if(startsWith(sig.args, method.args))
                {
                    signal = sig;
                    break;
                }
        }
        else if (!method)
        {
            foreach(meth; methods)
                if(startsWith(signal.args, meth.args))
                {
                    method = meth;
                    break;
                }
        }

        bool success = false;

        if(!signal && !method)
        {
            success = false;
        }
        else
        {
            int signalIndex = signal.index;
            int methodIndex = method.index;

            success = QMetaObject.connect(sender, signalIndex, receiver, methodIndex, type);
        }

        if(!success)
        {
            throw new MetaException("QMetaObject: Failed to connect signal "
                ~ sender.classinfo.name ~ "." ~ signalString ~ " to slot "
                ~ receiver.classinfo.name ~ "." ~ methodString ~ ". Make sure the signal and slot exist and match.");
        }
    }
}

/**
 */
mixin template Q_CLASSINFO(string name, string value)
{
    import qtd.meta.Compiletime;
    mixin InnerAttribute!("Q_CLASSINFO", AttributeOptions.allowMultiple, name, value);
}

/**
 */
mixin template Q_PROPERTY(T, string params)
{
    static assert(false, "not implemented");
}

extern(C) void qtd_QMetaObject_activate_3(void* sender, void* m, int local_signal_index, void **argv);
extern(C) void qtd_QMetaObject_activate_4(void *sender, void* m, int from_local_signal_index, int to_local_signal_index, void **argv);
extern(C) bool qtd_QMetaObject_connect(const void* sender, int signal_index,
                                       const void* receiver, int method_index,
                                       int type, int *types);

extern(C) int qtd_QMetaObject_indexOfMethod(void *nativeId, const(char) *method);
extern(C) int qtd_QMetaObject_methodCount(void *nativeId);

extern(C) void* qtd_QMetaObject_superClass(void* nativeId);
