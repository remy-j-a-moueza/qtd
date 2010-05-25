#ifndef QVARIANT_SHELL_H
#define QVARIANT_SHELL_H

#include <QtCore/QHash>
#include <qtd_core.h>
#include <qvariant.h>

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

class QVariant_QtDShell : public QVariant
{
public:
    QVariant_QtDShell();
    QVariant_QtDShell(QDataStream&  s0);
    QVariant_QtDShell(Qt::GlobalColor  color0);
    QVariant_QtDShell(bool  b0);
    QVariant_QtDShell(const QBitArray&  bitarray0);
    QVariant_QtDShell(const QByteArray&  bytearray0);
    QVariant_QtDShell(const QChar&  qchar0);
    QVariant_QtDShell(const QDate&  date0);
    QVariant_QtDShell(const QDateTime&  datetime0);
    QVariant_QtDShell(const QLatin1String&  string0);
    QVariant_QtDShell(const QLine&  line0);
    QVariant_QtDShell(const QLineF&  line0);
    QVariant_QtDShell(const QList<QVariant >&  list0);
    QVariant_QtDShell(const QLocale&  locale0);
    QVariant_QtDShell(const QMap<QString , QVariant >&  map0);
    QVariant_QtDShell(const QPoint&  pt0);
    QVariant_QtDShell(const QPointF&  pt0);
    QVariant_QtDShell(const QRect&  rect0);
    QVariant_QtDShell(const QRectF&  rect0);
    QVariant_QtDShell(const QRegExp&  regExp0);
    QVariant_QtDShell(const QSize&  size0);
    QVariant_QtDShell(const QSizeF&  size0);
    QVariant_QtDShell(const QString&  string0);
    QVariant_QtDShell(const QStringList&  stringlist0);
    QVariant_QtDShell(const QTime&  time0);
    QVariant_QtDShell(const QUrl&  url0);
    QVariant_QtDShell(const QVariant&  other0);
    QVariant_QtDShell(const char*  str0);
    QVariant_QtDShell(double  d0);
    QVariant_QtDShell(int  i0);
    QVariant_QtDShell(int  typeOrUserType0, const void*  copy1);
    QVariant_QtDShell(qint64  ll0);
    QVariant_QtDShell(uint  ui0);
    QVariant_QtDShell(quint64  ull0);
    ~QVariant_QtDShell();

    bool  __public_cmp(const QVariant&  other0) const;
    void __public_create(int  type0, const void*  copy1);
};

#endif // QVARIANT_SHELL_H
