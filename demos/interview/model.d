/****************************************************************************
**
** Copyright (C) 2008 Nokia Corporation and/or its subsidiary(-ies).
** Contact: Qt Software Information (qt-info@nokia.com)
**
** This file is part of the demonstration applications of the Qt Toolkit.
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

module model;

import qt.gui.QIcon;
import qt.gui.QPixmap;
import qt.gui.QFileIconProvider;

import qt.core.QAbstractItemModel;
import qt.core.QVariant;
import qt.core.QModelIndex;

import std.conv; //, std.algorithm;
import std.stdio;

class Node
{
    this(Node parent_ = null)
    {
        parent = parent_;
    }
        
    Node parent;
    Node[] children;
}

size_t find(const Node[] arr, const Node elem)
{
    size_t res = arr.length;
    for(size_t i = 0; i < arr.length; i++)
        if (arr[i] is elem)
            res = i;
    return res;
}

class Model : QAbstractItemModel
{

    this(int rows, int columns, QObject parent = null)
    {
        super(parent);
        rc = rows;
        cc = columns;
        tree = new Node[rows];
        foreach(ref node; tree) {
            node = new Node;
        }
        
        iconProvider = new QFileIconProvider;
        
        folder = iconProvider.icon(QFileIconProvider.Folder);
        file = iconProvider.icon(QFileIconProvider.File);
        services = new QIcon(":/images/services.png");
    }


    override QModelIndex index(int row, int column, const QModelIndex parent) const
    {
        if (row < rc && row >= 0 && column < cc && column >= 0) {
            auto p = cast(Node) parent.internalPointer();
            auto n = getNode(row, p);
            if (n !is null)
                return createIndex(row, column, cast(void*)n);
        }
        return QModelIndex();
    }

    override QModelIndex parent(const QModelIndex child) const
    {
        if (child.isValid()) {
            Node n = cast(Node) child.internalPointer();
            Node p = parent(n);
            if (p !is null)
                return createIndex(row(p), 0, cast(void*)p);
        }
        return QModelIndex();
    }

    override int rowCount(const QModelIndex parent) const
    {
        return (parent.isValid() && parent.column() != 0) ? 0 : rc;
    }

    override int columnCount(const QModelIndex parent) const
    {
        return cc;
    }
    
    override QVariant data(const QModelIndex index, int role) const
    {
        if (!index.isValid)
            return new QVariant;
        if (role == Qt.DisplayRole)
            return new QVariant("Item " ~ to!string(index.row) ~ ":" ~ to!string(index.column));
        if (role == Qt.DecorationRole) {
            if (index.column == 0)
                //return iconProvider.icon(QFileIconProvider::Folder);
                return folder.toVariant;
            return file.toVariant;
        }
        return new QVariant;
    }
    
    override QVariant headerData(int section, Qt.Orientation orientation, int role) const
    {
        if (role == Qt.DisplayRole)
            return new QVariant(to!string(section));
        if (role == Qt.DecorationRole)
            return services.toVariant;
        return QAbstractItemModel.headerData(section, orientation, role);
    }

    override bool hasChildren(const QModelIndex parent) const
    {
        if (parent.isValid && parent.column != 0)
            return false;
        return rc > 0 && cc > 0;
    }
    
    override int flags(const QModelIndex index) const
    {
        if (!index.isValid)
            return 0;
        return (Qt.ItemIsDragEnabled | Qt.ItemIsSelectable | Qt.ItemIsEnabled);
    }

    const (Node) getNode(int row, Node parent) const
    {
        if(parent !is null && parent.children.length == 0) {
            for(int i = 0; i < rc; i++)
                parent.children ~= new Node(parent);
        }

        auto v = parent !is null ? parent.children : tree;
        return v[row];
    }

    Node parent(Node child) const
    {
        return child !is null ? child.parent : null;
    }
    
    int row(Node node) const
    {
        auto v = node.parent !is null ? node.parent.children : tree;
        return cast(int)find(v, node);
    }


    int rc, cc;
    Node[] tree;
    QFileIconProvider iconProvider;
    
    QIcon folder, services, file;
}
