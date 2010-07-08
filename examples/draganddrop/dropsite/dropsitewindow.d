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

module dropsitewindow;

import std.string : format, strip, toupper;

import qt.gui.QWidget;
import qt.gui.QLabel;
import qt.gui.QTableWidget;
import qt.gui.QPushButton;
import qt.gui.QVBoxLayout;
import qt.gui.QDialogButtonBox;

import droparea;

class DropSiteWindow : public QWidget
{
public:

    this()
    {
        abstractLabel = new QLabel(tr("This example accepts drags from other "
            "applications and displays the MIME types "
            "provided by the drag object."));

        abstractLabel.setWordWrap(true);
        abstractLabel.adjustSize();

        dropArea = new DropArea;
        connect(dropArea, "changed", this, "updateFormatsTable");

        string[] labels;
        labels ~= tr("Format");
        labels ~= tr("Content");

        formatsTable = new QTableWidget;
        formatsTable.setColumnCount(2);
        formatsTable.setEditTriggers(QAbstractItemView.NoEditTriggers);
        formatsTable.setHorizontalHeaderLabels(labels.toQList());
        formatsTable.horizontalHeader().setStretchLastSection(true);

        clearButton = new QPushButton(tr("Clear"));
        quitButton = new QPushButton(tr("Quit"));

        buttonBox = new QDialogButtonBox;
        buttonBox.addButton(clearButton, QDialogButtonBox.ActionRole);
        buttonBox.addButton(quitButton, QDialogButtonBox.RejectRole);

        connect(quitButton, "pressed", this, "close");
        connect(clearButton, "pressed", dropArea, "clearArea");

        QVBoxLayout mainLayout = new QVBoxLayout;
        mainLayout.addWidget(abstractLabel);
        mainLayout.addWidget(dropArea);
        mainLayout.addWidget(formatsTable);
        mainLayout.addWidget(buttonBox);
        setLayout(mainLayout);

        setWindowTitle(tr("Drop Site"));
        setMinimumSize(350, 500);
    }

    void slot_updateFormatsTable(QMimeData mimeData)
    {
        formatsTable.setRowCount(0);
        if (!mimeData)
            return;

        foreach (string format; mimeData.formats()) {

            QTableWidgetItem formatItem = new QTableWidgetItem(format);
            formatItem.setFlags(Qt.ItemIsEnabled);
            formatItem.setTextAlignment(Qt.AlignTop | Qt.AlignLeft);

            string text;
            if (format == "text/plain") {
                text = strip(mimeData.text());
            } else if (format == "text/html") {
                text = strip(mimeData.html());
            } else if (format == "text/uri-list") {
                auto urlList = mimeData.urls();
                for (int i = 0; i < urlList.length && i < 32; ++i) {
                    string url = urlList[i].path();
                    text ~= url ~ " ";
                }
            } else {
                QByteArray data = mimeData.data(format);
                for (int i = 0; i < data.size() && i < 32; ++i) {
                    string hex = toupper(std.string.format("%x", data.at(i)));
                    text ~= hex ~ " ";
                }
            }

            int row = formatsTable.rowCount();

            formatsTable.insertRow(row);
            formatsTable.setItem(row, 0, new QTableWidgetItem(format));
            formatsTable.setItem(row, 1, new QTableWidgetItem(text));
        }

        formatsTable.resizeColumnToContents(0);
    }
    
private:

    DropArea dropArea;
    QLabel abstractLabel;
    QTableWidget formatsTable;

    QPushButton clearButton;
    QPushButton quitButton;
    QDialogButtonBox buttonBox;

    mixin Q_OBJECT;
}
