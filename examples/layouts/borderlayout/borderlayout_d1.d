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
module borderlayout_d1;


import qt.gui.QLayout;
import qt.gui.QWidgetItem;
import qt.gui.QTextBrowser;
import qt.core.QSize;
import qt.core.QRect;


class BorderLayout : public QLayout
{
public:

    enum Position { West, North, South, East, Center };

    this(QWidget parent, int margin = 0, int spacing = -1)
    {
        super(parent);
        setMargin(margin);
        setWidgetSpacing(spacing);
    }

    this(int spacing = -1)
    {
        setWidgetSpacing(spacing);
    }

    ~this()
    {
        QLayoutItem l = takeAt(0);
        while (l) {
            delete l;
            l = takeAt(0);
        }
    }

    void addItem(IQLayoutItem item)
    {
        add(item, Position.West);
    }

    void addWidget(QWidget widget, Position position)
    {
        add(cast(IQLayoutItem) new QWidgetItem(widget), position);
    }

    int expandingDirections()
    {
        return Qt.Horizontal | Qt.Vertical;
    }

    bool hasHeightForWidth()
    {
        return false;
    }

    int count()
    {
        return list.length;
    }

    QLayoutItem itemAt(int index)
    {
        if(index >= 0 && index < list.length) 
            return list[index].item;
        else
            return null;
    }

    QSize minimumSize()
    {
        return calculateSize(SizeType.MinimumSize);
    }

    void setGeometry(QRect rect)
    {
        ItemWrapper center = null;
        int eastWidth = 0;
        int westWidth = 0;
        int northHeight = 0;
        int southHeight = 0;
        int centerHeight = 0;
        int i;

        super.setGeometry(rect);

        for (i = 0; i < list.length; ++i) {
            ItemWrapper wrapper = list[i];
            IQLayoutItem item = wrapper.item;
            Position position = wrapper.position;

            if (position == Position.North) {
                item.setGeometry(QRect(rect.x(), northHeight, rect.width(),
                        item.sizeHint().height()));

                northHeight += item.geometry().height() + widgetSpacing();
            } else if (position == Position.South) {
                item.setGeometry(QRect(item.geometry().x(),
                        item.geometry().y(), rect.width(),
                        item.sizeHint().height()));

                southHeight += item.geometry().height() + widgetSpacing();

                item.setGeometry(QRect(rect.x(),
                      rect.y() + rect.height() - southHeight + widgetSpacing(),
                      item.geometry().width(),
                      item.geometry().height()));
            } else if (position == Position.Center) {
                center = wrapper;
            }
        }

        centerHeight = rect.height() - northHeight - southHeight;

        for (i = 0; i < list.length; ++i) {
            ItemWrapper wrapper = list[i];
            IQLayoutItem item = wrapper.item;
            Position position = wrapper.position;

            if (position == Position.West) {
                item.setGeometry(QRect(rect.x() + westWidth, northHeight,
                        item.sizeHint().width(), centerHeight));

                westWidth += item.geometry().width() + widgetSpacing();
            } else if (position == Position.East) {
                item.setGeometry(QRect(item.geometry().x(), item.geometry().y(),
                        item.sizeHint().width(), centerHeight));

                eastWidth += item.geometry().width() + widgetSpacing();

                item.setGeometry(QRect(
                      rect.x() + rect.width() - eastWidth + widgetSpacing(),
                      northHeight, item.geometry().width(),
                      item.geometry().height()));
            }
        }

        if (center)
            center.item.setGeometry(QRect(westWidth, northHeight,
                rect.width() - eastWidth - westWidth,
                centerHeight));
    }

    QSize sizeHint()
    {
        return calculateSize(SizeType.SizeHint);
    }

    QLayoutItem takeAt(int index)
    {
        if (index >= 0 && index < list.length) {
            ItemWrapper layoutStruct = list[index];
            return layoutStruct.item;
        }
        return null;
    }

    void add(IQLayoutItem item, Position position)
    {
        list ~= new ItemWrapper(item, position);
    }

private:

    class ItemWrapper
    {
        this(IQLayoutItem i, Position p)
        {
            item = i;
            position = p;
        }

        IQLayoutItem item;
        Position position;
    };

    enum SizeType { MinimumSize, SizeHint };

    QSize calculateSize(SizeType sizeType)
    {
        QSize totalSize;

        for (int i = 0; i < list.length; ++i) {
            ItemWrapper wrapper = list[i];
            Position position = wrapper.position;
            QSize itemSize;

            if (sizeType == SizeType.MinimumSize)
                itemSize = wrapper.item.minimumSize();
            else // (sizeType == SizeHint)
                itemSize = wrapper.item.sizeHint();

            if (position == Position.North || position == Position.South || position == Position.Center)
                totalSize.setHeight(totalSize.height + itemSize.height);
            
            if (position == Position.West || position == Position.East || position == Position.Center)
                totalSize.setWidth(totalSize.width + itemSize.width);
        }
        return totalSize;
    }

    ItemWrapper[] list;
}
