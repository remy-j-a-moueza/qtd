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

module urllineedit;

import qt.core.QUrl;
import qt.core.QEvent;
//import qt.core.QDebug;

import qt.gui.QWidget;
import qt.gui.QStyleOptionFrame;
import qt.gui.QApplication;
import qt.gui.QCompleter;
import qt.gui.QFocusEvent;
import qt.gui.QHBoxLayout;
import qt.gui.QLabel;
import qt.gui.QLineEdit;
import qt.gui.QPainter;
import qt.gui.QStyle;
import qt.gui.QStyleOptionFrameV2;
import qt.gui.QLinearGradient;


import browserapplication;
import searchlineedit;
import webview;


class ExLineEdit : public QWidget
{
public:

	this(QWidget parent = null)
	{
		super(parent);

		m_leftWidget = 0;
		m_lineEdit = new QLineEdit(this);
		m_clearButton = 0;

		setFocusPolicy(m_lineEdit.focusPolicy());
		setAttribute(Qt.WA_InputMethodEnabled);
		setSizePolicy(m_lineEdit.sizePolicy());
		setBackgroundRole(m_lineEdit.backgroundRole());
		setMouseTracking(true);
		setAcceptDrops(true);
		setAttribute(Qt.WA_MacShowFocusRect, true);
		QPalette p = m_lineEdit.palette();
		setPalette(p);

		// line edit
		m_lineEdit.setFrame(false);
		m_lineEdit.setFocusProxy(this);
		m_lineEdit.setAttribute(Qt.WA_MacShowFocusRect, false);
		QPalette clearPalette = m_lineEdit.palette();
		clearPalette.setBrush(QPalette.Base, QBrush(Qt.transparent));
		m_lineEdit.setPalette(clearPalette);

		// clearButton
		m_clearButton = new ClearButton(this);
		m_clearButton.clicked.connect(&m_lineEdit.clear);
		m_lineEdit.textChanged.connect(&m_clearButton.textChanged);
	}

	QLineEdit lineEdit() { return m_lineEdit; }

	void setLeftWidget(QWidget widget)
	{
		m_leftWidget = widget;
	}

	QWidget leftWidget()
	{
		return m_leftWidget;
	}

	QSize sizeHint()
	{
		m_lineEdit.setFrame(true);
		QSize size = m_lineEdit.sizeHint();
		m_lineEdit.setFrame(false);
		return size;
	}

	QVariant inputMethodQuery(Qt.InputMethodQuery property)
	{
		return m_lineEdit.inputMethodQuery(property);
	}

protected:

	void focusInEvent(QFocusEvent event)
	{
		m_lineEdit.event(event);
		QWidget.focusInEvent(event);
	}

	void focusOutEvent(QFocusEvent event)
	{
		m_lineEdit.event(event);

		if (m_lineEdit.completer()) {
			m_lineEdit.completer().activated.connect(& m_lineEdit.setText);
			m_lineEdit.completer().highlighted.connect(&m_lineEdit._q_completionHighlighted);
		}
		QWidget.focusOutEvent(event);
	}

	void keyPressEvent(QKeyEvent event)
	{
		m_lineEdit.event(event);
	}

	void paintEvent(QPaintEvent event)
	{
		auto p = new QPainter(this);
		QStyleOptionFrameV2 panel;
		initStyleOption(&panel);
		style().drawPrimitive(QStyle.PE_PanelLineEdit, &panel, &p, this);
	}

	void resizeEvent(QResizeEvent event)
	{
		assert(m_leftWidget);
		updateGeometries();
		QWidget.resizeEvent(event);
	}

	void inputMethodEvent(QInputMethodEvent e)
	{
		m_lineEdit.event(e);
	}

	bool event(QEvent event)
	{
		if (event.type() == QEvent.ShortcutOverride)
			return m_lineEdit.event(event);
		return QWidget.event(event);
	}

protected:

	void updateGeometries()
	{
		QStyleOptionFrameV2 panel;
		initStyleOption(&panel);
		QRect rect = style().subElementRect(QStyle.SE_LineEditContents, &panel, this);

		int height = rect.height();
		int width = rect.width();

		int m_leftWidgetHeight = m_leftWidget.height();
		m_leftWidget.setGeometry(rect.x() + 2,          rect.y() + (height - m_leftWidgetHeight)/2,
		m_leftWidget.width(), m_leftWidget.height());

		int clearButtonWidth = this.height();
		m_lineEdit.setGeometry(m_leftWidget.x() + m_leftWidget.width(),        0,
		width - clearButtonWidth - m_leftWidget.width(), this.height());

		m_clearButton.setGeometry(this.width() - clearButtonWidth, 0,
		clearButtonWidth, this.height());
	}

	void initStyleOption(QStyleOptionFrameV2 option)
	{
		option.initFrom(this);
		option.rect = contentsRect();
		option.lineWidth = style().pixelMetric(QStyle.PM_DefaultFrameWidth, option, this);
		option.midLineWidth = 0;
		option.state |= QStyle.State_Sunken;
		if (m_lineEdit.isReadOnly())
			option.state |= QStyle.State_ReadOnly;
		version(QT_KEYPAD_NAVIGATION)
		{
			if (hasEditFocus())
				option.state |= QStyle.State_HasEditFocus;
		}
		else
		{
			option.features = QStyleOptionFrameV2.None;
		}
	}
	
	QWidget m_leftWidget;
	QLineEdit m_lineEdit;
	ClearButton m_clearButton;
}


class UrlIconLabel : public QLabel
{
public:

	this(QWidget parent)
	{
		super(parent);
		m_webView = 0;
		setMinimumWidth(16);
		setMinimumHeight(16);
	}

	WebView m_webView;

protected:

	void mousePressEvent(QMouseEvent event)
	{
		if (event.button() == Qt.LeftButton)
			m_dragStartPos = event.pos();
		QLabel.mousePressEvent(event);
	}

	void mouseMoveEvent(QMouseEvent event)
	{
		if (event.buttons() == Qt.LeftButton
				&& (event.pos() - m_dragStartPos).manhattanLength() > QApplication.startDragDistance()
				&& m_webView) {
			QDrag drag = new QDrag(this);
			QMimeData mimeData = new QMimeData;
			mimeData.setText(QString.fromUtf8(m_webView.getUrl().toEncoded()));
			QUrl[] urls;
			urls ~= m_webView.getUrl();
			mimeData.setUrls(urls);
			drag.setMimeData(mimeData);
			drag.exec();
		}
	}

private:

	QPoint m_dragStartPos;
}


class UrlLineEdit : public ExLineEdit
{
public:

	this(QWidget parent = null)
	{
		super(parent);
		m_webView = 0;
		m_iconLabel = 0;
		// icon
		m_iconLabel = new UrlIconLabel(this);
		m_iconLabel.resize(16, 16);
		setLeftWidget(m_iconLabel);
		m_defaultBaseColor = palette().color(QPalette.Base);

		webViewIconChanged();
	}
	
	void setWebView(WebView webView)
	{
		assert(!m_webView);
		m_webView = webView;
		m_iconLabel.m_webView = webView;
		webView.urlChanged.connect(&this.webViewUrlChanged);
		webView.loadFinished.connect(&this.webViewIconChanged);
		webView.iconChanged.connect(&this.webViewIconChanged);
		webView.loadProgress.connect(&this.update);
	}

protected:

	void paintEvent(QPaintEvent event)
	{
		QPalette p = palette();
		if (m_webView && m_webView.getUrl().scheme() == "https") {
			auto lightYellow = new QColor(248, 248, 210);
			p.setBrush(QPalette.Base, generateGradient(lightYellow));
		} else {
			p.setBrush(QPalette.Base, m_defaultBaseColor);
		}
		setPalette(p);
		ExLineEdit.paintEvent(event);

		auto painter = new QPainter(this);
		QStyleOptionFrameV2 panel;
		initStyleOption(&panel);
		QRect backgroundRect = style().subElementRect(QStyle.SE_LineEditContents, &panel, this);
		if (m_webView && !hasFocus()) {
			int progress = m_webView.progress();
			QColor loadingColor = new QColor(116, 192, 250);
			painter.setBrush(generateGradient(loadingColor));
			painter.setPen(Qt.transparent);
			int mid = backgroundRect.width() / 100 * progress;
			QRect progressRect = QRect(backgroundRect.x(), backgroundRect.y(), mid, backgroundRect.height());
			painter.drawRect(progressRect);
		}
	}

	void focusOutEvent(QFocusEvent event)
	{
		if (m_lineEdit.text().isEmpty() && m_webView)
			m_lineEdit.setText(QString.fromUtf8(m_webView.getUrl().toEncoded()));
		ExLineEdit.focusOutEvent(event);
	}

private:
	
	void webViewUrlChanged(QUrl url)
	{
		m_lineEdit.setText(QString.fromUtf8(url.toEncoded()));
		m_lineEdit.setCursorPosition(0);
	}

	void webViewIconChanged()
	{
		QUrl url = m_webView ? m_webView.getUrl() : new QUrl();
		QIcon icon = BrowserApplication.instance().icon(url);
		auto pixmap = new QPixmap(icon.pixmap(16, 16));
		m_iconLabel.setPixmap(pixmap);
	}

private:

	QLinearGradient generateGradient(QColor color)
	{
		auto gradient = new QLinearGradient(0, 0, 0, height());
		gradient.setColorAt(0, m_defaultBaseColor);
		gradient.setColorAt(0.15, color.lighter(120));
		gradient.setColorAt(0.5, color);
		gradient.setColorAt(0.85, color.lighter(120));
		gradient.setColorAt(1, m_defaultBaseColor);
		return gradient;
	}

	WebView m_webView;
	UrlIconLabel m_iconLabel;
	QColor m_defaultBaseColor;
}
