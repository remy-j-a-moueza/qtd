#! /bin/bash
dmd -L-L../../../output/build/lib -I../../../d2 -I../../../output/build simple.d -L-lqtdqwt -L-lqtdgui -L-lqtdcore -L-lcpp_qwt -L-lcpp_core -L-lcpp_gui -L-lqwt-qt4 -L-lQtGui -L-lQtCore -ofsimple
