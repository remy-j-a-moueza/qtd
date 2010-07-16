#include <QVariant>
#include <qbitarray.h>
#include <qbytearray.h>
#include <qdatastream.h>
#include <qdatetime.h>
#include <qline.h>
#include <qlist.h>
#include <qlocale.h>
#include <qpoint.h>
#include <qrect.h>
#include <qregexp.h>
#include <qstringlist.h>
#include <qurl.h>
#include <qvariant.h>

#include "QVariant_shell.h"
#include <qvariant.h>

#include "qtd_core.h"
QTD_EXTERN QTD_EXPORT void qtd_QVariant_destructor(void *ptr)
{
    delete (QVariant *)ptr;
}

QTD_EXTERN QTD_EXPORT void qtd_QVariant_call_destructor(QVariant *ptr)
{
    ptr->~QVariant();
}

QVariant_QtDShell::QVariant_QtDShell()
    : QVariant()
{
}

QVariant_QtDShell::QVariant_QtDShell(QDataStream&  s0)
    : QVariant(s0)
{
}

QVariant_QtDShell::QVariant_QtDShell(Qt::GlobalColor  color0)
    : QVariant(color0)
{
}

QVariant_QtDShell::QVariant_QtDShell(bool  b0)
    : QVariant(b0)
{
}

QVariant_QtDShell::QVariant_QtDShell(const QBitArray&  bitarray0)
    : QVariant(bitarray0)
{
}

QVariant_QtDShell::QVariant_QtDShell(const QByteArray&  bytearray0)
    : QVariant(bytearray0)
{
}

QVariant_QtDShell::QVariant_QtDShell(const QChar&  qchar0)
    : QVariant(qchar0)
{
}

QVariant_QtDShell::QVariant_QtDShell(const QDate&  date0)
    : QVariant(date0)
{
}

QVariant_QtDShell::QVariant_QtDShell(const QDateTime&  datetime0)
    : QVariant(datetime0)
{
}

QVariant_QtDShell::QVariant_QtDShell(const QLatin1String&  string0)
    : QVariant(string0)
{
}

QVariant_QtDShell::QVariant_QtDShell(const QLine&  line0)
    : QVariant(line0)
{
}

QVariant_QtDShell::QVariant_QtDShell(const QLineF&  line0)
    : QVariant(line0)
{
}

QVariant_QtDShell::QVariant_QtDShell(const QList<QVariant >&  list0)
    : QVariant(list0)
{
}

QVariant_QtDShell::QVariant_QtDShell(const QLocale&  locale0)
    : QVariant(locale0)
{
}

QVariant_QtDShell::QVariant_QtDShell(const QMap<QString , QVariant >&  map0)
    : QVariant(map0)
{
}

QVariant_QtDShell::QVariant_QtDShell(const QPoint&  pt0)
    : QVariant(pt0)
{
}

QVariant_QtDShell::QVariant_QtDShell(const QPointF&  pt0)
    : QVariant(pt0)
{
}

QVariant_QtDShell::QVariant_QtDShell(const QRect&  rect0)
    : QVariant(rect0)
{
}

QVariant_QtDShell::QVariant_QtDShell(const QRectF&  rect0)
    : QVariant(rect0)
{
}

QVariant_QtDShell::QVariant_QtDShell(const QRegExp&  regExp0)
    : QVariant(regExp0)
{
}

QVariant_QtDShell::QVariant_QtDShell(const QSize&  size0)
    : QVariant(size0)
{
}

QVariant_QtDShell::QVariant_QtDShell(const QSizeF&  size0)
    : QVariant(size0)
{
}

QVariant_QtDShell::QVariant_QtDShell(const QString&  string0)
    : QVariant(string0)
{
}

QVariant_QtDShell::QVariant_QtDShell(const QStringList&  stringlist0)
    : QVariant(stringlist0)
{
}

QVariant_QtDShell::QVariant_QtDShell(const QTime&  time0)
    : QVariant(time0)
{
}

QVariant_QtDShell::QVariant_QtDShell(const QUrl&  url0)
    : QVariant(url0)
{
}

QVariant_QtDShell::QVariant_QtDShell(const QVariant&  other0)
    : QVariant(other0)
{
}

QVariant_QtDShell::QVariant_QtDShell(const char*  str0)
    : QVariant(str0)
{
}

QVariant_QtDShell::QVariant_QtDShell(double  d0)
    : QVariant(d0)
{
}

QVariant_QtDShell::QVariant_QtDShell(int  i0)
    : QVariant(i0)
{
}

QVariant_QtDShell::QVariant_QtDShell(int  typeOrUserType0, const void*  copy1)
    : QVariant(typeOrUserType0, copy1)
{
}

QVariant_QtDShell::QVariant_QtDShell(qint64  ll0)
    : QVariant(ll0)
{
}

QVariant_QtDShell::QVariant_QtDShell(uint  ui0)
    : QVariant(ui0)
{
}

QVariant_QtDShell::QVariant_QtDShell(quint64  ull0)
    : QVariant(ull0)
{
}

QVariant_QtDShell::~QVariant_QtDShell()
{
}

// Virtual overrides
// Functions in shell class
// public overrides for functions that are protected in the base class
bool  QVariant_QtDShell::__public_cmp(const QVariant&  other0) const
{
    return QVariant::cmp((const QVariant& )other0);
}

void QVariant_QtDShell::__public_create(int  type0, const void*  copy1)
{
    QVariant::create((int )type0, (const void* )copy1);
}

// Write virtual function overries used to decide on static/virtual calls
// ---externC---
// QVariant::QVariant()
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant
()
{
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell();
    return (void *) __qt_this;

}

// QVariant::QVariant(QDataStream & s)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_QDataStream
(void* s0)
{
    QDataStream&  __qt_s0 = (QDataStream& ) * (QDataStream *) s0;
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((QDataStream& )__qt_s0);
    return (void *) __qt_this;

}

// QVariant::QVariant(Qt::GlobalColor color)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_GlobalColor
(int color0)
{
    Qt::GlobalColor __qt_color0 = (Qt::GlobalColor) color0;
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((Qt::GlobalColor )__qt_color0);
    return (void *) __qt_this;

}

// QVariant::QVariant(bool b)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_bool
(bool b0)
{
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((bool )b0);
    return (void *) __qt_this;

}

// QVariant::QVariant(const QBitArray & bitarray)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_QBitArray
(void* bitarray0)
{
    const QBitArray&  __qt_bitarray0 = (const QBitArray& ) *(QBitArray *)bitarray0;
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((const QBitArray& )__qt_bitarray0);
    return (void *) __qt_this;

}

// QVariant::QVariant(const QByteArray & bytearray)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_QByteArray
(void* bytearray0)
{
    const QByteArray&  __qt_bytearray0 = (const QByteArray& ) *(QByteArray *)bytearray0;
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((const QByteArray& )__qt_bytearray0);
    return (void *) __qt_this;

}

// QVariant::QVariant(const QChar & qchar)
// QVariant::QVariant(const QDate & date)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_QDate
(void* date0)
{
    const QDate&  __qt_date0 = (const QDate& ) *(QDate *)date0;
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((const QDate& )__qt_date0);
    return (void *) __qt_this;

}

// QVariant::QVariant(const QDateTime & datetime)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_QDateTime
(void* datetime0)
{
    const QDateTime&  __qt_datetime0 = (const QDateTime& ) *(QDateTime *)datetime0;
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((const QDateTime& )__qt_datetime0);
    return (void *) __qt_this;

}

// QVariant::QVariant(const QLine & line)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_QLine
(void* line0)
{
    const QLine&  __qt_line0 = (const QLine& ) *(QLine *)line0;
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((const QLine& )__qt_line0);
    return (void *) __qt_this;

}

// QVariant::QVariant(const QLineF & line)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_QLineF
(void* line0)
{
    const QLineF&  __qt_line0 = (const QLineF& ) *(QLineF *)line0;
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((const QLineF& )__qt_line0);
    return (void *) __qt_this;

}

// QVariant::QVariant(const QList<QVariant > & list)
// QVariant::QVariant(const QLocale & locale)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_QLocale
(void* locale0)
{
    const QLocale&  __qt_locale0 = (const QLocale& ) *(QLocale *)locale0;
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((const QLocale& )__qt_locale0);
    return (void *) __qt_this;

}

// QVariant::QVariant(const QMap<QString, QVariant > & map)
// QVariant::QVariant(const QPoint & pt)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_QPoint
(void* pt0)
{
    const QPoint&  __qt_pt0 = (const QPoint& ) *(QPoint *)pt0;
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((const QPoint& )__qt_pt0);
    return (void *) __qt_this;

}

// QVariant::QVariant(const QPointF & pt)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_QPointF
(void* pt0)
{
    const QPointF&  __qt_pt0 = (const QPointF& ) *(QPointF *)pt0;
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((const QPointF& )__qt_pt0);
    return (void *) __qt_this;

}

// QVariant::QVariant(const QRect & rect)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_QRect
(void* rect0)
{
    const QRect&  __qt_rect0 = (const QRect& ) *(QRect *)rect0;
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((const QRect& )__qt_rect0);
    return (void *) __qt_this;

}

// QVariant::QVariant(const QRectF & rect)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_QRectF
(void* rect0)
{
    const QRectF&  __qt_rect0 = (const QRectF& ) *(QRectF *)rect0;
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((const QRectF& )__qt_rect0);
    return (void *) __qt_this;

}

// QVariant::QVariant(const QRegExp & regExp)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_QRegExp
(void* regExp0)
{
    const QRegExp&  __qt_regExp0 = (const QRegExp& ) *(QRegExp *)regExp0;
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((const QRegExp& )__qt_regExp0);
    return (void *) __qt_this;

}

// QVariant::QVariant(const QSize & size)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_QSize
(void* size0)
{
    const QSize&  __qt_size0 = (const QSize& ) *(QSize *)size0;
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((const QSize& )__qt_size0);
    return (void *) __qt_this;

}

// QVariant::QVariant(const QSizeF & size)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_QSizeF
(void* size0)
{
    const QSizeF&  __qt_size0 = (const QSizeF& ) *(QSizeF *)size0;
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((const QSizeF& )__qt_size0);
    return (void *) __qt_this;

}

// QVariant::QVariant(const QString & string)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_String
(DArray string0)
{
    QString __qt_string0 = QString::fromUtf8((const char *)string0.ptr, string0.length);
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((const QString& )__qt_string0);
    return (void *) __qt_this;

}

// QVariant::QVariant(const QStringList & stringlist)
// QVariant::QVariant(const QTime & time)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_QTime
(void* time0)
{
    const QTime&  __qt_time0 = (const QTime& ) *(QTime *)time0;
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((const QTime& )__qt_time0);
    return (void *) __qt_this;

}

// QVariant::QVariant(const QUrl & url)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_QUrl
(void* url0)
{
    const QUrl&  __qt_url0 = (const QUrl& ) *(QUrl *)url0;
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((const QUrl& )__qt_url0);
    return (void *) __qt_this;

}

// QVariant::QVariant(const QVariant & other)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_QVariant
(void* other0)
{
    const QVariant&  __qt_other0 = (const QVariant& ) *(QVariant *)other0;
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((const QVariant& )__qt_other0);
    return (void *) __qt_this;

}

// QVariant::QVariant(const char * str)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_nativepointerchar
(char* str0)
{
    const char*  __qt_str0 = (const char* ) str0;
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((const char* )__qt_str0);
    return (void *) __qt_this;

}

// QVariant::QVariant(double d)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_double
(double d0)
{
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((double )d0);
    return (void *) __qt_this;

}

// QVariant::QVariant(int i)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_int
(int i0)
{
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((int )i0);
    return (void *) __qt_this;

}

// QVariant::QVariant(int typeOrUserType, const void * copy)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_int_nativepointervoid
(int typeOrUserType0,
 void* copy1)
{
    const void*  __qt_copy1 = (const void* ) copy1;
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((int )typeOrUserType0, (const void* )__qt_copy1);
    return (void *) __qt_this;

}

// QVariant::QVariant(long long ll)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_long
(qint64 ll0)
{
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((qint64 )ll0);
    return (void *) __qt_this;

}

// QVariant::QVariant(uint ui)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_uint
(uint ui0)
{
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((uint )ui0);
    return (void *) __qt_this;

}

// QVariant::QVariant(unsigned long long ull)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_QVariant_ulong
(quint64 ull0)
{
    QVariant_QtDShell *__qt_this = new QVariant_QtDShell((quint64 )ull0);
    return (void *) __qt_this;

}

// QVariant::canConvert() const
QTD_EXTERN QTD_EXPORT bool qtd_QVariant_canConvert
(void* __this_nativeId, QVariant::Type type)
{
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    bool  __qt_return_value = __qt_this->canConvert(type);

    bool __java_return_value = __qt_return_value;

    return __java_return_value;
}

// QVariant::clear()
QTD_EXTERN QTD_EXPORT void qtd_QVariant_clear
(void* __this_nativeId)
{
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    __qt_this->clear();

}

// QVariant::cmp(const QVariant & other) const
QTD_EXTERN QTD_EXPORT bool qtd_QVariant_cmp_QVariant
(void* __this_nativeId,
 void* other0)
{
    const QVariant&  __qt_other0 = (const QVariant& ) *(QVariant *)other0;
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    bool  __qt_return_value = __qt_this->__public_cmp((const QVariant& )__qt_other0);

    bool __java_return_value = __qt_return_value;

    return __java_return_value;
}

// QVariant::create(int type, const void * copy)
QTD_EXTERN QTD_EXPORT void qtd_QVariant_create_int_nativepointervoid
(void* __this_nativeId,
 int type0,
 void* copy1)
{
    const void*  __qt_copy1 = (const void* ) copy1;
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    __qt_this->__public_create((int )type0, (const void* )__qt_copy1);

}

// QVariant::isNull() const
QTD_EXTERN QTD_EXPORT bool qtd_QVariant_isNull
(void* __this_nativeId)
{
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    bool  __qt_return_value = __qt_this->isNull();

    bool __java_return_value = __qt_return_value;

    return __java_return_value;
}

// QVariant::isValid() const
QTD_EXTERN QTD_EXPORT bool qtd_QVariant_isValid
(void* __this_nativeId)
{
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    bool  __qt_return_value = __qt_this->isValid();

    bool __java_return_value = __qt_return_value;

    return __java_return_value;
}

// QVariant::load(QDataStream & ds)
QTD_EXTERN QTD_EXPORT void qtd_QVariant_load_QDataStream
(void* __this_nativeId,
 void* ds0)
{
    QDataStream&  __qt_ds0 = (QDataStream& ) * (QDataStream *) ds0;
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    __qt_this->load((QDataStream& )__qt_ds0);

}

// QVariant::operator<<(QDataStream & s)
QTD_EXTERN QTD_EXPORT void qtd_QVariant_writeTo_QDataStream
(void* __this_nativeId,
 void* s0)
{
    QDataStream&  __qt_s0 = (QDataStream& ) * (QDataStream *) s0;
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    if (__qt_this != 0) ::operator<<((QDataStream& )__qt_s0, *__qt_this);

}

// QVariant::operator=(const QVariant & other)
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_operator_assign_QVariant
(void* __this_nativeId,
 void* other0)
{
    const QVariant&  __qt_other0 = (const QVariant& ) *(QVariant *)other0;
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    QVariant&  __qt_return_value = __qt_this->operator=((const QVariant& )__qt_other0);

    void* __java_return_value = (void*) &__qt_return_value;// qtjambi_from_cpointer

    return __java_return_value;
}

// QVariant::operator==(const QVariant & v) const
QTD_EXTERN QTD_EXPORT bool qtd_QVariant_operator_equal_QVariant
(void* __this_nativeId,
 void* v0)
{
    const QVariant&  __qt_v0 = (const QVariant& ) *(QVariant *)v0;
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    bool  __qt_return_value = __qt_this->operator==((const QVariant& )__qt_v0);

    bool __java_return_value = __qt_return_value;

    return __java_return_value;
}

// QVariant::operator>>(QDataStream & s)
QTD_EXTERN QTD_EXPORT void qtd_QVariant_readFrom_QDataStream
(void* __this_nativeId,
 void* s0)
{
    QDataStream&  __qt_s0 = (QDataStream& ) * (QDataStream *) s0;
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    if (__qt_this != 0) ::operator>>((QDataStream& )__qt_s0, *__qt_this);

}

// QVariant::save(QDataStream & ds) const
QTD_EXTERN QTD_EXPORT void qtd_QVariant_save_QDataStream
(void* __this_nativeId,
 void* ds0)
{
    QDataStream&  __qt_ds0 = (QDataStream& ) * (QDataStream *) ds0;
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    __qt_this->save((QDataStream& )__qt_ds0);

}

// QVariant::toBitArray() const
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_toBitArray
(void* __this_nativeId)
{
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    QBitArray  __qt_return_value = __qt_this->toBitArray();

    void* __java_return_value = (void*) new QBitArray(__qt_return_value);

    return __java_return_value;
}

// QVariant::toBool() const
QTD_EXTERN QTD_EXPORT bool qtd_QVariant_toBool
(void* __this_nativeId)
{
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    bool  __qt_return_value = __qt_this->toBool();

    bool __java_return_value = __qt_return_value;

    return __java_return_value;
}

// QVariant::toByteArray() const
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_toByteArray
(void* __this_nativeId)
{
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    QByteArray  __qt_return_value = __qt_this->toByteArray();

    void* __java_return_value = (void*) new QByteArray(__qt_return_value);

    return __java_return_value;
}

// QVariant::toChar() const
// QVariant::toDate() const
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_toDate
(void* __this_nativeId)
{
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    QDate  __qt_return_value = __qt_this->toDate();

    void* __java_return_value = (void*) new QDate(__qt_return_value);

    return __java_return_value;
}

// QVariant::toDateTime() const
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_toDateTime
(void* __this_nativeId)
{
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    QDateTime  __qt_return_value = __qt_this->toDateTime();

    void* __java_return_value = (void*) new QDateTime(__qt_return_value);

    return __java_return_value;
}

// QVariant::toDouble(bool * ok) const
QTD_EXTERN QTD_EXPORT double qtd_QVariant_toDouble_nativepointerbool
(void* __this_nativeId,
 bool* ok0)
{
    bool*  __qt_ok0 = (bool* ) ok0;
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    double  __qt_return_value = __qt_this->toDouble((bool* )__qt_ok0);

    double __java_return_value = __qt_return_value;

    return __java_return_value;
}

// QVariant::toInt(bool * ok) const
QTD_EXTERN QTD_EXPORT int qtd_QVariant_toInt_nativepointerbool
(void* __this_nativeId,
 bool* ok0)
{
    bool*  __qt_ok0 = (bool* ) ok0;
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    int  __qt_return_value = __qt_this->toInt((bool* )__qt_ok0);

    int __java_return_value = __qt_return_value;

    return __java_return_value;
}

// QVariant::toLine() const
QTD_EXTERN QTD_EXPORT QLine qtd_QVariant_toLine
(void* __this_nativeId)
{
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    return __qt_this->toLine();
}

// QVariant::toLineF() const
QTD_EXTERN QTD_EXPORT QLineF qtd_QVariant_toLineF
(void* __this_nativeId)
{
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    return __qt_this->toLineF();
}

// QVariant::toList() const
// QVariant::toLocale() const
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_toLocale
(void* __this_nativeId)
{
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    QLocale  __qt_return_value = __qt_this->toLocale();

    void* __java_return_value = (void*) new QLocale(__qt_return_value);

    return __java_return_value;
}

// QVariant::toLongLong(bool * ok) const
QTD_EXTERN QTD_EXPORT qint64 qtd_QVariant_toLongLong_nativepointerbool
(void* __this_nativeId,
 bool* ok0)
{
    bool*  __qt_ok0 = (bool* ) ok0;
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    qint64  __qt_return_value = __qt_this->toLongLong((bool* )__qt_ok0);

    qint64 __java_return_value = __qt_return_value;

    return __java_return_value;
}

// QVariant::toMap() const
// QVariant::toPoint() const
QTD_EXTERN QTD_EXPORT QPoint qtd_QVariant_toPoint
(void* __this_nativeId)
{
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    QPoint  __qt_return_value = __qt_this->toPoint();

    return __qt_return_value;
}

// QVariant::toPointF() const
QTD_EXTERN QTD_EXPORT QPointF qtd_QVariant_toPointF
(void* __this_nativeId)
{
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    QPointF  __qt_return_value = __qt_this->toPointF();

    return __qt_return_value;
}

// QVariant::toRect() const
QTD_EXTERN QTD_EXPORT QRect qtd_QVariant_toRect
(void* __this_nativeId)
{
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    QRect  __qt_return_value = __qt_this->toRect();

    return __qt_return_value;
}

// QVariant::toRectF() const
QTD_EXTERN QTD_EXPORT QRectF qtd_QVariant_toRectF
(void* __this_nativeId)
{
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    QRectF  __qt_return_value = __qt_this->toRectF();

    return __qt_return_value;
}

// QVariant::toRegExp() const
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_toRegExp
(void* __this_nativeId)
{
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    QRegExp  __qt_return_value = __qt_this->toRegExp();

    void* __java_return_value = (void*) new QRegExp(__qt_return_value);

    return __java_return_value;
}

// QVariant::toSize() const
QTD_EXTERN QTD_EXPORT QSize qtd_QVariant_toSize
(void* __this_nativeId)
{
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    QSize  __qt_return_value = __qt_this->toSize();


    return __qt_return_value;
}

// QVariant::toSizeF() const
QTD_EXTERN QTD_EXPORT QSizeF qtd_QVariant_toSizeF
(void* __this_nativeId)
{
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    QSizeF  __qt_return_value = __qt_this->toSizeF();


    return __qt_return_value;
}

// QVariant::toString() const
QTD_EXTERN QTD_EXPORT void qtd_QVariant_toString
(void* __this_nativeId,
 void* __java_return_value)
{
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    QString  __qt_return_value = __qt_this->toString();

    qtd_toUtf8(__qt_return_value.utf16(), __qt_return_value.size(), __java_return_value);

}

// QVariant::toStringList() const
// QVariant::toTime() const
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_toTime
(void* __this_nativeId)
{
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    QTime  __qt_return_value = __qt_this->toTime();

    void* __java_return_value = (void*) new QTime(__qt_return_value);

    return __java_return_value;
}

// QVariant::toUInt(bool * ok) const
QTD_EXTERN QTD_EXPORT uint qtd_QVariant_toUInt_nativepointerbool
(void* __this_nativeId,
 bool* ok0)
{
    bool*  __qt_ok0 = (bool* ) ok0;
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    uint  __qt_return_value = __qt_this->toUInt((bool* )__qt_ok0);

    uint __java_return_value = __qt_return_value;

    return __java_return_value;
}

// QVariant::toULongLong(bool * ok) const
QTD_EXTERN QTD_EXPORT quint64 qtd_QVariant_toULongLong_nativepointerbool
(void* __this_nativeId,
 bool* ok0)
{
    bool*  __qt_ok0 = (bool* ) ok0;
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    quint64  __qt_return_value = __qt_this->toULongLong((bool* )__qt_ok0);

    quint64 __java_return_value = __qt_return_value;

    return __java_return_value;
}

// QVariant::toUrl() const
QTD_EXTERN QTD_EXPORT void* qtd_QVariant_toUrl
(void* __this_nativeId)
{
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    QUrl  __qt_return_value = __qt_this->toUrl();

    void* __java_return_value = (void*) new QUrl(__qt_return_value);

    return __java_return_value;
}

// QVariant::typeName() const
QTD_EXTERN QTD_EXPORT char* qtd_QVariant_typeName
(void* __this_nativeId)
{
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    const char*  __qt_return_value = __qt_this->typeName();

    char* __java_return_value = (char*) __qt_return_value;// qtjambi_from_cpointer

    return __java_return_value;
}

// QVariant::type() const
QTD_EXTERN QTD_EXPORT int qtd_QVariant_type
(void* __this_nativeId)
{
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    int  __qt_return_value = __qt_this->type();

    int __java_return_value = __qt_return_value;

    return __java_return_value;
}

// QVariant::userType() const
QTD_EXTERN QTD_EXPORT int qtd_QVariant_userType
(void* __this_nativeId)
{
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    int  __qt_return_value = __qt_this->userType();

    int __java_return_value = __qt_return_value;

    return __java_return_value;
}

QTD_EXTERN QTD_EXPORT void *qtd_QVariant_data(void* __this_nativeId)
{
    QVariant_QtDShell *__qt_this = (QVariant_QtDShell *) __this_nativeId;
    return __qt_this->data();
}

// ---externC---end
// Field accessors



QTD_EXTERN QTD_EXPORT void* qtd_QVariant_placed_copy(void* variant0, void* place) {
    const QVariant&  __qt_variant0 = (const QVariant& ) *(QVariant *)variant0;
    QVariant *result = new (place)QVariant((const QVariant& )__qt_variant0);
    return (void *) result;
}