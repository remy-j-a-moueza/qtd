../../../tools/drcc/drcc systray.qrc > qrc_systray.d
dmd main.d window.d qrc_systray.d libqtdcore.lib libqtdgui.lib -I../../../ -I../../../qt/d1 -ofsystray