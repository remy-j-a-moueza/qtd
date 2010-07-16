#include <qdatastream.h>
#include <qpoint.h>

#include "qtd_core.h"

// ---externC---
// QPointF::operator<<(QDataStream & arg__1)
QTD_EXTERN QTD_EXPORT void qtd_QPointF_writeTo_QDataStream
(void* __this_nativeId,
 void* arg__1)
{
    QDataStream&  __qt_arg__1 = (QDataStream& ) * (QDataStream *) arg__1;
    QPointF *__qt_this = (QPointF *) __this_nativeId;
    if (__qt_this != 0) ::operator<<((QDataStream& )__qt_arg__1, *__qt_this);

}

// QPointF::operator>>(QDataStream & arg__1)
QTD_EXTERN QTD_EXPORT void qtd_QPointF_readFrom_QDataStream
(void* __this_nativeId,
 void* arg__1)
{
    QDataStream&  __qt_arg__1 = (QDataStream& ) * (QDataStream *) arg__1;
    QPointF *__qt_this = (QPointF *) __this_nativeId;
    if (__qt_this != 0) ::operator>>((QDataStream& )__qt_arg__1, *__qt_this);

}
// ---externC---end
