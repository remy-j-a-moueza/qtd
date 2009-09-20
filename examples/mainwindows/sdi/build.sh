#! /bin/bash
drcc -name sdi sdi.qrc -o qrc_sdi.d
dmd main.d mainwindow.d qrc_sdi.d -I../../../ -I../../../qt/d1 -L-L../../../lib -L-lqtdgui -L-lqtdcore -L-lQtCore -L-lQtGui -ofsdi
