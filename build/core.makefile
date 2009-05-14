ifeq ($(D_VERSION), 1)
D_PATH = d1/qt
else
D_PATH = d2/qt
endif

##--------------------------
QTD_CORE += QGlobal qtd/Str core/Qt qtd/ArrayOpsPrimitive QtDObject $(D_PATH)/Signal
##--------------------------

## Qt Lib name.
qt_core_name = QtCore

## Libraries linked to the cpp part (is active only when  CPP_SHARED == true).
core_link_cpp += 

## Libraries linked to the d part (is active only when  CPP_SHARED == true)..
core_link_d += 

## Module specific cpp files.
core_cpp_files += cpp/qt_qtd/qtd_core.cpp cpp/qt_qtd/ArrayOpsPrimitive_shell.cpp

## Module specific d files.
core_d_files += $(QTD_CORE:%=qt/%.d)

## Classes.
## TODO: use list that genareted by dgen.
core_classes =  \
	ArrayOps \
	QChildEvent \
	QCoreApplication \
	QEvent \
	QEventLoop \
	QObject \
	QTimerEvent \
	QTranslator \
	QPoint \
    QPointF \
    QRect \
    QRectF \
    QByteArray \
	QLocale \
	QSize \
	QSizeF \
	QDataStream \
    QLine \
    QLineF \
	QMimeData \
	QIODevice \
	QDateTime \
	QDate \
	QTime \
	QVariant \
	QBitArray \
	QRegExp \
	QUrl \
	QModelIndex \
	QAbstractItemModel \
	QAbstractFileEngine \
	QFile \
	QDir \
	QFileInfo \
	QTextStream \
	QString \
	QTimer 