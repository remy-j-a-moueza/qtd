#include "qtd_core.h"
#include <qobjectdefs.h>


#include <QList>

QTD_EXTERN QTD_EXPORT void* qtd_QMetaObject_superClass(void *nativeId)
{
    return (void*)((QMetaObject*)nativeId)->superClass();
}

QTD_EXTERN QTD_EXPORT void qtd_QMetaObject_activate(QObject *sender, int signal_index, void **argv)
{
    QMetaObject::activate(sender, signal_index, argv);
}

QTD_EXTERN QTD_EXPORT void qtd_QMetaObject_activate_3(QObject *sender, const QMetaObject *m, int local_signal_index, void **argv)
{
    QMetaObject::activate(sender, m, local_signal_index, argv);
}

QTD_EXTERN QTD_EXPORT void qtd_QMetaObject_activate_4(QObject *sender, const QMetaObject *m, int from_local_signal_index, int to_local_signal_index, void **argv)
{
    QMetaObject::activate(sender, m, from_local_signal_index, to_local_signal_index, argv);
}

QTD_EXTERN QTD_EXPORT bool qtd_QMetaObject_connect(const QObject *sender, int signal_index,
                                                   const QObject *receiver, int method_index,
                                                   int type, int *types)
{
    return QMetaObject::connect(sender, signal_index, receiver, method_index, type, types);
}

QTD_EXTERN QTD_EXPORT int qtd_QMetaObject_indexOfMethod(void *nativeId, const char *method)
{
    return ((QMetaObject*)nativeId)->indexOfMethod(method);
}

QTD_EXTERN QTD_EXPORT int qtd_QMetaObject_methodCount(void *nativeId)
{
    return ((QMetaObject*)nativeId)->methodCount();
}

QTD_EXTERN QTD_EXPORT void qtd_create_QList(void *nativeId)
{
    QList<int> & list = (*(QList<int> *)nativeId);
    list.append(54);
    list.append(45);
}

QTD_EXTERN QTD_EXPORT void qtd_create_QList_double(void *nativeId)
{
    QList<double> & list = (*(QList<double> *)nativeId);
    list.append(54.44);
    list.append(45.55);
}

QTD_EXTERN QTD_EXPORT void qtd_create_QList_QObject(void *nativeId)
{
    QList<QObject*> & list2 = (*(QList<QObject*> *)nativeId);

    QList<QObject*> list;
    QObject* a1 = new QObject();
    a1->setObjectName("a1");
    list.append(a1);
    QObject* a2 = new QObject();
    a2->setObjectName("a2");
    list.append(a2);
    list2 = list;
}
