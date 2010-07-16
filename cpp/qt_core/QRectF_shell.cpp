#include <qdatastream.h>
#include <qrect.h>

#include "qtd_core.h"


// QRectF::contains(const QPointF & p) const
QTD_EXTERN QTD_EXPORT bool qtd_QRectF_contains_QPointF
(void* __this_nativeId,
 void* p0)
{
    QRectF *__qt_this = (QRectF *) __this_nativeId;
    const QPointF&  __qt_p0 = (const QPointF& ) *(QPointF *)p0;

    bool  __qt_return_value = __qt_this->contains((const QPointF& )__qt_p0);

    bool __d_return_value = __qt_return_value;

    return __d_return_value;
}

// QRectF::contains(const QRectF & r) const
QTD_EXTERN QTD_EXPORT bool qtd_QRectF_contains_QRectF
(void* __this_nativeId,
 void* r0)
{
    const QRectF&  __qt_r0 = (const QRectF& ) *(QRectF *)r0;
    QRectF *__qt_this = (QRectF *) __this_nativeId;
    bool  __qt_return_value = __qt_this->contains((const QRectF& )__qt_r0);

    bool __d_return_value = __qt_return_value;

    return __d_return_value;
}

// QRectF::intersects(const QRectF & r) const
QTD_EXTERN QTD_EXPORT bool qtd_QRectF_intersects_QRectF
(void* __this_nativeId,
 void* r0)
{
    const QRectF&  __qt_r0 = (const QRectF& ) *(QRectF *)r0;
    QRectF *__qt_this = (QRectF *) __this_nativeId;
    bool  __qt_return_value = __qt_this->intersects((const QRectF& )__qt_r0);

    bool __d_return_value = __qt_return_value;

    return __d_return_value;
}

// QRectF::normalized() const
QTD_EXTERN QTD_EXPORT QRectF qtd_QRectF_normalized
(void* __this_nativeId)
{
    QRectF *__qt_this = (QRectF *) __this_nativeId;
    return __qt_this->normalized();
}

// QRectF::operator&(const QRectF & r) const
QTD_EXTERN QTD_EXPORT QRectF qtd_QRectF_operator_and_QRectF
(void* __this_nativeId,
 void* r0)
{
    const QRectF&  __qt_r0 = (const QRectF& ) *(QRectF *)r0;
    QRectF *__qt_this = (QRectF *) __this_nativeId;
    return __qt_this->operator&((const QRectF& )__qt_r0);
}

// QRectF::operator<<(QDataStream & arg__1)
QTD_EXTERN QTD_EXPORT void qtd_QRectF_writeTo_QDataStream
(void* __this_nativeId,
 void* arg__1)
{
    QDataStream&  __qt_arg__1 = (QDataStream& ) * (QDataStream *) arg__1;
    QRectF *__qt_this = (QRectF *) __this_nativeId;
    if (__qt_this != 0) ::operator<<((QDataStream& )__qt_arg__1, *__qt_this);

}

// QRectF::operator>>(QDataStream & arg__1)
QTD_EXTERN QTD_EXPORT void qtd_QRectF_readFrom_QDataStream
(void* __this_nativeId,
 void* arg__1)
{
    QDataStream&  __qt_arg__1 = (QDataStream& ) * (QDataStream *) arg__1;
    QRectF *__qt_this = (QRectF *) __this_nativeId;
    if (__qt_this != 0) ::operator>>((QDataStream& )__qt_arg__1, *__qt_this);

}

// QRectF::operator|(const QRectF & r) const
QTD_EXTERN QTD_EXPORT QRectF qtd_QRectF_operator_or_QRectF
(void* __this_nativeId,
 void* r0)
{
    const QRectF&  __qt_r0 = (const QRectF& ) *(QRectF *)r0;
    QRectF *__qt_this = (QRectF *) __this_nativeId;
    return __qt_this->operator|((const QRectF& )__qt_r0);
}

// QRectF::toAlignedRect() const
QTD_EXTERN QTD_EXPORT QRect qtd_QRectF_toAlignedRect
(void* __this_nativeId)
{
    QRectF *__qt_this = (QRectF *) __this_nativeId;
    return __qt_this->toAlignedRect();
}
