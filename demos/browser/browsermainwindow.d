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
module browsermainwindow;


import qt.core.QUrl;
import qt.core.QSettings;
import qt.gui.QMainWindow;
import qt.gui.QIcon;
import qt.gui.QDesktopWidget;
import qt.gui.QFileDialog;
import qt.gui.QPlainTextEdit;
import qt.gui.QPrintDialog;
import qt.gui.QPrintPreviewDialog;
import qt.gui.QPrinter;
import qt.gui.QMenuBar;
import qt.gui.QMessageBox;
import qt.gui.QStatusBar;
import qt.gui.QToolBar;
import qt.gui.QInputDialog;

//import qt.core.QDebug;

import qt.webkit.QWebFrame;
import qt.webkit.QWebHistory;

import autosaver;
import bookmarks;
import browserapplication;
import chasewidget;
import downloadmanager;
import history;
import settings;
import tabwidget;
import toolbarsearch;
import webview;
import ui_passworddialog;


/*!
The MainWindow of the Browser Application.

Handles the tab widget and all the actions
*/
class BrowserMainWindow : public QMainWindow
{
	
static const int BrowserMainWindowMagic = 0xba;

public:

	this(QWidget parent = null, int flags = 0) //Qt.WindowFlags flags
	{
		super(parent, flags);
		m_tabWidget = new TabWidget(this);
		m_autoSaver = new AutoSaver(this);
		m_historyBack = 0;
		m_historyForward = 0;
		m_stop = 0;
		m_reload = 0;

		setAttribute(Qt_WidgetAttribute.WA_DeleteOnClose, true);
		statusBar().setSizeGripEnabled(true);
		setupMenu();
		setupToolBar();

		QWidget centralWidget = new QWidget(this);
		BookmarksModel boomarksModel = BrowserApplication.bookmarksManager().bookmarksModel();
		m_bookmarksToolbar = new BookmarksToolBar(boomarksModel, this);
		m_bookmarksToolba.openUrl.connect(&m_tabWidget.loadUrlInCurrentTab);
		m_bookmarksToolbar.toggleViewAction.toggled.connect(&thisupdateBookmarksToolbarActionText);

		QVBoxLayout layout = new QVBoxLayout;
		layout.setSpacing(0);
		layout.setMargin(0);
		version(Q_WS_MAC)
		{
			layout.addWidget(m_bookmarksToolbar);
			layout.addWidget(new QWidget); // <- OS X tab widget style bug
		} else {
			addToolBarBreak();
			addToolBar(m_bookmarksToolbar);
		}
		layout.addWidget(m_tabWidget);
		centralWidget.setLayout(layout);
		setCentralWidget(centralWidget);

		m_tabWidget.loadPage.connect(&thisloadPage);
		m_tabWidget.setCurrentTitle.connect(&this.slotUpdateWindowTitle);
		m_tabWidget.showStatusBarMessage.connect(&statusBar().showMessage);
		m_tabWidget.linkHovered.connect(&statusBar().showMessage);
		m_tabWidget.loadProgress.connect(&this.slotLoadProgress);
		m_tabWidget.tabsChanged.connect(&m_autoSaver.changeOccurred);
		m_tabWidget.geometryChangeRequested.connect(&this.geometryChangeRequested);
		m_tabWidget.printRequested.connect(&this.printRequested);
		m_tabWidget.menuBarVisibilityChangeRequested.connect(&menuBar().setVisible);
		m_tabWidget.statusBarVisibilityChangeRequested.connect(&statusBar().setVisible);
		m_tabWidget.toolBarVisibilityChangeRequested.connect(&m_navigationBar.setVisible);
		m_tabWidget.toolBarVisibilityChangeRequested.connect(&m_bookmarksToolbar.setVisible);
		version(Q_WS_MAC) {
			m_tabWidget.lastTabClosed().connect(&thisclose);
		} else {
			m_tabWidget.lastTabClosed().connect(&m_tabWidget.newTab);
		}

		slotUpdateWindowTitle();
		loadDefaultState();
		m_tabWidget.newTab();

		int size = m_tabWidget.lineEditStack().sizeHint().height();
		m_navigationBar.setIconSize(QSize(size, size));
	}

	~this()
	{
		m_autoSaver.changeOccurred();
		m_autoSaver.saveIfNeccessary();
	}


	QSize sizeHint()
	{
		QRect desktopRect = QApplication.desktop().screenGeometry();
		QSize size = desktopRect.size() * qreal(0.9);
		return size;
	}

public:

	static QUrl guessUrlFromString(string string)
	{
		string urlStr = string.trimmed();
		auto test = new QRegExp("^[a-zA-Z]+\\:.*");

		// Check if it looks like a qualified URL. Try parsing it and see.
		bool hasSchema = test.exactMatch(urlStr);
		if (hasSchema) {
			QUrl url = QUrl.fromEncoded(urlStr.toUtf8(), QUrl.TolerantMode);
			if (url.isValid())
				return url;
		}

		// Might be a file.
		if (QFile.exists(urlStr)) {
			QFileInfo info(urlStr);
			return QUrl.fromLocalFile(info.absoluteFilePath());
		}

		// Might be a shorturl - try to detect the schema.
		if (!hasSchema) {
			int dotIndex = urlStr.indexOf(QLatin1Char('.'));
			if (dotIndex != -1) {
				string prefix = urlStr.left(dotIndex).toLower();
				QByteArray schema = (prefix == "ftp") ? prefix.toLatin1() : "http";
				QUrl url =
				QUrl.fromEncoded(schema + "://" + urlStr.toUtf8(), QUrl.TolerantMode);
				if (url.isValid())
					return url;
			}
		}

		// Fall back to QUrl's own tolerant parser.
		QUrl url = QUrl.fromEncoded(string.toUtf8(), QUrl.TolerantMode);

		// finally for cases where the user just types in a hostname add http
		if (url.scheme().isEmpty())
			url = QUrl.fromEncoded("http://" + string.toUtf8(), QUrl.TolerantMode);
		return url;
	}

	TabWidget tabWidget()
	{
		return m_tabWidget;
	}

	WebView currentTab()
	{
		return m_tabWidget.currentWebView();
	}

	QByteArray saveState(bool withTabs)
	{
		int version_ = 2;
		auto data = new QByteArray;
		auto stream = new QDataStream(&data, QIODevice.WriteOnly);

		stream << cast(int) BrowserMainWindowMagic;
		stream << cast(int) version_;

		stream << size();
		stream << !m_navigationBar.isHidden();
		stream << !m_bookmarksToolbar.isHidden();
		stream << !statusBar().isHidden();
		if (withTabs)
			stream << tabWidget().saveState();
		else
			stream << new QByteArray();
		return data;
	}


	bool restoreState(QByteArray state)
	{
		int version_ = 2;
		QByteArray sd = state;
		auto stream = new QDataStream(&sd, QIODevice.ReadOnly);
		if (stream.atEnd())
			return false;

		int marker;
		int v;
		stream >> marker;
		stream >> v;
		if (marker != BrowserMainWindowMagic || v != version_)
			return false;

		QSize size;
		bool showToolbar;
		bool showBookmarksBar;
		bool showStatusbar;
		QByteArray tabState;

		stream >> size;
		stream >> showToolbar;
		stream >> showBookmarksBar;
		stream >> showStatusbar;
		stream >> tabState;

		resize(size);

		m_navigationBar.setVisible(showToolbar);
		updateToolbarActionText(showToolbar);

		m_bookmarksToolbar.setVisible(showBookmarksBar);
		updateBookmarksToolbarActionText(showBookmarksBar);

		statusBar().setVisible(showStatusbar);
		updateStatusbarActionText(showStatusbar);

		if (!tabWidget().restoreState(tabState))
			return false;

		return true;
	}

public:

	void loadPage(string page)
	{
		QUrl url = guessUrlFromString(page);
		loadUrl(url);
	}

	void slotHome()
	{
		auto settings = new QSettings;
		settings.beginGroup("MainWindow");
		string home = settings.value("home", "http://qtsoftware.com/").toString();
		loadPage(home);
	}

protected:

	void closeEvent(QCloseEvent event)
	{
		if (m_tabWidget.count() > 1) {
			int ret = QMessageBox.warning(this, null,
				   tr("Are you sure you want to close the window?"
				      "  There are %1 tab open").arg(m_tabWidget.count()),
				   QMessageBox.Yes | QMessageBox.No,
				   QMessageBox.No);
			if (ret == QMessageBox.No) {
				event.ignore();
				return;
			}
		}
		event.accept();
		deleteLater();
	}

private:

	void save()
	{
		BrowserApplication.instance().saveSession();

		auto settings = new QSettings;
		settings.beginGroup("BrowserMainWindow");
		QByteArray data = saveState(false);
		settings.setValue("defaultState", data);
		settings.endGroup();
	}

	void slotLoadProgress(int progress)
	{
		if (progress < 100 && progress > 0) {
			m_chaseWidget.setAnimated(true);
			m_stopReload.triggered.disconnect(&m_reload.trigger);
			if (m_stopIcon.isNull())
				m_stopIcon = style().standardIcon(QStyle.SP_BrowserStop);
			m_stopReload.setIcon(m_stopIcon);
			m_stopReload.triggered.connect(&m_stop.trigger);
			m_stopReload.setToolTip(tr("Stop loading the current page"));
		} else {
			m_chaseWidget.setAnimated(false);
			m_stopReload.triggered.disconnect(m_stop.trigger);
			m_stopReload.setIcon(m_reloadIcon);
			m_stopReload.triggered.connect(&m_reload.trigger);
			m_stopReload.setToolTip(tr("Reload the current page"));
		}
	}

	void slotUpdateStatusbar(string string)
	{
		statusBar().showMessage(string, 2000);
	}

	void slotUpdateWindowTitle(string title = null)
	{
		if (title.isEmpty()) {
			setWindowTitle(tr("Qt Demo Browser"));
		} else {
			version(Q_WS_MAC)
			{
				setWindowTitle(title);
			} else {
				setWindowTitle(tr("%1 - Qt Demo Browser", "Page title and Browser name").arg(title));
			}
		}
	}

	void loadUrl(QUrl url)
	{
		if (!currentTab() || !url.isValid())
			return;

			m_tabWidget.currentLineEdit().setText(QString.fromUtf8(url.toEncoded()));
			m_tabWidget.loadUrlInCurrentTab(url);
	}

	void slotPreferences()
	{
		SettingsDialog s = new SettingsDialog(this);
		s.show();
	}

	void slotFileNew()
	{
		BrowserApplication.instance().newMainWindow();
		BrowserMainWindow mw = BrowserApplication.instance().mainWindow();
		mw.slotHome();
	}

	void slotFileOpen()
	{
		string file = QFileDialog.getOpenFileName(this, tr("Open Web Resource"), null,
		tr("Web Resources (*.html *.htm *.svg *.png *.gif *.svgz);;All files (*.*)"));

		if (file.isEmpty())
			return;

		loadPage(file);
	}

	void slotFilePrintPreview()
	{
		version(QT_NO_PRINTER)
		{
			if (!currentTab())
				return;
			QPrintPreviewDialog dialog = new QPrintPreviewDialog(this);
			dialog.paintRequested.connect(&currentTab.print);
			dialog.exec();
		}
	}

	void slotFilePrint()
	{
		if (!currentTab())
			return;
		printRequested(currentTab().page().mainFrame());
	}

	void slotPrivateBrowsing()
	{
		QWebSettings settings = QWebSettings.globalSettings();
		bool pb = settings.testAttribute(QWebSettings.PrivateBrowsingEnabled);
		if (!pb) {
			string title = tr("Are you sure you want to turn on private browsing?");
			string text = tr("<b>%1</b><br><br>When private browsing in turned on,"
			" webpages are not added to the history,"
			" items are automatically removed from the Downloads window,"
			" new cookies are not stored, current cookies can't be accessed,"
			" site icons wont be stored, session wont be saved, "
			" and searches are not addded to the pop-up menu in the Google search box."
			"  Until you close the window, you can still click the Back and Forward buttons"
			" to return to the webpages you have opened.").arg(title);

			QMessageBox.StandardButton button = QMessageBox.question(this, null, text,
			       QMessageBox.Ok | QMessageBox.Cancel,
			       QMessageBox.Ok);
			if (button == QMessageBox.Ok) {
				settings.setAttribute(QWebSettings.PrivateBrowsingEnabled, true);
			}
		} else {
			settings.setAttribute(QWebSettings.PrivateBrowsingEnabled, false);

			BrowserMainWindow[] windows = BrowserApplication.instance().mainWindows();
			for (int i = 0; i < windows.length; ++i) {
				BrowserMainWindow window = windows[i];
				window.m_lastSearch = null; //QString::null
				window.tabWidget().clearTabs();
			}
		}
	}

	void slotFileSaveAs()
	{
		BrowserApplication.downloadManager().download(currentTab().url(), true);
	}

	void slotEditFind()
	{
		if (!currentTab())
			return;
		bool ok;
		string search = QInputDialog.getText(this, tr("Find"), tr("Text:"), QLineEdit.Normal, m_lastSearch, &ok);
		if (ok && !search.isEmpty()) {
			m_lastSearch = search;
			if (!currentTab().findText(m_lastSearch))
				slotUpdateStatusbar(tr("\"%1\" not found.").arg(m_lastSearch));
		}
	}

	void slotEditFindNext()
	{
		if (!currentTab() && !m_lastSearch.isEmpty())
			return;
		currentTab().findText(m_lastSearch);
	}

	void slotEditFindPrevious()
	{
		if (!currentTab() && !m_lastSearch.isEmpty())
			return;
		currentTab().findText(m_lastSearch, QWebPage.FindBackward);
	}

	void slotShowBookmarksDialog()
	{
		BookmarksDialog dialog = new BookmarksDialog(this);
		dialog.openUrl.connect(&m_tabWidget.loadUrlInCurrentTab);
		dialog.show();
	}

	void slotAddBookmark()
	{
		WebView webView = currentTab();
		string url = webView.getUrl().toString();
		string title = webView.title();
		AddBookmarkDialog dialog(url, title);
		dialog.exec();
	}

	void slotViewZoomIn()
	{
		if (!currentTab())
			return;
		currentTab().setZoomFactor(currentTab().zoomFactor() + 0.1);
	}

	void BslotViewZoomOut()
	{
		if (!currentTab())
			return;
		currentTab().setZoomFactor(currentTab().zoomFactor() - 0.1);
	}

	void slotViewResetZoom()
	{
		if (!currentTab())
			return;
		currentTab().setZoomFactor(1.0);
	}

	void slotViewZoomTextOnly(bool enable)
	{
		if (!currentTab())
			return;
		currentTab().page().settings().setAttribute(QWebSettings.ZoomTextOnly, enable);
	}

	void slotViewToolbar()
	{
		if (m_navigationBar.isVisible()) {
			updateToolbarActionText(false);
			m_navigationBar.close();
		} else {
			updateToolbarActionText(true);
			m_navigationBar.show();
		}
		m_autoSaver.changeOccurred();
	}


	void slotViewBookmarksBar()
	{
		if (m_bookmarksToolbar.isVisible()) {
			updateBookmarksToolbarActionText(false);
			m_bookmarksToolbar.close();
		} else {
			updateBookmarksToolbarActionText(true);
			m_bookmarksToolbar.show();
		}
		m_autoSaver.changeOccurred();
	}

	void slotViewStatusbar()
	{
		if (statusBar().isVisible()) {
			updateStatusbarActionText(false);
			statusBar().close();
		} else {
			updateStatusbarActionText(true);
			statusBar().show();
		}
		m_autoSaver.changeOccurred();
	}

	void slotViewPageSource()
	{
		if (!currentTab())
			return;

		string markup = currentTab().page().mainFrame().toHtml();
		QPlainTextEdit view = new QPlainTextEdit(markup);
		view.setWindowTitle(tr("Page Source of %1").arg(currentTab().title()));
		view.setMinimumWidth(640);
		view.setAttribute(Qt.WA_DeleteOnClose);
		view.show();
	}


	void slotViewFullScreen(bool makeFullScreen)
	{
		if (makeFullScreen) {
			showFullScreen();
		} else {
			if (isMinimized())
				showMinimized();
			else if (isMaximized())
				showMaximized();
			else showNormal();
		}
	}

	void slotWebSearch()
	{
		m_toolbarSearch.lineEdit().selectAll();
		m_toolbarSearch.lineEdit().setFocus();
	}

	void slotToggleInspector(bool enable)
	{
		QWebSettings.globalSettings().setAttribute(QWebSettings.DeveloperExtrasEnabled, enable);
		if (enable) {
			int result = QMessageBox.question(this, tr("Web Inspector"),
						   tr("The web inspector will only work correctly for pages that were loaded after enabling.\n"
						   "Do you want to reload all pages?"),
						   QMessageBox.Yes | QMessageBox.No);
			if (result == QMessageBox.Yes) {
				m_tabWidget.reloadAllTabs();
			}
		}
	}

	void slotAboutApplication()
	{
		QMessageBox.about(this, tr("About"), tr(
			"Version %1"
			"<p>This demo demonstrates Qt's "
			"webkit facilities in action, providing an example "
			"browser for you to experiment with.<p>"
			"<p>QtWebKit is based on the Open Source WebKit Project developed at <a href=\"http://webkit.org/\">http://webkit.org/</a>."
			).arg(QCoreApplication.applicationVersion()));
	}

	void slotDownloadManager()
	{
		BrowserApplication.downloadManager().show();
	}

	void slotSelectLineEdit()
	{
		m_tabWidget.currentLineEdit().selectAll();
		m_tabWidget.currentLineEdit().setFocus();
	}

	void slotAboutToShowBackMenu()
	{
		m_historyBackMenu.clear();
		if (!currentTab())
			return;
		QWebHistory history = currentTab().history();
		int historyCount = history.count();
		for (int i = history.backItems(historyCount).count() - 1; i >= 0; --i) {
			QWebHistoryItem item = history.backItems(history.count())[i];
			QAction action = new QAction(this);
			action.setData(-1*(historyCount-i-1));
			QIcon icon = BrowserApplication.instance().icon(item.url());
			action.setIcon(icon);
			action.setText(item.title());
			m_historyBackMenu.addAction(action);
		}
	}

	void slotAboutToShowForwardMenu()
	{
		m_historyForwardMenu.clear();
		if (!currentTab())
			return;
		QWebHistory history = currentTab().history();
		int historyCount = history.count();
		for (int i = 0; i < history.forwardItems(history.count()).count(); ++i) {
			QWebHistoryItem item = history.forwardItems(historyCount)[i];
			QAction action = new QAction(this);
			action.setData(historyCount-i);
			QIcon icon = BrowserApplication.instance().icon(item.url());
			action.setIcon(icon);
			action.setText(item.title());
			m_historyForwardMenu.addAction(action);
		}
	}

	void slotAboutToShowWindowMenu()
	{
		m_windowMenu.clear();
		m_windowMenu.addAction(m_tabWidget.nextTabAction());
		m_windowMenu.addAction(m_tabWidget.previousTabAction());
		m_windowMenu.addSeparator();
		m_windowMenu.addAction(tr("Downloads"), this, SLOT(slotDownloadManager()), QKeySequence(tr("Alt+Ctrl+L", "Download Manager")));

		m_windowMenu.addSeparator();
		BrowserMainWindow[] windows = BrowserApplication.instance().mainWindows();
		for (int i = 0; i < windows.length; ++i) {
			BrowserMainWindow window = windows[i];
			QAction action = m_windowMenu.addAction(window.windowTitle(), this, SLOT(slotShowWindow()));
			action.setData(i);
			action.setCheckable(true);
			if (window == this)
			action.setChecked(true);
		}
	}

	void slotOpenActionUrl(QAction action)
	{
		int offset = action.data().toInt();
		QWebHistory history = currentTab().history();
		if (offset < 0)
			history.goToItem(history.backItems(-1*offset).first()); // back
		else if (offset > 0)
			history.goToItem(history.forwardItems(history.count() - offset + 1).back()); // forward
	}

	void slotShowWindow()
	{
		if (QAction action = cast(QAction) signalSender()) {
			QVariant v = action.data();
			if (v.canConvert!(int)) {
				int offset = cast(int) v;
				BrowserMainWindow[] windows = BrowserApplication.instance().mainWindows();
				windows[offset].activateWindow();
				windows[offset].currentTab().setFocus();
			}
		}
	}

	void slotSwapFocus()
	{
		if (currentTab().hasFocus())
			m_tabWidget.currentLineEdit().setFocus();
		else
			currentTab().setFocus();
	}

	void printRequested(QWebFrame frame)
	{
		version(QT_NO_PRINTER)
		{
			QPrinter printer;
			QPrintDialog dialog = new QPrintDialog(&printer, this);
			dialog.setWindowTitle(tr("Print Document"));
			if (dialog.exec() != QDialog.Accepted)
				return;
			frame.print(&printer);
		}
	}

	void geometryChangeRequested(QRect geometry)
	{
		setGeometry(geometry);
	}

	void updateToolbarActionText(bool visible)
	{
		m_viewToolbar.setText(!visible ? tr("Show Toolbar") : tr("Hide Toolbar"));
	}
    
	void updateBookmarksToolbarActionText(bool visible)
	{
		m_viewBookmarkBar.setText(!visible ? tr("Show Bookmarks bar") : tr("Hide Bookmarks bar"));
	}

private:

	void loadDefaultState()
	{
		QSettings settings;
		settings.beginGroup("BrowserMainWindow");
		QByteArray data = settings.value("defaultState").toByteArray();
		restoreState(data);
		settings.endGroup();
	}

	void setupMenu()
	{
		new QShortcut(QKeySequence(Qt.Key_F6), this, SLOT(slotSwapFocus()));

		// File
		QMenu fileMenu = menuBar().addMenu(tr("&File"));

		fileMenu.addAction(tr("&New Window"), this, SLOT(slotFileNew()), QKeySequence.New);
		fileMenu.addAction(m_tabWidget.newTabAction());
		fileMenu.addAction(tr("&Open File..."), this, SLOT(slotFileOpen()), QKeySequence.Open);
		fileMenu.addAction(tr("Open &Location..."), this, SLOT(slotSelectLineEdit()), QKeySequence(Qt.ControlModifier + Qt.Key_L));
		fileMenu.addSeparator();
		fileMenu.addAction(m_tabWidget.closeTabAction());
		fileMenu.addSeparator();
		fileMenu.addAction(tr("&Save As..."), this,  SLOT(slotFileSaveAs()), QKeySequence(QKeySequence.Save));
		fileMenu.addSeparator();
		BookmarksManager bookmarksManager = BrowserApplication.bookmarksManager();
		fileMenu.addAction(tr("&Import Bookmarks..."), bookmarksManager, SLOT(importBookmarks()));
		fileMenu.addAction(tr("&Export Bookmarks..."), bookmarksManager, SLOT(exportBookmarks()));
		fileMenu.addSeparator();
		fileMenu.addAction(tr("P&rint Preview..."), this, SLOT(slotFilePrintPreview()));
		fileMenu.addAction(tr("&Print..."), this, SLOT(slotFilePrint()), QKeySequence.Print);
		fileMenu.addSeparator();
		QAction action = fileMenu.addAction(tr("Private &Browsing..."), this, SLOT(slotPrivateBrowsing()));
		action.setCheckable(true);
		fileMenu.addSeparator();

		version(Q_WS_MAC) {
			fileMenu.addAction(tr("&Quit"), BrowserApplication.instance(), SLOT(quitBrowser()), QKeySequence(Qt.CTRL | Qt.Key_Q));
		} else {
			fileMenu.addAction(tr("&Quit"), this, SLOT(close()), QKeySequence(Qt.CTRL | Qt.Key_Q));
		}

		// Edit
		QMenu editMenu = menuBar().addMenu(tr("&Edit"));
		QAction m_undo = editMenu.addAction(tr("&Undo"));
		m_undo.setShortcuts(QKeySequence.Undo);
		m_tabWidget.addWebAction(m_undo, QWebPage.Undo);
		QAction m_redo = editMenu.addAction(tr("&Redo"));
		m_redo.setShortcuts(QKeySequence.Redo);
		m_tabWidget.addWebAction(m_redo, QWebPage.Redo);
		editMenu.addSeparator();
		QAction m_cut = editMenu.addAction(tr("Cu&t"));
		m_cut.setShortcuts(QKeySequence.Cut);
		m_tabWidget.addWebAction(m_cut, QWebPage.Cut);
		QAction m_copy = editMenu.addAction(tr("&Copy"));
		m_copy.setShortcuts(QKeySequence.Copy);
		m_tabWidget.addWebAction(m_copy, QWebPage.Copy);
		QAction m_paste = editMenu.addAction(tr("&Paste"));
		m_paste.setShortcuts(QKeySequence.Paste);
		m_tabWidget.addWebAction(m_paste, QWebPage.Paste);
		editMenu.addSeparator();

		QAction m_find = editMenu.addAction(tr("&Find"));
		m_find.setShortcuts(QKeySequence.Find);
		m_find.triggered().connect(&this.slotEditFind);
		new QShortcut(QKeySequence(Qt.Key_Slash), this, SLOT(slotEditFind()));

		QAction m_findNext = editMenu.addAction(tr("&Find Next"));
		m_findNext.setShortcuts(QKeySequence.FindNext);
		m_findNext.triggered().connect(&this.slotEditFindNext);

		QAction m_findPrevious = editMenu.addAction(tr("&Find Previous"));
		m_findPrevious.setShortcuts(QKeySequence.FindPrevious);
		m_findPrevious.triggered().connect(&this.slotEditFindPrevious);

		editMenu.addSeparator();
		editMenu.addAction(tr("&Preferences"), this, SLOT(slotPreferences()), tr("Ctrl+,"));

		// View
		QMenu viewMenu = menuBar().addMenu(tr("&View"));

		m_viewBookmarkBar = new QAction(this);
		updateBookmarksToolbarActionText(true);
		m_viewBookmarkBar.setShortcut(tr("Shift+Ctrl+B"));
		m_viewBookmarkBar.triggered().connect(&this.slotViewBookmarksBar);
		viewMenu.addAction(m_viewBookmarkBar);

		m_viewToolbar = new QAction(this);
		updateToolbarActionText(true);
		m_viewToolbar.setShortcut(tr("Ctrl+|"));
		m_viewToolbar.triggered().connect(&this.slotViewToolbar);
		viewMenu.addAction(m_viewToolbar);

		m_viewStatusbar = new QAction(this);
		updateStatusbarActionText(true);
		m_viewStatusbar.setShortcut(tr("Ctrl+/"));
		m_viewStatusbar.triggered().connect(&this.slotViewStatusbar);
		viewMenu.addAction(m_viewStatusbar);

		viewMenu.addSeparator();

		m_stop = viewMenu.addAction(tr("&Stop"));
		QKeySequence[] shortcuts;
		shortcuts.append(QKeySequence(Qt.CTRL | Qt.Key_Period));
		shortcuts.append(Qt.Key_Escape);
		m_stop.setShortcuts(shortcuts);
		m_tabWidget.addWebAction(m_stop, QWebPage.Stop);

		m_reload = viewMenu.addAction(tr("Reload Page"));
		m_reload.setShortcuts(QKeySequence.Refresh);
		m_tabWidget.addWebAction(m_reload, QWebPage.Reload);

		viewMenu.addAction(tr("Zoom &In"), this, SLOT(slotViewZoomIn()), QKeySequence(Qt.CTRL | Qt.Key_Plus));
		viewMenu.addAction(tr("Zoom &Out"), this, SLOT(slotViewZoomOut()), QKeySequence(Qt.CTRL | Qt.Key_Minus));
		viewMenu.addAction(tr("Reset &Zoom"), this, SLOT(slotViewResetZoom()), QKeySequence(Qt.CTRL | Qt.Key_0));
		QAction zoomTextOnlyAction = viewMenu.addAction(tr("Zoom &Text Only"));
		zoomTextOnlyAction.toggled().connect(&this.slotViewZoomTextOnly);
		zoomTextOnlyAction.setCheckable(true);
		zoomTextOnlyAction.setChecked(false);

		viewMenu.addSeparator();
		viewMenu.addAction(tr("Page S&ource"), this, SLOT(slotViewPageSource()), tr("Ctrl+Alt+U"));
		QAction a = viewMenu.addAction(tr("&Full Screen"), this, SLOT(slotViewFullScreen),  Qt.Key_F11);
		a.setCheckable(true);

		// History
		HistoryMenu historyMenu = new HistoryMenu(this);
		historyMenu.openUrl.connect(&m_tabWidget.loadUrlInCurrentTab);
		historyMenu.hovered.connect(&this.slotUpdateStatusbar);
		historyMenu.setTitle(tr("Hi&story"));
		menuBar().addMenu(historyMenu);
		QAction[] historyActions;

		m_historyBack = new QAction(tr("Back"), this);
		m_tabWidget.addWebAction(m_historyBack, QWebPage.Back);
		m_historyBack.setShortcuts(QKeySequence.Back);
		m_historyBack.setIconVisibleInMenu(false);

		m_historyForward = new QAction(tr("Forward"), this);
		m_tabWidget.addWebAction(m_historyForward, QWebPage.Forward);
		m_historyForward.setShortcuts(QKeySequence.Forward);
		m_historyForward.setIconVisibleInMenu(false);

		QAction m_historyHome = new QAction(tr("Home"), this);
		m_historyHome.triggered().connect(&this.slotHome);
		m_historyHome.setShortcut(QKeySequence(Qt.CTRL | Qt.SHIFT | Qt.Key_H));

		m_restoreLastSession = new QAction(tr("Restore Last Session"), this);
		m_restoreLastSession.triggered().connect(BrowserApplication.instance().restoreLastSession);
		m_restoreLastSession.setEnabled(BrowserApplication.instance().canRestoreSession());

		historyActions.append(m_historyBack);
		historyActions.append(m_historyForward);
		historyActions.append(m_historyHome);
		historyActions.append(m_tabWidget.recentlyClosedTabsAction());
		historyActions.append(m_restoreLastSession);
		historyMenu.setInitialActions(historyActions);

		// Bookmarks
		BookmarksMenu bookmarksMenu = new BookmarksMenu(this);
		bookmarksMenu.openUrl.connect(&m_tabWidget.loadUrlInCurrentTab);
		bookmarksMenu.hovered.connect(&this.slotUpdateStatusbar);
		bookmarksMenu.setTitle(tr("&Bookmarks"));
		menuBar().addMenu(bookmarksMenu);

		QAction[] bookmarksActions;

		QAction showAllBookmarksAction = new QAction(tr("Show All Bookmarks"), this);
		showAllBookmarksAction.triggered().connect(&this.slotShowBookmarksDialog);
		m_addBookmark = new QAction(new QIcon(":addbookmark.png"), tr("Add Bookmark..."), this);
		m_addBookmark.setIconVisibleInMenu(false);

		m_addBookmark.triggered().connect(&this.slotAddBookmark);
		m_addBookmark.setShortcut(QKeySequence(Qt.CTRL | Qt.Key_D));

		bookmarksActions.append(showAllBookmarksAction);
		bookmarksActions.append(m_addBookmark);
		bookmarksMenu.setInitialActions(bookmarksActions);

		// Window
		m_windowMenu = menuBar().addMenu(tr("&Window"));
		m_windowMenu.aboutToShow().connect(&this.slotAboutToShowWindowMenu);
		slotAboutToShowWindowMenu();

		QMenu toolsMenu = menuBar().addMenu(tr("&Tools"));
		toolsMenu.addAction(tr("Web &Search"), this, SLOT(slotWebSearch()), QKeySequence(tr("Ctrl+K", "Web Search")));
		version(Q_CC_MINGW)
		{
			a = toolsMenu.addAction(tr("Enable Web &Inspector"), this, SLOT(slotToggleInspector));
			a.setCheckable(true);
		}

		QMenu helpMenu = menuBar().addMenu(tr("&Help"));
		helpMenu.addAction(tr("About &Qt"), qApp, SLOT(aboutQt()));
		helpMenu.addAction(tr("About &Demo Browser"), this, SLOT(slotAboutApplication()));
	}

	void setupToolBar()
	{
		setUnifiedTitleAndToolBarOnMac(true);
		m_navigationBar = addToolBar(tr("Navigation"));
		m_navigationBar.toggleViewAction().toggled.connect(&this.updateToolbarActionText);

		m_historyBack.setIcon(style().standardIcon(QStyle.SP_ArrowBack, 0, this));
		m_historyBackMenu = new QMenu(this);
		m_historyBack.setMenu(m_historyBackMenu);
		m_historyBackMenu.aboutToShow().connect(&this.slotAboutToShowBackMenu);
		m_historyBackMenu.triggered.connect(&this.slotOpenActionUrl);
		m_navigationBar.addAction(m_historyBack);

		m_historyForward.setIcon(style().standardIcon(QStyle.SP_ArrowForward, 0, this));
		m_historyForwardMenu = new QMenu(this);
		m_historyForwardMenu.aboutToShow.connect(&this.slotAboutToShowForwardMenu);
		m_historyForwardMenu.triggered.connect(&this.slotOpenActionUrl);
		m_historyForward.setMenu(m_historyForwardMenu);
		m_navigationBar.addAction(m_historyForward);

		m_stopReload = new QAction(this);
		m_reloadIcon = style().standardIcon(QStyle.SP_BrowserReload);
		m_stopReload.setIcon(m_reloadIcon);

		m_navigationBar.addAction(m_stopReload);

		m_navigationBar.addWidget(m_tabWidget.lineEditStack());

		m_toolbarSearch = new ToolbarSearch(m_navigationBar);
		m_navigationBar.addWidget(m_toolbarSearch);
		m_toolbarSearch.search.connect(&loadUrl);

		m_chaseWidget = new ChaseWidget(this);
		m_navigationBar.addWidget(m_chaseWidget);
	}

	void updateStatusbarActionText(bool visible)
	{
		m_viewStatusbar.setText(!visible ? tr("Show Status Bar") : tr("Hide Status Bar"));
	}

private:

	QToolBar m_navigationBar;
	ToolbarSearch m_toolbarSearch;
	BookmarksToolBar m_bookmarksToolbar;
	ChaseWidget m_chaseWidget;
	TabWidget m_tabWidget;
	AutoSaver m_autoSaver;

	QAction m_historyBack;
	QMenu m_historyBackMenu;
	QAction m_historyForward;
	QMenu m_historyForwardMenu;
	QMenu m_windowMenu;

	QAction m_stop;
	QAction m_reload;
	QAction m_stopReload;
	QAction m_viewToolbar;
	QAction m_viewBookmarkBar;
	QAction m_viewStatusbar;
	QAction m_restoreLastSession;
	QAction m_addBookmark;

	QIcon m_reloadIcon;
	QIcon m_stopIcon;

	string m_lastSearch;
}
