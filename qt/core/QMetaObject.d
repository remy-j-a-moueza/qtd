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
}

extern(C) void* qtd_QMetaObject_superClass(void* nativeId);