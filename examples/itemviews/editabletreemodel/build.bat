../../../tools/drcc/drcc editabletreemodel.qrc -o qrc_editabletreemodel.d
../../../tools/duic/duic mainwindow.ui -o ui_mainwindow.d
dmd main.d mainwindow.d treeitem.d treemodel.d ui_mainwindow.d qrc_editabletreemodel.d libqtdcore.lib libqtdgui.lib -I../../../