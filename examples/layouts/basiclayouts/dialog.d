/****************************************************************************
**
** Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies).
** Contact: Qt Software Information (qt-info@nokia.com)
**
** This file is part of the examples of the Qt Toolkit.
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
module dialog;


import qt.gui.QDialogButtonBox;
import qt.gui.QGroupBox;
import qt.gui.QLabel;
import qt.gui.QLineEdit;
import qt.gui.QMenuBar;
import qt.gui.QPushButton;
import qt.gui.QTextEdit;
import qt.gui.QDialog;
import qt.gui.QVBoxLayout;
import qt.gui.QHBoxLayout;
import qt.gui.QGridLayout;
import qt.gui.QFormLayout;
import qt.gui.QComboBox;
import qt.gui.QSpinBox;

import std.string : format;

import std.stdio;

class Dialog : public QDialog
{
    this()
    {
        createMenu();
        createHorizontalGroupBox();
        createGridGroupBox();
        createFormGroupBox();

        bigEditor = new QTextEdit;
        bigEditor.setPlainText(tr("This widget takes up all the remaining space in the top-level layout."));

        buttonBox = new QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel);

        connect(buttonBox, "accepted", this, "accept");
        connect(buttonBox, "rejected", this, "reject");

        QVBoxLayout mainLayout = new QVBoxLayout;

        mainLayout.setMenuBar(menuBar);

        mainLayout.addWidget(horizontalGroupBox);
        mainLayout.addWidget(gridGroupBox);
        mainLayout.addWidget(formGroupBox);
        mainLayout.addWidget(bigEditor);
        mainLayout.addWidget(buttonBox);

        setLayout(mainLayout);

        setWindowTitle(tr("Basic Layouts"));
    }

    void createMenu()
    {
        menuBar = new QMenuBar;

        fileMenu = new QMenu(tr("&File"), this);
        exitAction = fileMenu.addAction(tr("E&xit"));
        menuBar.addMenu(fileMenu);

        connect(exitAction, "triggered", this, "accept");
    }

    void createHorizontalGroupBox()
    {
        horizontalGroupBox = new QGroupBox(tr("Horizontal layout"));
        QHBoxLayout layout = new QHBoxLayout;

        for (int i = 0; i < NumButtons; ++i) {
	    version(Tango)
		const string str = tr("Button {}:");
	    else
		const string str = tr("Button %s:");
            buttons[i] = new QPushButton(format(str, i + 1));
            layout.addWidget(buttons[i]);
        }
        horizontalGroupBox.setLayout(layout);
    }

    void createGridGroupBox()
    {
        gridGroupBox = new QGroupBox(tr("Grid layout"));
        QGridLayout layout = new QGridLayout;

        for (int i = 0; i < NumGridRows; ++i) {
	    version(Tango)
		const string str = tr("Line {}:");
	    else
		const string str = tr("Line %s:");
            labels[i] = new QLabel(format(str, i + 1));
            lineEdits[i] = new QLineEdit;
            layout.addWidget(labels[i], i + 1, 0);
            layout.addWidget(lineEdits[i], i + 1, 1);
        }

        smallEditor = new QTextEdit;
        smallEditor.setPlainText(tr("This widget takes up about two thirds of the grid layout."));
        layout.addWidget(smallEditor, 0, 2, 4, 1);

        layout.setColumnStretch(1, 10);
        layout.setColumnStretch(2, 20);
        gridGroupBox.setLayout(layout);
    }

    void createFormGroupBox()
    {
        formGroupBox = new QGroupBox(tr("Form layout"));
        QFormLayout layout = new QFormLayout;
        layout.addRow(new QLabel(tr("Line 1:")), new QLineEdit);
        layout.addRow(new QLabel(tr("Line 2, long text:")), new QComboBox);
        layout.addRow(new QLabel(tr("Line 3:")), new QSpinBox);
        formGroupBox.setLayout(layout);
    }

    enum { NumGridRows = 3, NumButtons = 4 };

    QMenuBar menuBar;
    QGroupBox horizontalGroupBox;
    QGroupBox gridGroupBox;
    QGroupBox formGroupBox;
    QTextEdit smallEditor;
    QTextEdit bigEditor;
    QLabel[NumGridRows] labels;
    QLineEdit[NumGridRows] lineEdits;
    QPushButton[NumButtons] buttons;
    QDialogButtonBox buttonBox;

    QMenu fileMenu;
    QAction exitAction;

    mixin Q_OBJECT;
}
