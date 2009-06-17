#! /bin/bash

../../tools/drcc/drcc deform.qrc -o qrc_deform.d

ldc main.d pathdeform.d qrc_deform.d ../shared/arthurstyle.d ../shared/arthurwidgets.d -L-L../../lib -L-lqtdgui -L-lqtdcore -I../../ -I../../qt/d1 -L-lQtGui -L-lQtCore -ofbrowser -d-version=QT_NO_UITOOLS
