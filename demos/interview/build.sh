#! /bin/bash

drcc -name interview interview.qrc -o qrc_interview.d
dmd main.d model_d2.d qrc_interview.d -L-L../../lib -L-lqtdgui -L-lqtdcore -I../../ -I../../qt/d2 -L-lQtGui -L-lQtCore -ofinterview
