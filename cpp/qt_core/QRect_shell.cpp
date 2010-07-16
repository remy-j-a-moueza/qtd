#include <qdatastream.h>
#include <qrect.h>

#include "qtd_core.h"

// QRect::contains(const QPoint & p, bool proper) const
QTD_EXTERN QTD_EXPORT bool qtd_QRect_contains_QPoint_bool
(void* __this_nativeId,
 void* p0,
 bool proper1)
{
    QRect *__qt_this = (QRect *) __this_nativeId;
    const QPoint&  __qt_p0 = (const QPoint& ) *(QPoint *)p0;
    bool  __qt_return_value = __qt_this->contains((const QPoint& )p0, (bool )proper1);

    bool __d_return_value = __qt_return_value;

    return __d_return_value;
}

// QRect::contains(const QRect & r, bool proper) const
QTD_EXTERN QTD_EXPORT bool qtd_QRect_contains_QRect_bool
(void* __this_nativeId,
 void* r0,
 bool proper1)
{
    const QRect&  __qt_r0 = (const QRect& ) *(QRect *)r0;
    QRect *__qt_this = (QRect *) __this_nativeId;
    bool  __qt_return_value = __qt_this->contains((const QRect& )__qt_r0, (bool )proper1);

    bool __d_return_value = __qt_return_value;

    return __d_return_value;
}

// QRect::intersects(const QRect & r) const
QTD_EXTERN QTD_EXPORT bool qtd_QRect_intersects_QRect
(void* __this_nativeId,
 void* r0)
{
    const QRect&  __qt_r0 = (const QRect& ) *(QRect *)r0;
    QRect *__qt_this = (QRect *) __this_nativeId;
    bool  __qt_return_value = __qt_this->intersects((const QRect& )__qt_r0);

    bool __d_return_value = __qt_return_value;

    return __d_return_value;
}

// QRect::normalized() const
QTD_EXTERN QTD_EXPORT QRect qtd_QRect_normalized
(void* __this_nativeId)
{
    QRect *__qt_this = (QRect *) __this_nativeId;
    return __qt_this->normalized();
}

// QRect::operator&(const QRect & r) const
QTD_EXTERN QTD_EXPORT QRect qtd_QRect_operator_and_QRect
(void* __this_nativeId,
 void* r0)
{
    const QRect&  __qt_r0 = (const QRect& ) *(QRect *)r0;
    QRect *__qt_this = (QRect *) __this_nativeId;
    return __qt_this->operator&((const QRect& )__qt_r0);
}

// QRect::operator<<(QDataStream & arg__1)
QTD_EXTERN QTD_EXPORT void qtd_QRect_writeTo_QDataStream
(void* __this_nativeId,
 void* arg__1)
{
    QDataStream&  __qt_arg__1 = (QDataStream& ) * (QDataStream *) arg__1;
    QRect *__qt_this = (QRect *) __this_nativeId;
    if (__qt_this != 0) ::operator<<((QDataStream& )__qt_arg__1, *__qt_this);

}

// QRect::operator>>(QDataStream & arg__1)
QTD_EXTERN QTD_EXPORT void qtd_QRect_readFrom_QDataStream
(void* __this_nativeId,
 void* arg__1)
{
    QDataStream&  __qt_arg__1 = (QDataStream& ) * (QDataStream *) arg__1;
    QRect *__qt_this = (QRect *) __this_nativeId;
    if (__qt_this != 0) ::operator>>((QDataStream& )__qt_arg__1, *__qt_this);

}

// QRect::operator|(const QRect & r) const
QTD_EXTERN QTD_EXPORT QRect qtd_QRect_operator_or_QRect
(void* __this_nativeId,
 void* r0)
{
    const QRect&  __qt_r0 = (const QRect& ) *(QRect *)r0;
    QRect *__qt_this = (QRect *) __this_nativeId;
    return __qt_this->operator|((const QRect& )__qt_r0);
}
