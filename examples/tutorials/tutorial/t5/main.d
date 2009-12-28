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

import qt.gui.QApplication;
import qt.gui.QFont;
import qt.gui.QLCDNumber;
import qt.gui.QPushButton;
import qt.gui.QSlider;
import qt.gui.QVBoxLayout;
import qt.gui.QWidget;


class MyWidget : public QWidget
{
public:
    this(QWidget parent = null)
    {
        super(parent);
        auto quit = new QPushButton("Quit");
        quit.setFont(new QFont("Times", 18, QFont.Bold));

        auto lcd = new QLCDNumber(2);
        lcd.setSegmentStyle(QLCDNumber.Filled);

        auto slider = new QSlider(Qt.Horizontal);
        slider.setRange(0, 99);
        slider.setValue(0);

        connect(quit, "clicked", qApp(), "quit");
        connect(slider, "valueChanged", lcd, "display");

        auto layout = new QVBoxLayout;
        layout.addWidget(quit);
        layout.addWidget(lcd);
        layout.addWidget(slider);
        setLayout(layout);
    }
}

int main(string[] args)
{
    auto app = new QApplication(args);
    auto widget = new MyWidget;
    widget.show();
    return app.exec();
}
