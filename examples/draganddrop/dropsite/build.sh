#! /bin/bash

dmd main.d droparea.d dropsitewindow.d -I../../../ -I../../../qt/d1 -L-L../../../lib -L-lqtdgui -L-lqtdcore -L-lQtCore -L-lQtGui -ofdropsite
