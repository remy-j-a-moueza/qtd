module qt.core.QMetaObject;

import qt.QGlobal;
import qt.core.QObject;
import qt.QtdObject;

final class QMetaObject
{
    private
    {
        void* _nativeId;
        QMetaObject _base; // super class
        QMetaObject _firstDerived; // head of the linked list of derived classes
        QMetaObject _next; // next sibling on this derivation level
        ClassInfo _classInfo;

        QObject function(void* nativeId) _createWrapper;
    }
    
    private void addDerived(QMetaObject mo)
    {
        mo._next = _firstDerived;
        _firstDerived = mo;
    }
    
    // NOTE: construction is split between this non-templated constructor and 'construct' function below.
    this(void* nativeId, QMetaObject base)
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
        
        static QObject createWrapper(void* nativeId)
        {
            T obj = new Concrete(nativeId, QtdObjectFlags.nativeOwnership);
            // TODO: this probably should be moved to QObject constructor
            qtd_create_qobject_entity(nativeId, cast(void*)obj);
            return obj;
        }

        _createWrapper = &createWrapper;        
    }
    
    /++
    +/
    QMetaObject base()
    {
        return _base;
    }
    
    /++
    +/
    void* nativeId()
    {
        return _nativeId;
    }

    /++
    +/
    ClassInfo classInfo()
    {
        return _classInfo;
    }
    
    private QObject lookupDerived(void*[] moIds, void* nativeObjId)
    {
        assert (moIds.length >= 1);
                
        for (auto mo = _firstDerived; mo !is null; mo = mo._next)
        {
            if (mo._nativeId == moIds[0])
            {
                if (moIds.length == 1) // exact match found
                    return mo._createWrapper(nativeObjId);
                else // look deeper
                    return mo.lookupDerived(moIds[1..$], nativeObjId);
            }
        }
        
        // no initialized wrapper that matches the native object.
        // use the base class wrapper
        return _createWrapper(nativeObjId);
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
                                    
                    result = lookupDerived(moIds, nativeObjId);                    
                }
            }
        }

        return result;
    }
}

extern(C) void* qtd_QMetaObject_superClass(void* nativeId);