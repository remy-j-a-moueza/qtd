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
module webview;

import qt.gui.QClipboard;
import qt.gui.QMenu;
import qt.gui.QMessageBox;
import qt.gui.QMouseEvent;
//import qt.core.QDebug;
import qt.core.QBuffer;
import qt.webkit.QWebView;
import qt.webkit.QWebHitTestResult;
version(QT_NO_UITOOLS) {} else
{
	import qt.uitools.QUiLoader;
}

import tango.text.convert.Format;

import browserapplication;
import browsermainwindow;
import cookiejar;
import downloadmanager;
import networkaccessmanager;
import tabwidget;


class WebPage : public QWebPage
{
	mixin Signal!("loadingUrl", QUrl /*url*/);

public:

	this(QObject parent = null)
	{
		super(parent);
		m_keyboardModifiers = Qt_KeyboardModifier.NoModifier;
		m_pressedButtons = Qt_MouseButton.NoButton;
		m_openInNewTab = false;
		setNetworkAccessManager(BrowserApplication.networkAccessManager());
		this.unsupportedContent.connect(&this.handleUnsupportedContent);
	}
	
	BrowserMainWindow mainWindow()
	{
		QObject w = this.parent();
		while (w) {
			if (BrowserMainWindow mw = cast(BrowserMainWindow) w)
				return mw;
			w = w.parent();
		}
		return BrowserApplication.instance().mainWindow();
	}

protected:

	bool acceptNavigationRequest(QWebFrame frame, QNetworkRequest request, NavigationType type)
	{
		// ctrl open in new tab
		// ctrl-shift open in new tab and select
		// ctrl-alt open in new window
		if (type == QWebPage.NavigationTypeLinkClicked
			&& (m_keyboardModifiers & Qt_KeyboardModifier.ControlModifier
			|| m_pressedButtons == Qt_MouseButton.MidButton)) {
			bool newWindow = (m_keyboardModifiers & Qt_KeyboardModifier.AltModifier);
			WebView webView;
			if (newWindow) {
				BrowserApplication.instance().newMainWindow();
				BrowserMainWindow newMainWindow = BrowserApplication.instance().mainWindow();
				webView = newMainWindow.currentTab();
				newMainWindow.raise();
				newMainWindow.activateWindow();
				webView.setFocus();
			} else {
				bool selectNewTab = (m_keyboardModifiers & Qt_KeyboardModifier.ShiftModifier);
				webView = mainWindow().tabWidget().newTab(selectNewTab);
			}
			webView.load(request);
			m_keyboardModifiers = Qt_KeyboardModifier.NoModifier;
			m_pressedButtons = Qt_MouseButton.NoButton;
			return false;
		}
		if (frame == mainFrame()) {
			m_loadingUrl = request.url();
			loadingUrl.emit(m_loadingUrl);
		}
		return QWebPage.acceptNavigationRequest(frame, request, type);
	}

	QWebPage createWindow(QWebPage.WebWindowType type)
	{
		if (m_keyboardModifiers & Qt_KeyboardModifier.ControlModifier || m_pressedButtons == Qt_MouseButton.MidButton)
			m_openInNewTab = true;
		if (m_openInNewTab) {
			m_openInNewTab = false;
			return mainWindow().tabWidget().newTab().page();
		}
		BrowserApplication.instance().newMainWindow();
		BrowserMainWindow mainWindow = BrowserApplication.instance().mainWindow();
		return mainWindow.currentTab().page();
	}

	version(QT_NO_UITOOLS) {} else
	{
		QObject createPlugin(string classId, QUrl url, string[] paramNames, string[] paramValues)
		{
			auto loader = new QUiLoader;
			return loader.createWidget(classId, view());
		}
	}

private:

	void handleUnsupportedContent(QNetworkReply reply)
	{
		if (reply.error() == QNetworkReply.NoError) {
			BrowserApplication.downloadManager().handleUnsupportedContent(reply);
			return;
		}

		auto file = new QFile(":/notfound.html");
		bool isOpened = file.open(QIODevice.ReadOnly);
		assert(isOpened);
		string title = Format(tr("Error loading page: {}"), reply.url().toString());
		string html = Format(file.readAll(),
			title,
			reply.errorString(),
			reply.url().toString());

		QBuffer imageBuffer;
		imageBuffer.open(QBuffer.ReadWrite);
		QIcon icon = view().style().standardIcon(QStyle.SP_MessageBoxWarning, 0, view());
		QPixmap pixmap = icon.pixmap(QSize(32,32));
		if (pixmap.save(&imageBuffer, "PNG")) {
			html.replace("IMAGE_BINARY_DATA_HERE",
				imageBuffer.buffer().toBase64());
		}

		QWebFrame[] frames;
		frames.append(mainFrame());
		while (!frames.isEmpty()) {
			QWebFrame frame = frames.takeFirst();
			if (frame.url() == reply.url()) {
				frame.setHtml(html, reply.url());
				return;
			}
			QWebFrame[] children = frame.childFrames();
			foreach(QWebFrame frame; children)
				frames.append(frame);
		}
		if (m_loadingUrl == reply.url()) {
			mainFrame().setHtml(html, reply.url());
		}
	}

private:

	// set the webview mousepressedevent
	Qt_KeyboardModifier m_keyboardModifiers;
	Qt_MouseButton m_pressedButtons;
	bool m_openInNewTab;
	QUrl m_loadingUrl;
}

class WebView : public QWebView
{
public:
	
	this(QWidget parent = null)
	{
		super(parent);
		m_progress = 0;
		m_page = new WebPage(this);
		setPage(m_page);
		page().statusBarMessage.connect(&setStatusBarText);
		this.loadProgress.connect(&this.setProgress);
		this.loadFinished.connect(&this.loadFinished);
		page().loadingUrl.connect(&this.urlChanged);
		page().downloadRequested.connect(&this.downloadRequested);
		page().setForwardUnsupportedContent(true);
	}

	WebPage webPage() { return m_page; }

	void loadUrl(QUrl url)
	{
		m_initialUrl = url;
		load(url);
	}

	QUrl getUrl()
	{
		QUrl url = QWebView.url();
		if (!url.isEmpty())
			return url;
		return m_initialUrl;
	}

	string lastStatusBarText()
	{
		return m_statusBarText;
	}

	int progress()
	{
		return m_progress;
	}

protected:

	void mousePressEvent(QMouseEvent event)
	{
		m_page.m_pressedButtons = event.buttons();
		m_page.m_keyboardModifiers = event.modifiers();
		QWebView.mousePressEvent(event);
	}

	void mouseReleaseEvent(QMouseEvent event)
	{
		QWebView.mouseReleaseEvent(event);
		if (!event.isAccepted() && (m_page.m_pressedButtons & Qt_MouseButton.MidButton)) {
			auto url = new QUrl(QApplication.clipboard().text(QClipboard.Selection));
			if (!url.isEmpty() && url.isValid() && !url.scheme().isEmpty()) {
				setUrl(url);
			}
		}
	}

	void contextMenuEvent(QContextMenuEvent event)
	{
		QWebHitTestResult r = page().mainFrame().hitTestContent(event.pos());
		if (!r.linkUrl().isEmpty()) {
			auto menu = new QMenu(this);
			menu.addAction(pageAction(QWebPage.OpenLinkInNewWindow));
			menu.addAction(tr("Open in New Tab"), this, SLOT(openLinkInNewTab()));
			menu.addSeparator();
			menu.addAction(pageAction(QWebPage.DownloadLinkToDisk));
			// Add link to bookmarks...
			menu.addSeparator();
			menu.addAction(pageAction(QWebPage.CopyLinkToClipboard));
			if (page().settings().testAttribute(QWebSettings.DeveloperExtrasEnabled))
				menu.addAction(pageAction(QWebPage.InspectElement));
			menu.exec(mapToGlobal(event.pos()));
			return;
		}
		QWebView.contextMenuEvent(event);
	}

	void wheelEvent(QWheelEvent event)
	{
		if (QApplication.keyboardModifiers() & Qt.ControlModifier) {
			int numDegrees = event.delta() / 8;
			int numSteps = numDegrees / 15;
			setTextSizeMultiplier(textSizeMultiplier() + numSteps * 0.1);
			event.accept();
			return;
		}
		QWebView.wheelEvent(event);
	}


private:

	void setProgress(int progress)
	{
		m_progress = progress;
	}

	void loadFinished()
	{
		if (100 != m_progress) {
			qWarning("Received finished signal while progress is still:" ~ progress() ~ "Url:" ~ url());
		}
		m_progress = 0;
	}

	void setStatusBarText(string str)
	{
		m_statusBarText = str;
	}

	void downloadRequested(QNetworkRequest request)
	{
		BrowserApplication.downloadManager().download(request);
	}

	void openLinkInNewTab()
	{
		m_page.m_openInNewTab = true;
		pageAction(QWebPage.OpenLinkInNewWindow).trigger();
	}
	
private:

	string m_statusBarText;
	QUrl m_initialUrl;
	int m_progress;
	WebPage m_page;
}
