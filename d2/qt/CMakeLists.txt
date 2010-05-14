project (qt_d D)

set(QT_SRCS_D
QtdObject.d
QGlobal.d

core/QChildEvent.d
core/QCoreApplication.d
core/QEvent.d
core/QEventLoop.d
core/QObject.d
core/QTimerEvent.d
core/QTranslator.d
core/Qt.d

qtd/Str.d
)

#add_subdirectory(core)
#add_subdirectory(qtd)

#add_library(qt_d STATIC ${QT_CORE_SRCS_D} ${QT_QTD_SRCS_D} ${QT_SRCS_D})
add_library(qt_d STATIC ${QT_SRCS_D})
