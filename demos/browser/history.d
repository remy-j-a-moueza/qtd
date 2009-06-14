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

module history;


import qt.gui.QClipboard;
import qt.gui.QDesktopServices;
import qt.gui.QHeaderView;
import qt.gui.QStyle;
import qt.gui.QSortFilterProxyModel;
import qt.gui.QAbstractTableModel;
//import qt.core.QtAlgorithms;
import qt.core.QBuffer;
import qt.core.QDir;
import qt.core.QFile;
import qt.core.QFileInfo;
import qt.core.QSettings;
import qt.core.QTemporaryFile;
import qt.core.QTextStream;
//import qt.core.QDebug;
import qt.core.QDateTime;
//import qt.core.QHash;
import qt.core.QObject;
import qt.core.QTimer;
import qt.core.QUrl;
import qt.webkit.QWebHistoryInterface;
import qt.webkit.QWebSettings;
//import QWebHistoryInterface;

import tango.text.convert.Format;

import autosaver;
import browserapplication;
import modelmenu;


static const uint HISTORY_VERSION = 23;


class HistoryItem
{
public:

	this() {}

	this(string u, QDateTime d = null, string t = null)
	{
		title = t;
		url = u;
		dateTime = d ? d : new QDateTime();
	}

	//bool operator==(HistoryItem &other)
	int opEquals(HistoryItem other)
        {
		return cast(int) (other.title == title && other.url == url && other.dateTime == dateTime);
	}

	// history is sorted in reverse
	//bool operator <(HistoryItem &other)
	int opCmp(HistoryItem other)
        {
		return cast(int) (dateTime > other.dateTime);
	}

	string title;
	string url;
	QDateTime dateTime;
}


class HistoryManager : public QWebHistoryInterface
{
	mixin Signal!("historyReset");
	mixin Signal!("entryAdded", HistoryItem /*item*/);
	mixin Signal!("entryRemoved", HistoryItem /*item*/);
	mixin Signal!("entryUpdated", int /*offset*/);

public:

	this(QObject parent = null)
	{
		super(parent);
		m_saveTimer = new AutoSaver(this);
		m_historyLimit = 30;
		m_historyModel = 0;
		m_historyFilterModel = 0;
		m_historyTreeModel = 0;

		m_expiredTimer.setSingleShot(true);
		
		m_expiredTimer.timeout.connect(&this.checkForExpired);
		this.entryAdded.connect(&m_saveTimer.changeOccurred);
		this.entryRemoved.connect(&m_saveTimer.changeOccurred);
		
		load();

		m_historyModel = new HistoryModel(this, this);
		m_historyFilterModel = new HistoryFilterModel(m_historyModel, this);
		m_historyTreeModel = new HistoryTreeModel(m_historyFilterModel, this);

		// QWebHistoryInterface will delete the history manager
		QWebHistoryInterface.setDefaultInterface(this);
	}

	~this()
	{
		m_saveTimer.saveIfNeccessary();
	}

	bool historyContains(string url)
	{
		return m_historyFilterModel.historyContains(url);
	}

	void addHistoryEntry(string url)
	{
		QUrl cleanUrl(url);
		cleanUrl.setPassword(null);
		cleanUrl.setHost(toLower(cleanUrl.host()));
		auto item = new HistoryItem(cleanUrl.toString(), QDateTime.currentDateTime());
		addHistoryItem(item);
	}

	void updateHistoryItem(QUrl url, string title)
	{
		for (int i = 0; i < m_history.length; ++i) {
			if (url == m_history[i].url) {
				m_history[i].title = title;
				m_saveTimer.changeOccurred();
				if (m_lastSavedUrl.isEmpty())
				m_lastSavedUrl = m_history[i].url;
				entryUpdated.emit(i);
				break;
			}
		}
	}

	int historyLimit()
	{
		return m_historyLimit;
	}

	void setHistoryLimit(int limit)
	{
		if (m_historyLimit == limit)
			return;
		m_historyLimit = limit;
		checkForExpired();
		m_saveTimer.changeOccurred();
	}

	HistoryItem[] history()
	{
		return m_history;
	}

	void setHistory(HistoryItem[] history, bool loadedAndSorted = false)
	{
		m_history = history;

		// verify that it is sorted by date
		if (!loadedAndSorted)
			qSort(m_history.begin(), m_history.end());

		checkForExpired();

		if (loadedAndSorted) {
			m_lastSavedUrl = m_history.value(0).url;
		} else {
			m_lastSavedUrl = null;
			m_saveTimer.changeOccurred();
		}
		historyReset.emit();
	}

	// History manager keeps around these models for use by the completer and other classes
	HistoryModel historyModel()
	{
		return m_historyModel;
	}

	HistoryFilterModel historyFilterModel()
	{
		return m_historyFilterModel;
	}

	HistoryTreeModel historyTreeModel()
	{
		return m_historyTreeModel;
	}

public:

	void clear()
	{
		m_history = null;
		m_lastSavedUrl = null;
		m_saveTimer.changeOccurred();
		m_saveTimer.saveIfNeccessary();
		historyReset();
	}

	void loadSettings()
	{
		// load settings
		QSettings settings;
		settings.beginGroup("history");
		m_historyLimit = settings.value("historyLimit", 30).toInt();
	}

private:
	
	void save()
	{
		QSettings settings;
		settings.beginGroup("history");
		settings.setValue("historyLimit", m_historyLimit);

		bool saveAll = m_lastSavedUrl.isEmpty();
		int first = m_history.length - 1;
		if (!saveAll) {
			// find the first one to save
			for (int i = 0; i < m_history.length; ++i) {
				if (m_history[i].url == m_lastSavedUrl) {
					first = i - 1;
					break;
				}
			}
		}
		
		if (first == m_history.length - 1)
			saveAll = true;

		string directory = QDesktopServices.storageLocation(QDesktopServices.DataLocation);
		if (directory.isEmpty())
			directory = QDir.homePath() ~ "/." ~ QCoreApplication.applicationName();
		if (!QFile.exists(directory)) {
			QDir dir;
			dir.mkpath(directory);
		}

		auto historyFile = new QFile(directory ~ "/history");
		// When saving everything use a temporary file to prevent possible data loss.
		auto tempFile = new QTemporaryFile;
		tempFile.setAutoRemove(false);
		bool open = false;
		if (saveAll) {
			open = tempFile.open();
		} else {
			open = historyFile.open(QFile.Append);
		}

		if (!open) {
			qWarning("Unable to open history file for saving" ~ (saveAll ? tempFile.fileName() : historyFile.fileName()));
			return;
		}

		QDataStream out_ = (saveAll ? tempFile : historyFile);
		for (int i = first; i >= 0; --i) {
			QByteArray data;
			auto stream = new QDataStream(data, QIODevice.WriteOnly);
			HistoryItem item = m_history[i];
			stream << HISTORY_VERSION << item.url << item.dateTime << item.title;
			out_ << data;
		}
		tempFile.close();

		if (saveAll) {
			if (historyFile.exists() && !historyFile.remove())
				qWarning("History: error removing old history." ~ historyFile.errorString());
			if (!tempFile.rename(historyFile.fileName()))
				qWarning("History: error moving new history over old." ~ tempFile.errorString() ~ historyFile.fileName());
		}
		m_lastSavedUrl = m_history.value(0).url;
	}

	void checkForExpired()
	{
		if (m_historyLimit < 0 || m_history.length == 0)
			return;

		QDateTime now = QDateTime.currentDateTime();
		int nextTimeout = 0;

		while (m_history.length) {
			QDateTime checkForExpired = m_history.last().dateTime;
			checkForExpired.setDate(checkForExpired.date().addDays(m_historyLimit));
			if (now.daysTo(checkForExpired) > 7) {
				// check at most in a week to prevent int overflows on the timer
				nextTimeout = 7 * 86400;
			} else {
				nextTimeout = now.secsTo(checkForExpired);
			}
			if (nextTimeout > 0)
				break;
			HistoryItem item = m_history.takeLast();
			// remove from saved file also
			m_lastSavedUrl = null;
			entryRemoved.emit(item);
		}

		if (nextTimeout > 0)
			m_expiredTimer.start(nextTimeout * 1000);
	}

protected:

	void addHistoryItem(HistoryItem item)
	{
		QWebSettings globalSettings = QWebSettings.globalSettings();
		if (globalSettings.testAttribute(QWebSettings.PrivateBrowsingEnabled))
			return;

		m_history = [item] ~ m_history;
		entryAdded.emit(item);
		if (m_history.length == 1)
			checkForExpired();
	}

private:
	
	void load()
	{
		loadSettings();

		historyFile = new QFile(QDesktopServices.storageLocation(QDesktopServices.DataLocation) ~ "/history");
		if (!historyFile.exists())
			return;
		if (!historyFile.open(QFile.ReadOnly)) {
			qWarning("Unable to open history file" ~ historyFile.fileName());
			return;
		}

		HistoryItem[] list;
		auto in_ = new QDataStream(&historyFile);
		// Double check that the history file is sorted as it is read in
		bool needToSort = false;
		auto lastInsertedItem = new HistoryItem;
		auto data = new QByteArray;
		auto stream = new QDataStream;
		auto buffer = new QBuffer;
		stream.setDevice(buffer);
		while (!historyFile.atEnd()) {
			in_ >> data;
			buffer.close();
			buffer.setBuffer(data);
			buffer.open(QIODevice.ReadOnly);
			uint ver;
			stream >> ver;
			if (ver != HISTORY_VERSION)
				continue;
			auto item = new HistoryItem;
			stream >> item.url;
			stream >> item.dateTime;
			stream >> item.title;

			if (!item.dateTime.isValid())
				continue;

			if (item == lastInsertedItem) {
				if (lastInsertedItem.title.isEmpty() && !list.isEmpty())
				list[0].title = item.title;
				continue;
			}

			if (!needToSort && !list.isEmpty() && lastInsertedItem < item)
				needToSort = true;

			list.prepend(item);
			lastInsertedItem = item;
		}
		
		if (needToSort)
			qSort(list.begin(), list.end());

		setHistory(list, true);

		// If we had to sort re-write the whole history sorted
		if (needToSort) {
			m_lastSavedUrl = null;
			m_saveTimer.changeOccurred();
		}
	}

	AutoSaver m_saveTimer;
	int m_historyLimit;
	QTimer m_expiredTimer;
	HistoryItem[] m_history;
	string m_lastSavedUrl;

	HistoryModel m_historyModel;
	HistoryFilterModel m_historyFilterModel;
	HistoryTreeModel m_historyTreeModel;
}


class HistoryModel : public QAbstractTableModel
{
public:

	void historyReset()
	{
		reset();
	}

	void entryAdded()
	{
		beginInsertRows(QModelIndex(), 0, 0);
		endInsertRows();
	}

	void entryUpdated(int offset)
	{
		QModelIndex idx = index(offset, 0);
		dataChanged.emit(idx, idx);
	}

public:

	enum Roles {
		DateRole = Qt_ItemDataRole.UserRole + 1,
		DateTimeRole = Qt_ItemDataRole.UserRole + 2,
		UrlRole = Qt_ItemDataRole.UserRole + 3,
		UrlStringRole = Qt_ItemDataRole.UserRole + 4
	};

	this(HistoryManager history, QObject parent = null)
	{
		super(parent);
		m_history = history;
		assert(m_history);
		
		m_history.historyReset.connect(&this.historyReset);
		m_history.entryRemoved.connect(&this.historyReset);
		m_history.entryAdded.connect(&this.entryAdded);
		m_history.entryUpdated.connect(&this.entryUpdated);
	}
    
	QVariant headerData(int section, Qt_Orientation orientation, int role = Qt_ItemDataRole.DisplayRole)
	{
		if (orientation == Qt_Orientation.Horizontal && role == Qt_Orientation.DisplayRole) {
			switch (section) {
				case 0: return tr("Title");
				case 1: return tr("Address");
			}
		}
		return QAbstractTableModel.headerData(section, orientation, role);
	}

	QVariant data(QModelIndex index, int role = Qt_ItemDataRole.DisplayRole)
	{
		HistoryItem[] lst = m_history.history();
		if (index.row() < 0 || index.row() >= lst.length)
			return new QVariant();

		HistoryItem item = lst[index.row()];
		switch (role) {
			case DateTimeRole:
				return item.dateTime;
			case DateRole:
				return item.dateTime.date();
			case UrlRole:
				return new QUrl(item.url);
			case UrlStringRole:
				return item.url;
			case Qt_ItemDataRole.DisplayRole:
			case Qt_ItemDataRole.EditRole: {
				switch (index.column()) {
					case 0:
						// when there is no title try to generate one from the url
						if (item.title.isEmpty()) {
							string page = (new QFileInfo((new QUrl(item.url)).path())).fileName();
							if (!page.isEmpty())
								return page;
							return item.url;
						}
						return item.title;
					case 1:
						return item.url;
				}
			}
			case Qt_ItemDataRole.DecorationRole:
				if (index.column() == 0) {
					return BrowserApplication.instance().icon(item.url);
				}
		}
		return new QVariant();
	}

	int columnCount(QModelIndex parent = QModelIndex())
	{
		return (parent.isValid()) ? 0 : 2;
	}

	int rowCount(QModelIndex parent = QModelIndex())
	{
		return (parent.isValid()) ? 0 : m_history.history().count();
	}

	bool removeRows(int row, int count, QModelIndex parent = QModelIndex())
	{
		if (parent.isValid())
			return false;
		int lastRow = row + count - 1;
		beginRemoveRows(parent, row, lastRow);
		HistoryItem[] lst = m_history.history();
		for (int i = lastRow; i >= row; --i)
			lst.removeAt(i);
		m_history.historyReset.disconnect(&this.historyReset);
		m_history.setHistory(lst);
		m_history.historyReset.connect(&this.historyReset);
		endRemoveRows();
		return true;
	}

private:

	HistoryManager m_history;
}


const uint MOVEDROWS = 15;


/*!
Proxy model that will remove any duplicate entries.
Both m_sourceRow and m_historyHash store their offsets not from
the front of the list, but as offsets from the back.
*/
class HistoryFilterModel : public QAbstractProxyModel
{
public:

	this(QAbstractItemModel sourceModel, QObject parent = null)
	{
		super(parent);
		m_loaded = false;
		setSourceModel(sourceModel);
	}

	bool historyContains(string url)
	{
		load();
		return ((url in m_historyHash) != null);
	}
	
	int historyLocation(string url)
	{
		load();
		if (!(url in m_historyHash))
			return 0;
		return sourceModel().rowCount() - m_historyHash.value(url);
	}

	QModelIndex mapFromSource(QModelIndex sourceIndex)
	{
		load();
		string url = sourceIndex.data(HistoryModel.UrlStringRole).toString();
		if (!(url in m_historyHash))
			return QModelIndex();

		// This can be done in a binary search, but we can't use qBinary find
		// because it can't take: qBinaryFind(m_sourceRow.end(), m_sourceRow.begin(), v);
		// so if this is a performance bottlneck then convert to binary search, until then
		// the cleaner/easier to read code wins the day.
		int realRow = -1;
		int sourceModelRow = sourceModel().rowCount() - sourceIndex.row();

		for (int i = 0; i < m_sourceRow.count(); ++i) {
			if (m_sourceRow[i] == sourceModelRow) {
				realRow = i;
				break;
			}
		}
		if (realRow == -1)
			return QModelIndex();

		return createIndex(realRow, sourceIndex.column(), sourceModel().rowCount() - sourceIndex.row());
	}

	QModelIndex mapToSource(QModelIndex proxyIndex)
	{
		load();
		int sourceRow = sourceModel().rowCount() - proxyIndex.internalId();
		return sourceModel().index(sourceRow, proxyIndex.column());
	}

	void setSourceModel(QAbstractItemModel newSourceModel)
	{
		if (sourceModel()) {
			sourceModel.modelReset.disconnect(&this.sourceReset);
			sourceModel.dataChanged.disconnect(&this.dataChanged);
			sourceModel.rowsInserted.disconnect(&this.sourceRowsInserted);
			sourceModel.rowsRemoved.disconnect(&this.sourceRowsRemoved);
		}

		QAbstractProxyModel.setSourceModel(newSourceModel);

		if (sourceModel()) {
			m_loaded = false;
			sourceModel.modelReset.connect(&this.sourceReset);
			sourceModel.dataChanged.connect(&this.sourceDataChanged);
			sourceModel.rowsInserted.connect(&this.sourceRowsInserted);
			sourceModel.rowsRemoved.connect(&this.sourceRowsRemoved);
		}
	}

	QVariant headerData(int section, Qt_Orientation orientation, int role = Qt_ItemDataRole.DisplayRole)
	{
		return sourceModel().headerData(section, orientation, role);
	}

	int rowCount(QModelIndex parent = QModelIndex())
	{
		load();
		if (parent.isValid())
			return 0;
		return m_historyHash.length;
	}

	int columnCount(QModelIndex parent = QModelIndex())
	{
		return (parent.isValid()) ? 0 : 2;
	}

	QModelIndex index(int, int, QModelIndex = QModelIndex())
	{
		load();
		if (row < 0 || row >= rowCount(parent) || column < 0 || column >= columnCount(parent))
			return QModelIndex();

		return createIndex(row, column, m_sourceRow[row]);
	}

	QModelIndex parent(QModelIndex index = QModelIndex())
	{
		return QModelIndex();
	}

	/*
	Removing a continuous block of rows will remove filtered rows too as this is
	the users intention.
	*/
	bool removeRows(int row, int count, QModelIndex parent = QModelIndex())
	{
		if (row < 0 || count <= 0 || row + count > rowCount(parent) || parent.isValid())
			return false;
		int lastRow = row + count - 1;
		sourceModel.rowsRemoved,disconnect(&this.sourceRowsRemoved);
		beginRemoveRows(parent, row, lastRow);
		int oldCount = rowCount();
		int start = sourceModel().rowCount() - m_sourceRow.value(row);
		int end = sourceModel().rowCount() - m_sourceRow.value(lastRow);
		sourceModel().removeRows(start, end - start + 1);
		endRemoveRows();
		sourceModel.rowsRemoved.connect(&this.sourceRowsRemoved);
		m_loaded = false;
		if (oldCount - count != rowCount())
			reset();
		return true;
	}

	QVariant data(QModelIndex index, int role = Qt_ItemDataRole.DisplayRole)
	{
		return QAbstractProxyModel.data(index, role);
	}

private:

	void sourceReset()
	{
		m_loaded = false;
		reset();
	}

	void sourceDataChanged(QModelIndex topLeft, QModelIndex bottomRight)
	{
		dataChanged.emit(mapFromSource(topLeft), mapFromSource(bottomRight));
	}

	void sourceRowsRemoved(QModelIndex , int start, int end)
	{
		sourceReset();
	}

	void sourceRowsInserted(QModelIndex parent, int start, int end)
	{
		assert(start == end && start == 0);
		
		if (!m_loaded)
			return;
		QModelIndex idx = sourceModel().index(start, 0, parent);
		string url = idx.data(HistoryModel.UrlStringRole).toString();
		if (url in m_historyHash) {
			int sourceRow = sourceModel().rowCount() - m_historyHash[url];
			int realRow = mapFromSource(sourceModel().index(sourceRow, 0)).row();
			beginRemoveRows(QModelIndex(), realRow, realRow);
			m_sourceRow.removeAt(realRow);
			m_historyHash.remove(url);
			endRemoveRows();
		}
		beginInsertRows(QModelIndex(), 0, 0);
		m_historyHash[url] = (sourceModel().rowCount() - start);
		m_sourceRow.insert(0, sourceModel().rowCount());
		endInsertRows();
	}

private:
	void load()
	{
		if (m_loaded)
			return;
		m_sourceRow.clear();
		m_historyHash = null;
		m_historyHash.length = sourceModel().rowCount();
		m_historyHash.length = 0;
		for (int i = 0; i < sourceModel().rowCount(); ++i) {
			QModelIndex idx = sourceModel().index(i, 0);
			string url = idx.data(HistoryModel.UrlStringRole).toString();
			if (!(url in m_historyHash)) {
				m_sourceRow.append(sourceModel().rowCount() - i);
				m_historyHash[url] = sourceModel().rowCount() - i;
			}
		}
		m_loaded = true;
	}

	int[] m_sourceRow;
	int[string] m_historyHash;
	bool m_loaded;
}


/*
The history menu
- Removes the first twenty entries and puts them as children of the top level.
- If there are less then twenty entries then the first folder is also removed.

The mapping is done by knowing that HistoryTreeModel is over a table
We store that row offset in our index's private data.
*/
class HistoryMenuModel : public QAbstractProxyModel
{
public:
    
	/*
	Maps the first bunch of items of the source model to the root
	*/
	this(HistoryTreeModel sourceModel, QObject parent = null)
	{
		super(parent);
		m_treeModel = sourceModel;
		setSourceModel(sourceModel);
	}

	int columnCount(QModelIndex parent)
	{
		return m_treeModel.columnCount(mapToSource(parent));
	}

	int rowCount(QModelIndex parent = QModelIndex())
	{
		if (parent.column() > 0)
			return 0;

		if (!parent.isValid()) {
			int folders = sourceModel().rowCount();
			int bumpedItems = bumpedRows();
			if (bumpedItems <= MOVEDROWS && bumpedItems == sourceModel().rowCount(sourceModel().index(0, 0)))
				--folders;
			return bumpedItems + folders;
		}

		if (parent.internalId() == -1) {
			if (parent.row() < bumpedRows())
				return 0;
		}

		QModelIndex idx = mapToSource(parent);
		int defaultCount = sourceModel().rowCount(idx);
		if (idx == sourceModel().index(0, 0))
			return defaultCount - bumpedRows();
		return defaultCount;
	}

	QModelIndex mapFromSource(QModelIndex sourceIndex)
	{
		// currently not used or autotested
		assert(false);
		int sr = m_treeModel.mapToSource(sourceIndex).row();
		return createIndex(sourceIndex.row(), sourceIndex.column(), sr);
	}

	QModelIndex mapToSource(QModelIndex proxyIndex)
	{
		if (!proxyIndex.isValid())
			return QModelIndex();

		if (proxyIndex.internalId() == -1) {
			int bumpedItems = bumpedRows();
			if (proxyIndex.row() < bumpedItems)
				return m_treeModel.index(proxyIndex.row(), proxyIndex.column(), m_treeModel.index(0, 0));
			if (bumpedItems <= MOVEDROWS && bumpedItems == sourceModel().rowCount(m_treeModel.index(0, 0)))
				--bumpedItems;
			return m_treeModel.index(proxyIndex.row() - bumpedItems, proxyIndex.column());
		}

		QModelIndex historyIndex = m_treeModel.sourceModel().index(proxyIndex.internalId(), proxyIndex.column());
		QModelIndex treeIndex = m_treeModel.mapFromSource(historyIndex);
		return treeIndex;
	}

	QModelIndex index(int row, int column, QModelIndex parent = QModelIndex())
	{
		if (row < 0 || column < 0 || column >= columnCount(parent) || parent.column() > 0)
			return QModelIndex();
		
		if (!parent.isValid())
			return createIndex(row, column, -1);

		QModelIndex treeIndexParent = mapToSource(parent);

		int bumpedItems = 0;
		if (treeIndexParent == m_treeModel.index(0, 0))
			bumpedItems = bumpedRows();
		QModelIndex treeIndex = m_treeModel.index(row + bumpedItems, column, treeIndexParent);
		QModelIndex historyIndex = m_treeModel.mapToSource(treeIndex);
		int historyRow = historyIndex.row();
		if (historyRow == -1)
			historyRow = treeIndex.row();
		return createIndex(row, column, historyRow);
	}

	QModelIndex parent(QModelIndex index = QModelIndex())
	{
		int offset = index.internalId();
		if (offset == -1 || !index.isValid())
			return QModelIndex();

		QModelIndex historyIndex = m_treeModel.sourceModel().index(index.internalId(), 0);
		QModelIndex treeIndex = m_treeModel.mapFromSource(historyIndex);
		QModelIndex treeIndexParent = treeIndex.parent();

		int sr = m_treeModel.mapToSource(treeIndexParent).row();
		int bumpedItems = bumpedRows();
		if (bumpedItems <= MOVEDROWS && bumpedItems == sourceModel().rowCount(sourceModel().index(0, 0)))
			--bumpedItems;
		return createIndex(bumpedItems + treeIndexParent.row(), treeIndexParent.column(), sr);
	}

	int bumpedRows()
	{
		QModelIndex first = m_treeModel.index(0, 0);
		if (!first.isValid())
			return 0;
		return qMin(m_treeModel.rowCount(first), MOVEDROWS);
	}

private:

	HistoryTreeModel m_treeModel;
}


// Menu that is dynamically populated from the history
class HistoryMenu : public ModelMenu
{
	mixin Signal!("openUrl", QUrl /*url*/);
	
public:

	this(QWidget parent = null)
	{
		super(parent);
		m_history = 0;
		activated.connect(&this.activated);
		setHoverRole(HistoryModel.UrlStringRole);
	}

	void setInitialActions(QAction[] actions)
	{
		m_initialActions = actions;
		for (int i = 0; i < m_initialActions.length; ++i)
			addAction(m_initialActions[i]);
	}

protected:

	bool prePopulated()
	{
		if (!m_history) {
			m_history = BrowserApplication.historyManager();
			m_historyMenuModel = new HistoryMenuModel(m_history.historyTreeModel(), this);
			setModel(m_historyMenuModel);
		}
		// initial actions
		for (int i = 0; i < m_initialActions.length; ++i)
			addAction(m_initialActions[i]);
		if (m_initialActions.length)
			addSeparator();
		setFirstSeparator(m_historyMenuModel.bumpedRows());

		return false;
	}

	void postPopulated()
	{
		if (m_history.history().count() > 0)
			addSeparator();

		QAction showAllAction = new QAction(tr("Show All History"), this);
		showAllAction.triggered.connect(&this.showHistoryDialog);
		addAction(showAllAction);

		QAction clearAction = new QAction(tr("Clear History"), this);
		clearAction.triggered.connect(&m_history.clear);
		addAction(clearAction);
	}

private:

	void activated(QModelIndex index)
	{
		openUrl.emit(index.data(HistoryModel.UrlRole).toUrl());
	}

	void showHistoryDialog()
	{
		auto dialog = new HistoryDialog(this);
		dialog.openUrl(QUrl).connect(&this.openUrl(QUrl));
		dialog.show();
	}

private:

	HistoryManager m_history;
	HistoryMenuModel m_historyMenuModel;
	QAction[] m_initialActions;
}


// proxy model for the history model that
// exposes each url http://www.foo.com and it url starting at the host www.foo.com
class HistoryCompletionModel : public QAbstractProxyModel
{
public:

	this(QObject parent = null)
	{
		super(parent);
	}

	QVariant data(QModelIndex index, int role)
	{
		if (sourceModel() && (role == Qt_ItemDataRole.EditRole || role == Qt_ItemDataRole.DisplayRole) && index.isValid()) {
			QModelIndex idx = mapToSource(index);
			idx = idx.sibling(idx.row(), 1);
			string urlString = idx.data(HistoryModel.UrlStringRole).toString();
			if (index.row() % 2) {
				QUrl url = urlString;
				string s = url.toString(QUrl.RemoveScheme | QUrl.RemoveUserInfo | QUrl.StripTrailingSlash);
				return s.mid(2);  // strip // from the front
			}
			return urlString;
		}
		return QAbstractProxyModel.data(index, role);
	}

	int rowCount(QModelIndex parent = QModelIndex())
	{
		return (parent.isValid() || !sourceModel()) ? 0 : sourceModel().rowCount(parent) * 2;
	}

	int columnCount(QModelIndex parent = QModelIndex())
	{
		return (parent.isValid()) ? 0 : 1;
	}

	QModelIndex mapFromSource(QModelIndex sourceIndex)
	{
		int row = sourceIndex.row() * 2;
		return index(row, sourceIndex.column());
	}

	QModelIndex mapToSource(QModelIndex proxyIndex)
	{
		if (!sourceModel())
			return QModelIndex();
		int row = proxyIndex.row() / 2;
		return sourceModel().index(row, proxyIndex.column());
	}

	QModelIndex index(int, int, QModelIndex = QModelIndex())
	{
		if (row < 0 || row >= rowCount(parent) || column < 0 || column >= columnCount(parent))
			return QModelIndex();
		return createIndex(row, column, 0);
	}

	QModelIndex parent(QModelIndex index = QModelIndex())
	{
		return QModelIndex();
	}

	void setSourceModel(QAbstractItemModel sourceModel)
	{
		if (sourceModel()) {
			sourceModel.modelReset.disconnect(&this.sourceReset);
			sourceModel.rowsInserted.disconnect(&this.sourceReset);
			sourceModel.rowsRemoved.disconnect(&this.sourceReset);
		}

		QAbstractProxyModel.setSourceModel(newSourceModel);

		if (newSourceModel) {
			newSourceModel.modelReset.connect(&this.sourceReset);
			sourceModel.rowsInserted.connect(&this.sourceReset);
			sourceModel.rowsRemoved.connect(&this.sourceReset);
		}

		reset();
	}

private:

	void sourceReset()
	{
		reset();
	}
}


// proxy model for the history model that converts the list
// into a tree, one top level node per day.
// Used in the HistoryDialog.
class HistoryTreeModel : public QAbstractProxyModel
{
public:

	this(QAbstractItemModel sourceModel, QObject parent = null)
	{
		super(parent);
		setSourceModel(sourceModel);
	}

	QVariant data(QModelIndex index, int role = Qt_ItemDataRole.DisplayRole)
	{
		if ((role == Qt_ItemDataRole.EditRole || role == Qt_ItemDataRole.DisplayRole)) {
			int start = index.internalId();
			if (start == 0) {
				int offset = sourceDateRow(index.row());
				if (index.column() == 0) {
					QModelIndex idx = sourceModel().index(offset, 0);
					QDate date = idx.data(HistoryModel.DateRole).toDate();
					if (date == QDate.currentDate())
						return tr("Earlier Today");
					return date.toString("dddd, MMMM d, yyyy");
				}
				if (index.column() == 1) {
					return Format(tr("{} items"), rowCount(index.sibling(index.row(), 0)));
				}
			}
		}
		if (role == Qt_ItemDataRole.DecorationRole && index.column() == 0 && !index.parent().isValid())
			return new QIcon(":history.png");
		if (role == HistoryModel.DateRole && index.column() == 0 && index.internalId() == 0) {
			int offset = sourceDateRow(index.row());
			QModelIndex idx = sourceModel().index(offset, 0);
			return idx.data(HistoryModel.DateRole);
		}

		return QAbstractProxyModel.data(index, role);
	}

	int columnCount(QModelIndex parent)
	{
		return sourceModel().columnCount(mapToSource(parent));
	}

	int rowCount(QModelIndex parent = QModelIndex())
	{
		if ( parent.internalId() != 0 || parent.column() > 0 || !sourceModel())
			return 0;

		// row count OF dates
		if (!parent.isValid()) {
			if (m_sourceRowCache.length)
				return m_sourceRowCache.length;
			QDate currentDate;
			int rows = 0;
			int totalRows = sourceModel().rowCount();

			for (int i = 0; i < totalRows; ++i) {
				QDate rowDate = sourceModel().index(i, 0).data(HistoryModel.DateRole).toDate();
				if (rowDate != currentDate) {
					m_sourceRowCache ~= i;
					currentDate = rowDate;
					++rows;
				}
			}
			assert(m_sourceRowCache.length == rows);
			return rows;
		}

		// row count FOR a date
		int start = sourceDateRow(parent.row());
		int end = sourceDateRow(parent.row() + 1);
		return (end - start);
	}

	QModelIndex mapFromSource(QModelIndex sourceIndex)
	{
		if (!sourceIndex.isValid())
			return QModelIndex();

		if (m_sourceRowCache.length == 0)
			rowCount(QModelIndex());

		//int[].iterator it;
		//it = qLowerBound(m_sourceRowCache.begin(), m_sourceRowCache.end(), sourceIndex.row());
		int it = 0;
		it = qLowerBound(m_sourceRowCache, sourceIndex.row());
		if (it != sourceIndex.row())
			--it;
		int dateRow = qMax(0, it);
		int row = sourceIndex.row() - m_sourceRowCache[dateRow];
		return createIndex(row, sourceIndex.column(), dateRow + 1);
	}

	QModelIndex mapToSource(QModelIndex proxyIndex)
	{
		int offset = proxyIndex.internalId();
		if (offset == 0)
			return QModelIndex();
		int startDateRow = sourceDateRow(offset - 1);
		return sourceModel().index(startDateRow + proxyIndex.row(), proxyIndex.column());
	}

	QModelIndex index(int row, int column, QModelIndex parent = QModelIndex())
	{
		if (row < 0 || column < 0 || column >= columnCount(parent) || parent.column() > 0)
			return QModelIndex();

		if (!parent.isValid())
			return createIndex(row, column, 0);
		return createIndex(row, column, parent.row() + 1);
	}

	QModelIndex parent(QModelIndex index = QModelIndex())
	{
		int offset = index.internalId();
		if (offset == 0 || !index.isValid())
			return QModelIndex();
		return createIndex(offset - 1, 0, 0);
	}

	bool hasChildren(QModelIndex parent = QModelIndex())
	{
		QModelIndex grandparent = parent.parent();
		if (!grandparent.isValid())
			return true;
		return false;
	}

	int flags(QModelIndex index)
	{
		if (!index.isValid())
			return Qt_ItemFlag.NoItemFlags;
		return Qt_ItemFlag.ItemIsSelectable | Qt_ItemFlag.ItemIsEnabled | Qt_ItemFlag.ItemIsDragEnabled;
	}

	bool removeRows(int row, int count, QModelIndex parent = QModelIndex())
	{
		if (row < 0 || count <= 0 || row + count > rowCount(parent))
			return false;

		if (parent.isValid()) {
			// removing pages
			int offset = sourceDateRow(parent.row());
			return sourceModel().removeRows(offset + row, count);
		} else {
			// removing whole dates
			for (int i = row + count - 1; i >= row; --i) {
				QModelIndex dateParent = index(i, 0);
				int offset = sourceDateRow(dateParent.row());
				if (!sourceModel().removeRows(offset, rowCount(dateParent)))
					return false;
			}
		}
		return true;
	}

	QVariant headerData(int section, Qt_Orientation orientation, int role = Qt_ItemDataRole.DisplayRole)
	{
		return sourceModel().headerData(section, orientation, role);
	}

	void setSourceModel(QAbstractItemModel newSourceModel)
	{
		if (sourceModel()) {
			sourceModel.modelReset.disconnect(&this.sourceReset);
			sourceModel.layoutChanged.disconnect(&this.sourceReset);
			sourceModel.rowsInserted.disconnect(&this.sourceRowsInserted);
			sourceModel.rowsRemoved.disconnect(&this.sourceRowsRemoved);
		}

		QAbstractProxyModel.setSourceModel(newSourceModel);

		if (newSourceModel) {
			sourceModel.modelReset.connect(&this.sourceReset);
			sourceModel.layoutChanged.connect(&this.sourceReset);
			sourceModel.rowsInserted.connect(&this.sourceRowsInserted);
			sourceModel.rowsRemoved.connect(&this.sourceRowsRemoved);
		}

		reset();
	}

private:

	void sourceReset()
	{
		m_sourceRowCache.length = 0;
		reset();
	}

	void sourceRowsInserted(QModelIndex parent, int start, int end)
	{
		assert(!parent.isValid());
		if (start != 0 || start != end) {
			m_sourceRowCache.length = 0;
			reset();
			return;
		}

		m_sourceRowCache.length = 0;
		QModelIndex treeIndex = mapFromSource(sourceModel().index(start, 0));
		QModelIndex treeParent = treeIndex.parent();
		if (rowCount(treeParent) == 1) {
			beginInsertRows(QModelIndex(), 0, 0);
			endInsertRows();
		} else {
			beginInsertRows(treeParent, treeIndex.row(), treeIndex.row());
			endInsertRows();
		}
	}

	void sourceRowsRemoved(QModelIndex parent, int start, int end)
	{
		assert(!parent.isValid());
		if (m_sourceRowCache.length == 0)
			return;
		for (int i = end; i >= start;) {
			//int[]::iterator it;
			//it = qLowerBound(m_sourceRowCache.begin(), m_sourceRowCache.end(), i);
			int it;
			it = qLowerBound(m_sourceRowCache, i);
			// playing it safe
			if (it == m_sourceRowCache.length) {
				m_sourceRowCache.length = 0;
				reset();
				return;
			}

			if (it != i)
				--it;
			int row = qMax(0, it);
			int offset = m_sourceRowCache[row];
			QModelIndex dateParent = index(row, 0);
			// If we can remove all the rows in the date do that and skip over them
			int rc = rowCount(dateParent);
			if (i - rc + 1 == offset && start <= i - rc + 1) {
				beginRemoveRows(QModelIndex(), row, row);
				m_sourceRowCache.removeAt(row);
				i -= rc + 1;
			} else {
				beginRemoveRows(dateParent, i - offset, i - offset);
				++row;
				--i;
			}
			for (int j = row; j < m_sourceRowCache.length; ++j)
				--m_sourceRowCache[j];
			endRemoveRows();
		}
	}

private:

	// Translate the top level date row into the offset where that date starts
	int sourceDateRow(int row)
	{
		if (row <= 0)
			return 0;

		if (m_sourceRowCache.length == 0)
			rowCount(QModelIndex());

		if (row >= m_sourceRowCache.length) {
			if (!sourceModel())
				return 0;
			return sourceModel().rowCount();
		}
		return m_sourceRowCache[row];
	}

	int[] m_sourceRowCache;
}


// A modified QSortFilterProxyModel that always accepts the root nodes in the tree
// so filtering is only done on the children.
// Used in the HistoryDialog
class TreeProxyModel : public QSortFilterProxyModel
{
public:

	this(QObject parent = null)
	{
		super(parent);
		setSortRole(HistoryModel.DateTimeRole);
		setFilterCaseSensitivity(Qt_CaseSensitivity.CaseInsensitive);
	}

protected:

	bool filterAcceptsRow(int source_row, QModelIndex source_parent)
	{
		if (!source_parent.isValid())
			return true;
		return QSortFilterProxyModel.filterAcceptsRow(source_row, source_parent);
	}
}


import ui_historydialog;

class HistoryDialog : public QDialog //, public Ui_HistoryDialog
{
	mixin Ui_HistoryDialog;
	mixin Signal!("openUrl", QUrl /*url*/);

public:

	this(QWidget parent = null, HistoryManager history = null)
	{
		super(parent);
		HistoryManager history = setHistory;
		if (!history)
			history = BrowserApplication.historyManager();
		setupUi(this);
		tree.setUniformRowHeights(true);
		tree.setSelectionBehavior(QAbstractItemView.SelectRows);
		tree.setTextElideMode(Qt_TextElideMode.ElideMiddle);
		auto model = history.historyTreeModel();
		auto proxyModel = new TreeProxyModel(this);
		search.textChanged.connect(&proxyModel.setFilterFixedString);
		removeButton.clicked.connect(&tree.removeOne);
		removeAllButton.clicked.connect(&history.clear);
		proxyModel.setSourceModel(model);
		tree.setModel(proxyModel);
		tree.setExpanded(proxyModel.index(0, 0), true);
		tree.setAlternatingRowColors(true);
		QFontMetrics fm = font();
		int header = fm.width(QLatin1Char('m')) * 40;
		tree.header().resizeSection(0, header);
		tree.header().setStretchLastSection(true);
		tree.activated(QModelIndex).connect(this.open);
		tree.setContextMenuPolicy(Qt_ContextMenuPolicy.CustomContextMenu);
		tree.customContextMenuRequested.connect(&this.customContextMenuRequested);
	}

private:

	void customContextMenuRequested(QPoint pos)
	{
		auto menu = new QMenu;
		QModelIndex index = tree.indexAt(pos);
		index = index.sibling(index.row(), 0);
		if (index.isValid() && !tree.model().hasChildren(index)) {
			menu.addAction(tr("Open"), this, SLOT(open()));
			menu.addSeparator();
			menu.addAction(tr("Copy"), this, SLOT(copy()));
		}
		menu.addAction(tr("Delete"), tree, SLOT(removeOne()));
		menu.exec(QCursor.pos());
	}

	void open()
	{
		QModelIndex index = tree.currentIndex();
		if (!index.parent().isValid())
			return;
		openUrl.emit(index.data(HistoryModel.UrlRole).toUrl());
	}

	void copy()
	{
		QModelIndex index = tree.currentIndex();
		if (!index.parent().isValid())
			return;
		string url = index.data(HistoryModel.UrlStringRole).toString();

		QClipboard clipboard = QApplication.clipboard();
		clipboard.setText(url);
	}
}
