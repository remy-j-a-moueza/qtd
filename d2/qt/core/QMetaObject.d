module qt.core.QMetaObject;

import
    qt.QGlobal,
    qt.core.QObject,
    qtd.QtdObject,
    std.algorithm,
    qtd.meta.Runtime,
    qtd.meta.Compiletime,
    qtd.Marshal,
    qtd.MOC,
    std.string,
    std.typetuple,
    std.c.stdlib;

class QMetaArgument : MetaBase
{
}

class QMetaMethod : MetaBase
{
    alias typeof(this) This;

//    QMetaArgument[]  arguments;
    string signature;
    int indexOfMethod;

    this(string signature_, int indexOfMethod_)
    {
        signature = signature_;
        indexOfMethod = indexOfMethod_;
    }

    string args() const
    {
        int openBracket = indexOf(signature, '(');
        if(signature.length - openBracket - 2 > 0)
            return signature[openBracket + 1 .. $-1];
        else
            return "";
    }

    string name() const
    {
        int openBracket = indexOf(signature, '(');
        return signature[0..openBracket];
    }

    // mixin(Derived) or typeof(Derived) would help a lot here
    static create(alias method, M : This)(uint index)
    {
        alias ParameterTypeTuple!method Args;
        return new M(.signature!(Args)(methodName!(method)), index);
    }
}

class QMetaSignal : QMetaMethod
{
    alias typeof(this) This;

    this(string signature_, int indexOfMethod_)
    {
        super(signature_, indexOfMethod_);
    }

    static This create(alias method)(uint index)
    {
        return typeof(super).create!(method, This)(index);
    }
}

class QMetaSlot : QMetaMethod
{
    alias typeof(this) This;

    this(string signature_, int indexOfMethod_)
    {
        super(signature_, indexOfMethod_);
    }

    static This create(alias method)(uint index)
    {
        return typeof(super).create!(method, This)(index);
    }
}

/**
    Base class for QtD meta-classes.
 */
abstract class QtdMetaClass : MetaClass
{
private:
    void* nativeId_;

    this() {}

public:

    /**
     */
    @property
    void* nativeId()
    {
        return nativeId_;
    }

    /* internal */ void construct(T)()
    {
        super.construct!T();
        nativeId_ = T.qtd_nativeMetaObject;
    }
}

struct QMetaObjectNative
{
    QMetaObjectNative *superdata;
    immutable(char) *stringdata;
    const(uint) *data;
    void *extradata;
}

class QMetaException : Exception { this(string msg) { super(msg); } }

final class QMetaObject : QtdMetaClass
{
    alias typeof(this) This;

    enum Call
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

    private
    {
        QMetaMethod[] _methods;
        QObject function(void* nativeId) _createWrapper;
    }

    void construct(T : QObject)()
    {
        super.construct!T();

        static if (isQtType!T)
        {
            static if (is(T.ConcreteType))
                alias T.ConcreteType Concrete;
            else
                alias T Concrete;

            _createWrapper = function QObject(void* nativeId) {
                    auto obj = new Concrete(nativeId, cast(QtdObjectFlags)(QtdObjectFlags.nativeOwnership | QtdObjectFlags.dynamicEntity));
                    T.__createEntity(nativeId, cast(void*)obj);
                    return obj;
                };

            T._populateMetaInfo;
        }

        // create run time meta-objects for user-defined signals and slots
        else static if (is(typeof(T.methods)))
        {
            alias BaseClassesTuple!(T)[0] Base;
            int index = Base.staticMetaObject().methodCount();

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

    /* internal */ alias createImpl!This create;

    /**
     */
    @property
    override This base()
    {
        return super.base;
    }

    /**
     */
    @property
    override This firstDerived()
    {
        return super.firstDerived;
    }

    /**
     */
    @property
    override This next()
    {
        return super.next;
    }

    /**
     */
    @property
    override QMetaObjectNative* nativeId()
    {
        return cast(QMetaObjectNative*)super.nativeId;
    }

    @property
    const (QMetaMethod[]) methods()
    {
        return _methods;
    }

    void addMethod(QMetaMethod method_)
    {
        _methods ~= method_;
    }

    QMetaMethod lookUpMethod(string slot)
    {
        foreach (method; _methods)
            if (method.signature == slot)
                return method;
        if (base)
            return base.lookUpMethod(slot);
        else
            return null;
    }

    QMetaSignal lookUpSignal(string signal)
    {
        foreach (method; _methods)
            if (method.signature == signal && cast(QMetaSignal)method)
                return cast(QMetaSignal)method;
        if (base)
            return base.lookUpSignal(signal);
        else
            return null;
    }

    QMetaMethod[] lookUpMethodOverloads(string methodName)
    {
        typeof(return) result;
        foreach (method; _methods)
            if (method.name == methodName)
                result ~= method;
        if (base)
            result ~= base.lookUpMethodOverloads(methodName);
        return result;
    }

    QMetaSignal[] lookUpSignalOverloads(string signalName)
    {
        typeof(return) result;
        foreach (method; _methods)
            if (method.name == signalName && cast(QMetaSignal)method)
                result ~= cast(QMetaSignal)method;
        if (base)
            result ~= base.lookUpSignalOverloads(signalName);
        return result;
    }

    private QMetaObject lookupDerived(void*[] moIds)
    {
        assert (moIds.length >= 1);

        for (auto mo = firstDerived; mo !is null; mo = mo.next)
        {
            if (mo.nativeId == moIds[0])
            {
                if (moIds.length == 1) // exact match found
                    return mo;
                else // look deeper
                    return mo.lookupDerived(moIds[1..$]);
            }
        }

        // no initialized wrapper that matches the native object.
        // use the base class wrapper
        return this;
    }

    QObject getObject(void* nativeObjId)
    {
        QObject result;

        if (nativeObjId)
        {
            result = cast(QObject)qtd_get_d_qobject(nativeObjId);
            if (!result)
            {
                auto nId = nativeId;
                auto moId = qtd_QObject_metaObject(nativeObjId);
                if (nId == moId)
                     result = _createWrapper(nativeObjId);
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

                    result = lookupDerived(moIds)._createWrapper(nativeObjId);
                }
            }
        }

        return result;
    }

    static void activate(QObject sender, QMetaObject m, int local_signal_index, void **argv)
    {
        qtd_QMetaObject_activate_3(sender.__nativeId, m.nativeId, local_signal_index, argv);
    }

    static void activate(QObject sender, QMetaObject m, int from_local_signal_index, int to_local_signal_index, void **argv)
    {
        qtd_QMetaObject_activate_4(sender.__nativeId, m.nativeId, from_local_signal_index, to_local_signal_index, argv);
    }

    static bool connect(const QObject sender, int signal_index,
                        const QObject receiver, int method_index,
                        int type = 0, int *types = null)
    {
        return qtd_QMetaObject_connect(sender.__nativeId, signal_index, receiver.__nativeId, method_index, type, types);
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
            signal = sender.metaObject.lookUpSignal(signalString);
        else
            signals = sender.metaObject.lookUpSignalOverloads(signalString); // parameters not specified. Looking for a match

        if(indexOf(methodString, '(') > 0)
            method = receiver.metaObject.lookUpMethod(methodString);
        else
            methods = receiver.metaObject.lookUpMethodOverloads(methodString); // parameters not specified. Looking for a match

        if(!signal && !method)
        {
            Top:
            foreach(sig; signals)
                foreach(meth; methods)
                    if(startsWith(sig.args, meth.args))
                    {
                        signal = sig;
                        method = meth;
                        break Top;
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
            int signalIndex = signal.indexOfMethod;
            int methodIndex = method.indexOfMethod;

            success = QMetaObject.connect(sender, signalIndex, receiver, methodIndex, type);
        }

        if(!success)
            throw new QMetaException("QMetaObject: Signal " ~ signalString ~ " cannot be connected to slot " ~ methodString);
    }
}

/**
 */
mixin template Q_CLASSINFO(string name, string value)
{
    mixin InnerAttribute!("Q_CLASSINFO", AttributeOptions.allowMultiple, name, value);
}

version (QtdUnittest)
{
    unittest
    {
        static class Test : QObject
        {
            mixin Q_CLASSINFO!("author", "Sabrina Schweinsteiger");
            mixin Q_CLASSINFO!("url", "http://doc.moosesoft.co.uk/1.0/");

            mixin Q_OBJECT;
        }
    }
}

extern(C) void qtd_QMetaObject_activate_3(void* sender, void* m, int local_signal_index, void **argv);
extern(C) void qtd_QMetaObject_activate_4(void *sender, void* m, int from_local_signal_index, int to_local_signal_index, void **argv);
extern(C) bool qtd_QMetaObject_connect(const void* sender, int signal_index,
                                       const void* receiver, int method_index,
                                       int type, int *types);

extern(C) int qtd_QMetaObject_indexOfMethod(void *nativeId, const(char) *method);
extern(C) int qtd_QMetaObject_methodCount(void *nativeId);

extern(C) void* qtd_QMetaObject_superClass(void* nativeId);
