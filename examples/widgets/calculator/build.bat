set LIB=..\..\..\lib
dmd -I..\..\..\ main.d button.d calculator.d %LIB%\libqtdgui.lib %LIB%\libqtdcore.lib
