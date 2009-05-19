TEMPLATE = app
TARGET = drcc

DEFINES += QT_RCC
INCLUDEPATH += .
DEPENDPATH += .

CONFIG += qt
QT -= gui
QT += xml

HEADERS += qcorecmdlineargs_p.h rcc.h
SOURCES += main.cpp rcc.cpp

target.path=$$[QT_INSTALL_BINS]
INSTALLS += target
