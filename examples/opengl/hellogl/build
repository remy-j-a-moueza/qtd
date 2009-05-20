#! /bin/bash
#rcc mainwindow.qrc -o mainwindow_rcc.cpp
#g++ -c -I/usr/share/qt4/mkspecs/linux-g++ -I. -I/usr/include/qt4/QtCore -I/usr/include/qt4/QtGui -I/usr/include/qt4 -I/usr/X11R6/include mainwindow_rcc.cpp
dmd main.d window.d glwidget.d opengl/gl.d opengl/glu.d -L-L../../../lib -I../../../ -I../../../qt/d1 -L-lqtdgui -L-lqtdcore -L-lqtdopengl -L-lQtGui -L-lQtCore -L-lQtOpenGL -L-lGLU -ofhellogl
