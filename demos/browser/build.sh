#! /bin/bash

../../tools/duic/duic bookmarksdialog.ui -o ui_bookmarksdialog.d
../../tools/duic/duic addbookmarkdialog.ui -o ui_addbookmarkdialog.d
../../tools/duic/duic cookiesexceptionsdialog.ui -o ui_cookiesexceptionsdialog.d
../../tools/duic/duic cookiesdialog.ui -o ui_cookiesdialog.d
../../tools/duic/duic downloaditem.ui -o ui_downloaditem.d
../../tools/duic/duic downloaddialog.ui -o ui_downloaddialog.d
../../tools/duic/duic historydialog.ui -o ui_historydialog.d
../../tools/duic/duic passworddialog.ui -o ui_passworddialog.d
../../tools/duic/duic proxydialog.ui -o ui_proxydialog.d
../../tools/duic/duic settings.ui -o ui_settings.d

ldc *.d -L-L../../lib -L-lqtdgui -L-lqtdcore -I../../ -I../../qt/d1 -L-lQtGui -L-lQtCore -ofbrowser -d-version=QT_NO_UITOOLS
