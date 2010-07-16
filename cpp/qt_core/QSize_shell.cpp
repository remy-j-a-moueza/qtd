#include <qdatastream.h>
#include <qsize.h>
#include "qtd_core.h"


// QSize::operator<<(QDataStream & arg__1)
QTD_EXTERN QTD_EXPORT void __qtd_QSize_writeTo_QDataStream
(void* __this_nativeId,
 void* arg__1)
{
    QDataStream&  __qt_arg__1 = (QDataStream& ) * (QDataStream *) arg__1;
    QSize *__qt_this = (QSize *) __this_nativeId;
    if (__qt_this != 0) ::operator<<((QDataStream& )__qt_arg__1, *__qt_this);

}

// QSize::operator>>(QDataStream & arg__1)
QTD_EXTERN QTD_EXPORT void __qtd_QSize_readFrom_QDataStream
(void* __this_nativeId,
 void* arg__1)
{
    QDataStream&  __qt_arg__1 = (QDataStream& ) * (QDataStream *) arg__1;
    QSize *__qt_this = (QSize *) __this_nativeId;
    if (__qt_this != 0) ::operator>>((QDataStream& )__qt_arg__1, *__qt_this);

}

// QSize::scale(const QSize & s, Qt::AspectRatioMode mode)
QTD_EXTERN QTD_EXPORT void __qtd_QSize_scale_QSize_AspectRatioMode
(void* __this_nativeId,
 void* s0,
 int mode1)
{
    const QSize&  __qt_s0 = (const QSize& ) *(QSize *)s0;
    Qt::AspectRatioMode __qt_mode1 = (Qt::AspectRatioMode) mode1;
    QSize *__qt_this = (QSize *) __this_nativeId;
    __qt_this->scale((const QSize& )__qt_s0, (Qt::AspectRatioMode )__qt_mode1);

}
