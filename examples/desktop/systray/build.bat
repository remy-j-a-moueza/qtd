../../../tools/drcc/drcc systray.qrc > resources.d
dmd main.d window.d resources.d libqtdcore.lib libqtdgui.lib -I../../../ -I../../../qt/d1 -ofsystray