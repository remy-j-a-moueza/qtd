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

import QtGui.QMenu
import QtCore.QAbstractItemModel;

import modelmenu;

import QtCore.QAbstractItemModel;
import qdebug;



// A QMenu that is dynamically populated from a QAbstractItemModel
class ModelMenu : public QMenu
{
    Q_OBJECT

signals:
    void activated(const QModelIndex &index);
    void hovered(const QString &text);

public:
    ModelMenu(QWidget *parent = null)
{
	super(parent);
	m_maxRows = 7;
    m_firstSeparator = -1;
 m_maxWidth = -1;
     m_hoverRole = 0;
     m_separatorRole = 0;
 m_model = 0;
    connect(this, SIGNAL(aboutToShow()), this, SLOT(aboutToShow()));
}

    void setModel(QAbstractItemModel *model)
{
    m_model = model;
}

    QAbstractItemModel *model() const
{
    return m_model;
}

    void setMaxRows(int max)
{
    m_maxRows = max;
}

    int maxRows() const
{
    return m_maxRows;
}

    void setFirstSeparator(int offset)
{
    m_firstSeparator = offset;
}

    int firstSeparator() const
{
    return m_firstSeparator;
}

    void setRootIndex(const QModelIndex &index)
{
    m_root = index;
}
    QModelIndex rootIndex() const
{
    return m_root;
}

    void setHoverRole(int role)
{
    m_hoverRole = role;
}
    int hoverRole() const
{
    return m_hoverRole;
}

    void setSeparatorRole(int role)
{
    m_separatorRole = role;
}

    int separatorRole() const
{
    return m_separatorRole;
}

    QAction *makeAction(const QIcon &icon, const QString &text, QObject *parent);
{
    QFontMetrics fm(font());
    if (-1 == m_maxWidth)
        m_maxWidth = fm.width(QLatin1Char('m')) * 30;
    QString smallText = fm.elidedText(text, Qt.ElideMiddle, m_maxWidth);
    return new QAction(icon, smallText, parent);
}

protected:
    // add any actions before the tree, return true if any actions are added.
    virtual bool prePopulated()
{
    return false;
}
    // add any actions after the tree
    virtual void postPopulated()
{
}

    // put all of the children of parent into menu up to max
    void createMenu(const QModelIndex &parent, int max, QMenu *parentMenu = null, QMenu *menu = null)
{
    if (!menu) {
        QString title = parent.data().toString();
        menu = new QMenu(title, this);
        QIcon icon = qvariant_cast<QIcon>(parent.data(Qt.DecorationRole));
        menu.setIcon(icon);
        parentMenu.addMenu(menu);
        QVariant v;
        v.setValue(parent);
        menu.menuAction().setData(v);
        connect(menu, SIGNAL(aboutToShow()), this, SLOT(aboutToShow()));
        return;
    }

    int end = m_model.rowCount(parent);
    if (max != -1)
        end = qMin(max, end);

    connect(menu, SIGNAL(triggered(QAction*)), this, SLOT(triggered(QAction*)));
    connect(menu, SIGNAL(hovered(QAction*)), this, SLOT(hovered(QAction*)));

    for (int i = 0; i < end; ++i) {
        QModelIndex idx = m_model.index(i, 0, parent);
        if (m_model.hasChildren(idx)) {
            createMenu(idx, -1, menu);
        } else {
            if (m_separatorRole != 0
                && idx.data(m_separatorRole).toBool())
                addSeparator();
            else
                menu.addAction(makeAction(idx));
        }
        if (menu == this && i == m_firstSeparator - 1)
            addSeparator();
    }
}

private slots:
Q_DECLARE_METATYPE(QModelIndex)
void aboutToShow()
{
    if (QMenu *menu = qobject_cast<QMenu*>(sender())) {
        QVariant v = menu.menuAction().data();
        if (v.canConvert<QModelIndex>()) {
            QModelIndex idx = qvariant_cast<QModelIndex>(v);
            createMenu(idx, -1, menu, menu);
            disconnect(menu, SIGNAL(aboutToShow()), this, SLOT(aboutToShow()));
            return;
        }
    }

    clear();
    if (prePopulated())
        addSeparator();
    int max = m_maxRows;
    if (max != -1)
        max += m_firstSeparator;
    createMenu(m_root, max, this, this);
    postPopulated();
}


    void triggered(QAction *action)
{
    QVariant v = action.data();
    if (v.canConvert<QModelIndex>()) {
        QModelIndex idx = qvariant_cast<QModelIndex>(v);
        emit activated(idx);
    }
}

    void hovered(QAction *action)
{
    QVariant v = action.data();
    if (v.canConvert<QModelIndex>()) {
        QModelIndex idx = qvariant_cast<QModelIndex>(v);
        QString hoveredString = idx.data(m_hoverRole).toString();
        if (!hoveredString.isEmpty())
            emit hovered(hoveredString);
    }
}

private:
    QAction *makeAction(const QModelIndex &index);
{
    QIcon icon = qvariant_cast<QIcon>(index.data(Qt.DecorationRole));
    QAction *action = makeAction(icon, index.data().toString(), this);
    QVariant v;
    v.setValue(index);
    action.setData(v);
    return action;
}

    int m_maxRows;
    int m_firstSeparator;
    int m_maxWidth;
    int m_hoverRole;
    int m_separatorRole;
    QAbstractItemModel *m_model;
    QPersistentModelIndex m_root;
}
