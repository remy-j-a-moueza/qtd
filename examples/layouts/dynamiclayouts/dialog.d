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


import qt.gui.QDialog;
import qt.gui.QGroupBox;
import qt.gui.QGridLayout;
import qt.gui.QLabel;
import qt.gui.QComboBox;
import qt.gui.QDialogButtonBox;
import qt.gui.QPushButton;
import qt.gui.QMessageBox;
import qt.gui.QSpinBox;
import qt.gui.QDial;
import qt.gui.QProgressBar;


class Dialog : public QDialog
{
public:

    this(QWidget parent = null)
    {
        super(parent);

        createRotableGroupBox();
        createOptionsGroupBox();
        createButtonBox();

        mainLayout = new QGridLayout;
        mainLayout.addWidget(rotableGroupBox, 0, 0);
        mainLayout.addWidget(optionsGroupBox, 1, 0);
        mainLayout.addWidget(buttonBox, 2, 0);
        setLayout(mainLayout);

        mainLayout.setSizeConstraint(QLayout.SetMinimumSize);

        setWindowTitle(tr("Dynamic Layouts"));
    }

private: // slots

    void slot_buttonsOrientationChanged(int index)
    {
        mainLayout.setSizeConstraint(QLayout.SetNoConstraint);
        setMinimumSize(0, 0);

        Qt.Orientation orientation = cast(Qt.Orientation) buttonsOrientationComboBox.itemData(index).toInt();

        if (orientation == buttonBox.orientation())
            return;

        mainLayout.removeWidget(buttonBox);

        int spacing = mainLayout.spacing();

        QSize oldSizeHint = buttonBox.sizeHint() + QSize(spacing, spacing);
        buttonBox.setOrientation(orientation);
        QSize newSizeHint = buttonBox.sizeHint() + QSize(spacing, spacing);

        if (orientation == Qt.Orientation.Horizontal) {
            mainLayout.addWidget(buttonBox, 2, 0);
            resize(size() + QSize(-1 * oldSizeHint.width(), newSizeHint.height()));
        } else {
            mainLayout.addWidget(buttonBox, 0, 3, 2, 1);
            resize(size() + QSize(newSizeHint.width(), -1 * oldSizeHint.height()));
        }

        mainLayout.setSizeConstraint(QLayout.SetDefaultConstraint);
    }

    void slot_rotateWidgets()
    {
        assert(rotableWidgets.length % 2 == 0);

        foreach (QWidget widget; rotableWidgets)
            rotableLayout.removeWidget(widget);

        rotableWidgets = rotableWidgets[1..$] ~ rotableWidgets[0];

        auto n = rotableWidgets.length;
        for (int i = 0; i < n / 2; ++i) {
            rotableLayout.addWidget(rotableWidgets[n - i - 1], 0, i);
            rotableLayout.addWidget(rotableWidgets[i], 1, i);
        }
    }

    void slot_help()
    {
        QMessageBox.information(this, tr("Dynamic Layouts Help"),
            tr("This example shows how to change layouts dynamically."));
    }

private:

    void createRotableGroupBox()
    {
        rotableGroupBox = new QGroupBox(tr("Rotable Widgets"));

        auto a0 = new QSpinBox;
        auto a1 = new QSlider;
        auto a2 = new QDial;
        auto a3 = new QProgressBar;

        rotableWidgets ~= a0;
        rotableWidgets ~= a1;
        rotableWidgets ~= a2;
        rotableWidgets ~= a3;

        auto n = rotableWidgets.length;

        for (int i = 0; i < n; ++i)
            connect(rotableWidgets[i], "valueChanged", rotableWidgets[(i + 1) % n], "setValue");

        rotableLayout = new QGridLayout;
        rotableGroupBox.setLayout(rotableLayout);

        rotateWidgets();

    }

    void createOptionsGroupBox()
    {
        optionsGroupBox = new QGroupBox(tr("Options"));

        buttonsOrientationLabel = new QLabel(tr("Orientation of buttons:"));

        buttonsOrientationComboBox = new QComboBox;
        buttonsOrientationComboBox.addItem(tr("Horizontal"), new QVariant(cast(ulong) Qt.Horizontal));
        buttonsOrientationComboBox.addItem(tr("Vertical"), new QVariant(cast(ulong) Qt.Vertical));

        connect(buttonsOrientationComboBox, "currentIndexChanged", this, "buttonsOrientationChanged");

        optionsLayout = new QGridLayout;
        optionsLayout.addWidget(buttonsOrientationLabel, 0, 0);
        optionsLayout.addWidget(buttonsOrientationComboBox, 0, 1);
        optionsLayout.setColumnStretch(2, 1);
        optionsGroupBox.setLayout(optionsLayout);
    }

    void createButtonBox()
    {
        buttonBox = new QDialogButtonBox;

        closeButton = buttonBox.addButton(QDialogButtonBox.Close);
        helpButton = buttonBox.addButton(QDialogButtonBox.Help);
        rotateWidgetsButton = buttonBox.addButton(tr("Rotate &Widgets"), QDialogButtonBox.ActionRole);

        connect(rotateWidgetsButton, "clicked", this, "rotateWidgets");
        connect(closeButton, "clicked", this, "close");
        connect(helpButton, "clicked", this, "help");
    }

    QGroupBox rotableGroupBox;
    QWidget[] rotableWidgets;

    QGroupBox optionsGroupBox;
    QLabel buttonsOrientationLabel;
    QComboBox buttonsOrientationComboBox;

    QDialogButtonBox buttonBox;
    QPushButton closeButton;
    QPushButton helpButton;
    QPushButton rotateWidgetsButton;

    QGridLayout mainLayout;
    QGridLayout rotableLayout;
    QGridLayout optionsLayout;

    mixin Q_OBJECT;
}
