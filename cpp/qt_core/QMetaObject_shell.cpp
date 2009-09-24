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
