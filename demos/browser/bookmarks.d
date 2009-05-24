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

module bookmarks;


import qt.core.QObject;
import qt.core.QAbstractItemModel;

import qt.gui.QUndoCommand;

import qt.core.QBuffer;
import qt.core.QFile;
import qt.core.QMimeData;

import qt.gui.QDesktopServices;
import qt.gui.QDragEnterEvent;
import qt.gui.QFileDialog;
import qt.gui.QHeaderView;
import qt.gui.QIcon;
import qt.gui.QMessageBox;
import qt.gui.QToolButton;

import QtWebKit.QWebSettings;

import qt.core.QDebug;

import bookmarks;
import autosaver;
import browserapplication;
import history;
import xbel;


const string BOOKMARKBAR = "Bookmarks Bar";
const string BOOKMARKMENU = "Bookmarks Menu";


/*!
Bookmark manager, owner of the bookmarks, loads, saves and basic tasks
*/
class BookmarksManager : public QObject
{
	mixin Signal!("entryAdded", BookmarkNode /*item*/);
	mixin Signal!("entryRemoved", BookmarkNode /*parent*/, int /*row*/, BookmarkNode /*item*/);
	mixin Signal!("entryChanged", BookmarkNode /*item*/);

public:

	this(QObject parent = null)
	{
		super(parent);
		m_loaded = false;
		m_saveTimer = new AutoSaver(this);
		m_bookmarkRootNode = null;
		m_bookmarkModel = null;
		this.entryAdded.connect(&m_saveTimer.changeOccurred);
		this.entryRemoved.connect(&m_saveTimer.changeOccurred);
		this.entryChanged.connect(&m_saveTimer.changeOccurred);
	}

	~this()
	{
		m_saveTimer.saveIfNeccessary();
	}

	void addBookmark(BookmarkNode parent, BookmarkNode node, int row = -1)
	{
		if (!m_loaded)
			return;
		assert(parent);
		InsertBookmarksCommand command = new InsertBookmarksCommand(this, parent, node, row);
		m_commands.push(command);
	}

	void removeBookmark(BookmarkNode node)
	{
		if (!m_loaded)
			return;

		assert(node);
		BookmarkNode parent = node.parent();
		int row = parent.children().indexOf(node);
		RemoveBookmarksCommand command = new RemoveBookmarksCommand(this, parent, row);
		m_commands.push(command);
	}

	void setTitle(BookmarkNode node, string newTitle)
	{
		if (!m_loaded)
			return;

		assert(node);
		ChangeBookmarkCommand command = new ChangeBookmarkCommand(this, node, newTitle, true);
		m_commands.push(command);
	}

	void setUrl(BookmarkNode node, string newUrl)
	{
		if (!m_loaded)
			return;

		assert(node);
		ChangeBookmarkCommand command = new ChangeBookmarkCommand(this, node, newUrl, false);
		m_commands.push(command);
	}

	void changeExpanded()
	{
		m_saveTimer.changeOccurred();
	}

	BookmarkNode bookmarks()
	{
		if (!m_loaded)
			load();
		return m_bookmarkRootNode;
	}

	BookmarkNode menu()
	{
		if (!m_loaded)
			load();

		for (int i = m_bookmarkRootNode.children().count() - 1; i >= 0; --i) {
			BookmarkNode node = m_bookmarkRootNode.children()[i];
			if (node.title == tr(BOOKMARKMENU))
				return node;
		}
		assert(false);
		return 0;
	}

	BookmarkNode toolbar()
	{
		if (!m_loaded)
			load();

		for (int i = m_bookmarkRootNode.children().count() - 1; i >= 0; --i) {
			BookmarkNode node = m_bookmarkRootNode.children()[i];
			if (node.title == tr(BOOKMARKBAR))
				return node;
		}
		assert(false);
		return 0;
	}

	BookmarksModel bookmarksModel()
	{
		if (!m_bookmarkModel)
			m_bookmarkModel = new BookmarksModel(this, this);
		return m_bookmarkModel;
	}

	QUndoStack undoRedoStack() { return m_commands; };

public:

	void importBookmarks()
	{
		string fileName = QFileDialog.getOpenFileName(0, tr("Open File"), null, tr("XBEL (*.xbel *.xml)"));
		if (fileName.isEmpty())
			return;

		XbelReader reader;
		BookmarkNode importRootNode = reader.read(fileName);
		if (reader.error() != QXmlStreamReader.NoError) {
			QMessageBox.warning(0, QLatin1String("Loading Bookmark"),
				tr("Error when loading bookmarks on line %1, column %2:\n"
				"%3").arg(reader.lineNumber()).arg(reader.columnNumber()).arg(reader.errorString()));
		}

		importRootNode.setType(BookmarkNode.Folder);
		importRootNode.title = (tr("Imported %1").arg(QDate.currentDate().toString(Qt.SystemLocaleShortDate)));
		addBookmark(menu(), importRootNode);
	}


	void exportBookmarks()
	{
		string fileName = QFileDialog.getSaveFileName(0, tr("Save File"),
				tr("%1 Bookmarks.xbel").arg(QCoreApplication.applicationName()),
				tr("XBEL (*.xbel *.xml)"));
		if (fileName.isEmpty())
			return;

		XbelWriter writer;
		if (!writer.write(fileName, m_bookmarkRootNode))
			QMessageBox.critical(0, tr("Export error"), tr("error saving bookmarks"));
	}

private:

	void save()
	{
		if (!m_loaded)
			return;

		XbelWriter writer;
		string dir = QDesktopServices.storageLocation(QDesktopServices.DataLocation);
		string bookmarkFile = dir + QLatin1String("/bookmarks.xbel");
		if (!writer.write(bookmarkFile, m_bookmarkRootNode))
			qWarning() << "BookmarkManager: error saving to" << bookmarkFile;
	}

private:
	
	void load()
	{
		if (m_loaded)
			return;
		m_loaded = true;

		string dir = QDesktopServices.storageLocation(QDesktopServices.DataLocation);
		string bookmarkFile = dir ~ QLatin1String("/bookmarks.xbel");
		if (!QFile.exists(bookmarkFile))
			bookmarkFile = QLatin1String(":defaultbookmarks.xbel");

		XbelReader reader;
		m_bookmarkRootNode = reader.read(bookmarkFile);
		if (reader.error() != QXmlStreamReader.NoError) {
			QMessageBox.warning(0, QLatin1String("Loading Bookmark"),
			tr("Error when loading bookmarks on line %1, column %2:\n"
			"%3").arg(reader.lineNumber()).arg(reader.columnNumber()).arg(reader.errorString()));
		}

		BookmarkNode toolbar = null;
		BookmarkNode menu = null;
		BookmarkNode[] others;
		for (int i = m_bookmarkRootNode.children().count() - 1; i >= 0; --i) {
			BookmarkNode node = m_bookmarkRootNode.children()[i];
			if (node.type() == BookmarkNode.Folder) {
				// Automatically convert
				if (node.title == tr("Toolbar Bookmarks") && !toolbar) {
					node.title = tr(BOOKMARKBAR);
				}
				if (node.title == tr(BOOKMARKBAR) && !toolbar) {
					toolbar = node;
				}

				// Automatically convert
				if (node.title == tr("Menu") && !menu) {
					node.title = tr(BOOKMARKMENU);
				}
				if (node.title == tr(BOOKMARKMENU) && !menu) {
					menu = node;
				}
			} else {
				others ~= node;
			}
			m_bookmarkRootNode.remove(node);
		}
		assert(m_bookmarkRootNode.children().count() == 0);
		if (!toolbar) {
			toolbar = new BookmarkNode(BookmarkNode.Folder, m_bookmarkRootNode);
			toolbar.title = tr(BOOKMARKBAR);
		} else {
			m_bookmarkRootNode.add(toolbar);
		}

		if (!menu) {
			menu = new BookmarkNode(BookmarkNode.Folder, m_bookmarkRootNode);
			menu.title = tr(BOOKMARKMENU);
		} else {
			m_bookmarkRootNode.add(menu);
		}

		for (int i = 0; i < others.length; ++i)
			menu.add(others[i]);
	}

	bool m_loaded;
	AutoSaver m_saveTimer;
	BookmarkNode m_bookmarkRootNode;
	BookmarksModel m_bookmarkModel;
	QUndoStack m_commands;
}

class RemoveBookmarksCommand : public QUndoCommand
{
public:

	this(BookmarksManager m_bookmarkManagaer, BookmarkNode parent, int row)
	{
		super(BookmarksManager.tr("Remove Bookmark"));
		m_row = row;
		m_bookmarkManagaer = m_bookmarkManagaer;
		m_node = parent.children().value(row);
		m_parent = parent;
		m_done = false;
	}

	~this()
	{
		if (m_done && !m_node.parent()) {
			delete m_node;
		}
	}

	void undo()
	{
		m_parent.add(m_node, m_row);
		m_bookmarkManagaer.entryAdded.emit(m_node);
		m_done = false;
	}

	void redo()
	{
		m_parent.remove(m_node);
		m_bookmarkManagaer.entryRemoved.emit(m_parent, m_row, m_node);
		m_done = true;
	}

protected:

	int m_row;
	BookmarksManager m_bookmarkManagaer;
	BookmarkNode m_node;
	BookmarkNode m_parent;
	bool m_done;
}

class InsertBookmarksCommand : public RemoveBookmarksCommand
{
public:
	this(BookmarksManager m_bookmarkManagaer, BookmarkNode parent, BookmarkNode node, int row)
	{
		super(m_bookmarkManagaer, parent, row);

		setText(BookmarksManager.tr("Insert Bookmark"));
		m_node = node;
	}

	void undo() { RemoveBookmarksCommand.redo(); }
	void redo() { RemoveBookmarksCommand.undo(); }
}

class ChangeBookmarkCommand : public QUndoCommand
{
public:

	this(BookmarksManager m_bookmarkManagaer, BookmarkNode node, string newValue, bool title)
	{
		super();
		m_bookmarkManagaer = m_bookmarkManagaer;
		m_title = title;
		m_newValue = newValue;
		m_node = node;
		if (m_title) {
			m_oldValue = m_node.title;
			setText(BookmarksManager.tr("Name Change"));
		} else {
			m_oldValue = m_node.url;
			setText(BookmarksManager.tr("Address Change"));
		}
	}

	void undo()
	{
		if (m_title)
			m_node.title = m_oldValue;
		else
			m_node.url = m_oldValue;
		m_bookmarkManagaer.entryChanged.emit(m_node);
	}

	void redo()
	{
		if (m_title)
			m_node.title = m_newValue;
		else
			m_node.url = m_newValue;
		m_bookmarkManagaer.entryChanged.emit(m_node);
	}

private:
	
	BookmarksManager m_bookmarkManagaer;
	bool m_title;
	string m_oldValue;
	string m_newValue;
	BookmarkNode m_node;
}

/*!
BookmarksModel is a QAbstractItemModel wrapper around the BookmarkManager
*/
import qt.gui.QIcon;

class BookmarksModel : public QAbstractItemModel
{
public:

	void entryAdded(BookmarkNode item)
	{
		assert(item && item.parent());
		int row = item.parent().children().indexOf(item);
		BookmarkNode parent = item.parent();
		// item was already added so remove beore beginInsertRows is called
		parent.remove(item);
		beginInsertRows(index(parent), row, row);
		parent.add(item, row);
		endInsertRows();
	}

	void entryRemoved(BookmarkNode parent, int row, BookmarkNode item)
	{
		// item was already removed, re-add so beginRemoveRows works
		parent.add(item, row);
		beginRemoveRows(index(parent), row, row);
		parent.remove(item);
		endRemoveRows();
	}

	void entryChanged(BookmarkNode item)
	{
		QModelIndex idx = index(item);
		dataChanged.emit(idx, idx);
	}

public:

	enum Roles {
		TypeRole = Qt.UserRole + 1,
		UrlRole = Qt.UserRole + 2,
		UrlStringRole = Qt.UserRole + 3,
		SeparatorRole = Qt.UserRole + 4
	};

	this(BookmarksManager bookmarkManager, QObject parent = null)
	{
		super(parent);
		m_endMacro = false;
		m_bookmarksManager = bookmarkManager;
		bookmarkManager.entryAdded.connect(&this.entryAdded);
		bookmarkManager.entryRemoved.connect(&this.entryRemoved);
		bookmarkManager.entryChanged.connect(&this.entryChanged);
	}
    
	BookmarksManager bookmarksManager()
	{
		return m_bookmarksManager;
	}

	QVariant headerData(int section, Qt.Orientation orientation, int role = Qt.DisplayRole)
	{
		if (orientation == Qt.Horizontal && role == Qt.DisplayRole) {
			switch (section) {
				case 0: return tr("Title");
				case 1: return tr("Address");
			}
		}
		return QAbstractItemModel.headerData(section, orientation, role);
	}
    
	QVariant data(QModelIndex index, int role = Qt.DisplayRole)
	{
		if (!index.isValid() || index.model() != this)
			return QVariant();

		BookmarkNode bookmarkNode = node(index);
		switch (role) {
			case Qt.EditRole:
			case Qt.DisplayRole:
				if (bookmarkNode.type() == BookmarkNode.Separator) {
					switch (index.column()) {
						case 0: return QString(50, 0xB7);
						case 1: return QString();
					}
				}

				switch (index.column()) {
					case 0: return bookmarkNode.title;
					case 1: return bookmarkNode.url;
				}
				break;
			case BookmarksModel.UrlRole:
				return QUrl(bookmarkNode.url);
				break;
			case BookmarksModel.UrlStringRole:
				return bookmarkNode.url;
				break;
			case BookmarksModel.TypeRole:
				return bookmarkNode.type();
				break;
			case BookmarksModel.SeparatorRole:
				return (bookmarkNode.type() == BookmarkNode.Separator);
				break;
			case Qt.DecorationRole:
				if (index.column() == 0) {
					if (bookmarkNode.type() == BookmarkNode.Folder)
						return QApplication.style().standardIcon(QStyle.SP_DirIcon);
					return BrowserApplication.instance().icon(bookmarkNode.url);
				}
		}

		return QVariant();
	}

	int columnCount(QModelIndex parent = QModelIndex())
	{
		return (parent.column() > 0) ? 0 : 2;
	}

	int rowCount(QModelIndex parent = QModelIndex())
	{
		if (parent.column() > 0)
			return 0;

		if (!parent.isValid())
			return m_bookmarksManager.bookmarks().children().count();

		BookmarkNode item = cast(BookmarkNode) parent.internalPointer();
		return item.children().count();
	}

	QModelIndex index(int row, int column, QModelIndex parent = QModelIndex())
	{
		if (row < 0 || column < 0 || row >= rowCount(parent) || column >= columnCount(parent))
			return QModelIndex();

		// get the parent node
		BookmarkNode parentNode = node(parent);
		return createIndex(row, column, parentNode.children()[row]);
	}

	QModelIndex parent(QModelIndex index = QModelIndex())
	{
		if (!index.isValid())
			return QModelIndex();

		BookmarkNode itemNode = node(index);
		BookmarkNode parentNode = (itemNode ? itemNode.parent() : 0);
		if (!parentNode || parentNode == m_bookmarksManager.bookmarks())
			return QModelIndex();

		// get the parent's row
		BookmarkNode grandParentNode = parentNode.parent();
		int parentRow = grandParentNode.children().indexOf(parentNode);
		assert(parentRow >= 0);
		return createIndex(parentRow, 0, parentNode);
	}

	Qt.ItemFlags flags(QModelIndex index)
	{
		if (!index.isValid())
			return Qt.NoItemFlags;

		Qt.ItemFlags flags = Qt.ItemIsSelectable | Qt.ItemIsEnabled;

		BookmarkNode bookmarkNode = node(index);

		if (bookmarkNode != m_bookmarksManager.menu() && bookmarkNode != m_bookmarksManager.toolbar()) {
			flags |= Qt.ItemIsDragEnabled;
			if (bookmarkNode.type() != BookmarkNode.Separator)
				flags |= Qt.ItemIsEditable;
		}
		if (hasChildren(index))
			flags |= Qt.ItemIsDropEnabled;
		return flags;
	}

	Qt.DropActions supportedDropActions()
	{
		return Qt.CopyAction | Qt.MoveAction;
	}

	bool removeRows(int row, int count, QModelIndex parent = QModelIndex())
	{
		if (row < 0 || count <= 0 || row + count > rowCount(parent))
			return false;

		BookmarkNode bookmarkNode = node(parent);
		for (int i = row + count - 1; i >= row; --i) {
			BookmarkNode node = bookmarkNode.children()[i];
			if (node == m_bookmarksManager.menu() || node == m_bookmarksManager.toolbar())
				continue;

			m_bookmarksManager.removeBookmark(node);
		}
		if (m_endMacro) {
			m_bookmarksManager.undoRedoStack().endMacro();
			m_endMacro = false;
		}
		return true;
	}
    
	bool setData(QModelIndex index, QVariant value, int role = Qt.EditRole)
	{
		if (!index.isValid() || (flags(index) & Qt.ItemIsEditable) == 0)
			return false;

		BookmarkNode item = node(index);

		switch (role) {
			case Qt.EditRole:
			case Qt.DisplayRole:
				if (index.column() == 0) {
					m_bookmarksManager.setTitle(item, value.toString());
					break;
				}
				if (index.column() == 1) {
					m_bookmarksManager.setUrl(item, value.toString());
					break;
				}
				return false;
			case BookmarksModel.UrlRole:
				m_bookmarksManager.setUrl(item, value.toUrl().toString());
				break;
			case BookmarksModel.UrlStringRole:
				m_bookmarksManager.setUrl(item, value.toString());
				break;
			default:
				break;
				return false;
		}

		return true;
	}

	QMimeData mimeData(QModelIndexList indexes)
	{
		QMimeData mimeData = new QMimeData();
		QByteArray data;
		auto stream = new QDataStream(&data, QIODevice.WriteOnly);
		foreach (QModelIndex index; indexes) {
			if (index.column() != 0 || !index.isValid())
				continue;
			QByteArray encodedData;
			auto buffer = new QBuffer(&encodedData);
			buffer.open(QBuffer.ReadWrite);
			XbelWriter writer;
			const BookmarkNode parentNode = node(index);
			writer.write(&buffer, parentNode);
			stream << encodedData;
		}
		mimeData.setData(MIMETYPE, data);
		return mimeData;
	}

	const string MIMETYPE = QLatin1String("application/bookmarks.xbel");

	string[] mimeTypes()
	{
		return [ MIMETYPE ];
	}

	bool dropMimeData(QMimeData data,  Qt.DropAction action, int row, int column, QModelIndex parent)
	{
		if (action == Qt.IgnoreAction)
			return true;

		if (!data.hasFormat(MIMETYPE) || column > 0)
			return false;

		QByteArray ba = data.data(MIMETYPE);
		QDataStream stream = new QDataStream(&ba, QIODevice.ReadOnly);
		if (stream.atEnd())
			return false;

		QUndoStack undoStack = m_bookmarksManager.undoRedoStack();
		undoStack.beginMacro(QLatin1String("Move Bookmarks"));

		while (!stream.atEnd()) {
			QByteArray encodedData;
			stream >> encodedData;
			QBuffer buffer = new QBuffer(&encodedData);
			buffer.open(QBuffer.ReadOnly);

			XbelReader reader;
			BookmarkNode rootNode = reader.read(&buffer);
			BookmarkNode[] children = rootNode.children();
			for (int i = 0; i < children.count(); ++i) {
				BookmarkNode bookmarkNode = children[i];
				rootNode.remove(bookmarkNode);
				row = qMax(0, row);
				BookmarkNode parentNode = node(parent);
				m_bookmarksManager.addBookmark(parentNode, bookmarkNode, row);
				m_endMacro = true;
			}
			delete rootNode;
		}
		return true;
	}

	bool hasChildren(QModelIndex parent = QModelIndex())
	{
		if (!parent.isValid())
			return true;
		const BookmarkNode parentNode = node(parent);
		return (parentNode.type() == BookmarkNode.Folder);
	}

	BookmarkNode node(QModelIndex index)
	{
		BookmarkNode itemNode = cast(BookmarkNode) index.internalPointer();
		if (!itemNode)
			return m_bookmarksManager.bookmarks();
		return itemNode;
	}

	QModelIndex index(BookmarkNode node)
	{
		BookmarkNode parent = node.parent();
		if (!parent)
			return QModelIndex();
		return createIndex(parent.children().indexOf(node), 0, node);
	}

private:

	bool m_endMacro;
	BookmarksManager m_bookmarksManager;
}

// Menu that is dynamically populated from the bookmarks
import modelmenu;

class BookmarksMenu : public ModelMenu
{
	mixin Signal!("openUrl", QUrl /*url*/);

public:

	this(QWidget parent = null)
	{
		super(parent);	
		m_bookmarksManager = 0;
		this.activated.connect(&this.activated);
		setMaxRows(-1);
		setHoverRole(BookmarksModel.UrlStringRole);
		setSeparatorRole(BookmarksModel.SeparatorRole);
	}
	
	void setInitialActions(QAction[] actions)
	{
		m_initialActions = actions;
		for (int i = 0; i < m_initialActions.count(); ++i)
			addAction(m_initialActions[i]);
	}

protected:

	bool prePopulated()
	{
		m_bookmarksManager = BrowserApplication.bookmarksManager();
		setModel(m_bookmarksManager.bookmarksModel());
		setRootIndex(m_bookmarksManager.bookmarksModel().index(1, 0));
		// initial actions
		for (int i = 0; i < m_initialActions.count(); ++i)
			addAction(m_initialActions[i]);
		if (!m_initialActions.isEmpty())
			addSeparator();
		createMenu(model().index(0, 0), 1, this);
		return true;
	}

private:

	void activated(QModelIndex index)
	{
		openUrl.emit(index.data(BookmarksModel.UrlRole).toUrl());
	}

private:

	BookmarksManager m_bookmarksManager;
	QAction[] m_initialActions;
}

/*
    Proxy model that filters out the bookmarks so only the folders
    are left behind.  Used in the add bookmark dialog combobox.
 */
import qt.gui.QSortFilterProxyModel;

class AddBookmarkProxyModel : public QSortFilterProxyModel
{
public:

	this(QObject  parent = null)
	{
		super(parent);
	}
	
	int columnCount(QModelIndex  parent = QModelIndex())
	{
		return qMin(1, QSortFilterProxyModel.columnCount(parent));
	}

	protected:

	bool filterAcceptsRow(int source_row, QModelIndex source_parent)
	{
		QModelIndex idx = sourceModel().index(source_row, 0, source_parent);
		return sourceModel().hasChildren(idx);
	}
}

/*!
Add bookmark dialog
*/

import ui_addbookmarkdialog;

class AddBookmarkDialog : public QDialog, public Ui_AddBookmarkDialog
{
public:

	this(string url, string title, QWidget parent = null, BookmarksManager bookmarkManager = null)
	//: QDialog(parent)
	{
		m_url = url;
		m_bookmarksManager = bookmarkManager;

		setWindowFlags(Qt.Sheet);
		if (!m_bookmarksManager)
			m_bookmarksManager = BrowserApplication.bookmarksManager();
		setupUi(this);
		QTreeView view = new QTreeView(this);
		m_proxyModel = new AddBookmarkProxyModel(this);
		BookmarksModel model = m_bookmarksManager.bookmarksModel();
		m_proxyModel.setSourceModel(model);
		view.setModel(m_proxyModel);
		view.expandAll();
		view.header().setStretchLastSection(true);
		view.header().hide();
		view.setItemsExpandable(false);
		view.setRootIsDecorated(false);
		view.setIndentation(10);
		location.setModel(m_proxyModel);
		view.show();
		location.setView(view);
		BookmarkNode menu = m_bookmarksManager.menu();
		QModelIndex idx = m_proxyModel.mapFromSource(model.index(menu));
		view.setCurrentIndex(idx);
		location.setCurrentIndex(idx.row());
		name.setText(title);
	}

private:
	
	void accept()
	{
		QModelIndex index = location.view().currentIndex();
		index = m_proxyModel.mapToSource(index);
		if (!index.isValid())
			index = m_bookmarksManager.bookmarksModel().index(0, 0);
		BookmarkNode parent = m_bookmarksManager.bookmarksModel().node(index);
		BookmarkNode bookmark = new BookmarkNode(BookmarkNode.Bookmark);
		bookmark.url = m_url;
		bookmark.title = name.text();
		m_bookmarksManager.addBookmark(parent, bookmark);
		QDialog.accept();
	}

private:

	string m_url;
	BookmarksManager m_bookmarksManager;
	AddBookmarkProxyModel m_proxyModel;
}

import ui_bookmarks;

//class TreeProxyModel;
class BookmarksDialog : public QDialog, public Ui_BookmarksDialog
{
	mixin Signal!("openUrl", QUrl /*url*/);

public:

	this(QWidget parent = null, BookmarksManager manager = null)
	//: QDialog(parent)
	{
		m_bookmarksManager = manager;
		if (!m_bookmarksManager)
			m_bookmarksManager = BrowserApplication.bookmarksManager();
		setupUi(this);

		tree.setUniformRowHeights(true);
		tree.setSelectionBehavior(QAbstractItemView.SelectRows);
		tree.setSelectionMode(QAbstractItemView.ContiguousSelection);
		tree.setTextElideMode(Qt.ElideMiddle);
		m_bookmarksModel = m_bookmarksManager.bookmarksModel();
		m_proxyModel = new TreeProxyModel(this);
		search.textChanged.connect(&m_proxyModel.setFilterFixedString);
		removeButton.clicked.connect(&tree.removeOne);
		m_proxyModel.setSourceModel(m_bookmarksModel);
		tree.setModel(m_proxyModel);
		tree.setDragDropMode(QAbstractItemView.InternalMove);
		tree.setExpanded(m_proxyModel.index(0, 0), true);
		tree.setAlternatingRowColors(true);
		auto fm = new QFontMetrics(font());
		int header = fm.width(QLatin1Char('m')) * 40;
		tree.header().resizeSection(0, header);
		tree.header().setStretchLastSection(true);
		tree.activated.connect(&this.open);
		tree.setContextMenuPolicy(Qt.CustomContextMenu);
		tree.customContextMenuRequested.connect(&this.customContextMenuRequested);
		addFolderButton.clicked.connect(&this.newFolder);
		expandNodes(m_bookmarksManager.bookmarks());
		setAttribute(Qt.WA_DeleteOnClose);
	}
	
	~this()
	{
		if (saveExpandedNodes(tree.rootIndex()))
			m_bookmarksManager.changeExpanded();
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
		}
		menu.addAction(tr("Delete"), tree, SLOT(removeOne()));
		menu.exec(QCursor.pos());
	}
	
	void open()
	{
		QModelIndex index = tree.currentIndex();
		if (!index.parent().isValid())
			return;
		openUrl.emit(index.sibling(index.row(), 1).data(BookmarksModel.UrlRole).toUrl());
	}

	void newFolder()
	{
		QModelIndex currentIndex = tree.currentIndex();
		QModelIndex idx = currentIndex;
		if (idx.isValid() && !idx.model().hasChildren(idx))
			idx = idx.parent();
		if (!idx.isValid())
			idx = tree.rootIndex();
		idx = m_proxyModel.mapToSource(idx);
		BookmarkNode parent = m_bookmarksManager.bookmarksModel().node(idx);
		BookmarkNode node = new BookmarkNode(BookmarkNode.Folder);
		node.title = tr("New Folder");
		m_bookmarksManager.addBookmark(parent, node, currentIndex.row() + 1);
	}

private:
	void expandNodes(BookmarkNode node)
	{
		for (int i = 0; i < node.children().count(); ++i) {
			BookmarkNode childNode = node.children()[i];
			if (childNode.expanded) {
				QModelIndex idx = m_bookmarksModel.index(childNode);
				idx = m_proxyModel.mapFromSource(idx);
				tree.setExpanded(idx, true);
				expandNodes(childNode);
			}
		}
	}

	bool saveExpandedNodes(QModelIndex parent)
	{
		bool changed = false;
		for (int i = 0; i < m_proxyModel.rowCount(parent); ++i) {
			QModelIndex child = m_proxyModel.index(i, 0, parent);
			QModelIndex sourceIndex = m_proxyModel.mapToSource(child);
			BookmarkNode childNode = m_bookmarksModel.node(sourceIndex);
			bool wasExpanded = childNode.expanded;
			if (tree.isExpanded(child)) {
				childNode.expanded = true;
				changed |= saveExpandedNodes(child);
			} else {
				childNode.expanded = false;
			}
			changed |= (wasExpanded != childNode.expanded);
		}
		return changed;
	}

	BookmarksManager m_bookmarksManager;
	BookmarksModel m_bookmarksModel;
	TreeProxyModel m_proxyModel;
}


import qt.gui.QToolBar;


class BookmarksToolBar : public QToolBar
{
mixin Signal!("openUrl", QUrl /*url*/);

public:

	this(BookmarksModel model, QWidget parent = null)
	{
		super(tr("Bookmark"), parent);
		m_bookmarksModel = model;
		this.actionTriggered.connect(&this.triggered);
		setRootIndex(model.index(0, 0));
		m_bookmarksModel.modelReset.connect(&this.build);
		m_bookmarksModel.rowsInserted.connect(&this.build);
		m_bookmarksModel.rowsRemoved.connect(&this.build);
		m_bookmarksModel.dataChanged.connect(&this.build);
		setAcceptDrops(true);
	}

	void setRootIndex(QModelIndex index)
	{
		m_root = index;
		build();
	}

	QModelIndex rootIndex()
	{
		return m_root;
	}

protected:

	void dragEnterEvent(QDragEnterEvent event)
	{
		QMimeData mimeData = event.mimeData();
		if (mimeData.hasUrls())
			event.acceptProposedAction();
		QToolBar.dragEnterEvent(event);
	}

	void dropEvent(QDropEvent event)
	{
		QMimeData mimeData = event.mimeData();
		if (mimeData.hasUrls() && mimeData.hasText()) {
			QUrl[] urls = mimeData.urls();
			QAction action = actionAt(event.pos());
			string dropText;
			if (action)
				dropText = action.text();
			int row = -1;
			QModelIndex parentIndex = m_root;
			for (int i = 0; i < m_bookmarksModel.rowCount(m_root); ++i) {
				QModelIndex idx = m_bookmarksModel.index(i, 0, m_root);
				string title = idx.data().toString();
				if (title == dropText) {
					row = i;
					if (m_bookmarksModel.hasChildren(idx)) {
						parentIndex = idx;
						row = -1;
					}
					break;
				}
			}
			BookmarkNode bookmark = new BookmarkNode(BookmarkNode.Bookmark);
			bookmark.url = urls[0].toString();
			bookmark.title = mimeData.text();

			BookmarkNode parent = m_bookmarksModel.node(parentIndex);
			BookmarksManager bookmarksManager = m_bookmarksModel.bookmarksManager();
			bookmarksManager.addBookmark(parent, bookmark, row);
			event.acceptProposedAction();
		}
		QToolBar.dropEvent(event);
	}

private:

	void triggered(QAction action)
	{
		QVariant v = action.data();
		if (v.canConvert!(QUrl)()) {
			openUrl.emit(v.toUrl());
		}
	}

	void activated(QModelIndex index)
	{
		openUrl.emit(index.data(BookmarksModel.UrlRole).toUrl());
	}

	void build()
	{
		clear();
		for (int i = 0; i < m_bookmarksModel.rowCount(m_root); ++i) {
			QModelIndex idx = m_bookmarksModel.index(i, 0, m_root);
			if (m_bookmarksModel.hasChildren(idx)) {
				QToolButton button = new QToolButton(this);
				button.setPopupMode(QToolButton.InstantPopup);
				button.setArrowType(Qt.DownArrow);
				button.setText(idx.data().toString());
				ModelMenu menu = new ModelMenu(this);
				menu.activated.connect(&this.activated);
				menu.setModel(m_bookmarksModel);
				menu.setRootIndex(idx);
				menu.addAction(new QAction(menu));
				button.setMenu(menu);
				button.setToolButtonStyle(Qt.ToolButtonTextOnly);
				QAction a = addWidget(button);
				a.setText(idx.data().toString());
			} else {
				QAction action = addAction(idx.data().toString());
				action.setData(idx.data(BookmarksModel.UrlRole));
			}
		}
	}

private:

	BookmarksModel m_bookmarksModel;
	QPersistentModelIndex m_root;
}
