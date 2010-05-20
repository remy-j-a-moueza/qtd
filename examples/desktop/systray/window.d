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
module window;

import qt.gui.QSystemTrayIcon;
import qt.gui.QDialog;
import qt.gui.QAction;
import qt.gui.QCheckBox;
import qt.gui.QComboBox;
import qt.gui.QGroupBox;
import qt.gui.QLabel;
import qt.gui.QLineEdit;
import qt.gui.QMenu;
import qt.gui.QPushButton;
import qt.gui.QSpinBox;
import qt.gui.QTextEdit;
import qt.gui.QVBoxLayout;
import qt.gui.QHBoxLayout;
import qt.gui.QMessageBox;
import qt.gui.QGridLayout;


class Window : public QDialog
{
public:

    this()
    {
        createIconGroupBox();
        createMessageGroupBox();

        iconLabel.setMinimumWidth(durationLabel.sizeHint().width());

        createActions();
        createTrayIcon();

        connect(showMessageButton, "clicked", this, "showMessage");
        connect(showIconCheckBox, "toggled", trayIcon, "setVisible");
        connect(iconComboBox, "currentIndexChanged", this, "setIcon");
        connect(trayIcon, "messageClicked", this, "messageClicked");
        connect(trayIcon, "activated", this, "iconActivated");

        QVBoxLayout mainLayout = new QVBoxLayout;
        mainLayout.addWidget(iconGroupBox);
        mainLayout.addWidget(messageGroupBox);
        setLayout(mainLayout);

        iconComboBox.setCurrentIndex(1);
        trayIcon.show();

        setWindowTitle(tr("Systray"));
        resize(400, 300);
    }

    void setVisible(bool visible)
    {
        minimizeAction.setEnabled(visible);
        maximizeAction.setEnabled(!isMaximized());
        restoreAction.setEnabled(isMaximized() || !visible);
        QDialog.setVisible(visible);
    }

    protected:

    void closeEvent(QCloseEvent event)
    {
        if (trayIcon.isVisible()) {
            QMessageBox.information(this, tr("Systray"),
                tr("The program will keep running in the system tray. To terminate the program, "
                "choose <b>Quit</b> in the context menu of the system tray entry."));
            hide();
            event.ignore();
        }
    }

private: // slots

    void slot_setIcon(int index)
    {
        QIcon icon = iconComboBox.itemIcon(index);
        trayIcon.setIcon(icon);
        setWindowIcon(icon);

        trayIcon.setToolTip(iconComboBox.itemText(index));
    }
    
    void slot_iconActivated(QSystemTrayIcon.ActivationReason reason)
    {
        switch (reason) {
            case QSystemTrayIcon.Trigger:
            case QSystemTrayIcon.DoubleClick:
                iconComboBox.setCurrentIndex((iconComboBox.currentIndex() + 1) % iconComboBox.count());
                break;
            case QSystemTrayIcon.MiddleClick:
                showMessage();
                break;
            default:
        }
    }
    
    void slot_showMessage()
    {
        QSystemTrayIcon.MessageIcon icon = cast(QSystemTrayIcon.MessageIcon)
            typeComboBox.itemData(typeComboBox.currentIndex()).toInt();
        trayIcon.showMessage(titleEdit.text(), bodyEdit.toPlainText(), icon, durationSpinBox.value() * 1000);
    }
    
    void slot_messageClicked()
    {
        QMessageBox.information(null, tr("Systray"),
            tr("Sorry, I already gave what help I could.\nMaybe you should try asking a human?"));
    }

private:

    void createIconGroupBox()
    {
        iconGroupBox = new QGroupBox(tr("Tray Icon"));

        iconLabel = new QLabel("Icon:");

        iconComboBox = new QComboBox;
        iconComboBox.addItem(new QIcon(":/images/bad.svg"), tr("Bad"));
        iconComboBox.addItem(new QIcon(":/images/heart.svg"), tr("Heart"));
        iconComboBox.addItem(new QIcon(":/images/trash.svg"), tr("Trash"));

        showIconCheckBox = new QCheckBox(tr("Show icon"));
        showIconCheckBox.setChecked(true);

        QHBoxLayout iconLayout = new QHBoxLayout;
        iconLayout.addWidget(iconLabel);
        iconLayout.addWidget(iconComboBox);
        iconLayout.addStretch();
        iconLayout.addWidget(showIconCheckBox);
        iconGroupBox.setLayout(iconLayout);
    }

    void createMessageGroupBox()
    {
        messageGroupBox = new QGroupBox(tr("Balloon Message"));

        typeLabel = new QLabel(tr("Type:"));

        typeComboBox = new QComboBox;
        typeComboBox.addItem(tr("None"), new QVariant(cast(ulong) QSystemTrayIcon.NoIcon));
        typeComboBox.addItem(style().standardIcon(
            QStyle.SP_MessageBoxInformation), tr("Information"),
            new QVariant(cast(ulong) QSystemTrayIcon.Information));
        typeComboBox.addItem(style().standardIcon(
            QStyle.SP_MessageBoxWarning), tr("Warning"),
            new QVariant(cast(ulong) QSystemTrayIcon.Warning));
        typeComboBox.addItem(style().standardIcon(
            QStyle.SP_MessageBoxCritical), tr("Critical"),
            new QVariant(cast(ulong) QSystemTrayIcon.Critical));
        typeComboBox.setCurrentIndex(1);

        durationLabel = new QLabel(tr("Duration:"));

        durationSpinBox = new QSpinBox;
        durationSpinBox.setRange(5, 60);
        durationSpinBox.setSuffix(" s");
        durationSpinBox.setValue(15);

        durationWarningLabel = new QLabel(tr("(some systems might ignore this hint)"));
        durationWarningLabel.setIndent(10);

        titleLabel = new QLabel(tr("Title:"));

        titleEdit = new QLineEdit(tr("Cannot connect to network"));

        bodyLabel = new QLabel(tr("Body:"));

        bodyEdit = new QTextEdit;
        bodyEdit.setPlainText(tr("Don't believe me. Honestly, I don't have a clue.\nClick this balloon for details."));

        showMessageButton = new QPushButton(tr("Show Message"));
        showMessageButton.setDefault(true);

        QGridLayout messageLayout = new QGridLayout;
        messageLayout.addWidget(typeLabel, 0, 0);
        messageLayout.addWidget(typeComboBox, 0, 1, 1, 2);
        messageLayout.addWidget(durationLabel, 1, 0);
        messageLayout.addWidget(durationSpinBox, 1, 1);
        messageLayout.addWidget(durationWarningLabel, 1, 2, 1, 3);
        messageLayout.addWidget(titleLabel, 2, 0);
        messageLayout.addWidget(titleEdit, 2, 1, 1, 4);
        messageLayout.addWidget(bodyLabel, 3, 0);
        messageLayout.addWidget(bodyEdit, 3, 1, 2, 4);
        messageLayout.addWidget(showMessageButton, 5, 4);
        messageLayout.setColumnStretch(3, 1);
        messageLayout.setRowStretch(4, 1);
        messageGroupBox.setLayout(messageLayout);
    }

    void createActions()
    {
        minimizeAction = new QAction(tr("Mi&nimize"), this);
        connect(minimizeAction, "triggered", this, "hide");

        maximizeAction = new QAction(tr("Ma&ximize"), this);
        connect(maximizeAction, "triggered", this, "showMaximized");

        restoreAction = new QAction(tr("&Restore"), this);
        connect(restoreAction, "triggered", this, "showNormal");

        quitAction = new QAction(tr("&Quit"), this);
        connect(quitAction, "triggered", qApp(), "quit");
    }

    void createTrayIcon()
    {
        trayIconMenu = new QMenu(this);
        trayIconMenu.addAction(minimizeAction);
        trayIconMenu.addAction(maximizeAction);
        trayIconMenu.addAction(restoreAction);
        trayIconMenu.addSeparator();
        trayIconMenu.addAction(quitAction);

        trayIcon = new QSystemTrayIcon(this);
        trayIcon.setContextMenu(trayIconMenu);
    }

    QGroupBox iconGroupBox;
    QLabel iconLabel;
    QComboBox iconComboBox;
    QCheckBox showIconCheckBox;

    QGroupBox messageGroupBox;
    QLabel typeLabel;
    QLabel durationLabel;
    QLabel durationWarningLabel;
    QLabel titleLabel;
    QLabel bodyLabel;
    QComboBox typeComboBox;
    QSpinBox durationSpinBox;
    QLineEdit titleEdit;
    QTextEdit bodyEdit;
    QPushButton showMessageButton;

    QAction minimizeAction;
    QAction maximizeAction;
    QAction restoreAction;
    QAction quitAction;

    QSystemTrayIcon trayIcon;
    QMenu trayIconMenu;

    mixin Q_OBJECT;
}
