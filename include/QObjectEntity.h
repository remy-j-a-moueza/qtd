#ifndef QQOBJECTENTITY_H
#define QQOBJECTENTITY_H

#include "qtd_core.h"
#include <qobject.h>
#include <iostream>

QTD_EXPORT(void, qtd_delete_d_qobject, (void* dPtr))

//TODO: user data ID must be registered with QObject::registerUserData;
#define userDataId 0

class QtD_QObjectEntity : public QtD_Entity, public QObjectUserData
{
public:

    QtD_QObjectEntity(QObject *qObject, void *dId) : QtD_Entity(dId)
    {
        qObject->setUserData(userDataId, this);
    }

    virtual ~QtD_QObjectEntity()
    {        
        if (dId)
            destroyEntity();     
    }
    
    inline void destroyEntity(QObject *qObject = NULL)
    {
        Q_ASSERT(dId);
        qtd_QtdObject_delete(dId);
        if (qObject)
        {
            qObject->setUserData(userDataId, NULL);
            dId = NULL;
        }
    }

    inline static QtD_QObjectEntity* getQObjectEntity(const QObject *qObject)
    {
        return static_cast<QtD_QObjectEntity*>(qObject->userData(userDataId));
    }
};

#endif // QQOBJECTENTITY_H
