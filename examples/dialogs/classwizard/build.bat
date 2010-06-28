../../../tools/drcc/drcc classwizard.qrc > qrc_classwizard.d
dmd -c -O -release -inline -unittest -version=QtdUnittest main.d qrc_classwizard.d classwizard.d ../../../output/build/lib/qtdcore.lib ../../../output/build/lib/qtdgui.lib -I../../../ -I../../../d2 -I../../../output/build/ -ofclasswizard.obj
dmd -O -release -inline -unittest -version=QtdUnittest classwizard.obj ../../../output/build/lib/qtdcore.lib ../../../output/build/lib/qtdgui.lib -I../../../ -I../../../d2 -I../../../output/build/ -ofclasswizard.exe
