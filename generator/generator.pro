#contains(QT_CONFIG, release) { 
#    CONFIG -= debug
#    CONFIG += release
#}

# Input
HEADERS += classlistgenerator.h \
    cppgenerator.h \
    cppheadergenerator.h \
    cppimplgenerator.h \
    docparser.h \
    generatorsetd.h \
    dgenerator.h \
    jumptable.h \
    metainfogenerator.h \
    metajavabuilder.h \
    qdocgenerator.h \
    uiconverter.h \
    containergenerator.h
SOURCES += classlistgenerator.cpp \
    cppgenerator.cpp \
    cppheadergenerator.cpp \
    cppimplgenerator.cpp \
    docparser.cpp \
    generatorsetd.cpp \
    dgenerator.cpp \
    jumptable.cpp \
    metainfogenerator.cpp \
    metajavabuilder.cpp \
    qdocgenerator.cpp \
    uiconverter.cpp \
    containergenerator.cpp
include(generator.pri)
