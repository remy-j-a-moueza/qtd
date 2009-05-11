PROJECT(QT_CORE_CPP CXX)
# source files

SET(QT_QTD_SRCS
qtd_core.cpp
)

ADD_LIBRARY(qt_qtd_cpp STATIC ${QT_QTD_SRCS})
