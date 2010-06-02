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

import qt.gui.QWidget;
import qt.gui.QSlider;
import qt.gui.QHBoxLayout;

import glwidget;
import std.stdio;

class Window : public QWidget
{
    public:
        this()
        {
            glWidget = new GLWidget;

            xSlider = createSlider();
            ySlider = createSlider();
            zSlider = createSlider();

            connect(xSlider, "valueChanged", glWidget, "setXRotation");
            connect(glWidget, "xRotationChanged", xSlider, "setValue");
            connect(ySlider, "valueChanged", glWidget, "setYRotation");
            connect(glWidget, "yRotationChanged", ySlider, "setValue");
            connect(zSlider, "valueChanged", glWidget, "setZRotation");
            connect(glWidget, "zRotationChanged", zSlider, "setValue");
            writeln("connected");

            QHBoxLayout mainLayout = new QHBoxLayout;
            mainLayout.addWidget(glWidget);
            mainLayout.addWidget(xSlider);
            mainLayout.addWidget(ySlider);
            mainLayout.addWidget(zSlider);
            setLayout(mainLayout);

            xSlider.setValue(15 * 16);
            ySlider.setValue(345 * 16);
            zSlider.setValue(0 * 16);
            setWindowTitle(tr("Hello GL"));
        }

    private:
        QSlider createSlider()
        {
            auto slider = new QSlider(Qt.Vertical);
            slider.setRange(0, 360 * 16);
            slider.setSingleStep(16);
            slider.setPageStep(15 * 16);
            slider.setTickInterval(15 * 16);
            slider.setTickPosition(QSlider.TicksRight);
            return slider;
        }

        GLWidget glWidget;
        QSlider xSlider;
        QSlider ySlider;
        QSlider zSlider;

        mixin Q_OBJECT;
}