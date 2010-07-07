/**
    Copyright: Copyright QtD Team, 2008-2010
    License: Boost License 1.0
 */

#include "qtd_core.h"
#include <iostream>

QTD_EXPORT(CORE, toUtf8);
QTD_EXPORT(CORE, QtdObject_delete);

QTD_EXTERN QTD_DLL_EXPORT void qtd_initCore()
{
    QObjectLink::userDataId = QObject::registerUserData();
}

QTD_EXTERN QTD_DLL_PUBLIC QModelIndex qtd_to_QModelIndex(QModelIndexAccessor mia)
{
    return * (QModelIndex *) (&mia) ;
}

QTD_EXTERN QTD_DLL_PUBLIC QModelIndexAccessor qtd_from_QModelIndex(const QModelIndex &index)
{
    QModelIndexAccessor mia = {
        index.row(),
        index.column(),
        index.internalPointer(),
        (QAbstractItemModel *) index.model()
    };

    return mia;
}

QTD_EXTERN QTD_DLL_PUBLIC const char* qtd_qVersion()
{
    return qVersion();
}

QTD_EXTERN QTD_DLL_PUBLIC bool qtd_qSharedBuild()
{
    return qSharedBuild();
}

extern bool qRegisterResourceData
    (int, const unsigned char *, const unsigned char *, const unsigned char *);

extern bool qUnregisterResourceData
    (int, const unsigned char *, const unsigned char *, const unsigned char *);

QTD_EXTERN QTD_DLL_PUBLIC bool qtd_register_resource_data(int version, const unsigned char *tree,
                                         const unsigned char *name, const unsigned char *data)
{
    return qRegisterResourceData(version, tree, name, data);
}

QTD_EXTERN QTD_DLL_PUBLIC bool qtd_unregister_resource_data(int version, const unsigned char *tree,
                                           const unsigned char *name, const unsigned char *data)
{
    return qUnregisterResourceData(version, tree, name, data);
}

QTD_EXTERN QTD_DLL_PUBLIC int qtd_qrand()
{
    return qrand();
}

QTD_EXTERN QTD_DLL_PUBLIC void qtd_qsrand(uint seed)
{
    qsrand(seed);
}

//
// QObjectLink implementation
//

QObjectLink::QObjectLink(QObject *qObject, void* dId) :
    QtdObjectLink(dId),
    flags(None)
{
    qObject->setUserData(userDataId, this);
}

uint QObjectLink::userDataId;

QObjectLink* QObjectLink::getLink(const QObject *qObject)
{
    return static_cast<QObjectLink*>(qObject->userData(userDataId));
}

void* QObjectLink::getDId(const QObject* qObject)
{
    QObjectLink* link = getLink(qObject);
    return link ? link->dId : NULL;
}

void QObjectLink::destroyLink(QObject* qObject)
{
    Q_ASSERT(dId);
    qtd_QtdObject_delete(dId);
    if (qObject)
    {
        qObject->setUserData(userDataId, NULL);
        dId = NULL;
    }
}

bool QObjectLink::createdByD()
{
    return CreatedByD & flags;
}

QObjectLink::~QObjectLink()
{
    if (dId)
        destroyLink();
}

