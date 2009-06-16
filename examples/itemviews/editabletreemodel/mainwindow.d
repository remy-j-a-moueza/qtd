/****************************************************************************
**
** Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies).
** Contact: Qt Software Information (qt-info@nokia.com)
**
** This file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:LGPL$
** Commercial Usage
** Licensees holding valid Qt Commercial licenses may use this file in
** accordance with the Qt Commercial License Agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and Nokia.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 2.1 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPL included in the
** packaging of this file.  Please review the following information to
** ensure the GNU Lesser General Public License version 2.1 requirements
** will be met: http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
**
** In addition, as a special exception, Nokia gives you certain
** additional rights. These rights are described in the Nokia Qt LGPL
** Exception version 1.0, included in the file LGPL_EXCEPTION.txt in this
** package.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3.0 as published by the Free Software
** Foundation and appearing in the file LICENSE.GPL included in the
** packaging of this file.  Please review the following information to
** ensure the GNU General Public License version 3.0 requirements will be
** met: http://www.gnu.org/copyleft/gpl.html.
**
** If you are unsure which license is appropriate for your use, please
** contact the sales department at qt-sales@nokia.com.
** $QT_END_LICENSE$
**
****************************************************************************/
module mainwindow;


import qt.core.QModelIndex;
import qt.core.QFile;
import qt.gui.QMainWindow;
import qt.gui.QAction;
import qt.gui.QTreeView;
import qt.gui.QWidget;

import tango.text.convert.Format;

import ui_mainwindow;
import mainwindow;
import treemodel;


class MainWindow : public QMainWindow
{

mixin Ui_MainWindow;

public:

	this(QWidget parent = null)
	{
		super(parent);
		setupUi(this);

		string[] headers;
		headers ~= tr("Title");
		headers ~= tr("Description");

		auto file = new QFile(":/default.txt");
		file.open(QIODevice.ReadOnly);
		TreeModel model = new TreeModel(headers, file.readAll().data()[0..file.size()]);
		file.close();

		view.setModel(model);
		for (int column = 0; column < model.columnCount(); ++column)
			view.resizeColumnToContents(column);

		exitAction.triggered.connect(&QApplication.quit);

		view.selectionModel().selectionChanged.connect(&this.updateActions);

		actionsMenu.aboutToShow.connect(&this.updateActions);
		insertRowAction.triggered.connect(&this.insertRow);
		insertColumnAction.triggered.connect(&this.insertColumn);
		removeRowAction.triggered.connect(&this.removeRow);
		removeColumnAction.triggered.connect(&this.removeColumn);
		insertChildAction.triggered.connect(&this.insertChild);

		updateActions();
	}

public:

	void updateActions()
	{
		bool hasSelection = !view.selectionModel().selection().isEmpty();
		removeRowAction.setEnabled(hasSelection);
		removeColumnAction.setEnabled(hasSelection);

		bool hasCurrent = view.selectionModel().currentIndex().isValid();
		insertRowAction.setEnabled(hasCurrent);
		insertColumnAction.setEnabled(hasCurrent);

		if (hasCurrent) {
			view.closePersistentEditor(view.selectionModel().currentIndex());

			int row = view.selectionModel().currentIndex().row();
			int column = view.selectionModel().currentIndex().column();
			if (view.selectionModel().currentIndex().parent().isValid())
				statusBar().showMessage(Format(tr("Position: ({},{})"), row, column));
			else
				statusBar().showMessage(Format(tr("Position: ({},{}) in top level"), row, column));
		}
	}

private:

	void insertChild()
	{
		QModelIndex index = view.selectionModel().currentIndex();
		QAbstractItemModel model = view.model();

		if (model.columnCount(index) == 0) {
			if (!model.insertColumn(0, index))
				return;
		}

		if (!model.insertRow(0, index))
			return;

		for (int column = 0; column < model.columnCount(index); ++column) {
			QModelIndex child = model.index(0, column, index);
			model.setData(child, QVariant("[No data]"), Qt.EditRole);
			if (!model.headerData(column, Qt.Horizontal).isValid())
				model.setHeaderData(column, Qt.Horizontal, QVariant("[No header]"), Qt.EditRole);
		}

		view.selectionModel().setCurrentIndex(model.index(0, 0, index), QItemSelectionModel.ClearAndSelect);
		updateActions();
	}

	bool insertColumn()
	{
		QModelIndex parent = QModelIndex(); //moved from method head
		QAbstractItemModel model = view.model();
		int column = view.selectionModel().currentIndex().column();

		// Insert a column in the parent item.
		bool changed = model.insertColumn(column + 1, parent);
		if (changed)
			model.setHeaderData(column + 1, Qt.Horizontal, QVariant("[No header]"), Qt.EditRole);

		updateActions();

		return changed;
	}

	void insertRow()
	{
		QModelIndex index = view.selectionModel().currentIndex();
		QAbstractItemModel model = view.model();

		if (!model.insertRow(index.row()+1, index.parent()))
			return;

		updateActions();

		for (int column = 0; column < model.columnCount(index.parent()); ++column) {
			QModelIndex child = model.index(index.row()+1, column, index.parent());
			model.setData(child, QVariant("[No data]"), Qt.EditRole);
		}
	}

	bool removeColumn()
	{
		QModelIndex parent = QModelIndex(); //moved from method head
		QAbstractItemModel model = view.model();
		int column = view.selectionModel().currentIndex().column();

		// Insert columns in each child of the parent item.
		bool changed = model.removeColumn(column, parent);

		if (!parent.isValid() && changed)
			updateActions();

		return changed;
	}

	void removeRow()
	{
		QModelIndex index = view.selectionModel().currentIndex();
		QAbstractItemModel model = view.model();
		if (model.removeRow(index.row(), index.parent()))
			updateActions();
	}

}
