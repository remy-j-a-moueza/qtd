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

module droparea;

import qt.gui.QLabel;

class DropArea : public QLabel
{
public:
    this(QWidget parent = null)
    {
        super(parent);

        setMinimumSize(200, 200);
        setFrameStyle(QFrame.Sunken | QFrame.StyledPanel);
        setAlignment(Qt.AlignCenter);
        setAcceptDrops(true);
        setAutoFillBackground(true);
        clearArea();
    }

    void slot_clearArea()
    {
        setText(tr("<drop content>"));
        setBackgroundRole(QPalette.Dark);

        changed(null);
    }

    final void signal_changed(QMimeData);

protected:
    void dragEnterEvent(QDragEnterEvent event)
    {
        setText(tr("<drop content>"));
        setBackgroundRole(QPalette.Highlight);

        event.acceptProposedAction();
        changed(event.mimeData);
    }

    void dragMoveEvent(QDragMoveEvent event)
    {
        event.acceptProposedAction();
    }

    void dragLeaveEvent(QDragLeaveEvent event)
    {
        clearArea();
        event.accept();
    }

    void dropEvent(QDropEvent event)
    {
        QMimeData mimeData = event.mimeData();

        if (mimeData.hasImage()) {
            setPixmap(new QPixmap(mimeData.imageData));
        } else if (mimeData.hasHtml()) {
            setText(mimeData.html());
            setTextFormat(Qt.RichText);
        } else if (mimeData.hasText()) {
            setText(mimeData.text());
            setTextFormat(Qt.PlainText);
        } else if (mimeData.hasUrls()) {
            auto urlList = mimeData.urls();
            string text;
            for (int i = 0; i < urlList.length && i < 32; ++i) {
                text ~= urlList[i].path() ~ "\n";
            }
            setText(text);
        } else {
            setText(tr("Cannot display data"));
        }

        setBackgroundRole(QPalette.Dark);
        event.acceptProposedAction();
    }

private:
    QLabel label;

    mixin Q_OBJECT;
}

