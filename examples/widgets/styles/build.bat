..\..\..\tools\drcc\drcc styles.qrc > qrc_styles.d
dmd -I..\..\..\ main.d widgetgallery.d norwegianwoodstyle.d qrc_styles.d ..\..\..\lib\libqtdgui.lib ..\..\..\lib\libqtdcore.lib