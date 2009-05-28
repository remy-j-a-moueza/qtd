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

module tabwidget;

import qt.gui.QTabBar;
import qt.gui.QShortcut;
import qt.gui.QClipboard;
import qt.gui.QCompleter;
import qt.gui.QListView;
import qt.gui.QMenu;
import qt.gui.QMessageBox;
import qt.gui.QMouseEvent;
import qt.gui.QStackedWidget;
import qt.gui.QStyle;
import qt.gui.QToolButton;
import qt.gui.QLineEdit;

//import qt.core.QDebug;

import browserapplication;
import browsermainwindow;
import history;
import urllineedit;
import webview;

/*
Tab bar with a few more features such as a context menu and shortcuts
 */
class TabBar : public QTabBar
{
	mixin Signal!("newTab");
	mixin Signal!("cloneTab", int /*index*);
	mixin Signal!("closeTab", int index*/);
	mixin Signal!("closeOtherTabs", int /*index*/);
	mixin Signal!("reloadTab", int /*index*/);
	mixin Signal!("reloadAllTabs");
	mixin Signal!("tabMoveRequested", int /*fromIndex*/, int /*toIndex*/);

public:

	this(QWidget parent = null)
	{
		super(parent);
		setContextMenuPolicy(Qt.CustomContextMenu);
		setAcceptDrops(true);
		this.customContextMenuRequested.connect(&this.contextMenuRequested);

		string alt = "Alt+%1";
		for (int i = 1; i <= 10; ++i) {
			int key = i;
			if (key == 10)
				key = 0;
			QShortcut shortCut = new QShortcut(alt.arg(key), this);
			m_tabShortcuts ~= shortCut;
			shortCut.activated.connect(&this.selectTabAction);
		}
		setTabsClosable(true);
		this.tabCloseRequested.connect(&this.closeTab);
		setSelectionBehaviorOnRemove(QTabBar.SelectPreviousTab);
		setMovable(true);
	}

protected:

	void mousePressEvent(QMouseEvent event)
	{
		if (event.button() == Qt.LeftButton)
			m_dragStartPos = event.pos();
		QTabBar.mousePressEvent(event);
	}

	void mouseMoveEvent(QMouseEvent event)
	{
		if (event.buttons() == Qt.LeftButton) {
			int diffX = event.pos().x() - m_dragStartPos.x();
			int diffY = event.pos().y() - m_dragStartPos.y();
			if ((event.pos() - m_dragStartPos).manhattanLength() > QApplication.startDragDistance() && diffX < 3 && diffX > -3 && diffY < -10) {
				QDrag drag = new QDrag(this);
				QMimeData mimeData = new QMimeData;
				QUrl[] urls;
				int index = tabAt(event.pos());
				QUrl url = tabData(index).toUrl();
				urls ~= url;
				mimeData.setUrls(urls);
				mimeData.setText(tabText(index));
				mimeData.setData("action", "tab-reordering");
				drag.setMimeData(mimeData);
				drag.exec();
			}
		}
		QTabBar.mouseMoveEvent(event);
	}

private:

	void selectTabAction()
	{
		if (QShortcut shortCut = cast(QShortcut) signalSender()) {
			int index = m_tabShortcuts.indexOf(shortCut);
			if (index == 0)
				index = 10;
			setCurrentIndex(index);
		}
	}

	void cloneTab()
	{
		if (QAction action = cast(QAction) signalSender()) {
			int index = action.data().toInt();
			cloneTab.emit(index);
		}
	}

	void closeTab()
	{
		if (QAction action = cast(QAction) signalSender()) {
			int index = action.data().toInt();
			closeTab.emit(index);
		}
	}

	void closeOtherTabs()
	{
		if (QAction action = cast(QAction) signalSender()) {
			int index = action.data().toInt();
			closeOtherTabs.emit(index);
		}
	}

	void reloadTab()
	{
		if (QAction action = cast(QAction) signalSender()) {
			int index = action.data().toInt();
			reloadTab.emit(index);
		}
	}

	void contextMenuRequested(QPoint position)
	{
		QMenu menu;
		menu.addAction(tr("New &Tab"), this, SIGNAL(newTab()), QKeySequence.AddTab);
		int index = tabAt(position);
		if (-1 != index) {
			QAction action = menu.addAction(tr("Clone Tab"), this, SLOT(cloneTab()));
			action.setData(index);

			menu.addSeparator();

			action = menu.addAction(tr("&Close Tab"), this, SLOT(closeTab()), QKeySequence.Close);
			action.setData(index);

			action = menu.addAction(tr("Close &Other Tabs"), this, SLOT(closeOtherTabs()));
			action.setData(index);

			menu.addSeparator();

			action = menu.addAction(tr("Reload Tab"), this, SLOT(reloadTab()), QKeySequence.Refresh);
			action.setData(index);
		} else {
			menu.addSeparator();
		}
		menu.addAction(tr("Reload All Tabs"), this, SIGNAL(reloadAllTabs()));
		menu.exec(QCursor.pos());
	}

private:
	
	QShortcut[] m_tabShortcuts;

	QPoint m_dragStartPos;
	int m_dragCurrentIndex;
}

import qt.webkit.QWebPage;

/*!
A proxy object that connects a single browser action
to one child webpage action at a time.

Example usage: used to keep the main window stop action in sync with
the current tabs webview's stop action.
*/
class WebActionMapper : public QObject
{
public:

	this(QAction root, QWebPage.WebAction webAction, QObject parent)
	{
		super(parent);	
		m_currentParent = 0;
		m_root = root;
		m_webAction = webAction;
		if (!m_root)
			return;
		m_root.triggered.connect(&this.rootTriggered);
		root.destroyed.connect(&this.rootDestroyed);
		root.setEnabled(false);
	}

	QWebPage.WebAction webAction()
	{
		return m_webAction;
	}

	void addChild(QAction action)
	{
		if (!action)
			return;
		action.changed.connect(&this.childChanged);
	}

	void updateCurrent(QWebPage currentParent)
	{
		if (m_currentParent)
			m_currentParent.destroyed.disconnect(&this.currentDestroyed);

		m_currentParent = currentParent;
		if (!m_root)
			return;
		if (!m_currentParent) {
			m_root.setEnabled(false);
			m_root.setChecked(false);
			return;
		}
		QAction source = m_currentParent.action(m_webAction);
		m_root.setChecked(source.isChecked());
		m_root.setEnabled(source.isEnabled());
		m_currentParent.destroyed.connect(&this.currentDestroyed);
	}

private:

	void rootTriggered()
	{
		if (m_currentParent) {
			QAction gotoAction = m_currentParent.action(m_webAction);
			gotoAction.trigger();
		}
	}

	void childChanged()
	{
		if (QAction source = cast(QAction) signalSender()) {
			if (m_root && m_currentParent && source.parent() == m_currentParent) {
					m_root.setChecked(source.isChecked());
					m_root.setEnabled(source.isEnabled());
			}
		}
	}

	void rootDestroyed()
	{
		m_root = 0;
	}
	
	void currentDestroyed()
	{
		updateCurrent(0);
	}

private:

	QWebPage m_currentParent;
	QAction m_root;
	QWebPage.WebAction m_webAction;
}


import qt.core.QUrl;
import qt.gui.QTabWidget;


/*!
TabWidget that contains WebViews and a stack widget of associated line edits.

Connects up the current tab's signals to this class's signal and uses WebActionMapper
to proxy the actions.
*/
class TabWidget : public QTabWidget
{
	// tab widget signals
	mixin Signal!("loadPage", string /*url*/);
	mixin Signal!("tabsChanged");
	mixin Signal!("lastTabClosed");

	// current tab signals
	mixin Signal!("setCurrentTitle", string /*url*/);
	mixin Signal!("showStatusBarMessage", string /*message*/);
	mixin Signal!("linkHovered", string /*link*/);
	mixin Signal!("loadProgress", int /*progress*/);
	mixin Signal!("geometryChangeRequested", QRect /*geometry*/);
	mixin Signal!("menuBarVisibilityChangeRequested", bool /*visible*/);
	mixin Signal!("statusBarVisibilityChangeRequested", bool /*visible*/);
	mixin Signal!("toolBarVisibilityChangeRequested", bool /*visible*/);
	mixin Signal!("printRequested", QWebFrame /*frame*/);

public:

	this(QWidget parent = null)
	{
		super(parent);
		m_recentlyClosedTabsAction = 0;
		m_newTabAction = 0;
		m_closeTabAction = 0;
		m_nextTabAction = 0;
		m_previousTabAction = 0;
		m_recentlyClosedTabsMenu = 0;
		m_lineEditCompleter = 0;
		m_lineEdits = 0;
		m_tabBar = new TabBar(this);

		setElideMode(Qt.ElideRight);

		m_tabBar.newTab.connect(&this.newTab);
		m_tabBar.closeTab.connect(&this.closeTab);
		m_tabBar.cloneTab.connect(&this.cloneTab);
		m_tabBar.closeOtherTabs.connect(&this.closeOtherTabs);
		m_tabBar.reloadTab.connect(&this.reloadTab);
		m_tabBar.reloadAllTabs.connect(&this.reloadAllTabs);
		m_tabBar.tabMoved.connect(&this.moveTab);
		setTabBar(m_tabBar);
		setDocumentMode(true);

		// Actions
		m_newTabAction = new QAction(new QIcon(":addtab.png"), tr("New &Tab"), this);
		m_newTabAction.setShortcuts(QKeySequence.AddTab);
		m_newTabAction.setIconVisibleInMenu(false);
		m_newTabAction.triggered.connect(&this.newTab);

		m_closeTabAction = new QAction(new QIcon(":closetab.png"), tr("&Close Tab"), this);
		m_closeTabAction.setShortcuts(QKeySequence.Close);
		m_closeTabAction.setIconVisibleInMenu(false);
		m_closeTabAction.triggered.connect(&this.closeTab);

		m_nextTabAction = new QAction(tr("Show Next Tab"), this);
		QKeySequence[] shortcuts;
		shortcuts ~= QKeySequence(Qt.CTRL | Qt.Key_BraceRight);
		shortcuts ~= QKeySequence(Qt.CTRL | Qt.Key_PageDown);
		shortcuts ~= QKeySequence(Qt.CTRL | Qt.Key_BracketRight);
		shortcuts ~= QKeySequence(Qt.CTRL | Qt.Key_Less);
		m_nextTabAction.setShortcuts(shortcuts);
		m_nextTabAction.triggered.connect(&this.nextTab);

		m_previousTabAction = new QAction(tr("Show Previous Tab"), this);
		shortcuts.clear();
		shortcuts ~= QKeySequence(Qt_Modifier.CTRL | Qt_Key.Key_BraceLeft);
		shortcuts ~= QKeySequence(Qt_Modifier.CTRL | Qt_Key.Key_PageUp);
		shortcuts ~= QKeySequence(Qt_Modifier.CTRL | Qt_Key.Key_BracketLeft);
		shortcuts ~= QKeySequence(Qt_Modifier.CTRL | Qt_Key.Key_Greater);
		m_previousTabAction.setShortcuts(shortcuts);
		m_previousTabAction.triggered.connect(&this.previousTab);

		m_recentlyClosedTabsMenu = new QMenu(this);
		m_recentlyClosedTabsMenu.aboutToShow.connect(&this.aboutToShowRecentTabsMenu);
		m_recentlyClosedTabsMenu.triggered.connect(&this.aboutToShowRecentTriggeredAction);
		m_recentlyClosedTabsAction = new QAction(tr("Recently Closed Tabs"), this);
		m_recentlyClosedTabsAction.setMenu(m_recentlyClosedTabsMenu);
		m_recentlyClosedTabsAction.setEnabled(false);

		this.currentChanged.connect(&this.currentChanged);

		m_lineEdits = new QStackedWidget(this);
	}

	void clearTabs()
	{
		// clear the recently closed tabs
		m_recentlyClosedTabs.length = 0;
		// clear the line edit history
		for (int i = 0; i < m_lineEdits.count(); ++i) {
			QLineEdit qLineEdit = lineEdit(i);
			qLineEdit.setText(qLineEdit.text());
		}
	}

	void addWebAction(QAction action, QWebPage.WebAction webAction)
	{
		if (!action)
			return;
		m_actions.append(new WebActionMapper(action, webAction, this));
	}

	QAction newTabAction()
	{
		return m_newTabAction;
	}

	QAction closeTabAction()
	{
		return m_closeTabAction;
	}
	
	QAction recentlyClosedTabsAction()
	{
		return m_recentlyClosedTabsAction;
	}

	QAction nextTabAction()
	{
		return m_nextTabAction;
	}

	QAction previousTabAction()
	{
		return m_previousTabAction;
	}

	QWidget lineEditStack()
	{
		return m_lineEdits;
	}

	QLineEdit currentLineEdit()
	{
		return lineEdit(m_lineEdits.currentIndex());
	}

	WebView currentWebView()
	{
		return webView(currentIndex());
	}

	WebView webView(int index)
	{
		QWidget widget = this.widget(index);
		if (WebView webView = cast(WebView) widget) {
			return webView;
		} else {
			// optimization to delay creating the first webview
			if (count() == 1) {
				TabWidget that = cast(TabWidget) this;
				that.setUpdatesEnabled(false);
				that.newTab();
				that.closeTab(0);
				that.setUpdatesEnabled(true);
				return currentWebView();
			}
		}
		return 0;
	}

	QLineEdit lineEdit(int index)
	{
		UrlLineEdit urlLineEdit = cast(UrlLineEdit) m_lineEdits.widget(index);
		if (urlLineEdit)
			return urlLineEdit.lineEdit();
		return 0;
	}

	int webViewIndex(WebView webView)
	{
		int index = indexOf(webView);
		return index;
	}

    
static const int TabWidgetMagic = 0xaa;

	QByteArray saveState()
	{
		int version_ = 1;
		auto data = new QByteArray;
		auto stream = new QDataStream(data, QIODevice.WriteOnly);

		stream << cast(int) TabWidgetMagic;
		stream << cast(int) version_;

		string[] tabs;
		for (int i = 0; i < count(); ++i) {
			if (WebView tab = cast(WebView) widget(i)) {
				tabs ~= tab.getUrl().toString();
			} else {
				tabs ~= null; //QString.null);
			}
		}
		stream << tabs;
		stream << currentIndex();
		return data;
	}

	bool restoreState(QByteArray state)
	{
		int version_ = 1;
		QByteArray sd = state;
		auto stream = new QDataStream(sd, QIODevice.ReadOnly);
		if (stream.atEnd())
			return false;

		int marker;
		int v;
		stream >> marker;
		stream >> v;
		if (marker != TabWidgetMagic || v != version_)
			return false;

		string[] openTabs;
		stream >> openTabs;

		for (int i = 0; i < openTabs.length; ++i) {
			if (i != 0)
				newTab();
			loadPage(openTabs[i]);
		}

		int currentTab;
		stream >> currentTab;
		setCurrentIndex(currentTab);

		return true;
	}

protected:

	void mouseDoubleClickEvent(QMouseEvent event)
	{
		if (!childAt(event.pos())
			// Remove the line below when QTabWidget does not have a one pixel frame
			&& event.pos().y() < (tabBar().y() + tabBar().height())) {
			newTab();
			return;
		}
		QTabWidget.mouseDoubleClickEvent(event);
	}


	void contextMenuEvent(QContextMenuEvent event)
	{
		if (!childAt(event.pos())) {
			m_tabBar.contextMenuRequested(event.pos());
			return;
		}
		QTabWidget.contextMenuEvent(event);
	}

	void mouseReleaseEvent(QMouseEvent event)
	{
		if (event.button() == Qt.MidButton && !childAt(event.pos())
		// Remove the line below when QTabWidget does not have a one pixel frame
		&& event.pos().y() < (tabBar().y() + tabBar().height())) {
			auto url = new QUrl(QApplication.clipboard().text(QClipboard.Selection));
			if (!url.isEmpty() && url.isValid() && !url.scheme().isEmpty()) {
				WebView webView = newTab();
				webView.setUrl(url);
			}
		}
	}

public:

	void loadUrlInCurrentTab(QUrl url)
	{
		WebView webView = currentWebView();
		if (webView) {
			webView.loadUrl(url);
			webView.setFocus();
		}
	}

	WebView newTab(bool makeCurrent = true)
	{
		// line edit
		UrlLineEdit urlLineEdit = new UrlLineEdit;
		QLineEdit lineEdit = urlLineEdit.lineEdit();
		if (!m_lineEditCompleter && count() > 0) {
			HistoryCompletionModel completionModel = new HistoryCompletionModel(this);
			completionModel.setSourceModel(BrowserApplication.historyManager().historyFilterModel());
			m_lineEditCompleter = new QCompleter(completionModel, this);
			// Should this be in Qt by default?
			QAbstractItemView popup = m_lineEditCompleter.popup();
			QListView listView = cast(QListView) popup;
			if (listView)
				listView.setUniformItemSizes(true);
		}
		lineEdit.setCompleter(m_lineEditCompleter);
		lineEdit.returnPressed.connect(&this.lineEditReturnPressed);
		m_lineEdits.addWidget(urlLineEdit);
		m_lineEdits.setSizePolicy(lineEdit.sizePolicy());

		// optimization to delay creating the more expensive WebView, history, etc
		if (count() == 0) {
			QWidget emptyWidget = new QWidget;
			QPalette p = emptyWidget.palette();
			p.setColor(QPalette.Window, palette().color(QPalette.Base));
			emptyWidget.setPalette(p);
			emptyWidget.setAutoFillBackground(true);
			this.currentChanged.disconnect(&this.currentChanged);
			addTab(emptyWidget, tr("(Untitled)"));
			this.currentChanged.connect(&this.currentChanged);
			return 0;
		}

		// webview
		WebView webView = new WebView;
		urlLineEdit.setWebView(webView);
		webView.loadStarted().connect(&this.webViewLoadStarted);
		webView.loadFinished.connect(&this.webViewIconChanged);
		webView.iconChanged.connect(&this.webViewIconChanged);
		webView.titleChanged.connect(&this.webViewTitleChanged);
		webView.urlChanged.connect(&this.webViewUrlChanged);
		webView.page().windowCloseRequested.connect(&this.windowCloseRequested);
		webView.page().geometryChangeRequested.connect(&this.geometryChangeRequested);
		webView.page().printRequested.connect(&this.printRequested);
		webView.page().menuBarVisibilityChangeRequested.connect(&this.menuBarVisibilityChangeRequested);
		webView.page().statusBarVisibilityChangeRequested.connect(&this.statusBarVisibilityChangeRequested);
		webView.page().toolBarVisibilityChangeRequested.connect(&this.toolBarVisibilityChangeRequested);
		addTab(webView, tr("(Untitled)"));
		if (makeCurrent)
			setCurrentWidget(webView);

		// webview actions
		for (int i = 0; i < m_actions.count(); ++i) {
			WebActionMapper mapper = m_actions[i];
			mapper.addChild(webView.page().action(mapper.webAction()));
		}

		if (count() == 1)
			currentChanged(currentIndex());
		tabsChanged.emit();
		return webView;
	}

	// When index is -1 index chooses the current tab
	void cloneTab(int index = -1)
	{
		if (index < 0)
			index = currentIndex();
		if (index < 0 || index >= count())
			return;
		WebView tab = newTab(false);
		tab.setUrl(webView(index).getUrl());
	}

	// When index is -1 index chooses the current tab
	void closeTab(int index = -1)
	{
		if (index < 0)
			index = currentIndex();
		if (index < 0 || index >= count())
			return;

		bool hasFocus = false;
		if (WebView tab = webView(index)) {
			if (tab.isModified()) {
				QMessageBox closeConfirmation(tab);
				closeConfirmation.setWindowFlags(Qt.Sheet);
				closeConfirmation.setWindowTitle(tr("Do you really want to close this page?"));
				closeConfirmation.setInformativeText(tr("You have modified this page and when closing it you would lose the modification.\n"
							     "Do you really want to close this page?\n"));
				closeConfirmation.setIcon(QMessageBox.Question);
				closeConfirmation.addButton(QMessageBox.Yes);
				closeConfirmation.addButton(QMessageBox.No);
				closeConfirmation.setEscapeButton(QMessageBox.No);
				if (closeConfirmation.exec() == QMessageBox.No)
				return;
			}
			hasFocus = tab.hasFocus();

			m_recentlyClosedTabsAction.setEnabled(true);
			m_recentlyClosedTabs = [tab.getUrl()] ~ m_recentlyClosedTabs;
			if (m_recentlyClosedTabs.length >= TabWidget.m_recentlyClosedTabsSize)
				m_recentlyClosedTabs = m_recentlyClosedTabs[0..$-1];
		}
		QWidget lineEdit = m_lineEdits.widget(index);
		m_lineEdits.removeWidget(lineEdit);
		lineEdit.deleteLater();
		QWidget webView = widget(index);
		removeTab(index);
		webView.deleteLater();
		tabsChanged.emit();
		if (hasFocus && count() > 0)
			currentWebView().setFocus();
		if (count() == 0)
			lastTabClosed.emit();
	}

	void closeOtherTabs(int index)
	{
		if (-1 == index)
			return;
		for (int i = count() - 1; i > index; --i)
			closeTab(i);
		for (int i = index - 1; i >= 0; --i)
			closeTab(i);
	}

	// When index is -1 index chooses the current tab
	void reloadTab(int index = -1)
	{
		if (index < 0)
			index = currentIndex();
		if (index < 0 || index >= count())
			return;

		QWidget widget = this.widget(index);
		if (WebView tab = cast(WebView) widget)
			tab.reload();
	}

	void reloadAllTabs()
	{
		for (int i = 0; i < count(); ++i) {
			QWidget tabWidget = widget(i);
			if (WebView tab = cast(WebView) tabWidget) {
				tab.reload();
			}
		}
	}
	
	void nextTab()
	{
		int next = currentIndex() + 1;
		if (next == count())
			next = 0;
		setCurrentIndex(next);
	}

	void previousTab()
	{
		int next = currentIndex() - 1;
		if (next < 0)
			next = count() - 1;
		setCurrentIndex(next);
	}

private:

	void currentChanged(int index)
	{
		WebView webView = this.webView(index);
		if (!webView)
			return;

		assert(m_lineEdits.count() == count());

		WebView oldWebView = this.webView(m_lineEdits.currentIndex());
		if (oldWebView) {
			oldWebView.statusBarMessage.disconnect(&this.showStatusBarMessage);
			oldWebView.page().linkHovered.disconnect(&this.linkHovered);
			oldWebView.loadProgress().disconnect(&this.loadProgress);
		}

		webView.statusBarMessage.connect(&this.showStatusBarMessage);
		webView.page().linkHovered.connect(&this.linkHovered);
		webView.loadProgress.connect(&this.loadProgress);

		for (int i = 0; i < m_actions.count(); ++i) {
			WebActionMapper mapper = m_actions[i];
			mapper.updateCurrent(webView.page());
		}
		setCurrentTitle.emit(webView.title());
		m_lineEdits.setCurrentIndex(index);
		loadProgress.emit(webView.progress());
		showStatusBarMessage.emit(webView.lastStatusBarText());
		if (webView.getUrl().isEmpty())
			m_lineEdits.currentWidget().setFocus();
		else
			webView.setFocus();
	}

	void aboutToShowRecentTabsMenu()
	{
		m_recentlyClosedTabsMenu.clear();
		for (int i = 0; i < m_recentlyClosedTabs.length; ++i) {
			QAction action = new QAction(m_recentlyClosedTabsMenu);
			action.setData(m_recentlyClosedTabs[i]);
			QIcon icon = BrowserApplication.instance().icon(m_recentlyClosedTabs[i]);
			action.setIcon(icon);
			action.setText(m_recentlyClosedTabs[i].toString());
			m_recentlyClosedTabsMenu.addAction(action);
		}
	}

	void aboutToShowRecentTriggeredAction(QAction action)
	{
		QUrl url = action.data().toUrl();
		loadUrlInCurrentTab(url);
	}

	void webViewLoadStarted()
	{
		WebView webView = cast(WebView) signalSender();
		int index = webViewIndex(webView);
		if (-1 != index) {
			auto icon = new QIcon(":loading.gif");
			setTabIcon(index, icon);
		}
	}

	void webViewIconChanged()
	{
		WebView webView = cast(WebView) signalSender();
		int index = webViewIndex(webView);
		if (-1 != index) {
			QIcon icon = BrowserApplication.instance().icon(webView.getUrl());
			setTabIcon(index, icon);
		}
	}

	void webViewTitleChanged(string title)
	{
		WebView webView = cast(WebView) signalSender();
		int index = webViewIndex(webView);
		if (-1 != index) {
			setTabText(index, title);
		}
		if (currentIndex() == index)
			setCurrentTitle.emit(title);
		BrowserApplication.historyManager().updateHistoryItem(webView.getUrl(), title);
	}

	void webViewUrlChanged(QUrl url)
	{
		WebView webView = cast(WebView) signalSender();
		int index = webViewIndex(webView);
		if (-1 != index) {
			m_tabBar.setTabData(index, url);
		}
		tabsChanged.emit();
	}

	void lineEditReturnPressed()
	{
		if (QLineEdit lineEdit = cast(QLineEdit) signalSender()) {
			loadPage.emit(lineEdit.text());
			if (m_lineEdits.currentWidget() == lineEdit)
				currentWebView().setFocus();
		}
	}

	void windowCloseRequested()
	{
		WebPage webPage = cast(WebPage) signalSender();
		WebView webView = cast(WebView) webPage.view();
		int index = webViewIndex(webView);
		if (index >= 0) {
			if (count() == 1)
				webView.webPage().mainWindow().close();
			else
				closeTab(index);
		}
	}

	void moveTab(int fromIndex, int toIndex)
	{
		QWidget lineEdit = m_lineEdits.widget(fromIndex);
		m_lineEdits.removeWidget(lineEdit);
		m_lineEdits.insertWidget(toIndex, lineEdit);
	}

private:

	QAction m_recentlyClosedTabsAction;
	QAction m_newTabAction;
	QAction m_closeTabAction;
	QAction m_nextTabAction;
	QAction m_previousTabAction;

	QMenu m_recentlyClosedTabsMenu;
	static const int m_recentlyClosedTabsSize = 10;
	QUrl[] m_recentlyClosedTabs;
	WebActionMapper[] m_actions;

	QCompleter m_lineEditCompleter;
	QStackedWidget m_lineEdits;
	TabBar m_tabBar;
}
