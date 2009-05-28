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

module chasewidget;


import qt.core.QSize;
import qt.core.QPoint;

import qt.gui.QColor;
import qt.gui.QPixmap;
import qt.gui.QWidget;
import qt.gui.QApplication;
import qt.gui.QHideEvent;
import qt.gui.QPainter;
import qt.gui.QPaintEvent;
import qt.gui.QShowEvent;


class ChaseWidget : public QWidget
{
public:

	this(QWidget parent = null, QPixmap pixmap = new QPixmap(), bool pixmapEnabled = false)
	{
		super(parent);
		m_segment = 0;
		m_delay = 100;
		m_step = 40;
		m_timerId = -1;
		m_animated = false;
		m_pixmap = pixmap;
		m_pixmapEnabled = pixmapEnabled;
	}

	void setAnimated(bool value)
	{
		if (m_animated == value)
			return;
		m_animated = value;
		if (m_timerId != -1) {
			killTimer(m_timerId);
			m_timerId = -1;
		}
		if (m_animated) {
			m_segment = 0;
			m_timerId = startTimer(m_delay);
		}
		update();
	}

	void setPixmapEnabled(bool enable)
	{
		m_pixmapEnabled = enable;
	}
	
	QSize sizeHint()
	{
		return QSize(32, 32);
	}

protected:

	void paintEvent(QPaintEvent event)
	{
		auto p = new QPainter(this);
		if (m_pixmapEnabled && !m_pixmap.isNull()) {
			p.drawPixmap(0, 0, m_pixmap);
			return;
		}

		int extent = qMin(width() - 8, height() - 8);
		int displ = extent / 4;
		int ext = extent / 4 - 1;

		p.setRenderHint(QPainter.Antialiasing, true);

		if(m_animated)
			p.setPen(Qt.gray);
		else
			p.setPen(QPen(palette().dark().color()));

		p.translate(width() / 2, height() / 2); // center

		for (int segment = 0; segment < segmentCount(); ++segment) {
			p.rotate(QApplication.isRightToLeft() ? m_step : -m_step);
			if(m_animated)
				p.setBrush(colorForSegment(segment));
			else
				p.setBrush(palette().background());
			p.drawEllipse(QRect(displ, -ext / 2, ext, ext));
		}
	}

	void timerEvent(QTimerEvent event)
	{
		if (event.timerId() == m_timerId) {
			++m_segment;
			update();
		}
		QWidget.timerEvent(event);
	}

private:

	int segmentCount()
	{
		return 360 / m_step;
	}

	QColor colorForSegment(int seg)
	{
		int index = ((seg + m_segment) % segmentCount());
		int comp = qMax(0, 255 - (index * (255 / segmentCount())));
		return QColor(comp, comp, comp, 255);
	}

	int m_segment;
	int m_delay;
	int m_step;
	int m_timerId;
	bool m_animated;
	QPixmap m_pixmap;
	bool m_pixmapEnabled;
}
