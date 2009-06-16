#! /bin/bash

../../../tools/drcc/drcc styles.qrc > qrc_styles.d
dmd main.d widgetgallery.d norwegianwoodstyle.d qrc_styles.d -I../../../ -I../../../qt/d1 -L-L../../../lib -L-lqtdgui -L-lqtdcore -L-lQtCore -L-lQtGui -ofstyles
