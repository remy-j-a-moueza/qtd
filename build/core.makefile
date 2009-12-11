ifeq ($(D_VERSION), 1)
D_PATH = d1/qt
else
D_PATH = d2/qt
endif

##--------------------------
QTD_CORE += QGlobal $(D_PATH)/qtd/Str core/Qt qtd/ArrayOpsPrimitive $(D_PATH)/QtdObject $(D_PATH)/Signal \
$(D_PATH)/core/QPoint \
$(D_PATH)/core/QPointF \
$(D_PATH)/core/QRect \
$(D_PATH)/core/QRectF \
$(D_PATH)/core/QSize \
$(D_PATH)/core/QSizeF \
$(D_PATH)/core/QLine \
$(D_PATH)/core/QLineF \
$(D_PATH)/core/QModelIndex \
$(D_PATH)/core/QVariant

##--------------------------

## Qt Lib name.
qt_core_name = QtCore

## Libraries linked to the cpp part (is active only when  CPP_SHARED == true).
core_link_cpp += 

## Libraries linked to the d part (is active only when  CPP_SHARED == true)..
core_link_d += 

## Module specific cpp files.
core_cpp_files += cpp/qt_qtd/qtd_core.cpp cpp/qt_qtd/ArrayOpsPrimitive_shell.cpp \
cpp/qt_core/QPoint_shell.cpp cpp/qt_core/QPointF_shell.cpp cpp/qt_core/QRect_shell.cpp cpp/qt_core/QRectF_shell.cpp \
cpp/qt_core/QSize_shell.cpp cpp/qt_core/QSizeF_shell.cpp cpp/qt_core/QLine_shell.cpp cpp/qt_core/QLineF_shell.cpp \
cpp/qt_core/QModelIndex_shell.cpp cpp/qt_core/QVariant_shell.cpp

## Module specific d files.
core_d_files += $(QTD_CORE:%=qt/%.d) qt/core/ArrayOps2

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
    QByteArray \
    QLocale \
    QDataStream \
    QMimeData \
    QIODevice \
    QDateTime \
    QDate \
    QTime \
    QBitArray \
    QRegExp \
    QUrl \
    QAbstractItemModel \
    QAbstractFileEngine \
    QFile \
    QDir \
    QFileInfo \
    QTextStream \
    QString \
    QTimer \
    QTextCodec \
    QTextCodec_ConverterState \
    QTextEncoder \
    QTextDecoder \
    QTimeLine \
    QAbstractFactory \
    QAbstractListModel \
    QCryptographicHash \
    QProcess \
    QBuffer \
    QMetaType \
    QLibraryInfo \
    QFileSystemWatcher \
    QXmlStreamEntityResolver