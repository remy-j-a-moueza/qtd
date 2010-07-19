/**
    Copyright: Copyright QtD Team, 2008-2010
    License: Boost License 1.0
 */

#include "qtd_core.h"
#include <typeinfo>

QTD_FUNC(CORE, toUtf8);
QTD_FUNC(CORE, QtdObject_delete);

QTD_EXTERN QTD_EXPORT void qtdInitCore()
{    
    QObjectLink::userDataId = QObject::registerUserData();
}

QTD_EXTERN QTD_EXPORT bool qtdTypeInfosEqual(void* info1, void* info2)
{
    std::type_info* i1 = (std::type_info*)info1;
    std::type_info* i2 = (std::type_info*)info2;

    return i1 == i2 || strcmp(i1->name(), i2->name()) == 0;
}

QTD_EXTERN QTD_EXPORT QModelIndex qtd_to_QModelIndex(QModelIndexAccessor mia)
{
    return * (QModelIndex *) (&mia) ;
}

QTD_EXTERN QTD_EXPORT QModelIndexAccessor qtd_from_QModelIndex(const QModelIndex &index)
{
    QModelIndexAccessor mia = {
        index.row(),
        index.column(),
        index.internalPointer(),
        (QAbstractItemModel *) index.model()
    };

    return mia;
}

QTD_EXTERN QTD_EXPORT const char* qtd_qVersion()
{
    return qVersion();
}

QTD_EXTERN QTD_EXPORT bool qtd_qSharedBuild()
{
    return qSharedBuild();
}

extern bool qRegisterResourceData
    (int, const unsigned char *, const unsigned char *, const unsigned char *);

extern bool qUnregisterResourceData
    (int, const unsigned char *, const unsigned char *, const unsigned char *);

QTD_EXTERN QTD_EXPORT bool qtd_qRegisterResourceData(int version, const unsigned char *tree,
                                         const unsigned char *name, const unsigned char *data)
{
    return qRegisterResourceData(version, tree, name, data);
}

QTD_EXTERN QTD_EXPORT bool qtd_qUnregisterResourceData(int version, const unsigned char *tree,
                                           const unsigned char *name, const unsigned char *data)
{
    return qUnregisterResourceData(version, tree, name, data);
}

QTD_EXTERN QTD_EXPORT int qtd_qrand()
{
    return qrand();
}

QTD_EXTERN QTD_EXPORT void qtd_qsrand(uint seed)
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

