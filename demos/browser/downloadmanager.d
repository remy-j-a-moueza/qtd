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

module downloadmanager;


import qt.core.QFile;
import qt.core.QTime;
//import qt.core.QMetaEnum;
import qt.core.QSettings;
//import qt.core.QDebug;
import qt.gui.QDesktopServices;
import qt.gui.QFileDialog;
import qt.gui.QHeaderView;
import qt.gui.QFileIconProvider;
import qt.core.QAbstractListModel;
import qt.network.QNetworkReply;
import qt.webkit.QWebSettings;

import tango.text.convert.Format;

import autosaver;
import browserapplication;
import networkaccessmanager;
import ui_downloaddialog;
import ui_downloaditem;


class DownloadItem : public QWidget //, public Ui_DownloadItem
{
	mixin Signal!("statusChanged");
	mixin Ui_DownloadItem;

public:
 
	/*!
	DownloadItem is a widget that is displayed in the download manager list.
	It moves the data from the QNetworkReply into the QFile as well
	as update the information/progressbar and report errors.
	*/
	this(QNetworkReply reply = null, bool requestFileName = false, QWidget parent = null)
	{
		super(parent);
		m_reply = reply;
		m_requestFileName = requestFileName;
		m_bytesReceived = 0;

		setupUi(this);
		QPalette p = downloadInfoLabel.palette();
		p.setColor(QPalette.Text, Qt.darkGray);
		downloadInfoLabel.setPalette(p);
		progressBar.setMaximum(0);
		tryAgainButton.hide();
		stopButton.clicked.connect(&this.stop);
		openButton.clicked.connect(&this.open);
		tryAgainButton.clicked.connect(&this.tryAgain);

		init();
	}

	bool downloading()
	{
		return (progressBar.isVisible());
	}

	bool downloadedSuccessfully()
	{
		return (stopButton.isHidden() && tryAgainButton.isHidden());
	}

	QUrl m_url;
	QFile m_output;
	QNetworkReply m_reply;

private:
	
	void stop()
	{
		setUpdatesEnabled(false);
		stopButton.setEnabled(false);
		stopButton.hide();
		tryAgainButton.setEnabled(true);
		tryAgainButton.show();
		setUpdatesEnabled(true);
		m_reply.abort();
	}

	void tryAgain()
	{
		if (!tryAgainButton.isEnabled())
			return;

		tryAgainButton.setEnabled(false);
		tryAgainButton.setVisible(false);
		stopButton.setEnabled(true);
		stopButton.setVisible(true);
		progressBar.setVisible(true);

		QNetworkReply r = BrowserApplication.networkAccessManager().get(QNetworkRequest(m_url));
		if (m_reply)
			m_reply.deleteLater();
		if (m_output.exists())
			m_output.remove();
		m_reply = r;
		init();
		statusChanged.emit();
	}

	void open()
	{
		auto info = new QFileInfo(m_output);
		QUrl url = QUrl.fromLocalFile(info.absolutePath());
		QDesktopServices.openUrl(url);
	}

	void downloadReadyRead()
	{
		if (m_requestFileName && m_output.fileName().isEmpty())
			return;
		if (!m_output.isOpen()) {
			// in case someone else has already put a file there
			if (!m_requestFileName)
				getFileName();
			if (!m_output.open(QIODevice.WriteOnly)) {
				downloadInfoLabel.setText(Format(tr("Error opening save file: {}"), m_output.errorString()));
				stopButton.click();
				statusChanged.emit();
				return;
			}
			statusChanged.emit();
		}
		if (-1 == m_output.write(m_reply.readAll())) {
			downloadInfoLabel.setText(Format(tr("Error saving: {}"), m_output.errorString()));
			stopButton.click();
		}
	}

	void error(QNetworkReply.NetworkError code)
	{
		qDebug("DownloadItem::error" ~ m_reply.errorString() ~ m_url);
		downloadInfoLabel.setText(Format(tr("Network Error: {}"), m_reply.errorString()));
		tryAgainButton.setEnabled(true);
		tryAgainButton.setVisible(true);
	}

	void downloadProgress(ulong bytesReceived, ulong bytesTotal)
	{
		m_bytesReceived = bytesReceived;
		if (bytesTotal == -1) {
			progressBar.setValue(0);
			progressBar.setMaximum(0);
		} else {
			progressBar.setValue(bytesReceived);
			progressBar.setMaximum(bytesTotal);
		}
		updateInfoLabel();
	}

	void metaDataChanged()
	{
		qDebug("DownloadItem::metaDataChanged: not handled.");
	}

	void finished()
	{
		progressBar.hide();
		stopButton.setEnabled(false);
		stopButton.hide();
		m_output.close();
		updateInfoLabel();
		statusChanged.emit();
	}

private:

	void getFileName()
	{
		auto settings = new QSettings;
		settings.beginGroup("downloadmanager");
		string defaultLocation = QDesktopServices.storageLocation(QDesktopServices.DesktopLocation);
		string downloadDirectory = settings.value("downloadDirectory", defaultLocation).toString();
		if (!downloadDirectory.isEmpty())
			downloadDirectory ~= "/";

		string defaultFileName = saveFileName(downloadDirectory);
		string fileName = defaultFileName;
		if (m_requestFileName) {
			fileName = QFileDialog.getSaveFileName(this, tr("Save File"), defaultFileName);
			if (fileName.isEmpty()) {
				m_reply.close();
				fileNameLabel.setText(Format(tr("Download canceled: {}"), (new QFileInfo(defaultFileName)).fileName()));
				return;
			}
		}
		m_output.setFileName(fileName);
		fileNameLabel.setText((new QFileInfo(m_output.fileName())).fileName());
		if (m_requestFileName)
			downloadReadyRead();
	}

	void init()
	{
		if (!m_reply)
			return;

		// attach to the m_reply
		m_url = m_reply.url();
		m_reply.setParent(this);
		m_reply.readyRead.connect(&this.downloadReadyRead);
		m_reply.error.connect(&this.error);
		m_reply.downloadProgress.connect(&this.downloadProgress);
		m_reply.metaDataChanged.connect(&this.metaDataChanged);
		m_reply.finished.connect(&this.finished);

		// reset info
		downloadInfoLabel.clear();
		progressBar.setValue(0);
		getFileName();

		// start timer for the download estimation
		m_downloadTime.start();

		if (m_reply.error() != QNetworkReply.NoError) {
			error(m_reply.error());
			finished();
		}
	}

	void updateInfoLabel()
	{
		if (m_reply.error() == QNetworkReply.NoError)
			return;

		ulong bytesTotal = progressBar.maximum();
		bool running = !downloadedSuccessfully();

		// update info label
		double speed = m_bytesReceived * 1000.0 / m_downloadTime.elapsed();
		double timeRemaining = (cast(double)(bytesTotal - m_bytesReceived)) / speed;
		string timeRemainingString = tr("seconds");
		if (timeRemaining > 60) {
			timeRemaining = timeRemaining / 60;
			timeRemainingString = tr("minutes");
		}
		timeRemaining = floor(timeRemaining);

		// When downloading the eta should never be 0
		if (timeRemaining == 0)
			timeRemaining = 1;

		string info;
		if (running) {
			string remaining;
			if (bytesTotal != 0)
				remaining = Format(tr("- {} {} remaining"), timeRemaining, timeRemainingString);
			
			info = Format(tr("{} of {} ({}/sec) {}"),
					dataString(m_bytesReceived),
					bytesTotal == 0 ? tr("?") : dataString(bytesTotal),
					dataString(cast(int) speed),
					remaining);
		} else {
			if (m_bytesReceived == bytesTotal)
				info = dataString(m_output.size());
			else
				info = Format(tr("{} of {} - Stopped"),
					dataString(m_bytesReceived),
					dataString(bytesTotal));
		}
		downloadInfoLabel.setText(info);
	}

	string dataString(int size)
	{
		string unit;
		if (size < 1024) {
			unit = tr("bytes");
		} else if (size < 1024*1024) {
			size /= 1024;
			unit = tr("kB");
		} else {
			size /= 1024*1024;
			unit = tr("MB");
		}
		return Format("{} {}", size, unit);
	}

	string saveFileName(string directory)
	{
		// Move this function into QNetworkReply to also get file name sent from the server
		string path = m_url.path();
		auto info = new QFileInfo(path);
		string baseName = info.completeBaseName();
		string endName = info.suffix();

		if (baseName.isEmpty()) {
			baseName = "unnamed_download";
			qDebug("DownloadManager:: downloading unknown file:" ~ m_url);
		}
		string name = directory ~ baseName ~ "." ~ endName;
		if (QFile.exists(name)) {
			// already exists, don't overwrite
			int i = 1;
			do {
				name = directory ~ baseName ~ "-" ~ .toString(i++) ~ "." ~ endName;
			} while (QFile.exists(name));
		}
		return name;
	}

	bool m_requestFileName;
	ulong m_bytesReceived;
	QTime m_downloadTime;
}


class DownloadManager : public QDialog //, public Ui_DownloadDialog
{
	mixin Ui_DownloadDialog;

public:

	enum RemovePolicy {
		Never,
		Exit,
		SuccessFullDownload
	};

	/*!
	DownloadManager is a Dialog that contains a list of DownloadItems

	It is a basic download manager.  It only downloads the file, doesn't do BitTorrent,
	extract zipped files or anything fancy.
	*/
	this(QWidget parent = null)
	{
		super(parent);
		
		m_autoSaver = new AutoSaver(this);
		m_manager = BrowserApplication.networkAccessManager();
		m_iconProvider = 0;
		m_removePolicy = RemovePolicy.Never;

		setupUi(this);
		downloadsView.setShowGrid(false);
		downloadsView.verticalHeader().hide();
		downloadsView.horizontalHeader().hide();
		downloadsView.setAlternatingRowColors(true);
		downloadsView.horizontalHeader().setStretchLastSection(true);
		m_model = new DownloadModel(this);
		downloadsView.setModel(m_model);
		cleanupButton.clicked.connect(&this.cleanup);
		load();
	}

	~this()
	{
		m_autoSaver.changeOccurred();
		m_autoSaver.saveIfNeccessary();
		if (m_iconProvider)
			delete m_iconProvider;
	}

	int activeDownloads()
	{
		int count = 0;
		for (int i = 0; i < m_downloads.length; ++i) {
			if (m_downloads[i].stopButton.isEnabled())
				++count;
		}
		return count;
	}

	RemovePolicy removePolicy()
	{
		return m_removePolicy;
	}

	void setRemovePolicy(RemovePolicy policy)
	{
		if (policy == m_removePolicy)
			return;
		m_removePolicy = policy;
		m_autoSaver.changeOccurred();
	}

public:

	void download(QNetworkRequest request, bool requestFileName = false)
	{
		if (request.url().isEmpty())
			return;
		handleUnsupportedContent(m_manager.get(request), requestFileName);
	}

	void download(QUrl url, bool requestFileName = false)
        {
		download(QNetworkRequest(url), requestFileName);
	}
	
	void handleUnsupportedContent(QNetworkReply reply, bool requestFileName = false)
	{
		if (!reply || reply.url().isEmpty())
			return;
		QVariant header = reply.header(QNetworkRequest.ContentLengthHeader);
		bool ok;
		int size = header.toInt(&ok);
		if (ok && size == 0)
			return;

		qDebug("DownloadManager::handleUnsupportedContent" ~ reply.url() ~ "requestFileName" ~ requestFileName);
		DownloadItem item = new DownloadItem(reply, requestFileName, this);
		addItem(item);
	}
	
	void cleanup()
	{
		if (m_downloads.length == 0)
			return;
		m_model.removeRows(0, m_downloads.length);
		updateItemCount();
		if (m_downloads.length == 0 && m_iconProvider) {
			delete m_iconProvider;
			m_iconProvider = 0;
		}
		m_autoSaver.changeOccurred();
	}

private:

	void save()
	{
		QSettings settings;
		settings.beginGroup("downloadmanager");
		QMetaEnum removePolicyEnum = staticMetaObject.enumerator(staticMetaObject.indexOfEnumerator("RemovePolicy"));
		settings.setValue("removeDownloadsPolicy", removePolicyEnum.valueToKey(m_removePolicy));
		settings.setValue("size", size());
		if (m_removePolicy == Exit)
			return;

		for (int i = 0; i < m_downloads.length; ++i) {
			string key = Format("download_{}_", i);
			settings.setValue(key ~ "url", m_downloads[i].m_url);
			settings.setValue(key ~ "location", (new QFileInfo(m_downloads[i].m_output)).filePath());
			settings.setValue(key ~ "done", m_downloads[i].downloadedSuccessfully());
		}
		int i = m_downloads.length;
		string key = Format("download_{}_", i);
		while (settings.contains(key ~ "url")) {
			settings.remove(key ~ "url");
			settings.remove(key ~ "location");
			settings.remove(key ~ "done");
			key = Format("download_{}_", ++i);
		}
	}

	void updateRow()
	{
		DownloadItem item = cast(DownloadItem) signalSender();
		int row = m_downloads.indexOf(item);
		if (-1 == row)
			return;
		if (!m_iconProvider)
			m_iconProvider = new QFileIconProvider();
		QIcon icon = m_iconProvider.icon(item.m_output.fileName());
		if (icon.isNull())
			icon = style().standardIcon(QStyle.SP_FileIcon);
		item.fileIcon.setPixmap(icon.pixmap(48, 48));
		downloadsView.setRowHeight(row, item.minimumSizeHint().height());

		bool remove = false;
		QWebSettings globalSettings = QWebSettings.globalSettings();
		if (!item.downloading() && globalSettings.testAttribute(QWebSettings.PrivateBrowsingEnabled))
			remove = true;

		if (item.downloadedSuccessfully() && removePolicy() == DownloadManager.SuccessFullDownload) {
			remove = true;
		}
		if (remove)
			m_model.removeRow(row);

		cleanupButton.setEnabled(m_downloads.length - activeDownloads() > 0);
	}

private:

	void addItem(DownloadItem item)
	{
		item.statusChanged.connect(&this.updateRow);
		int row = m_downloads.length;
		m_model.beginInsertRows(QModelIndex(), row, row);
		m_downloads ~= item;
		m_model.endInsertRows();
		updateItemCount();
		if (row == 0)
			show();
		downloadsView.setIndexWidget(m_model.index(row, 0), item);
		QIcon icon = style().standardIcon(QStyle.SP_FileIcon);
		item.fileIcon.setPixmap(icon.pixmap(48, 48));
		downloadsView.setRowHeight(row, item.sizeHint().height());
	}


	void updateItemCount()
	{
		int count = m_downloads.length;
		itemCount.setText(count == 1 ? tr("1 Download") : tr("{} Downloads").arg(count));
	}

	void load()
	{
		QSettings settings;
		settings.beginGroup("downloadmanager");
		QSize size = settings.value("size").toSize();
		if (size.isValid())
			resize(size);
		QByteArray value = settings.value("removeDownloadsPolicy", "Never").toByteArray();
		QMetaEnum removePolicyEnum = staticMetaObject.enumerator(staticMetaObject.indexOfEnumerator("RemovePolicy"));
		m_removePolicy = removePolicyEnum.keyToValue(value) == -1 ? Never :
			cast(RemovePolicy) removePolicyEnum.keyToValue(value);

		int i = 0;
		string key = Format("download_{}_", i);
		while (settings.contains(key ~ "url")) {
			QUrl url = settings.value(key ~ "url").toUrl();
			string fileName = settings.value(key ~ "location").toString();
			bool done = settings.value(key ~ "done", true).toBool();
			if (!url.isEmpty() && !fileName.isEmpty()) {
				DownloadItem item = new DownloadItem(0, this);
				item.m_output.setFileName(fileName);
				item.fileNameLabel.setText((new QFileInfo(item.m_output.fileName())).fileName());
				item.m_url = url;
				item.stopButton.setVisible(false);
				item.stopButton.setEnabled(false);
				item.tryAgainButton.setVisible(!done);
				item.tryAgainButton.setEnabled(!done);
				item.progressBar.setVisible(!done);
				addItem(item);
			}
			key = Format("download_{}_", ++i);
		}
		cleanupButton.setEnabled(m_downloads.length - activeDownloads() > 0);
	}

	AutoSaver m_autoSaver;
	DownloadModel m_model;
	QNetworkAccessManager m_manager;
	QFileIconProvider m_iconProvider;
	DownloadItem[] m_downloads;
	RemovePolicy m_removePolicy;
}


class DownloadModel : public QAbstractListModel
{
	
public:

	this(DownloadManager downloadManager, QObject parent = null)
	{
		super(parent);
		m_downloadManager = downloadManager;
	}

	QVariant data(QModelIndex index, int role = Qt.DisplayRole)
	{
		if (index.row() < 0 || index.row() >= rowCount(index.parent()))
			return QVariant();
		if (role == Qt.ToolTipRole)
			if (!m_downloadManager.m_downloads[index.row()].downloadedSuccessfully())
				return m_downloadManager.m_downloads[index.row()].downloadInfoLabel.text();
		return QVariant();
	}

	int rowCount(QModelIndex parent = QModelIndex())
	{
		return (parent.isValid()) ? 0 : m_downloadManager.m_downloads.length;
	}

	bool removeRows(int row, int count, QModelIndex parent = QModelIndex())
	{
		if (parent.isValid())
			return false;

		int lastRow = row + count - 1;
		for (int i = lastRow; i >= row; --i) {
			if (m_downloadManager.m_downloads[i].downloadedSuccessfully()
				|| m_downloadManager.m_downloads[i].tryAgainButton.isEnabled()) {
				beginRemoveRows(parent, i, i);
				m_downloadManager.m_downloads.takeAt(i).deleteLater();
				endRemoveRows();
			}
		}
		m_downloadManager.m_autoSaver.changeOccurred();
		return true;
	}

private:
	
	DownloadManager m_downloadManager;
}
