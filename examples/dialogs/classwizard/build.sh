#! /bin/bash

../../../tools/drcc/drcc classwizard.qrc > qrc_classwizard.d
dmd main.d classwizard.d qrc_classwizard.d -I../../../ -I../../../qt/d1 -L-L../../../lib -L-lqtdgui -L-lqtdcore -L-lQtCore -L-lQtGui -ofclasswizard
