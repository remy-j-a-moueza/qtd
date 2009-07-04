#! /bin/bash

../../../tools/drcc/drcc systray.qrc > qrc_systray.d
dmd main.d window.d qrc_systray.d -I../../../ -I../../../qt/d1 -L-L../../../lib -L-lqtdgui -L-lqtdcore -L-lQtCore -L-lQtGui -ofsystray
