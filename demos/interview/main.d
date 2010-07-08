/****************************************************************************
**
** Copyright (C) 2008 Nokia Corporation and/or its subsidiary(-ies).
** Contact: Qt Software Information (qt-info@nokia.com)
**
** This file is part of the demonstration applications of the Qt Toolkit.
**
** Commercial Usage
** Licensees holding valid Qt Commercial licenses may use this file in
** accordance with the Qt Commercial License Agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and Nokia.
**
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License versions 2.0 or 3.0 as published by the Free
** Software Foundation and appearing in the file LICENSE.GPL included in
** the packaging of this file.  Please review the following information
** to ensure GNU General Public Licensing requirements will be met:
** http://www.fsf.org/licensing/licenses/info/GPLv2.html and
** http://www.gnu.org/copyleft/gpl.html.  In addition, as a special
** exception, Nokia gives you certain additional rights. These rights
** are described in the Nokia Qt GPL Exception version 1.3, included in
** the file GPL_EXCEPTION.txt in this package.
**
** Qt for Windows(R) Licensees
** As a special exception, Nokia, as the sole copyright holder for Qt
** Designer, grants users of the Qt/Eclipse Integration plug-in the
** right for the Qt/Eclipse Integration to link to functionality
** provided by Qt Designer and its related libraries.
**
** If you are unsure which license is appropriate for your use, please
** contact the sales department at qt-sales@nokia.com.
**
****************************************************************************/
import model;

import qt.gui.QApplication;
import qt.gui.QItemSelectionModel;
import qt.gui.QSplitter;
import qt.gui.QTreeView;
import qt.gui.QHeaderView;
import qt.gui.QTableView;
import qt.gui.QTreeView;
import qt.gui.QListView;
import qt.gui.QIcon;
import qt.gui.QPixmap;

int main(string[] args)
{        
    scope app = new QApplication(args);
    
    scope page = new QSplitter;

    scope data = new Model(1000, 10); //parent = page
    scope selections = new QItemSelectionModel(data);

    scope table = new QTableView;
    table.setModel(data);
    table.setSelectionModel(selections);
	table.horizontalHeader.setMovable(true);
	table.verticalHeader.setMovable(true);
    // Set StaticContents to enable minimal repaints on resizes.
    table.viewport.setAttribute(Qt.WA_StaticContents);
    page.addWidget(table);

    scope tree = new QTreeView;
    tree.setModel(data);
    tree.setSelectionModel(selections);
    tree.setUniformRowHeights(true);
    tree.header.setStretchLastSection(false);
    tree.viewport.setAttribute(Qt.WA_StaticContents);
    // Disable the focus rect to get minimal repaints when scrolling on Mac.
    tree.setAttribute(Qt.WA_MacShowFocusRect, false);
    page.addWidget(tree);

    scope list = new QListView;
    list.setModel(data);
    list.setSelectionModel(selections);
    list.setViewMode(QListView.IconMode);
    list.setSelectionMode(QAbstractItemView.ExtendedSelection);
    list.setAlternatingRowColors(false);
    list.viewport.setAttribute(Qt.WA_StaticContents);
    list.setAttribute(Qt.WA_MacShowFocusRect, false);
    page.addWidget(list);

    page.setWindowIcon(new QIcon(new QPixmap(":/images/interview.png")));
    page.setWindowTitle("Interview");
    page.show();

    return app.exec();
}
