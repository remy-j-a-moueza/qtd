PROJECT(QT_CORE_CPP CXX)
# source files

SET(QT_CORE_SRCS
QChildEvent_shell.cpp
QCoreApplication_shell.cpp
QEvent_shell.cpp
QEventLoop_shell.cpp
QObject_shell.cpp
QTimerEvent_shell.cpp
QTranslator_shell.cpp
QRect_shell.cpp
QPoint_shell.cpp
QByteArray_shell.cpp
QLocale_shell.cpp
QSize_shell.cpp
QSizeF_shell.cpp
QDataStream_shell.cpp
QMimeData_shell.cpp
QIODevice_shell.cpp
QPointF_shell.cpp
QRectF_shell.cpp
QDateTime_shell.cpp
QDate_shell.cpp
QTime_shell.cpp
QVariant_shell.cpp
QBitArray_shell.cpp
QRegExp_shell.cpp
QUrl_shell.cpp
QModelIndex_shell.cpp
QAbstractItemModel_shell.cpp
QAbstractFileEngine_shell.cpp
QFile_shell.cpp
QDir_shell.cpp
QFileInfo_shell.cpp
QTextStream_shell.cpp
QString_shell.cpp
QTimer_shell.cpp
)

ADD_LIBRARY(qt_core_cpp STATIC ${QT_CORE_SRCS})
