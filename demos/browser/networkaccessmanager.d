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
module networkaccessmanager;


import qt.core.QSettings;
import qt.gui.QDesktopServices;
import qt.gui.QDialog;
import qt.gui.QMessageBox;
import qt.gui.QStyle;
import qt.gui.QTextDocument;
import qt.network.QNetworkAccessManager;
import qt.network.QAuthenticator;
import qt.network.QNetworkDiskCache;
import qt.network.QNetworkProxy;
import qt.network.QNetworkReply;
import qt.network.QSslError;

import browserapplication;
import browsermainwindow;
import ui_passworddialog;
import ui_proxydialog;


class NetworkAccessManager : public QNetworkAccessManager
{
public:

	this(QObject parent = null)
	{
		super(parent);

		this.authenticationRequired.connect(&authenticationRequired);
		this.proxyAuthenticationRequired.connect(&proxyAuthenticationRequired);
		version(QT_NO_OPENSSL) {
			this.sslErrors.connect(&sslErrors);
		}
		loadSettings();

		QNetworkDiskCache diskCache = new QNetworkDiskCache(this);
		string location = QDesktopServices.storageLocation(QDesktopServices.CacheLocation);
		diskCache.setCacheDirectory(location);
		setCache(diskCache);
	}

private:

    string[] sslTrustedHostList;

public:

	void loadSettings()
	{
		auto settings = new QSettings;
		settings.beginGroup("proxy");
		QNetworkProxy proxy;
		if (settings.value("enabled", false).toBool()) {
			if (settings.value("type", 0).toInt() == 0)
				proxy = QNetworkProxy.Socks5Proxy;
			else
				proxy = QNetworkProxy.HttpProxy;
			proxy.setHostName(settings.value("hostName").toString());
			proxy.setPort(settings.value("port", 1080).toInt());
			proxy.setUser(settings.value("userName").toString());
			proxy.setPassword(settings.value("password").toString());
		}
		setProxy(proxy);
	}

private:

	void authenticationRequired(QNetworkReply reply, QAuthenticator auth)
	{
		BrowserMainWindow mainWindow = BrowserApplication.instance().mainWindow();

		auto dialog = new QDialog(mainWindow);
		dialog.setWindowFlags(Qt.Sheet);

		auto passwordDialog = new Ui.PasswordDialog;
		passwordDialog.setupUi(&dialog);

		passwordDialog.iconLabel.setText(null);
		passwordDialog.iconLabel.setPixmap(mainWindow.style().standardIcon(QStyle.SP_MessageBoxQuestion, 0, mainWindow).pixmap(32, 32));

		string introMessage = Format(tr("<qt>Enter username and password for \"{}\" at {}</qt>"), Qt.escape(reply.url().toString()), Qt.escape(reply.url().toString()));
		passwordDialog.introLabel.setText(introMessage);
		passwordDialog.introLabel.setWordWrap(true);

		if (dialog.exec() == QDialog.Accepted) {
			auth.setUser(passwordDialog.userNameLineEdit.text());
			auth.setPassword(passwordDialog.passwordLineEdit.text());
		}
	}

	void proxyAuthenticationRequired(QNetworkProxy proxy, QAuthenticator auth)
	{
		BrowserMainWindow mainWindow = BrowserApplication.instance().mainWindow();

		auto dialog = new QDialog(mainWindow);
		dialog.setWindowFlags(Qt.Sheet);

		auto proxyDialog = new Ui.ProxyDialog;
		proxyDialog.setupUi(&dialog);

		proxyDialog.iconLabel.setText(null);
		proxyDialog.iconLabel.setPixmap(mainWindow.style().standardIcon(QStyle.SP_MessageBoxQuestion, 0, mainWindow).pixmap(32, 32));

		string introMessage = Format(tr("<qt>Connect to proxy \"{}\" using:</qt>"), Qt.escape(proxy.hostName()));
		proxyDialog.introLabel.setText(introMessage);
		proxyDialog.introLabel.setWordWrap(true);

		if (dialog.exec() == QDialog.Accepted) {
			auth.setUser(proxyDialog.userNameLineEdit.text());
			auth.setPassword(proxyDialog.passwordLineEdit.text());
		}
	}

version(QT_NO_OPENSSL)
{
	void sslErrors(QNetworkReply reply, QSslError[] error)
	{
		// check if SSL certificate has been trusted already
		string replyHost = reply.url().host() ~ ":" ~ reply.url().port();
		if(! sslTrustedHostList.contains(replyHost)) {
			BrowserMainWindow mainWindow = BrowserApplication.instance().mainWindow();

			string[] errorStrings;
			for (int i = 0; i < error.count(); ++i)
				errorStrings += error[i].errorString();
			string errors = errorStrings ~ "\n";
			int ret = QMessageBox.warning(mainWindow, QCoreApplication.applicationName(),
				Format(tr("SSL Errors:\n\n{}\n\n{}\n\n"
				"Do you want to ignore these errors for this host?"), reply.url().toString(), errors),
				QMessageBox.Yes | QMessageBox.No, QMessageBox.No);
			if (ret == QMessageBox.Yes) {
				reply.ignoreSslErrors();
				sslTrustedHostList.append(replyHost);
			}
		}
	}
}

}
