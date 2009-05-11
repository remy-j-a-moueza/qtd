PROJECT(qtd CXX C)
cmake_minimum_required(VERSION 2.6)
FIND_PACKAGE(Qt4 REQUIRED)
# Using Tango

#set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/modules/cmaked)
#set(CMAKE_D_USE_TANGO True)

include_directories(${QT_INCLUDES} include)

IF(CMAKE_HOST_WIN32)
    INCLUDE(${CMAKE_CURRENT_SOURCE_DIR}/cpp/qt_core/local.cmake)
    INCLUDE(${CMAKE_CURRENT_SOURCE_DIR}/cpp/qt_gui/local.cmake)
    INCLUDE(${CMAKE_CURRENT_SOURCE_DIR}/cpp/qt_opengl/local.cmake)
#    INCLUDE(${CMAKE_CURRENT_SOURCE_DIR}/cpp/qt_qtd/local.cmake)
    ADD_LIBRARY(qtd_cpp SHARED ${QT_QTD_SRCS} ${QT_CORE_SRCS} ${QT_GUI_SRCS})
    TARGET_LINK_LIBRARIES( qtd_cpp ${QT_LIBRARIES} )
ELSE(CMAKE_HOST_WIN32)
    ADD_SUBDIRECTORY(cpp/qt_core bin)
    ADD_SUBDIRECTORY(cpp/qt_gui bin)
    ADD_SUBDIRECTORY(cpp/qt_opengl bin)
    ADD_SUBDIRECTORY(cpp/qt_qtd bin)
ENDIF(CMAKE_HOST_WIN32)

#ADD_SUBDIRECTORY(qt bin)

