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
module cookiejar;

import qt.network.QNetworkCookieJar;
//import qt.core.QDebug;

import qt.core.QAbstractItemModel;
import qt.core.QDateTime;
import qt.core.QDir;
import qt.core.QFile;
//import qt.core.QMetaEnum;
import qt.core.QSettings;
import qt.core.QUrl;

import qt.gui.QDialog;
import qt.gui.QTableView;
import qt.gui.QCompleter;
import qt.gui.QDesktopServices;
import qt.gui.QFont;
import qt.gui.QFontMetrics;
import qt.gui.QHeaderView;
import qt.gui.QKeyEvent;
import qt.gui.QSortFilterProxyModel;
import qt.gui.QAbstractTableModel;

import qt.webkit.QWebSettings;

import cookiejar;
import autosaver;


static const uint JAR_VERSION = 23;

QDataStream opShl(QDataStream stream, QNetworkCookie[] list)
{
	stream << JAR_VERSION;
	stream << cast(uint) list.length;
	for (int i = 0; i < list.length; ++i)
		stream << list[i].toRawForm();
	return stream;
}

QDataStream opShr(QDataStream stream, ref QNetworkCookie[] list)
{
	list.clear();

	uint version_;
	stream >> version_;

	if (version_ != JAR_VERSION)
		return stream;

	uint count;
	stream >> count;
	for(uint i = 0; i < count; ++i)
	{
		auto value = new QByteArray;
		stream >> value;
		QNetworkCookie[] newCookies = QNetworkCookie.parseCookies(value);
		if (newCookies.length == 0 && value.length() != 0) {
			qWarning("CookieJar: Unable to parse saved cookie:" ~ cast(string) value.data());
		}
		
		for (int j = 0; j < newCookies.length; ++j)
			list ~= newCookies[j];
		
		if (stream.atEnd())
			break;
	}
	return stream;
}

class CookieJar : public QNetworkCookieJar
{
	mixin Signal!("cookiesChanged");

public:

	enum AcceptPolicy {
		AcceptAlways,
		AcceptNever,
		AcceptOnlyFromSitesNavigatedTo
	}

	enum KeepPolicy {
		KeepUntilExpire,
		KeepUntilExit,
		KeepUntilTimeLimit
	}

	this(QObject parent = null)
	{
		super(parent);
		m_loaded = false;
		m_saveTimer = new AutoSaver(this);
		m_acceptCookies = AcceptOnlyFromSitesNavigatedTo;
	}

	~this()
	{
		if (m_keepCookies == KeepUntilExit)
			clear();
		m_saveTimer.saveIfNeccessary();
	}

	QNetworkCookie[] cookiesForUrl(QUrl url)
	{
		CookieJar that = cast(CookieJar) this;
		if (!m_loaded)
			that.load();

		QWebSettings globalSettings = QWebSettings.globalSettings();
		if (globalSettings.testAttribute(QWebSettings.PrivateBrowsingEnabled)) {
			QNetworkCookie[] noCookies;
			return noCookies;
		}

		return QNetworkCookieJar.cookiesForUrl(url);
	}

	bool setCookiesFromUrl(QNetworkCookie[] cookieList, QUrl url)
	{
		if (!m_loaded)
			load();

		QWebSettings globalSettings = QWebSettings.globalSettings();
		if (globalSettings.testAttribute(QWebSettings.PrivateBrowsingEnabled))
			return false;

		string host = url.host();
		bool eBlock = qBinaryFind(m_exceptions_block.begin(), m_exceptions_block.end(), host) != m_exceptions_block.end();
		bool eAllow = qBinaryFind(m_exceptions_allow.begin(), m_exceptions_allow.end(), host) != m_exceptions_allow.end();
		bool eAllowSession = qBinaryFind(m_exceptions_allowForSession.begin(), m_exceptions_allowForSession.end(), host) != m_exceptions_allowForSession.end();

		bool addedCookies = false;
		// pass exceptions
		bool acceptInitially = (m_acceptCookies != AcceptNever);
		if ((acceptInitially && !eBlock) || (!acceptInitially && (eAllow || eAllowSession))) {
			// pass url domain == cookie domain
			QDateTime soon = QDateTime.currentDateTime();
			soon = soon.addDays(90);
			foreach(QNetworkCookie cookie; cookieList) {
				QNetworkCookie[] lst;
				if (m_keepCookies == KeepUntilTimeLimit && !cookie.isSessionCookie() && cookie.expirationDate() > soon) {
					cookie.setExpirationDate(soon);
				}
				lst += cookie;
				if (QNetworkCookieJar.setCookiesFromUrl(lst, url)) {
					addedCookies = true;
				} else {
					// finally force it in if wanted
					if (m_acceptCookies == AcceptAlways) {
						QNetworkCookie[] cookies = allCookies();
						cookies += cookie;
						setAllCookies(cookies);
						addedCookies = true;
					}
					/*
					else
					qWarning() << "setCookiesFromUrl failed" << url << cookieList.value(0).toRawForm();
					*/
				}
			}
		}

		if (addedCookies) {
			m_saveTimer.changeOccurred();
			cookiesChanged.emit();
		}
		return addedCookies;
	}

	AcceptPolicy acceptPolicy()
	{
		if (!m_loaded)
			(cast(CookieJar) this).load();
		return m_acceptCookies;
	}
    
	void setAcceptPolicy(AcceptPolicy policy)
	{
		if (!m_loaded)
			load();
		if (policy == m_acceptCookies)
			return;
		m_acceptCookies = policy;
		m_saveTimer.changeOccurred();
	}

	KeepPolicy keepPolicy()
	{
		if (!m_loaded)
			(cast(CookieJar) this).load();
		return m_keepCookies;
	}

	void setKeepPolicy(KeepPolicy policy)
	{
		if (!m_loaded)
			load();
		if (policy == m_keepCookies)
			return;
		m_keepCookies = policy;
		m_saveTimer.changeOccurred();
	}


	string[] blockedCookies()
	{
		if (!m_loaded)
			(cast(CookieJar) this).load();
		return m_exceptions_block;
	}

	string[] allowedCookies()
	{
		if (!m_loaded)
			(cast(CookieJar) this).load();
		return m_exceptions_allow;
	}
    
	string[] allowForSessionCookies()
	{
		if (!m_loaded)
			(cast(CookieJar) this).load();
		return m_exceptions_allowForSession;
	}

	void setBlockedCookies(string[] list)
	{
		if (!m_loaded)
			load();
		m_exceptions_block = list;
		qSort(m_exceptions_block.begin(), m_exceptions_block.end());
		m_saveTimer.changeOccurred();
	}
    
	void setAllowedCookies(string[] list)
	{
		if (!m_loaded)
			load();
		m_exceptions_allow = list;
		qSort(m_exceptions_allow.begin(), m_exceptions_allow.end());
		m_saveTimer.changeOccurred();
	}
    
	void setAllowForSessionCookies(string[] list)
	{
		if (!m_loaded)
			load();
		m_exceptions_allowForSession = list;
		qSort(m_exceptions_allowForSession.begin(), m_exceptions_allowForSession.end());
		m_saveTimer.changeOccurred();
	}

public:

	void clear()
	{
		setAllCookies(QNetworkCookie[]());
		m_saveTimer.changeOccurred();
		cookiesChanged.emit();
	}

	void loadSettings()
	{
		QSettings settings;
		settings.beginGroup("cookies");
		QByteArray value = settings.value("acceptCookies",
				"AcceptOnlyFromSitesNavigatedTo").toByteArray();
		QMetaEnum acceptPolicyEnum = staticMetaObject.enumerator(staticMetaObject.indexOfEnumerator("AcceptPolicy"));
		m_acceptCookies = acceptPolicyEnum.keyToValue(value) == -1 ?
				AcceptOnlyFromSitesNavigatedTo :
				cast(AcceptPolicy) acceptPolicyEnum.keyToValue(value);

		value = settings.value("keepCookiesUntil", "KeepUntilExpire").toByteArray();
		QMetaEnum keepPolicyEnum = staticMetaObject.enumerator(staticMetaObject.indexOfEnumerator("KeepPolicy"));
		m_keepCookies = keepPolicyEnum.keyToValue(value) == -1 ?
				KeepUntilExpire :
				cast(KeepPolicy) keepPolicyEnum.keyToValue(value);

		if (m_keepCookies == KeepUntilExit)
			setAllCookies(null);

		m_loaded = true;
		cookiesChanged.emit();
	}

private:

	void save()
	{
		if (!m_loaded)
			return;
		purgeOldCookies();
		string directory = QDesktopServices.storageLocation(QDesktopServices.DataLocation);
		if (directory.isEmpty())
			directory = QDir.homePath() ~ "/." ~ QCoreApplication.applicationName();
		if (!QFile.exists(directory)) {
			QDir dir;
			dir.mkpath(directory);
		}
		auto cookieSettings = new QSettings(directory ~ "/cookies.ini", QSettings.IniFormat);
		QNetworkCookie[] cookies = allCookies();
		for (int i = cookies.length - 1; i >= 0; --i) {
			if (cookies[i].isSessionCookie())
				cookies.removeAt(i);
		}
		//cookieSettings.setValue("cookies", qVariantFromValue<QNetworkCookie[] >(cookies)); //TODO!
		cookieSettings.beginGroup("Exceptions");
		cookieSettings.setValue("block", m_exceptions_block);
		cookieSettings.setValue("allow", m_exceptions_allow);
		cookieSettings.setValue("allowForSession", m_exceptions_allowForSession);

		// save cookie settings
		auto settings = new QSettings;
		settings.beginGroup("cookies");
		QMetaEnum acceptPolicyEnum = staticMetaObject.enumerator(staticMetaObject.indexOfEnumerator("AcceptPolicy"));
		settings.setValue("acceptCookies", acceptPolicyEnum.valueToKey(m_acceptCookies));

		QMetaEnum keepPolicyEnum = staticMetaObject.enumerator(staticMetaObject.indexOfEnumerator("KeepPolicy"));
		settings.setValue("keepCookiesUntil", keepPolicyEnum.valueToKey(m_keepCookies));
	}

private:

	void purgeOldCookies()
	{
		QNetworkCookie[] cookies = allCookies();
		if (cookies.isEmpty())
			return;
		int oldCount = cookies.count();
		QDateTime now = QDateTime.currentDateTime();
		for (int i = cookies.length - 1; i >= 0; --i) {
			if (!cookies[i].isSessionCookie() && cookies[i].expirationDate() < now)
				cookies.removeAt(i);
		}
		if (oldCount == cookies.length)
			return;
		setAllCookies(cookies);
		cookiesChanged.emit();
	}

	void load()
	{
		if (m_loaded)
			return;
		// load cookies and exceptions
		qRegisterMetaTypeStreamOperators!(QNetworkCookie[])("QNetworkCookie[]");
		auto cookieSettings = new QSettings(QDesktopServices.storageLocation(QDesktopServices.DataLocation) ~ "/cookies.ini", QSettings.IniFormat);
		setAllCookies(cast(QNetworkCookie[]) (cookieSettings.value("cookies")));
		cookieSettings.beginGroup("Exceptions");
		m_exceptions_block = cookieSettings.value("block").toStringList();
		m_exceptions_allow = cookieSettings.value("allow").toStringList();
		m_exceptions_allowForSession = cookieSettings.value("allowForSession").toStringList();
		qSort(m_exceptions_block.begin(), m_exceptions_block.end());
		qSort(m_exceptions_allow.begin(), m_exceptions_allow.end());
		qSort(m_exceptions_allowForSession.begin(), m_exceptions_allowForSession.end());

		loadSettings();
	}

	bool m_loaded;
	AutoSaver m_saveTimer;

	AcceptPolicy m_acceptCookies;
	KeepPolicy m_keepCookies;

	string[] m_exceptions_block;
	string[] m_exceptions_allow;
	string[] m_exceptions_allowForSession;
}

class CookieModel : public QAbstractTableModel
{

public:

	this(CookieJar jar, QObject parent = null)
	{
		super(parent);
		m_cookieJar = cookieJar;
		m_cookieJar.cookiesChanged.connect(&this.cookiesChanged);
		m_cookieJar.load();
	}

	QVariant headerData(int section, Qt.Orientation orientation, int role)
	{
		if (role == Qt.SizeHintRole) {
			auto font = new QFont;
			font.setPointSize(10);
			auto fm = new QFontMetrics(font);
			int height = fm.height() + fm.height()/3;
			int width = fm.width(headerData(section, orientation, Qt.DisplayRole).toString());
			return QSize(width, height);
		}

		if (orientation == Qt.Horizontal) {
			if (role != Qt.DisplayRole)
				return QVariant();

			switch (section) {
				case 0:
					return tr("Website");
				case 1:
					return tr("Name");
				case 2:
					return tr("Path");
				case 3:
					return tr("Secure");
				case 4:
					return tr("Expires");
				case 5:
					return tr("Contents");
				default:
					return new QVariant();
			}
		}
		return QAbstractTableModel.headerData(section, orientation, role);
	}

	QVariant data(QModelIndex index, int role = Qt.DisplayRole)
	{
		QNetworkCookie[] lst;
		
		if (m_cookieJar)
			lst = m_cookieJar.allCookies();
		
		if (index.row() < 0 || index.row() >= lst.length)
			return new QVariant();

		switch (role) {
			case Qt.DisplayRole:
			case Qt.EditRole: {
			QNetworkCookie cookie = lst[index.row];
				switch (index.column()) {
				    case 0:
					return cookie.domain();
				    case 1:
					return cookie.name();
				    case 2:
					return cookie.path();
				    case 3:
					return cookie.isSecure();
				    case 4:
					return cookie.expirationDate();
				    case 5:
					return cookie.value();
				}
			}
			case Qt.FontRole:{
				auto font = new QFont;
				font.setPointSize(10);
				return font;
			}
		}

		return QVariant();
	}

	int columnCount(QModelIndex parent = QModelIndex())
	{
		return (parent.isValid()) ? 0 : 6;
	}


	int rowCount(QModelIndex parent = QModelIndex())
	{
		return (parent.isValid() || !m_cookieJar) ? 0 : m_cookieJar.allCookies().count();
	}

	bool removeRows(int row, int count, QModelIndex parent = QModelIndex())
	{
		if (parent.isValid() || !m_cookieJar)
			return false;
		int lastRow = row + count - 1;
		beginRemoveRows(parent, row, lastRow);
		QNetworkCookie[] lst = m_cookieJar.allCookies();
		for (int i = lastRow; i >= row; --i) {
			lst.removeAt(i);
		}
		m_cookieJar.setAllCookies(lst);
		endRemoveRows();
		return true;
	}

private:
	
	void cookiesChanged()
	{
		reset();
	}

private:

	CookieJar m_cookieJar;
}


import ui_cookiesdialog;
import ui_cookiesexceptionsdialog;


class CookiesDialog : public QDialog //, public Ui_CookiesDialog
{
	mixin Ui_CookiesDialog;

public:

	this(CookieJar cookieJar, QWidget parent = null)
	{
		super(parent);
		setupUi(this);
		setWindowFlags(Qt.Sheet);
		CookieModel model = new CookieModel(cookieJar, this);
		m_proxyModel = new QSortFilterProxyModel(this);
		search.textChanged.connect(&m_proxyModel.setFilterFixedString);
		removeButton.clicked.connect(&cookiesTable.removeOne);
		removeAllButton.clicked.connect(&cookiesTable.removeAll);
		m_proxyModel.setSourceModel(model);
		cookiesTable.verticalHeader().hide();
		cookiesTable.setSelectionBehavior(QAbstractItemView.SelectRows);
		cookiesTable.setModel(m_proxyModel);
		cookiesTable.setAlternatingRowColors(true);
		cookiesTable.setTextElideMode(Qt.ElideMiddle);
		cookiesTable.setShowGrid(false);
		cookiesTable.setSortingEnabled(true);
		QFont f = font();
		f.setPointSize(10);
		QFontMetrics fm(f);
		int height = fm.height() + fm.height()/3;
		cookiesTable.verticalHeader().setDefaultSectionSize(height);
		cookiesTable.verticalHeader().setMinimumSectionSize(-1);
		for (int i = 0; i < model.columnCount(); ++i){
			int header = cookiesTable.horizontalHeader().sectionSizeHint(i);
			switch (i) {
				case 0:
					header = fm.width("averagehost.domain.com");
					break;
				case 1:
					header = fm.width("_session_id");
					break;
				case 4:
					header = fm.width(QDateTime.currentDateTime().toString(Qt.LocalDate));
					break;
			}
			int buffer = fm.width("xx");
			header += buffer;
			cookiesTable.horizontalHeader().resizeSection(i, header);
		}
		cookiesTable.horizontalHeader().setStretchLastSection(true);
	}
	
private:

	QSortFilterProxyModel m_proxyModel;
}

class CookieExceptionsModel : public QAbstractTableModel
{
public:

	this(CookieJar cookieJar, QObject parent = null)
	{
		super(parent);
		m_cookieJar = cookiejar;
		m_allowedCookies = m_cookieJar.allowedCookies();
		m_blockedCookies = m_cookieJar.blockedCookies();
		m_sessionCookies = m_cookieJar.allowForSessionCookies();
	}

	QVariant headerData(int section, Qt.Orientation orientation, int role)
	{
		if (role == Qt.SizeHintRole) {
			auto font = new QFont;
			font.setPointSize(10);
			auto fm =new QFontMetrics(font);
			int height = fm.height() + fm.height()/3;
			int width = fm.width(headerData(section, orientation, Qt.DisplayRole).toString());
			return QSize(width, height);
		}

		if (orientation == Qt.Horizontal && role == Qt.DisplayRole) {
			switch (section) {
				case 0:
					return tr("Website");
				case 1:
					return tr("Status");
			}
		}
		return QAbstractTableModel.headerData(section, orientation, role);
	}

	QVariant data(QModelIndex index, int role = Qt.DisplayRole)
	{
		if (index.row() < 0 || index.row() >= rowCount())
			return QVariant();

		switch (role) {
			case Qt.DisplayRole:
			case Qt.EditRole: {
				int row = index.row();
				if (row < m_allowedCookies.length) {
					switch (index.column()) {
						case 0:
							return m_allowedCookies[row];
						case 1:
							return tr("Allow");
					}
				}
				row = row - m_allowedCookies.length;
				if (row < m_blockedCookies.length) {
					switch (index.column()) {
						case 0:
							return m_blockedCookies[row];
						case 1:
							return tr("Block");
					}
				}
				row = row - m_blockedCookies.length;
				if (row < m_sessionCookies.length) {
					switch (index.column()) {
						case 0:
							return m_sessionCookies[row];
						case 1:
							return tr("Allow For Session");
					}
				}
			}
			case Qt.FontRole:{
				auto font = new QFont;
				font.setPointSize(10);
				return font;
			}
		}
		return QVariant();
	}

	int columnCount(QModelIndex parent = QModelIndex())
	{
		return (parent.isValid()) ? 0 : 2;
	}
	
	int rowCount(QModelIndex parent = QModelIndex())
	{
		return (parent.isValid() || !m_cookieJar) ? 0 : m_allowedCookies.length + m_blockedCookies.length + m_sessionCookies.length;
	}

	bool removeRows(int row, int count, QModelIndex parent)
	{
		if (parent.isValid() || !m_cookieJar)
			return false;

		int lastRow = row + count - 1;
		beginRemoveRows(parent, row, lastRow);
		for (int i = lastRow; i >= row; --i) {
			if (i < m_allowedCookies.length) {
				m_allowedCookies.removeAt(row);
				continue;
			}
			i = i - m_allowedCookies.length;
			if (i < m_blockedCookies.length) {
				m_blockedCookies.removeAt(row);
				continue;
			}
			i = i - m_blockedCookies.length;
			if (i < m_sessionCookies.length) {
				m_sessionCookies.removeAt(row);
				continue;
			}
		}
		
		m_cookieJar.setAllowedCookies(m_allowedCookies);
		m_cookieJar.setBlockedCookies(m_blockedCookies);
		m_cookieJar.setAllowForSessionCookies(m_sessionCookies);
		endRemoveRows();
		return true;
	}

private:

	CookieJar m_cookieJar;

	// Domains we allow, Domains we block, Domains we allow for this session
	string[] m_allowedCookies;
	string[] m_blockedCookies;
	string[] m_sessionCookies;
}


class CookiesExceptionsDialog : public QDialog //, public Ui_CookiesExceptionsDialog
{
	mixin Ui_CookiesExceptionsDialog;

public:

	this(CookieJar cookieJar, QWidget parent = null)
	{
		super(parent);
		m_cookieJar = cookieJar;
		setupUi(this);
		setWindowFlags(Qt.Sheet);
		removeButton.clicked.connect(&exceptionTable.removeOne);
		removeAllButton.clicked.connect(&exceptionTable.removeAll);
		exceptionTable.verticalHeader().hide();
		exceptionTable.setSelectionBehavior(QAbstractItemView.SelectRows);
		exceptionTable.setAlternatingRowColors(true);
		exceptionTable.setTextElideMode(Qt.ElideMiddle);
		exceptionTable.setShowGrid(false);
		exceptionTable.setSortingEnabled(true);
		m_exceptionsModel = new CookieExceptionsModel(cookieJar, this);
		m_proxyModel = new QSortFilterProxyModel(this);
		m_proxyModel.setSourceModel(m_exceptionsModel);
		search.textChanged.connect(&m_proxyModel.setFilterFixedString);
		exceptionTable.setModel(m_proxyModel);

		CookieModel cookieModel = new CookieModel(cookieJar, this);
		domainLineEdit.setCompleter(new QCompleter(cookieModel, domainLineEdit));

		domainLineEdit.textChanged.connect(&this.textChanged);
		blockButton.clicked.connect(&this.block);
		allowButton.clicked.connect(&this.allow);
		allowForSessionButton.clicked.connect(&this.allowForSession);

		QFont f = font();
		f.setPointSize(10);
		auto fm = new QFontMetrics(f);
		int height = fm.height() + fm.height()/3;
		exceptionTable.verticalHeader().setDefaultSectionSize(height);
		exceptionTable.verticalHeader().setMinimumSectionSize(-1);
		for (int i = 0; i < m_exceptionsModel.columnCount(); ++i) {
			int header = exceptionTable.horizontalHeader().sectionSizeHint(i);
			switch (i) {
				case 0:
				header = fm.width("averagebiglonghost.domain.com");
				break;
				case 1:
				header = fm.width("Allow For Session");
				break;
			}
			int buffer = fm.width("xx");
			header += buffer;
			exceptionTable.horizontalHeader().resizeSection(i, header);
		}
	}

private:

	void block()
	{
		if (domainLineEdit.text().isEmpty())
			return;
		m_exceptionsModel.m_blockedCookies ~= domainLineEdit.text();
		m_cookieJar.setBlockedCookies(m_exceptionsModel.m_blockedCookies);
		m_exceptionsModel.reset();
	}

	void allow()
	{
		if (domainLineEdit.text().isEmpty())
			return;
		m_exceptionsModel.m_allowedCookies ~= domainLineEdit.text();
		m_cookieJar.setAllowedCookies(m_exceptionsModel.m_allowedCookies);
		m_exceptionsModel.reset();
	}
	void allowForSession()
	{
		if (domainLineEdit.text().isEmpty())
			return;
		m_exceptionsModel.m_sessionCookie ~= domainLineEdit.text();
		m_cookieJar.setAllowForSessionCookies(m_exceptionsModel.m_sessionCookies);
		m_exceptionsModel.reset();
	}
	
	void textChanged(string text)
	{
		bool enabled = !text.isEmpty();
		blockButton.setEnabled(enabled);
		allowButton.setEnabled(enabled);
		allowForSessionButton.setEnabled(enabled);
	}
	
private:
	
	CookieExceptionsModel m_exceptionsModel;
	QSortFilterProxyModel m_proxyModel;
	CookieJar m_cookieJar;
}
