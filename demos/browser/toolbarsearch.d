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
module toolbarsearch;


import qt.core.QSettings;
import qt.core.QUrl;

import qt.gui.QCompleter;
import qt.gui.QMenu;
import qt.gui.QStringListModel;

import qt.webkit.QWebSettings;

import searchlineedit;
import autosaver;


class ToolbarSearch : public SearchLineEdit
{
	mixin Signal!("search", QUrl /*url*/);

public:

	/*
	ToolbarSearch is a very basic search widget that also contains a small history.
	Searches are turned into urls that use Google to perform search
	*/
	this(QWidget parent = null)
	{
		super(parent);
		m_autosaver = new AutoSaver(this);
		m_maxSavedSearches = 10;
		m_stringListModel = new QStringListModel(this);

		QMenu m = menu();
		m.aboutToShow().connect(&this.aboutToShowMenu);
		m.triggered.connect(&this.triggeredMenuAction);

		QCompleter completer = new QCompleter(m_stringListModel, this);
		completer.setCompletionMode(QCompleter.InlineCompletion);
		lineEdit().setCompleter(completer);

		lineEdit().returnPressed.connect(&searchNow);
		setInactiveText(tr("Google"));
		load();
	}
	
	~this()
	{
		m_autosaver.saveIfNeccessary();
	}

public:

	void clear()
	{
		m_stringListModel.setStringList(string[]());
		m_autosaver.changeOccurred();
	}

	void searchNow()
	{
		string searchText = lineEdit().text();
		string[] newList = m_stringListModel.stringList();
		if (newList.contains(searchText))
			newList.removeAt(newList.indexOf(searchText));
		newList.prepend(searchText);
		if (newList.size() >= m_maxSavedSearches)
			newList.removeLast();

		QWebSettings globalSettings = QWebSettings.globalSettings();
		if (!globalSettings.testAttribute(QWebSettings.PrivateBrowsingEnabled)) {
			m_stringListModel.setStringList(newList);
			m_autosaver.changeOccurred();
		}

		auto url = new QUrl("http://www.google.com/search");
		url.addQueryItem("q", searchText);
		url.addQueryItem("ie", "UTF-8");
		url.addQueryItem("oe", "UTF-8");
		url.addQueryItem("client", "qtdemobrowser");
		search.emit(url);
	}

private:

	void save()
	{
		QSettings settings;
		settings.beginGroup("toolbarsearch");
		settings.setValue("recentSearches", m_stringListModel.stringList());
		settings.setValue("maximumSaved", m_maxSavedSearches);
		settings.endGroup();
	}


	void aboutToShowMenu()
	{
		lineEdit().selectAll();
		QMenu m = menu();
		m.clear();
		string[] list = m_stringListModel.stringList();
		if (list.isEmpty()) {
			m.addAction(tr("No Recent Searches"));
			return;
		}

		QAction recent = m.addAction(tr("Recent Searches"));
		recent.setEnabled(false);
		for (int i = 0; i < list.length; ++i) {
			string text = list[i];
			m.addAction(text).setData(text);
		}
		m.addSeparator();
		m.addAction(tr("Clear Recent Searches"), this, SLOT(clear()));
	}

	void triggeredMenuAction(QAction action)
	{
		QVariant v = action.data();
		if (v.canConvert!(string)) {
			string text = v.toString();
			lineEdit().setText(text);
			searchNow();
		}
	}

private:

	void load()
	{
		QSettings settings;
		settings.beginGroup("toolbarsearch");
		string[] list = settings.value("recentSearches").toStringList();
		m_maxSavedSearches = settings.value("maximumSaved", m_maxSavedSearches).toInt();
		m_stringListModel.setStringList(list);
		settings.endGroup();
	}

	AutoSaver m_autosaver;
	int m_maxSavedSearches;
	QStringListModel m_stringListModel;
}
