#include <qdatastream.h>
#include <qline.h>

#include "qtd_core.h"


// QLineF::angle() const
QTD_EXTERN QTD_EXPORT double qtd_QLineF_angle
(void* __this_nativeId)
{
    QLineF *__qt_this = (QLineF *) __this_nativeId;
    double  __qt_return_value = __qt_this->angle();

    double __d_return_value = __qt_return_value;

    return __d_return_value;
}

// QLineF::angle(const QLineF & l) const
QTD_EXTERN QTD_EXPORT double qtd_QLineF_angle_QLineF
(void* __this_nativeId,
 void* l0)
{
    const QLineF&  __qt_l0 = (const QLineF& ) *(QLineF *)l0;
    QLineF *__qt_this = (QLineF *) __this_nativeId;
    double  __qt_return_value = __qt_this->angle((const QLineF& )__qt_l0);

    double __d_return_value = __qt_return_value;

    return __d_return_value;
}

// QLineF::angleTo(const QLineF & l) const
QTD_EXTERN QTD_EXPORT double qtd_QLineF_angleTo_QLineF
(void* __this_nativeId,
 void* l0)
{
    const QLineF&  __qt_l0 = (const QLineF& ) *(QLineF *)l0;
    QLineF *__qt_this = (QLineF *) __this_nativeId;
    double  __qt_return_value = __qt_this->angleTo((const QLineF& )__qt_l0);

    double __d_return_value = __qt_return_value;

    return __d_return_value;
}

// QLineF::intersect(const QLineF & l, QPointF * intersectionPoint) const
QTD_EXTERN QTD_EXPORT int qtd_QLineF_intersect_QLineF_nativepointerQPointF
(void* __this_nativeId,
 void* l0,
 void* intersectionPoint1)
{
    const QLineF&  __qt_l0 = (const QLineF& ) *(QLineF *)l0;
    QLineF *__qt_this = (QLineF *) __this_nativeId;
    int  __qt_return_value = __qt_this->intersect((const QLineF& )__qt_l0, (QPointF* )intersectionPoint1);

    int __d_return_value = __qt_return_value;

    return __d_return_value;
}

// QLineF::isNull() const
QTD_EXTERN QTD_EXPORT bool qtd_QLineF_isNull
(void* __this_nativeId)
{
    QLineF *__qt_this = (QLineF *) __this_nativeId;
    bool  __qt_return_value = __qt_this->isNull();

    bool __d_return_value = __qt_return_value;

    return __d_return_value;
}

// QLineF::length() const
QTD_EXTERN QTD_EXPORT double qtd_QLineF_length
(void* __this_nativeId)
{
    QLineF *__qt_this = (QLineF *) __this_nativeId;
    double  __qt_return_value = __qt_this->length();

    double __d_return_value = __qt_return_value;

    return __d_return_value;
}

// QLineF::operator<<(QDataStream & arg__1)
QTD_EXTERN QTD_EXPORT void qtd_QLineF_writeTo_QDataStream
(void* __this_nativeId,
 void* arg__1)
{
    QDataStream&  __qt_arg__1 = (QDataStream& ) * (QDataStream *) arg__1;
    QLineF *__qt_this = (QLineF *) __this_nativeId;
    if (__qt_this != 0) ::operator<<((QDataStream& )__qt_arg__1, *__qt_this);

}

// QLineF::operator>>(QDataStream & arg__1)
QTD_EXTERN QTD_EXPORT void qtd_QLineF_readFrom_QDataStream
(void* __this_nativeId,
 void* arg__1)
{
    QDataStream&  __qt_arg__1 = (QDataStream& ) * (QDataStream *) arg__1;
    QLineF *__qt_this = (QLineF *) __this_nativeId;
    if (__qt_this != 0) ::operator>>((QDataStream& )__qt_arg__1, *__qt_this);

}

// QLineF::p1() const
QTD_EXTERN QTD_EXPORT QPointF qtd_QLineF_p1
(void* __this_nativeId)
{
    QLineF *__qt_this = (QLineF *) __this_nativeId;
    QPointF  __qt_return_value = __qt_this->p1();

    QPointF *__d_return_value = (QPointF *) &__qt_return_value;

    return __qt_return_value;
}

// QLineF::setAngle(double angle)
QTD_EXTERN QTD_EXPORT void qtd_QLineF_setAngle_double
(void* __this_nativeId,
 double angle0)
{
    QLineF *__qt_this = (QLineF *) __this_nativeId;
    __qt_this->setAngle((double )angle0);

}

// QLineF::unitVector() const
QTD_EXTERN QTD_EXPORT QLineF qtd_QLineF_unitVector
(void* __this_nativeId)
{
    QLineF *__qt_this = (QLineF *) __this_nativeId;
    return __qt_this->unitVector();
}

// QLineF::fromPolar(double length, double angle)
QTD_EXTERN QTD_EXPORT QLineF qtd_QLineF_fromPolar_double_double
(double length0,
 double angle1)
{
    return QLineF::fromPolar((double )length0, (double )angle1);
}
