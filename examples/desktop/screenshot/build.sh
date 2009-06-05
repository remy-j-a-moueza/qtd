#! /bin/bash

ldc main.d screenshot.d -I../../../ -I../../../qt/d1 -L-L../../../lib -L-lqtdgui -L-lqtdcore -L-lQtCore -L-lQtGui -ofscreenshot
