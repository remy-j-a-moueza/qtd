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
module treeitem;


import qt.core.QVariant;

import tango.core.Array;


//substitute for QList methods
void insert(T)(ref T[] items, int pos, T item)
{
	items = items[0..pos] ~ [item] ~ items[pos..$];
}

T takeAt(T)(ref T[] items, int pos)
{
	T item = items[pos];
	items = items[0..pos] ~ items[pos+1..$];
	return item;
}

int indexOf(T)(T[] items, T item, int from = -1)
{
	assert(from < cast(int) items.length);
	auto beg = (from < 0) ? 0 : from;
	auto pos = beg + find(items[beg..$], item);
	return (pos == items.length) ? -1 : pos;
}

void remove(T)(ref T[] items, uint pos)
{
	items = items[0..pos] ~ items[pos+1..$];
}


class TreeItem
{
public:

	this(QVariant[] data, TreeItem parent = null)
	{
		parentItem = parent;
		itemData = data;
	}
	
	~this()
	{
		delete childItems;
	}

	TreeItem child(int number)
	{
		if(number < 0 || number >= childItems.length)
			return null;
		return childItems[number];
	}

	int childCount()
	{
		return childItems.length;
	}

	int columnCount()
	{
		return itemData.length;
	}

	QVariant data(int column)
	{
		if(column < 0 || column >= itemData.length)
			return null;
		return itemData[column];
	}

	bool insertChildren(int position, int count, int columns)
	{
		if (position < 0 || position > childItems.length)
			return false;

		for (int row = 0; row < count; ++row) {
			auto data = new QVariant[](columns);
			TreeItem item = new TreeItem(data, this);
			insert(childItems, position, item);
		}

		return true;
	}

	bool insertColumns(int position, int columns)
	{
		if (position < 0 || position > itemData.length)
			return false;

		for (int column = 0; column < columns; ++column)
			insert(itemData, position, new QVariant());

		foreach (TreeItem child; childItems)
			child.insertColumns(position, columns);

		return true;
	}

	TreeItem parent()
	{
		return parentItem;
	}

	bool removeChildren(int position, int count)
	{
		if (position < 0 || position + count > childItems.length)
			return false;

		for (int row = 0; row < count; ++row)
		{
			auto tmp = takeAt(childItems, position);
			delete tmp;
		}
		return true;
	}

	bool removeColumns(int position, int columns)
	{
		if (position < 0 || position + columns > itemData.length)
			return false;

		for (int column = 0; column < columns; ++column)
			remove(itemData, position);

		foreach (TreeItem child; childItems)
			child.removeColumns(position, columns);

		return true;
	}

	int childNumber()
	{
		if (parentItem)
			return indexOf(parentItem.childItems, cast(TreeItem) this);

		return 0;
	}

	bool setData(int column, QVariant value)
	{
		if (column < 0 || column >= itemData.length)
			return false;

		itemData[column] = value;
		return true;
	}

private:

	TreeItem[] childItems;
	QVariant[] itemData;
	TreeItem parentItem;
}
