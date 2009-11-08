#include "qtd_core.h"
#include <qobjectdefs.h>

extern "C" DLL_PUBLIC void* qtd_QMetaObject_superClass(void *nativeId)
{
    return (void*)((QMetaObject*)nativeId)->superClass();
}

extern "C" DLL_PUBLIC void qtd_QMetaObject_activate(QObject *sender, int signal_index, void **argv)
{
    QMetaObject::activate(sender, signal_index, argv);
}

extern "C" DLL_PUBLIC void qtd_QMetaObject_activate_3(QObject *sender, const QMetaObject *m, int local_signal_index, void **argv)
{
    QMetaObject::activate(sender, m, local_signal_index, argv);
}

extern "C" DLL_PUBLIC void qtd_QMetaObject_activate_4(QObject *sender, const QMetaObject *m, int from_local_signal_index, int to_local_signal_index, void **argv)
{
    QMetaObject::activate(sender, m, from_local_signal_index, to_local_signal_index, argv);
}

extern "C" DLL_PUBLIC bool qtd_QMetaObject_connect(const QObject *sender, int signal_index,
                                                   const QObject *receiver, int method_index,
                                                   int type, int *types)
{
    return QMetaObject::connect(sender, signal_index, receiver, method_index, type, types);
}

extern "C" DLL_PUBLIC int qtd_QMetaObject_indexOfMethod(void *nativeId, const char *method)
{
    return ((QMetaObject*)nativeId)->indexOfMethod(method);
}

extern "C" DLL_PUBLIC int qtd_QMetaObject_methodCount(void *nativeId)
{
    return ((QMetaObject*)nativeId)->methodCount();
}
