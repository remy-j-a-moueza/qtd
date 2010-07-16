#include <QString>
#include "qtd_core.h"

QTD_EXTERN QTD_EXPORT const ushort* qtd_QString_utf16
(void* __this_nativeId)
{
    QString *__qt_this = (QString *) __this_nativeId;
    return __qt_this->utf16();
}

QTD_EXTERN QTD_EXPORT int qtd_QString_size
(void* __this_nativeId)
{
    QString *__qt_this = (QString *) __this_nativeId;
    return __qt_this->size();
}

QTD_EXTERN QTD_EXPORT void qtd_QString_operatorAssign
(void* __this_nativeId,
 DArray text)
{
    QString *__qt_this = (QString *) __this_nativeId;
    *__qt_this = QString::fromUtf8((const char *)text.ptr, text.length);
}

QTD_EXTERN QTD_EXPORT void qtd_QString_destructor(void *ptr)
{
    delete (QString *)ptr;
}

QTD_EXTERN QTD_EXPORT void qtd_QString_call_destructor(QString *ptr)
{
    ptr->~QString();
}


QTD_EXTERN QTD_EXPORT void* qtd_QString_QString_QString
(void* string0)
{
    const QString&  __qt_string0 = (const QString& ) *(QString *)string0;
    QString *__qt_this = new QString((const QString& )__qt_string0);
    return (void *) __qt_this;
}

QTD_EXTERN QTD_EXPORT void* qtd_QString_new_fromUtf8_at
(void* place, DArray text)
{
    QString *__qt_this = new(place) QString;
    *__qt_this = QString::fromUtf8((const char *)text.ptr, text.length);
    return __qt_this;
}

QTD_EXTERN QTD_EXPORT void* qtd_QString_placed_copy(void* string0, void* place) {
    const QString&  __qt_string0 = (const QString& ) *(QString *)string0;
    QString *result = new (place)QString((const QString& )__qt_string0);
    return (void *) result;
}

QTD_EXTERN QTD_EXPORT void qtd_QString_placed_ctor(void* place) {
    new (place) QString();
}

QTD_EXTERN QTD_EXPORT void qtd_QString_assign_fromUtf8
(QString *__qt_this, DArray text)
{
    *__qt_this = QString::fromUtf8((const char *)text.ptr, text.length);
}