/****************************************************************************
**
** Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies).
** Contact: Qt Software Information (qt-info@nokia.com)
**
** This file is part of the demonstration applications of the Qt Toolkit.
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
module modelmenu;


import qt.gui.QMenu;
import qt.core.QAbstractItemModel;

import qt.core.QPersistentModelIndex;
//import qdebug;


// A QMenu that is dynamically populated from a QAbstractItemModel
class ModelMenu : public QMenu
{

mixin Signal!("activated", QModelIndex /*index*/);
mixin Signal!("linkHovered", string /*text*/);

public:

	this(QWidget parent = null)
	{
		super(parent);
		m_maxRows = 7;
		m_firstSeparator = -1;
		m_maxWidth = -1;
		m_hoverRole = 0;
		m_separatorRole = 0;
		m_model = 0;
		this.aboutToShow.connect(&this.aboutToShow);
	}

	void setModel(QAbstractItemModel model)
	{
		m_model = model;
	}

	QAbstractItemModel model()
	{
		return m_model;
	}

	void setMaxRows(int max)
	{
		m_maxRows = max;
	}

	int maxRows()
	{
		return m_maxRows;
	}

	void setFirstSeparator(int offset)
	{
		m_firstSeparator = offset;
	}	

	int firstSeparator()
	{
		return m_firstSeparator;
	}

	void setRootIndex(QModelIndex index)
	{
		m_root = index;
	}
	
	QModelIndex rootIndex()
	{
		return m_root;
	}

	void setHoverRole(int role)
	{
		m_hoverRole = role;
	}
	
	int hoverRole()
	{
		return m_hoverRole;
	}

	void setSeparatorRole(int role)
	{
		m_separatorRole = role;
	}

	int separatorRole()
	{
		return m_separatorRole;
	}

	QAction makeAction(QIcon icon, string text, QObject parent)
	{
		auto fm = new QFontMetrics(font());
		if (-1 == m_maxWidth)
			m_maxWidth = fm.width(QLatin1Char('m')) * 30;
		string smallText = fm.elidedText(text, Qt.ElideMiddle, m_maxWidth);
		return new QAction(icon, smallText, parent);
	}

protected:

	// add any actions before the tree, return true if any actions are added.
	bool prePopulated()
	{
		return false;
	}
	
	// add any actions after the tree
	void postPopulated()
	{
	}

	// put all of the children of parent into menu up to max
	void createMenu(QModelIndex parent, int max, QMenu parentMenu = null, QMenu menu = null)
	{
		if (!menu) {
			string title = parent.data().toString();
			menu = new QMenu(title, this);
			QIcon icon = cast(QIcon) parent.data(Qt.DecorationRole);
			menu.setIcon(icon);
			parentMenu.addMenu(menu);
			auto v = new QVariant;
			v.setValue(parent);
			menu.menuAction().setData(v);
			menu.aboutToShow.connect(&this.aboutToShow);
			return;
		}

		int end = m_model.rowCount(parent);
		if (max != -1)
			end = qMin(max, end);

		menu.triggered.connect(&this.triggered);
		menu.linkHovered.connect(&this.linkHovered);

		for (int i = 0; i < end; ++i) {
			QModelIndex idx = m_model.index(i, 0, parent);
			if (m_model.hasChildren(idx)) {
				createMenu(idx, -1, menu);
			} else {
				if (m_separatorRole != 0 && idx.data(m_separatorRole).toBool())
					addSeparator();
				else
					menu.addAction(makeAction(idx));
			}
			if (menu == this && i == m_firstSeparator - 1)
				addSeparator();
		}
	}

private:

	void aboutToShow()
	{
		if (QMenu menu = cast(QMenu) signalSender()) {
			QVariant v = menu.menuAction().data();
			if (v.canConvert!(QModelIndex)()) {
				QModelIndex idx = cast(QModelIndex) v;
				createMenu(idx, -1, menu, menu);
				menu.aboutToShow.disconnect(&this.aboutToShow);
				return;
			}
		}

		clear();
		if (prePopulated())
			addSeparator();
		int max = m_maxRows;
		if (max != -1)
			max += m_firstSeparator;
		createMenu(m_root, max, this, this);
		postPopulated();
	}

	void triggered(QAction action)
	{
		QVariant v = action.data();
		if (v.canConvert!(QModelIndex)()) {
			QModelIndex idx = cast(QModelIndex) v;
			activated.emit(idx);
		}
	}

	void linkHovered(QAction action)
	{
		QVariant v = action.data();
		if (v.canConvert!(QModelIndex)()) {
			QModelIndex idx = cast(QModelIndex) v;
			string hoveredString = idx.data(m_hoverRole).toString();
			if (!hoveredString.isEmpty())
				linkHovered.emit(hoveredString);
		}
	}

private:

	QAction makeAction(QModelIndex index)
	{
		QIcon icon = cast(QIcon) index.data(Qt.DecorationRole);
		QAction action = makeAction(icon, index.data().toString(), this);
		auto v = new QVariant;
		v.setValue(index);
		action.setData(v);
		return action;
	}

	int m_maxRows;
	int m_firstSeparator;
	int m_maxWidth;
	int m_hoverRole;
	int m_separatorRole;
	QAbstractItemModel m_model;
	QPersistentModelIndex m_root;
}
