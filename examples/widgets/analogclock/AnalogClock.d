/****************************************************************************
**
** Copyright (C) 2008 Nokia Corporation and/or its subsidiary(-ies).
** Contact: Qt Software Information (qt-info@nokia.com)
**
** This file is part of the example classes of the Qt Toolkit.
**
** Commercial Usage
** Licensees holding valid Qt Commercial licenses may use this file in
** accordance with the Qt Commercial License Agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and Nokia.
**
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License versions 2.0 or 3.0 as published by the Free
** Software Foundation and appearing in the file LICENSE.GPL included in
** the packaging of this file.  Please review the following information
** to ensure GNU General Public Licensing requirements will be met:
** http://www.fsf.org/licensing/licenses/info/GPLv2.html and
** http://www.gnu.org/copyleft/gpl.html.  In addition, as a special
** exception, Nokia gives you certain additional rights. These rights
** are described in the Nokia Qt GPL Exception version 1.3, included in
** the file GPL_EXCEPTION.txt in this package.
**
** Qt for Windows(R) Licensees
** As a special exception, Nokia, as the sole copyright holder for Qt
** Designer, grants users of the Qt/Eclipse Integration plug-in the
** right for the Qt/Eclipse Integration to link to functionality
** provided by Qt Designer and its related libraries.
**
** If you are unsure which license is appropriate for your use, please
** contact the sales department at qt-sales@nokia.com.
**
****************************************************************************/

module AnalogClock;

import qt.core.QPoint;
import qt.core.QTime;
import qt.core.QTimer;

import qt.gui.QWidget;
import qt.gui.QPolygon;
import qt.gui.QColor;
import qt.gui.QPaintEvent;
import qt.gui.QPainter;


class AnalogClock : public QWidget
{
public:
    this(QWidget parent = null)
    {
        super(parent);
        auto timer = new QTimer(this);
        connect(timer, "timeout", this, "update");
        timer.start(1000);
        setWindowTitle("Analog Clock");
        resize(200, 200);
    }

    void paintEvent(QPaintEvent event)
    {
        const QPoint[3] hourHand = [
            QPoint(7, 8),
            QPoint(-7, 8),
            QPoint(0, -40)
        ];
        const QPoint[3] minuteHand = [
            QPoint(7, 8),
            QPoint(-7, 8),
            QPoint(0, -70)
        ];

        scope hourColor = new QColor(127, 0, 127);
        scope minuteColor = new QColor(0, 127, 127, 191);

        int side = qMin(width(), height());
        QTime time = QTime.currentTime();

        // !! it is important that QPainter object should be scoped
        // !! in order to be destroyed after painting
        scope painter = new QPainter(this);

        painter.setRenderHint(QPainter.Antialiasing);
        painter.translate(width() / 2, height() / 2);
        painter.scale(side / 200.0, side / 200.0);

        painter.setPen(Qt.NoPen);
        painter.setBrush(hourColor);

        painter.save();
        painter.rotate(30.0 * ((time.hour() + time.minute() / 60.0)));
        painter.drawConvexPolygon(hourHand);
        painter.restore();

        painter.setPen(hourColor);

        for (int i = 0; i < 12; ++i) {
            painter.drawLine(88, 0, 96, 0);
            painter.rotate(30.0);
        }

        painter.setPen(Qt.NoPen);
        painter.setBrush(minuteColor);

        painter.save();
        painter.rotate(6.0 * (time.minute() + time.second() / 60.0));
        painter.drawConvexPolygon(minuteHand);
        painter.restore();

        painter.setPen(minuteColor);

        for (int j = 0; j < 60; ++j) {
            if ((j % 5) != 0)
                painter.drawLine(92, 0, 96, 0);
            painter.rotate(6.0);
        }
    }
    
    mixin Q_OBJECT;
}