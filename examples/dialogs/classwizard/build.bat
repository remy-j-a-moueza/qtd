../../../tools/drcc/drcc classwizard.qrc > qrc_classwizard.d
dmd main.d classwizard.d qrc_classwizard.d libqtdcore.lib libqtdgui.lib -I../../../ -I../../../qt/d1 -ofclasswizard