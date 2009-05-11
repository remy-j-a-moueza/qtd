PROJECT(QT_OPENGL_CPP CXX)
# source files

SET(QT_OPENGL_SRCS
QGLWidget_shell.cpp
QGLFormat_shell.cpp
QGLContext_shell.cpp
QGLColormap_shell.cpp
)

ADD_LIBRARY(qt_opengl_cpp STATIC ${QT_OPENGL_SRCS})
