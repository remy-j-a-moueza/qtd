#include <QString>
#include "qtd_core.h"

extern "C" DLL_PUBLIC const ushort* __qtd_QString_utf16
(void* __this_nativeId)
{
    QString *__qt_this = (QString *) __this_nativeId;
    return __qt_this->utf16();
}

extern "C" DLL_PUBLIC int __qtd_QString_size
(void* __this_nativeId)
{
    QString *__qt_this = (QString *) __this_nativeId;
    return __qt_this->size();
}

extern "C" DLL_PUBLIC void __qtd_QString_operatorAssign
(void* __this_nativeId,
 char* text, uint text_size)
{
    QString *__qt_this = (QString *) __this_nativeId;
    *__qt_this = QString::fromUtf8(text, text_size);
}
