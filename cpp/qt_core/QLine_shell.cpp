#include <qdatastream.h>
#include <qline.h>

#include "qtd_core.h"

// QLine::operator<<(QDataStream & arg__1)
QTD_EXTERN QTD_EXPORT void qtd_QLine_writeTo_QDataStream
(void* __this_nativeId,
 void* arg__1)
{
    QDataStream&  __qt_arg__1 = (QDataStream& ) * (QDataStream *) arg__1;
    QLine *__qt_this = (QLine *) __this_nativeId;
    if (__qt_this != 0) ::operator<<((QDataStream& )__qt_arg__1, *__qt_this);

}

// QLine::operator>>(QDataStream & arg__1)
QTD_EXTERN QTD_EXPORT void qtd_QLine_readFrom_QDataStream
(void* __this_nativeId,
 void* arg__1)
{
    QDataStream&  __qt_arg__1 = (QDataStream& ) * (QDataStream *) arg__1;
    QLine *__qt_this = (QLine *) __this_nativeId;
    if (__qt_this != 0) ::operator>>((QDataStream& )__qt_arg__1, *__qt_this);

}
