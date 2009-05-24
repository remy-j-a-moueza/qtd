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
module settings;


import qt.core.QSettings;

import qt.gui.qt.gui;
import qt.gui.QDialog;

import qt.webkit.QtWebKit;

import browserapplication;
import browsermainwindow;
import cookiejar;
import history;
import networkaccessmanager;
import webview;
import ui_settings;


class SettingsDialog : public QDialog, public Ui_Settings
{
public:
	
	this(QWidget parent = null)
	//: QDialog(parent)
	{
		setupUi(this);
		exceptionsButton.clicked.connect(&this.showExceptions);
		setHomeToCurrentPageButton.clicked.connect(&this.setHomeToCurrentPage);
		cookiesButton.clicked.connect(&this.showCookies());
		standardFontButton.clicked.connect(this.chooseFont);
		fixedFontButton.clicked.connect(&this.chooseFixedFont);

		loadDefaults();
		loadFromSettings();
	}
	
	void accept()
	{
		saveToSettings();
		QDialog.accept();
	}

private:

	void loadDefaults()
	{
		QWebSettings defaultSettings = QWebSettings.globalSettings();
		string standardFontFamily = defaultSettings.fontFamily(QWebSettings.StandardFont);
		int standardFontSize = defaultSettings.fontSize(QWebSettings.DefaultFontSize);
		standardFont = QFont(standardFontFamily, standardFontSize);
		standardLabel.setText(Format(QLatin1String("{} {}"), standardFont.family(), standardFont.pointSize()));

		string fixedFontFamily = defaultSettings.fontFamily(QWebSettings.FixedFont);
		int fixedFontSize = defaultSettings.fontSize(QWebSettings.DefaultFixedFontSize);
		fixedFont = QFont(fixedFontFamily, fixedFontSize);
		fixedLabel.setText(Format(QLatin1String("{} {}"), fixedFont.family(), fixedFont.pointSize()));

		downloadsLocation.setText(QDesktopServices.storageLocation(QDesktopServices.DesktopLocation));

		enableJavascript.setChecked(defaultSettings.testAttribute(QWebSettings.JavascriptEnabled));
		enablePlugins.setChecked(defaultSettings.testAttribute(QWebSettings.PluginsEnabled));
	}

	void loadFromSettings()
	{
		auto settings = new QSettings;
		settings.beginGroup(QLatin1String("MainWindow"));
		string defaultHome = QLatin1String("http://qtsoftware.com");
		homeLineEdit.setText(settings.value(QLatin1String("home"), defaultHome).toString());
		settings.endGroup();

		settings.beginGroup(QLatin1String("history"));
		int historyExpire = settings.value(QLatin1String("historyExpire")).toInt();
		int idx = 0;
		switch (historyExpire) {
			case 1: idx = 0; break;
			case 7: idx = 1; break;
			case 14: idx = 2; break;
			case 30: idx = 3; break;
			case 365: idx = 4; break;
			case -1: idx = 5; break;
			default:
				idx = 5;
		}
		expireHistory.setCurrentIndex(idx);
		settings.endGroup();

		settings.beginGroup(QLatin1String("downloadmanager"));
		string downloadDirectory = settings.value(QLatin1String("downloadDirectory"), downloadsLocation.text()).toString();
		downloadsLocation.setText(downloadDirectory);
		settings.endGroup();

		settings.beginGroup(QLatin1String("general"));
		openLinksIn.setCurrentIndex(settings.value(QLatin1String("openLinksIn"), openLinksIn.currentIndex()).toInt());

		settings.endGroup();

		// Appearance
		settings.beginGroup(QLatin1String("websettings"));
		fixedFont = qVariantValue<QFont>(settings.value(QLatin1String("fixedFont"), fixedFont));
		standardFont = qVariantValue<QFont>(settings.value(QLatin1String("standardFont"), standardFont));

		standardLabel.setText(Format(QLatin1String("{} {}"), standardFont.family(), standardFont.pointSize()));
		fixedLabel.setText(Format(QLatin1String("{} {}"), fixedFont.family(), fixedFont.pointSize()));

		enableJavascript.setChecked(settings.value(QLatin1String("enableJavascript"), enableJavascript.isChecked()).toBool());
		enablePlugins.setChecked(settings.value(QLatin1String("enablePlugins"), enablePlugins.isChecked()).toBool());
		userStyleSheet.setText(settings.value(QLatin1String("userStyleSheet")).toUrl().toString());
		settings.endGroup();

		// Privacy
		settings.beginGroup(QLatin1String("cookies"));

		CookieJar jar = BrowserApplication.cookieJar();
		QByteArray value = settings.value(QLatin1String("acceptCookies"), QLatin1String("AcceptOnlyFromSitesNavigatedTo")).toByteArray();
		QMetaEnum acceptPolicyEnum = jar.staticMetaObject.enumerator(jar.staticMetaObject.indexOfEnumerator("AcceptPolicy"));
		CookieJar.AcceptPolicy acceptCookies = acceptPolicyEnum.keyToValue(value) == -1 ? CookieJar.AcceptOnlyFromSitesNavigatedTo :
			cast(CookieJar.AcceptPolicy) acceptPolicyEnum.keyToValue(value);
		switch(acceptCookies) {
			case CookieJar.AcceptAlways:
				acceptCombo.setCurrentIndex(0);
				break;
			case CookieJar.AcceptNever:
				acceptCombo.setCurrentIndex(1);
				break;
			case CookieJar.AcceptOnlyFromSitesNavigatedTo:
				acceptCombo.setCurrentIndex(2);
				break;
		}

		value = settings.value(QLatin1String("keepCookiesUntil"), QLatin1String("Expire")).toByteArray();
		QMetaEnum keepPolicyEnum = jar.staticMetaObject.enumerator(jar.staticMetaObject.indexOfEnumerator("KeepPolicy"));
		CookieJar.KeepPolicy keepCookies = keepPolicyEnum.keyToValue(value) == -1 ? CookieJar.KeepUntilExpire :
			cast(CookieJar.KeepPolicy)(keepPolicyEnum.keyToValue(value));
		switch(keepCookies) {
			case CookieJar.KeepUntilExpire:
				keepUntilCombo.setCurrentIndex(0);
				break;
			case CookieJar.KeepUntilExit:
				keepUntilCombo.setCurrentIndex(1);
				break;
			case CookieJar.KeepUntilTimeLimit:
				keepUntilCombo.setCurrentIndex(2);
				break;
		}
		settings.endGroup();

		// Proxy
		settings.beginGroup(QLatin1String("proxy"));
		proxySupport.setChecked(settings.value(QLatin1String("enabled"), false).toBool());
		proxyType.setCurrentIndex(settings.value(QLatin1String("type"), 0).toInt());
		proxyHostName.setText(settings.value(QLatin1String("hostName")).toString());
		proxyPort.setValue(settings.value(QLatin1String("port"), 1080).toInt());
		proxyUserName.setText(settings.value(QLatin1String("userName")).toString());
		proxyPassword.setText(settings.value(QLatin1String("password")).toString());
		settings.endGroup();
	}

	void saveToSettings()
	{
		QSettings settings;
		settings.beginGroup(QLatin1String("MainWindow"));
		settings.setValue(QLatin1String("home"), homeLineEdit.text());
		settings.endGroup();

		settings.beginGroup(QLatin1String("general"));
		settings.setValue(QLatin1String("openLinksIn"), openLinksIn.currentIndex());
		settings.endGroup();

		settings.beginGroup(QLatin1String("history"));
		int historyExpire = expireHistory.currentIndex();
		int idx = -1;
		switch (historyExpire) {
			case 0: idx = 1; break;
			case 1: idx = 7; break;
			case 2: idx = 14; break;
			case 3: idx = 30; break;
			case 4: idx = 365; break;
			case 5: idx = -1; break;
		}
		settings.setValue(QLatin1String("historyExpire"), idx);
		settings.endGroup();

		// Appearance
		settings.beginGroup(QLatin1String("websettings"));
		settings.setValue(QLatin1String("fixedFont"), fixedFont);
		settings.setValue(QLatin1String("standardFont"), standardFont);
		settings.setValue(QLatin1String("enableJavascript"), enableJavascript.isChecked());
		settings.setValue(QLatin1String("enablePlugins"), enablePlugins.isChecked());
		string userStyleSheetString = userStyleSheet.text();
		if (QFile.exists(userStyleSheetString))
			settings.setValue(QLatin1String("userStyleSheet"), QUrl.fromLocalFile(userStyleSheetString));
		else
			settings.setValue(QLatin1String("userStyleSheet"), QUrl(userStyleSheetString));
		settings.endGroup();

		//Privacy
		settings.beginGroup(QLatin1String("cookies"));

		CookieJar.KeepPolicy keepCookies;
		switch(acceptCombo.currentIndex()) {
			default:
			case 0:
				keepCookies = CookieJar.KeepUntilExpire;
				break;
			case 1:
				keepCookies = CookieJar.KeepUntilExit;
				break;
			case 2:
				keepCookies = CookieJar.KeepUntilTimeLimit;
				break;
		}
		CookieJar jar = BrowserApplication.cookieJar();
		QMetaEnum acceptPolicyEnum = jar.staticMetaObject.enumerator(jar.staticMetaObject.indexOfEnumerator("AcceptPolicy"));
		settings.setValue(QLatin1String("acceptCookies"), QLatin1String(acceptPolicyEnum.valueToKey(keepCookies)));

		CookieJar.KeepPolicy keepPolicy;
		switch(keepUntilCombo.currentIndex()) {
			default:
		case 0:
			keepPolicy = CookieJar.KeepUntilExpire;
			break;
		case 1:
			keepPolicy = CookieJar.KeepUntilExit;
			break;
		case 2:
			keepPolicy = CookieJar.KeepUntilTimeLimit;
			break;
		}

		QMetaEnum keepPolicyEnum = jar.staticMetaObject.enumerator(jar.staticMetaObject.indexOfEnumerator("KeepPolicy"));
		settings.setValue(QLatin1String("keepCookiesUntil"), QLatin1String(keepPolicyEnum.valueToKey(keepPolicy)));

		settings.endGroup();

		// proxy
		settings.beginGroup(QLatin1String("proxy"));
		settings.setValue(QLatin1String("enabled"), proxySupport.isChecked());
		settings.setValue(QLatin1String("type"), proxyType.currentIndex());
		settings.setValue(QLatin1String("hostName"), proxyHostName.text());
		settings.setValue(QLatin1String("port"), proxyPort.text());
		settings.setValue(QLatin1String("userName"), proxyUserName.text());
		settings.setValue(QLatin1String("password"), proxyPassword.text());
		settings.endGroup();

		BrowserApplication.instance().loadSettings();
		BrowserApplication.networkAccessManager().loadSettings();
		BrowserApplication.cookieJar().loadSettings();
		BrowserApplication.historyManager().loadSettings();
	}

	void setHomeToCurrentPage()
	{
		BrowserMainWindow mw = cast(BrowserMainWindow) parent();
		WebView webView = mw.currentTab();
		if (webView)
			homeLineEdit.setText(webView.url().toString());
	}

	void showCookies()
	{
		CookiesDialog dialog = new CookiesDialog(BrowserApplication.cookieJar(), this);
		dialog.exec();
	}

	void showExceptions()
	{
		CookiesExceptionsDialog dialog = new CookiesExceptionsDialog(BrowserApplication.cookieJar(), this);
		dialog.exec();
	}

	void chooseFont()
	{
		bool ok;
		QFont font = QFontDialog.getFont(&ok, standardFont, this);
		if ( ok ) {
			standardFont = font;
			standardLabel.setText(Format(QLatin1String("{} {}"), font.family(), font.pointSize()));
		}
	}

	void chooseFixedFont()
	{
		bool ok;
		QFont font = QFontDialog.getFont(&ok, fixedFont, this);
		if ( ok ) {
			fixedFont = font;
			fixedLabel.setText(Format(QLatin1String("{} {}"), font.family(), font.pointSize()));
		}
	}

private:

	QFont standardFont;
	QFont fixedFont;
}
