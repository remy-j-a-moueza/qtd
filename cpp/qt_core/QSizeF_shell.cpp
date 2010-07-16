#include <qdatastream.h>
#include <qsize.h>
#include "qtd_core.h"

// QSizeF::operator<<(QDataStream & arg__1)
QTD_EXTERN QTD_EXPORT void __qtd_QSizeF_writeTo_QDataStream
(void* __this_nativeId,
 void* arg__1)
{
    QDataStream&  __qt_arg__1 = (QDataStream& ) * (QDataStream *) arg__1;
    QSizeF *__qt_this = (QSizeF *) __this_nativeId;
    if (__qt_this != 0) ::operator<<((QDataStream& )__qt_arg__1, *__qt_this);

}

// QSizeF::operator>>(QDataStream & arg__1)
QTD_EXTERN QTD_EXPORT void __qtd_QSizeF_readFrom_QDataStream
(void* __this_nativeId,
 void* arg__1)
{
    QDataStream&  __qt_arg__1 = (QDataStream& ) * (QDataStream *) arg__1;
    QSizeF *__qt_this = (QSizeF *) __this_nativeId;
    if (__qt_this != 0) ::operator>>((QDataStream& )__qt_arg__1, *__qt_this);

}

// QSizeF::scale(const QSizeF & s, Qt::AspectRatioMode mode)
QTD_EXTERN QTD_EXPORT void __qtd_QSizeF_scale_QSizeF_AspectRatioMode
(void* __this_nativeId,
 void* s0,
 int mode1)
{
    const QSizeF&  __qt_s0 = (const QSizeF& ) *(QSizeF *)s0;
    Qt::AspectRatioMode __qt_mode1 = (Qt::AspectRatioMode) mode1;
    QSizeF *__qt_this = (QSizeF *) __this_nativeId;
    __qt_this->scale((const QSizeF& )__qt_s0, (Qt::AspectRatioMode )__qt_mode1);

}
