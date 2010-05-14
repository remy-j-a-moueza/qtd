module qt.core.QMetaObject;

import qt.QGlobal;
import qt.core.QObject;
import qt.QtdObject;

import std.algorithm;
import std.string;
import std.stdio;

class Meta
{
    string name;
}

class MetaType : Meta
{
    this()
    {
    }
}

class MetaVariable : Meta
{
    MetaType type;
}

class MetaCallable : Meta { }

class MetaMethod : Meta { }

class QMetaArgument : MetaVariable { }

class QMetaMethod : MetaMethod
{
//    QMetaArgument[] arguments;
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
}

class QMetaSignal : QMetaMethod
{
    this(string signature_, int indexOfMethod_)
    {
        super(signature_, indexOfMethod_);
    }
}

class QMetaSlot : QMetaMethod
{
    this(string signature_, int indexOfMethod_)
    {
        super(signature_, indexOfMethod_);
    }
}

class MetaObject : MetaType
{
    MetaObject _base;
}

struct QMetaObjectNative
{
    QMetaObjectNative *superdata;
    immutable(char) *stringdata;
    const(uint) *data;
    void *extradata;
}

class QMetaException : Exception { this(string msg) { super(msg); } }

final class QMetaObject
{
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
        QMetaObjectNative* _nativeId;
        QMetaObject _base; // super class
        QMetaObject _firstDerived; // head of the linked list of derived classes
        QMetaObject _next; // next sibling on this derivation level
        QMetaMethod[] _methods;
        ClassInfo _classInfo;

        QObject function(void* nativeId) _createWrapper;
    }
    
    private void addDerived(QMetaObject mo)
    {
        mo._next = _firstDerived;
        _firstDerived = mo;
    }
    
    // NOTE: construction is split between this non-templated constructor and 'construct' function below.
    this(QMetaObjectNative* nativeId, QMetaObject base)
    {
        _nativeId = nativeId;
        if (base)
        {
            base.addDerived(this);
            _base = base;
        }
    }
    
    // TODO: remove when D acquires templated constructors       
    void construct(T : QObject, Concrete = T)()
    {
        _classInfo = T.classinfo;        

        _createWrapper = function QObject(void* nativeId) {
                // COMPILER BUG: cast is should not be needed
                auto obj = new Concrete(nativeId, cast(QtdObjectFlags)(QtdObjectFlags.nativeOwnership | QtdObjectFlags.dynamicEntity));
                // TODO: Probably this should be a virtual call from T's constructor
                T.__createEntity(nativeId, cast(void*)obj);
                return obj;
            };
    }
    
    /++
    +/
    QMetaObject base()
    {
        return _base;
    }
    
    /++
    +/
    QMetaObjectNative* nativeId()
    {
        return _nativeId;
    }

    /++
    +/
    ClassInfo classInfo()
    {
        return _classInfo;
    }
    
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
        if (_base)
            return _base.lookUpMethod(slot);
        else
            return null;
    }
    
    QMetaSignal lookUpSignal(string signal)
    {
        foreach (method; _methods)
            if (method.signature == signal && cast(QMetaSignal)method)
                return cast(QMetaSignal)method;
        if (_base)
            return _base.lookUpSignal(signal);
        else
            return null;
    }

    QMetaMethod[] lookUpMethodOverloads(string methodName)
    {
        typeof(return) result;
        foreach (method; _methods)
            if (method.name == methodName)
                result ~= method;
        if (_base)
            result ~= _base.lookUpMethodOverloads(methodName);
        return result;
    }

    QMetaSignal[] lookUpSignalOverloads(string signalName)
    {
        typeof(return) result;
        foreach (method; _methods)
            if (method.name == signalName && cast(QMetaSignal)method)
                result ~= cast(QMetaSignal)method;
        if (_base)
            result ~= _base.lookUpSignalOverloads(signalName);
        return result;
    }
    
    private QMetaObject lookupDerived(void*[] moIds)
    {
        assert (moIds.length >= 1);
                
        for (auto mo = _firstDerived; mo !is null; mo = mo._next)
        {
            if (mo._nativeId == moIds[0])
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
                auto moId = qtd_QObject_metaObject(nativeObjId);
                if (_nativeId == moId)
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
                        if (tmp == _nativeId)                        
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
        return qtd_QMetaObject_indexOfMethod(_nativeId, toStringz(method));
    }
    
    int methodCount()
    {
        return qtd_QMetaObject_methodCount(_nativeId);
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
            throw new QMetaException("QMetaObject: Signal " ~ signalString ~ " and slot " ~ methodString ~ " cannot be found");
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
