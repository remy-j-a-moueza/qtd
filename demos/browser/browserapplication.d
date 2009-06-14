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

module browserapplication;


import qt.core.QBuffer;
import qt.core.QDir;
import qt.core.QLibraryInfo;
import qt.core.QSettings;
import qt.core.QTextStream;
import qt.core.QTranslator;
import qt.core.QUrl;
import qt.core.QTimer;
//import qt.core.QPointer;

import qt.gui.QApplication;
import qt.gui.QIcon;
import qt.gui.QDesktopServices;
import qt.gui.QFileOpenEvent;
import qt.gui.QMessageBox;

import qt.network.QLocalServer;
import qt.network.QLocalSocket;
import qt.network.QNetworkProxy;
import qt.network.QSslSocket;

import qt.webkit.QWebSettings;

//import qt.core.QDebug;

import bookmarks;
import browsermainwindow;
import cookiejar;
import downloadmanager;
import history;
import networkaccessmanager;
import tabwidget;
import webview;


class BrowserApplication : public QApplication
{
public:

	this(string[] arguments)
	{
		super(arguments);
		m_localServer = null;
		QCoreApplication.setOrganizationName("Trolltech");
		QCoreApplication.setApplicationName("demobrowser");
		QCoreApplication.setApplicationVersion("0.1");
		version(Q_WS_QWS)
		{
			// Use a different server name for QWS so we can run an X11
			// browser and a QWS browser in parallel on the same machine for
			// debugging
			string serverName = QCoreApplication.applicationName() ~ "_qws";
		} else {
			string serverName = QCoreApplication.applicationName();
		}
		auto socket = new QLocalSocket;
		socket.connectToServer(serverName);
		if (socket.waitForConnected(500)) {
			auto stream = new QTextStream(&socket);
			string[] args = QCoreApplication.arguments();
			if (args.length > 1)
				stream.writeString(args[$-1]);
			//else
			//	stream << "";
			stream.flush();
			socket.waitForBytesWritten();
			return;
		}

		version(Q_WS_MAC) {
			QApplication.setQuitOnLastWindowClosed(false);
		} else {
			QApplication.setQuitOnLastWindowClosed(true);
		}

		m_localServer = new QLocalServer(this);
		m_localServer.newConnection.connect(&this.newLocalSocketConnection);
		if (!m_localServer.listen(serverName)) {
			if (m_localServer.serverError() == QAbstractSocket.AddressInUseError
				&& QFile.exists(m_localServer.serverName())) {
				QFile.remove(m_localServer.serverName());
				m_localServer.listen(serverName);
			}
		}

		version(QT_NO_OPENSSL) {} else {
			if (!QSslSocket.supportsSsl()) {
				QMessageBox.information(null, "Demo Browser",
					"This system does not support OpenSSL. SSL websites will not be available.");
			}
		}

		QDesktopServices.setUrlHandler("http", &this.openUrl);
		string localSysName = QLocale.system().name();

		installTranslator("qt_" ~ localSysName);

		auto settings = new QSettings;
		settings.beginGroup("sessions");
		m_lastSession = settings.value("lastSession").toByteArray();
		settings.endGroup();

		version(Q_WS_MAC) {
			this.lastWindowClosed.connect(&this.lastWindowClosed);
		}

		QTimer.singleShot(0, this, SLOT(postLaunch()));
	}

	~this()
	{
		delete s_downloadManager;
		for (int i = 0; i < m_mainWindows.length; ++i) {
			BrowserMainWindow window = m_mainWindows[i];
			delete window;
		}
		delete s_networkAccessManager;
		delete s_bookmarksManager;
	}

	static BrowserApplication instance()
	{
		return cast(BrowserApplication) QCoreApplication.instance();
	}

	void loadSettings()
	{
		QSettings settings = new QSettings;
		settings.beginGroup("websettings");

		QWebSettings defaultSettings = QWebSettings.globalSettings();
		string standardFontFamily = defaultSettings.fontFamily(QWebSettings.StandardFont);
		int standardFontSize = defaultSettings.fontSize(QWebSettings.DefaultFontSize);
		QFont standardFont = new QFont(standardFontFamily, standardFontSize);
		standardFont = QVariant.fromValue!(QFont)(settings.value("standardFont", standardFont));
		defaultSettings.setFontFamily(QWebSettings.StandardFont, standardFont.family());
		defaultSettings.setFontSize(QWebSettings.DefaultFontSize, standardFont.pointSize());

		string fixedFontFamily = defaultSettings.fontFamily(QWebSettings.FixedFont);
		int fixedFontSize = defaultSettings.fontSize(QWebSettings.DefaultFixedFontSize);
		QFont fixedFont = new QFont(fixedFontFamily, fixedFontSize);
		fixedFont = QVariant.fromValue!(QFont)(settings.value("fixedFont", fixedFont));
		defaultSettings.setFontFamily(QWebSettings.FixedFont, fixedFont.family());
		defaultSettings.setFontSize(QWebSettings.DefaultFixedFontSize, fixedFont.pointSize());

		defaultSettings.setAttribute(QWebSettings.JavascriptEnabled, settings.value("enableJavascript", new QVariant(true)).toBool());
		defaultSettings.setAttribute(QWebSettings.PluginsEnabled, settings.value("enablePlugins", new QVariant(true)).toBool());

		QUrl url = settings.value("userStyleSheet").toUrl();
		defaultSettings.setUserStyleSheetUrl(url);

		settings.endGroup();
	}

	bool isTheOnlyBrowser()
	{
		return (m_localServer !is null);
	}

	BrowserMainWindow mainWindow()
	{
		clean();
		if (m_mainWindows.length == 0)
			newMainWindow();
		return m_mainWindows[0];
	}

	BrowserMainWindow[] mainWindows()
	{
		clean();
		BrowserMainWindow[] list;
		for (int i = 0; i < m_mainWindows.length; ++i)
			list ~= m_mainWindows[i];
		return list;
	}

	QIcon icon(QUrl url)
	{
		QIcon icon = QWebSettings.iconForUrl(url);
		if (!icon.isNull())
			return icon.pixmap(16, 16);
		if (m_defaultIcon.isNull())
			m_defaultIcon = QIcon(":defaulticon.png");
		return m_defaultIcon.pixmap(16, 16);
	}

	void saveSession()
	{
		QWebSettings globalSettings = QWebSettings.globalSettings();
		if (globalSettings.testAttribute(QWebSettings.PrivateBrowsingEnabled))
			return;

		clean();

		QSettings settings = new QSettings;
		settings.beginGroup("sessions");

		QByteArray data = new QByteArray;
		auto buffer = new QBuffer(&data);
		auto stream = new QDataStream(&buffer);
		buffer.open(QIODevice.ReadWrite);

		stream.writeLong(m_mainWindows.length);
		for (int i = 0; i < m_mainWindows.length; ++i)
			stream << m_mainWindows[i].saveState();
		settings.setValue("lastSession", data);
		settings.endGroup();
	}

	bool canRestoreSession()
	{
		return !m_lastSession.isEmpty();
	}

	static HistoryManager historyManager()
	{
		if (!s_historyManager) {
			s_historyManager = new HistoryManager();
			QWebHistoryInterface.setDefaultInterface(s_historyManager);
		}
		return s_historyManager;
	}

	static CookieJar cookieJar()
	{
		return cast(CookieJar) networkAccessManager().cookieJar();
	}
	
	static DownloadManager downloadManager()
	{
		if (!s_downloadManager) {
			s_downloadManager = new DownloadManager();
		}
		return s_downloadManager;
	}

	static NetworkAccessManager networkAccessManager()
	{
		if (!s_networkAccessManager) {
			s_networkAccessManager = new NetworkAccessManager();
			s_networkAccessManager.setCookieJar(new CookieJar);
		}
		return s_networkAccessManager;
	}


	static BookmarksManager bookmarksManager()
	{
		if (!s_bookmarksManager) {
			s_bookmarksManager = new BookmarksManager;
		}
		return s_bookmarksManager;
	}


version(Q_WS_MAC)
{
	bool event(QEvent event)
	{
		switch (event.type()) {
			case QEvent.ApplicationActivate: {
				clean();
				if (m_mainWindows.length) {
					BrowserMainWindow mw = mainWindow();
					if (mw && !mw.isMinimized()) {
						mainWindow().show();
					}
					return true;
				}
			}
			case QEvent.FileOpen:
				if (m_mainWindows.length) {
					mainWindow().loadPage(cast(QFileOpenEvent) event.file());
					return true;
				}
			default:
				break;
		}
		return QApplication.event(event);
	}
}

public:

	BrowserMainWindow newMainWindow()
	{
		BrowserMainWindow browser = new BrowserMainWindow();
		m_mainWindows = [browser] ~ m_mainWindows;
		browser.show();
		return browser;
	}

	void restoreLastSession()
	{
		QByteArray[] windows;
		auto buffer = new QBuffer(&m_lastSession);
		auto stream = new QDataStream(&buffer);
		buffer.open(QIODevice.ReadOnly);
		int windowCount;
		stream >> windowCount;
		for (int i = 0; i < windowCount; ++i) {
			QByteArray windowState;
			stream >> windowState;
			windows ~= windowState;
		}
		for (int i = 0; i < windows.length; ++i) {
			BrowserMainWindow newWindow = 0;
			if (m_mainWindows.length == 1 && mainWindow().tabWidget().count() == 1
				&& mainWindow().currentTab().getUrl() is null) {
				newWindow = mainWindow();
			} else {
				newWindow = newMainWindow();
			}
			newWindow.restoreState(windows[i]);
		}
	}


version(Q_WS_MAC)
{
	import qt.gui.QMessageBox;
	
	void quitBrowser()
	{
		clean();
		int tabCount = 0;
		for (int i = 0; i < m_mainWindows.length; ++i) {
			tabCount =+ m_mainWindows[i].tabWidget().count();
		}

		if (tabCount > 1) {
			int ret = QMessageBox.warning(mainWindow(), null,
				Format(tr("There are %1 windows and %2 tabs open\n"
					"Do you want to quit anyway?"), m_mainWindows.length, tabCount),
			QMessageBox.Yes | QMessageBox.No,
			QMessageBox.No);
			if (ret == QMessageBox.No)
				return;
		}

		exit(0);
	}
	
	void lastWindowClosed()
	{
		clean();
		BrowserMainWindow mw = new BrowserMainWindow;
		mw.slotHome();
		m_mainWindows = [mw] ~ m_mainWindows;
	}
}

private:

	/*!
	Any actions that can be delayed until the window is visible
	*/
	void postLaunch()
	{
		string directory = QDesktopServices.storageLocation(QDesktopServices.DataLocation);
		if (directory.isEmpty())
			directory = QDir.homePath() ~ "/." ~ QCoreApplication.applicationName();
		QWebSettings.setIconDatabasePath(directory);

		setWindowIcon(new QIcon(":browser.svg"));

		loadSettings();

		// newMainWindow() needs to be called in main() for this to happen
		if (m_mainWindows.length > 0) {
			string[] args = QCoreApplication.arguments();
			if (args.length > 1)
				mainWindow().loadPage(args.last());
			else
				mainWindow().slotHome();
		}
		BrowserApplication.historyManager();
	}

	void openUrl(QUrl url)
	{
		mainWindow().loadPage(url.toString());
	}

	void newLocalSocketConnection()
	{
		QLocalSocket socket = m_localServer.nextPendingConnection();
		if (!socket)
			return;
		socket.waitForReadyRead(1000);
		auto stream = new QTextStream(socket);
		string url;
		stream >> url;
		if (url.length) {
			QSettings settings;
			settings.beginGroup("general");
			int openLinksIn = settings.value("openLinksIn", new QVariant(0)).toInt();
			settings.endGroup();
			if (openLinksIn == 1)
				newMainWindow();
			else
				mainWindow().tabWidget().newTab();
			openUrl(url);
		}
		delete socket;
		mainWindow().raise();
		mainWindow().activateWindow();
	}

private:

	void clean()
	{
		// cleanup any deleted main windows first
		for (int i = m_mainWindows.length - 1; i >= 0; --i)
			if (m_mainWindows[i] is null)
				m_mainWindows.removeAt(i);
	}

	void installTranslator(string name)
	{
		QTranslator translator = new QTranslator(this);
		translator.load(name, QLibraryInfo.location(QLibraryInfo.TranslationsPath));
		QApplication.installTranslator(translator);
	}

	static HistoryManager s_historyManager;
	static DownloadManager s_downloadManager;
	static NetworkAccessManager s_networkAccessManager;
	static BookmarksManager s_bookmarksManager;
	
	//QPointer!(BrowserMainWindow)[] m_mainWindows;
	BrowserMainWindow[] m_mainWindows;
	QLocalServer m_localServer;
	QByteArray m_lastSession;
	QIcon m_defaultIcon;
}
