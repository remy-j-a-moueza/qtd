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
module treemodel;


import qt.core.QAbstractItemModel;
import qt.core.QModelIndex;
import qt.core.QVariant;

import treeitem;

import tango.core.Array : find;
import tango.text.Util : trim;


//replacement for QString.split
T[][] split(T)(T[] str, T[] match, bool keep_empty = true)
{
	uint pos, start = 0;
	
	T[][] values;
	if(str.length == 0)
		return values;
	
	while(true)
	{
		pos = start + find(str[start..$], match);
		if(keep_empty)
		{
			if((pos - start) >= 0)
				values ~= str[start..pos];
		}
		else
		{
			if((pos - start) != 0)
				values ~= str[start..pos];
		}
		
		if(pos == str.length)
			break;
		
		start = pos + 1;
	}
	
	return values;	
}


class TreeModel : public QAbstractItemModel
{
public:

	this(string[] headers, string data, QObject parent = null)
	{
		super(parent);
		QVariant[] rootData;
		foreach(string header; headers)
			rootData ~= new QVariant(header);

		rootItem = new TreeItem(rootData);
		setupModelData(split(data, "\n"), rootItem);
	}

	~this()
	{
		delete rootItem;
	}

	QVariant data(QModelIndex index, int role)
	{
		if (!index.isValid())
			return new QVariant();

		if (role != Qt.DisplayRole && role != Qt.EditRole)
			return new QVariant();

		TreeItem item = getItem(index);
		return item.data(index.column());
	}

	QVariant headerData(int section, Qt.Orientation orientation, int role = Qt.DisplayRole)
	{
		if (orientation == Qt.Horizontal && role == Qt.DisplayRole)
			return rootItem.data(section);

		return new QVariant();
	}

	QModelIndex index(int row, int column, QModelIndex parent = QModelIndex())
	{
		if (parent.isValid() && parent.column() != 0)
			return QModelIndex();

		TreeItem parentItem = getItem(parent);

		TreeItem childItem = parentItem.child(row);
		if (childItem)
			return createIndex(row, column, cast(void*) childItem);
		else
			return QModelIndex();
	}

	QModelIndex parent(QModelIndex index)
	{
		if (!index.isValid())
			return QModelIndex();

		TreeItem childItem = getItem(index);
		TreeItem parentItem = childItem.parent();

		if (parentItem == rootItem)
			return QModelIndex();

		return createIndex(parentItem.childNumber(), 0, cast(void*) parentItem);
	}

	int rowCount(QModelIndex parent = QModelIndex())
	{
		TreeItem parentItem = getItem(parent);
		return parentItem.childCount();
	}
	
	int columnCount(QModelIndex parent = QModelIndex())
	{
		return rootItem.columnCount();
	}

	int flags(QModelIndex index)
	{
		if (!index.isValid())
			return 0;

		return Qt.ItemIsEditable | Qt.ItemIsEnabled | Qt.ItemIsSelectable;
	}


	bool setData(QModelIndex index, QVariant value, int role = Qt.EditRole)
	{
		if (role != Qt.EditRole)
			return false;

		TreeItem item = getItem(index);
		bool result = item.setData(index.column(), value);

		if (result)
			dataChanged.emit(index, index);

		return result;
	}

	bool setHeaderData(int section, Qt.Orientation orientation, QVariant value, int role = Qt.EditRole)
	{
		if (role != Qt.EditRole || orientation != Qt.Horizontal)
			return false;

		bool result = rootItem.setData(section, value);

		if (result)
			headerDataChanged.emit(orientation, section, section);

		return result;
	}

	bool insertColumns(int position, int columns, QModelIndex parent = QModelIndex())
	{
		bool success;

		beginInsertColumns(parent, position, position + columns - 1);
		success = rootItem.insertColumns(position, columns);
		endInsertColumns();

		return success;
	}


	bool removeColumns(int position, int columns, QModelIndex parent = QModelIndex())
	{
		bool success;

		beginRemoveColumns(parent, position, position + columns - 1);
		success = rootItem.removeColumns(position, columns);
		endRemoveColumns();

		if (rootItem.columnCount() == 0)
			removeRows(0, rowCount());

		return success;
	}


	bool insertRows(int position, int rows, QModelIndex parent = QModelIndex())
	{
		TreeItem parentItem = getItem(parent);
		bool success;

		beginInsertRows(parent, position, position + rows - 1);
		success = parentItem.insertChildren(position, rows, rootItem.columnCount());
		endInsertRows();

		return success;
	}

	bool removeRows(int position, int rows, QModelIndex parent = QModelIndex())
	{
		TreeItem parentItem = getItem(parent);
		bool success = true;

		beginRemoveRows(parent, position, position + rows - 1);
		success = parentItem.removeChildren(position, rows);
		endRemoveRows();

		return success;
	}

private:

	void setupModelData(string[] lines, TreeItem parent)
	{
		TreeItem[] parents;
		int[] indentations;
		parents ~= parent;
		indentations ~= 0;

		int number = 0;

		while (number < lines.length) {
			int position = 0;
			while (position < lines[number].length) {
				if (lines[number][position] != ' ')
					break;
				position++;
			}

			string lineData = trim(lines[number][position..$]);

			if (lineData.length) {
				// Read the column data from the rest of the line.
				string[] columnStrings = split(lineData, "\t", false);
				QVariant[] columnData;
				for (int column = 0; column < columnStrings.length; ++column)
					columnData ~= new QVariant(columnStrings[column]);

				if (position > indentations[$-1]) {
					// The last child of the current parent is now the new parent
					// unless the current parent has no children.

					if (parents[$-1].childCount() > 0) {
						parents ~= parents[$-1].child(parents[$-1].childCount()-1);
						indentations ~= position;
					}
				} else {
					while (position < indentations[$-1] && parents.length > 0) {
						parents = parents[0..$-1];
						indentations = indentations[0..$-1];
					}
				}

				// Append a new item to the current parent's list of children.
				parent = parents[$-1];
				parent.insertChildren(parent.childCount(), 1, rootItem.columnCount());
				for (int column = 0; column < columnData.length; ++column)
					parent.child(parent.childCount() - 1).setData(column, columnData[column]);
			}

			number++;
		}
	}

	TreeItem getItem(QModelIndex index)
	{
		if (index.isValid()) {
			TreeItem item = cast(TreeItem) index.internalPointer();
			if (item) return item;
		}
		return rootItem;
	}

	TreeItem rootItem;
}
