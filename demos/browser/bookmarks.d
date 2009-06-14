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
import qt.core.QBuffer;
import qt.core.QFile;
import qt.core.QMimeData;
import qt.core.QPersistentModelIndex;
import qt.gui.QUndoStack;
import qt.gui.QUndoCommand;
import qt.gui.QDesktopServices;
import qt.gui.QDragEnterEvent;
import qt.gui.QFileDialog;
import qt.gui.QHeaderView;
import qt.gui.QIcon;
import qt.gui.QMessageBox;
import qt.gui.QToolButton;
import qt.gui.QTreeView;
import qt.xml.QXmlStreamReader;
import qt.webkit.QWebSettings;

import tango.text.convert.Format;

//import qt.core.QDebug;

import autosaver;
import browserapplication;
import history;
import xbel;


const string BOOKMARKBAR = "Bookmarks Bar";
const string BOOKMARKMENU = "Bookmarks Menu";

// workaround for QList implementation
int indexOf(T)(T[] items, T item)
{
	for(auto i = 0; i < items.length; ++i)
	{
		if(items[i] == item)
			return i;
	}
	return -1;
}

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
		int row = indexOf(parent.children(), node);
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

		for (int i = m_bookmarkRootNode.children().length - 1; i >= 0; --i) {
			BookmarkNode node = m_bookmarkRootNode.children()[i];
			if (node.title == tr(BOOKMARKMENU))
				return node;
		}
		assert(false);
		return null;
	}

	BookmarkNode toolbar()
	{
		if (!m_loaded)
			load();

		for (int i = m_bookmarkRootNode.children().length - 1; i >= 0; --i) {
			BookmarkNode node = m_bookmarkRootNode.children()[i];
			if (node.title == tr(BOOKMARKBAR))
				return node;
		}
		assert(false);
		return null;
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
		string fileName = QFileDialog.getOpenFileName(null, tr("Open File"), null, tr("XBEL (*.xbel *.xml)"));
		if (fileName.length == 0)
			return;

		auto reader = new XbelReader;
		BookmarkNode importRootNode = reader.read(fileName);
		if (reader.error() != QXmlStreamReader.NoError) {
			QMessageBox.warning(null, "Loading Bookmark",
				Format(tr("Error when loading bookmarks on line %1, column %2:\n"
				"%3"), reader.lineNumber(), reader.columnNumber(), reader.errorString()));
		}

		importRootNode.setType(BookmarkNode.Type.Folder);
		importRootNode.title = Format(tr("Imported %1"), QDate.currentDate().toString(Qt_DateFormat.SystemLocaleShortDate));
		addBookmark(menu(), importRootNode);
	}

	void exportBookmarks()
	{
		string fileName = QFileDialog.getSaveFileName(null, tr("Save File"),
				Format(tr("%1 Bookmarks.xbel"), QCoreApplication.applicationName()),
				tr("XBEL (*.xbel *.xml)"));
		if (fileName.length == 0)
			return;

		auto writer = new XbelWriter;
		if (!writer.write(fileName, m_bookmarkRootNode))
			QMessageBox.critical(null, tr("Export error"), tr("error saving bookmarks"));
	}

private:

	void save()
	{
		if (!m_loaded)
			return;

		auto writer = new XbelWriter;
		string dir = QDesktopServices.storageLocation(QDesktopServices.DataLocation);
		string bookmarkFile = dir ~ "/bookmarks.xbel";
		if (!writer.write(bookmarkFile, m_bookmarkRootNode))
			qWarning("BookmarkManager: error saving to" ~ bookmarkFile);
	}

private:
	
	void load()
	{
		if (m_loaded)
			return;
		m_loaded = true;

		string dir = QDesktopServices.storageLocation(QDesktopServices.DataLocation);
		string bookmarkFile = dir ~ "/bookmarks.xbel";
		if (!QFile.exists(bookmarkFile))
			bookmarkFile = ":defaultbookmarks.xbel";

		XbelReader reader;
		m_bookmarkRootNode = reader.read(bookmarkFile);
		if (reader.error() != QXmlStreamReader.NoError) {
			QMessageBox.warning(null, "Loading Bookmark",
			Format(tr("Error when loading bookmarks on line %1, column %2:\n"
			"%3"), reader.lineNumber(), reader.columnNumber(), reader.errorString()));
		}

		BookmarkNode toolbar = null;
		BookmarkNode menu = null;
		BookmarkNode[] others;
		for (int i = m_bookmarkRootNode.children().length - 1; i >= 0; --i) {
			BookmarkNode node = m_bookmarkRootNode.children()[i];
			if (node.type() == BookmarkNode.Type.Folder) {
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
		assert(m_bookmarkRootNode.children().length == 0);
		if (!toolbar) {
			toolbar = new BookmarkNode(BookmarkNode.Type.Folder, m_bookmarkRootNode);
			toolbar.title = tr(BOOKMARKBAR);
		} else {
			m_bookmarkRootNode.add(toolbar);
		}

		if (!menu) {
			menu = new BookmarkNode(BookmarkNode.Type.Folder, m_bookmarkRootNode);
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

	this(BookmarksManager m_bookmarkManager, BookmarkNode parent, int row)
	{
		super(tr("Remove Bookmark"));
		m_row = row;
		m_bookmarkManager = m_bookmarkManager;
		m_node = (row < parent.children().length) ? parent.children()[row] : null;
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
		m_bookmarkManager.entryAdded.emit(m_node);
		m_done = false;
	}

	void redo()
	{
		m_parent.remove(m_node);
		m_bookmarkManager.entryRemoved.emit(m_parent, m_row, m_node);
		m_done = true;
	}

protected:

	int m_row;
	BookmarksManager m_bookmarkManager;
	BookmarkNode m_node;
	BookmarkNode m_parent;
	bool m_done;
}

class InsertBookmarksCommand : public RemoveBookmarksCommand
{
public:

	this(BookmarksManager m_bookmarkManager, BookmarkNode parent, BookmarkNode node, int row)
	{
		super(m_bookmarkManager, parent, row);

		setText(tr("Insert Bookmark"));
		m_node = node;
	}

	void undo() { RemoveBookmarksCommand.redo(); }
	void redo() { RemoveBookmarksCommand.undo(); }
}

class ChangeBookmarkCommand : public QUndoCommand
{
public:

	this(BookmarksManager m_bookmarkManager, BookmarkNode node, string newValue, bool title)
	{
		super();
		m_bookmarkManager = m_bookmarkManager;
		m_title = title;
		m_newValue = newValue;
		m_node = node;
		if (m_title) {
			m_oldValue = m_node.title;
			setText(tr("Name Change"));
		} else {
			m_oldValue = m_node.url;
			setText(tr("Address Change"));
		}
	}

	void undo()
	{
		if (m_title)
			m_node.title = m_oldValue;
		else
			m_node.url = m_oldValue;
		m_bookmarkManager.entryChanged.emit(m_node);
	}

	void redo()
	{
		if (m_title)
			m_node.title = m_newValue;
		else
			m_node.url = m_newValue;
		m_bookmarkManager.entryChanged.emit(m_node);
	}

private:
	
	BookmarksManager m_bookmarkManager;
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
		int row = indexOf(item.parent().children(), item);
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
				case 0: return new QVariant(tr("Title"));
				case 1: return QVariant(tr("Address"));
			}
		}
		return QAbstractItemModel.headerData(section, orientation, role);
	}
    
	QVariant data(QModelIndex index, int role = Qt.DisplayRole)
	{
		if (!index.isValid() || index.model() != this)
			return new QVariant();

		BookmarkNode bookmarkNode = node(index);
		switch (role) {
			case Qt_ItemDataRole.EditRole:
			case Qt_ItemDataRole.DisplayRole:
				if (bookmarkNode.type() == BookmarkNode.Type.Separator) {
					switch (index.column()) {
						case 0:
							char[] tmp = new char[](50);
							tmp[] = 0xB7;
							return new QVariant(tmp);
						case 1: return null;
					}
				}

				switch (index.column()) {
					case 0: return new QVariant(bookmarkNode.title);
					case 1: return new QVariant(bookmarkNode.url);
				}
				break;
			case BookmarksModel.Roles.UrlRole:
				return new QVariant(new QUrl(bookmarkNode.url));
				break;
			case BookmarksModel.Roles.UrlStringRole:
				return new QVariant(bookmarkNode.url);
				break;
			case BookmarksModel.Roles.TypeRole:
				return new QVariant(cast(ulong) bookmarkNode.type());
				break;
			case BookmarksModel.Roles.SeparatorRole:
				return new QVariant(bookmarkNode.type() == BookmarkNode.Type.Separator);
				break;
			case Qt_ItemDataRole.DecorationRole:
				if (index.column() == 0) {
					//TODO: is cast(void*) ok?
					if (bookmarkNode.type() == BookmarkNode.Type.Folder)
						return new QVariant(cast(void*) QApplication.style().standardIcon(QStyle.SP_DirIcon));
					return new QVariant(cast(void*) BrowserApplication.instance().icon(new QUrl(bookmarkNode.url)));
				}
		}

		return new QVariant();
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
			return m_bookmarksManager.bookmarks().children().length;

		BookmarkNode item = cast(BookmarkNode) parent.internalPointer();
		return item.children().length;
	}

	QModelIndex index(int row, int column, QModelIndex parent = QModelIndex())
	{
		if (row < 0 || column < 0 || row >= rowCount(parent) || column >= columnCount(parent))
			return QModelIndex();

		// get the parent node
		BookmarkNode parentNode = node(parent);
		return createIndex(row, column, cast(void*) parentNode.children()[row]);
	}

	QModelIndex parent(QModelIndex index = QModelIndex())
	{
		if (!index.isValid())
			return QModelIndex();

		BookmarkNode itemNode = node(index);
		BookmarkNode parentNode = (itemNode ? itemNode.parent() : null);
		if (!parentNode || parentNode == m_bookmarksManager.bookmarks())
			return QModelIndex();

		// get the parent's row
		BookmarkNode grandParentNode = parentNode.parent();
		int parentRow = grandParentNode.children().indexOf(parentNode);
		assert(parentRow >= 0);
		return createIndex(parentRow, 0, cast(void*) parentNode);
	}

	int flags(QModelIndex index)
	{
		if (!index.isValid())
			return Qt.NoItemFlags;

		int flags = Qt_ItemFlag.ItemIsSelectable | Qt_ItemFlag.ItemIsEnabled;

		BookmarkNode bookmarkNode = node(index);

		if (bookmarkNode != m_bookmarksManager.menu() && bookmarkNode != m_bookmarksManager.toolbar()) {
			flags |= Qt_ItemFlag.ItemIsDragEnabled;
			if (bookmarkNode.type() != BookmarkNode.Type.Separator)
				flags |= Qt_ItemFlag.ItemIsEditable;
		}
		if (hasChildren(index))
			flags |= Qt_ItemFlag.ItemIsDropEnabled;
		return flags;
	}

	int supportedDropActions()
	{
		return Qt_DropAction.CopyAction | Qt_DropAction.MoveAction;
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
    
	bool setData(QModelIndex index, QVariant value, int role = Qt_ItemDataRole.EditRole)
	{
		if (!index.isValid() || (flags(index) & Qt_ItemFlag.ItemIsEditable) == 0)
			return false;

		BookmarkNode item = node(index);

		switch (role) {
			case Qt_ItemDataRole.EditRole:
			case Qt_ItemDataRole.DisplayRole:
				if (index.column() == 0) {
					m_bookmarksManager.setTitle(item, value.toString());
					break;
				}
				if (index.column() == 1) {
					m_bookmarksManager.setUrl(item, value.toString());
					break;
				}
				return false;
			case BookmarksModel.Roles.UrlRole:
				m_bookmarksManager.setUrl(item, value.toUrl().toString());
				break;
			case BookmarksModel.Roles.UrlStringRole:
				m_bookmarksManager.setUrl(item, value.toString());
				break;
			default:
				break;
				return false;
		}

		return true;
	}

	QMimeData mimeData(QModelIndex[] indexes)
	{
		auto mimeData = new QMimeData();
		auto data = new QByteArray;
		auto stream = new QDataStream(data, QIODevice.WriteOnly);
		foreach (QModelIndex index; indexes) {
			if (index.column() != 0 || !index.isValid())
				continue;
			auto encodedData = new QByteArray;
			auto buffer = new QBuffer(encodedData);
			buffer.open(QBuffer.ReadWrite);
			auto writer = new XbelWriter;
			BookmarkNode parentNode = node(index);
			writer.write(buffer, parentNode);
			foreach(b; encodedData.data()[0..encodedData.size()])
				stream.writeByte(cast(byte) b);
		}
		mimeData.setData(MIMETYPE, data);
		return mimeData;
	}

	const string MIMETYPE = "application/bookmarks.xbel";

	string[] mimeTypes()
	{
		return [ MIMETYPE ];
	}

	bool dropMimeData(QMimeData data,  Qt_DropAction action, int row, int column, QModelIndex parent)
	{
		if (action == Qt_DropAction.IgnoreAction)
			return true;

		if (!data.hasFormat(MIMETYPE) || column > 0)
			return false;

		QByteArray ba = data.data(MIMETYPE);
		QDataStream stream = new QDataStream(ba, QIODevice.ReadOnly);
		if (stream.atEnd())
			return false;

		QUndoStack undoStack = m_bookmarksManager.undoRedoStack();
		undoStack.beginMacro("Move Bookmarks");

		while (!stream.atEnd()) {
			auto encodedData = new QByteArray;
			//stream >> encodedData; //TODO
			
			auto buffer = new QBuffer(encodedData);
			buffer.open(QBuffer.ReadOnly);

			auto reader = new XbelReader;
			BookmarkNode rootNode = reader.read(buffer);
			BookmarkNode[] children = rootNode.children();
			for (int i = 0; i < children.length; ++i) {
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
		BookmarkNode parentNode = node(parent);
		return (parentNode.type() == BookmarkNode.Type.Folder);
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
		return createIndex(indexOf(parent.children(), node), 0, cast(void*) node);
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
		m_bookmarksManager = null;
		this.activated.connect(&this.activatedIndex);
		setMaxRows(-1);
		setHoverRole(BookmarksModel.Roles.UrlStringRole);
		setSeparatorRole(BookmarksModel.Roles.SeparatorRole);
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
		m_bookmarksManager = BrowserApplication.bookmarksManager();
		setModel(m_bookmarksManager.bookmarksModel());
		setRootIndex(m_bookmarksManager.bookmarksModel().index(1, 0));
		// initial actions
		for (int i = 0; i < m_initialActions.length; ++i)
			addAction(m_initialActions[i]);
		if (m_initialActions.length)
			addSeparator();
		createMenu(model().index(0, 0), 1, this);
		return true;
	}

private:

	void activatedIndex(QModelIndex index)
	{
		openUrl.emit(index.data(BookmarksModel.Roles.UrlRole).toUrl());
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

class AddBookmarkDialog : public QDialog //, public Ui_AddBookmarkDialog
{
	mixin Ui_AddBookmarkDialog;
	
public:

	this(string url, string title, QWidget parent = null, BookmarksManager bookmarkManager = null)
	{
		super(parent);
		m_url = url;
		m_bookmarksManager = bookmarkManager;

		setWindowFlags(Qt.Sheet);
		if (!m_bookmarksManager)
			m_bookmarksManager = BrowserApplication.bookmarksManager();
		setupUi(this);
		auto view = new QTreeView(this);
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
		BookmarkNode bookmark = new BookmarkNode(BookmarkNode.Type.Bookmark);
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

import ui_bookmarksdialog;

//class TreeProxyModel;
class BookmarksDialog : public QDialog //, public Ui_BookmarksDialog
{
	mixin Ui_BookmarksDialog;
	
	mixin Signal!("openUrl", QUrl /*url*/);

public:

	this(QWidget parent = null, BookmarksManager manager = null)
	{
		super(parent);
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
		int header = fm.width("m") * 40;
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
			auto action = new QAction(tr("Open"), this);
			action.triggered.connect(&this.open);
			menu.addAction(action);
			menu.addSeparator();
		}
		auto action = new QAction(tr("Delete"), this);
		action.triggered.connect(&tree.removeOne);
		menu.addAction(action);
		menu.exec(QCursor.pos());
	}
	
	void open()
	{
		QModelIndex index = tree.currentIndex();
		if (!index.parent().isValid())
			return;
		openUrl.emit(index.sibling(index.row(), 1).data(BookmarksModel.Roles.UrlRole).toUrl());
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
		BookmarkNode node = new BookmarkNode(BookmarkNode.Type.Folder);
		node.title = tr("New Folder");
		m_bookmarksManager.addBookmark(parent, node, currentIndex.row() + 1);
	}

private:
	void expandNodes(BookmarkNode node)
	{
		for (int i = 0; i < node.children().length; ++i) {
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
		super.dragEnterEvent(event);
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
			BookmarkNode bookmark = new BookmarkNode(BookmarkNode.Type.Bookmark);
			bookmark.url = urls[0].toString();
			bookmark.title = mimeData.text();

			BookmarkNode parent = m_bookmarksModel.node(parentIndex);
			BookmarksManager bookmarksManager = m_bookmarksModel.bookmarksManager();
			bookmarksManager.addBookmark(parent, bookmark, row);
			event.acceptProposedAction();
		}
		super.dropEvent(event);
	}

private:

	void triggered(QAction action)
	{
		QVariant v = action.data();
		if (v.canConvert!(QUrl)) {
			openUrl.emit(v.toUrl());
		}
	}

	void activated(QModelIndex index)
	{
		openUrl.emit(index.data(BookmarksModel.Roles.UrlRole).toUrl());
	}

	void build()
	{
		clear();
		for (int i = 0; i < m_bookmarksModel.rowCount(m_root); ++i) {
			QModelIndex idx = m_bookmarksModel.index(i, 0, m_root);
			if (m_bookmarksModel.hasChildren(idx)) {
				QToolButton button = new QToolButton(this);
				button.setPopupMode(QToolButton.InstantPopup);
				button.setArrowType(Qt_ArrowType.DownArrow);
				button.setText(idx.data().toString());
				ModelMenu menu = new ModelMenu(this);
				menu.activated.connect(&this.activated);
				menu.setModel(m_bookmarksModel);
				menu.setRootIndex(idx);
				menu.addAction(new QAction(menu));
				button.setMenu(menu);
				button.setToolButtonStyle(Qt_ToolButtonStyle.ToolButtonTextOnly);
				QAction a = addWidget(button);
				a.setText(idx.data().toString());
			} else {
				QAction action = addAction(idx.data().toString());
				action.setData(idx.data(BookmarksModel.Roles.UrlRole));
			}
		}
	}

private:

	BookmarksModel m_bookmarksModel;
	/*TODO: needed? QPersistentModelIndex*/ QModelIndex m_root;
}
