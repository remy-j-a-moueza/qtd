#include <qdatastream.h>
#include <qpoint.h>

#include "qtd_core.h"


// QPoint::manhattanLength() const
QTD_EXTERN QTD_EXPORT int qtd_QPoint_manhattanLength
(void* __this_nativeId)
{
    QPoint *__qt_this = (QPoint *) __this_nativeId;
    int  __qt_return_value = __qt_this->manhattanLength();

    int __d_return_value = __qt_return_value;

    return __d_return_value;
}

// QPoint::operator<<(QDataStream & arg__1)
QTD_EXTERN QTD_EXPORT void qtd_QPoint_writeTo_QDataStream
(void* __this_nativeId,
 void* arg__1)
{
    QDataStream&  __qt_arg__1 = (QDataStream& ) * (QDataStream *) arg__1;
    QPoint *__qt_this = (QPoint *) __this_nativeId;
    if (__qt_this != 0) ::operator<<((QDataStream& )__qt_arg__1, *__qt_this);

}

// QPoint::operator>>(QDataStream & arg__1)
QTD_EXTERN QTD_EXPORT void qtd_QPoint_readFrom_QDataStream
(void* __this_nativeId,
 void* arg__1)
{
    QDataStream&  __qt_arg__1 = (QDataStream& ) * (QDataStream *) arg__1;
    QPoint *__qt_this = (QPoint *) __this_nativeId;
    if (__qt_this != 0) ::operator>>((QDataStream& )__qt_arg__1, *__qt_this);

}
// ---externC---end
