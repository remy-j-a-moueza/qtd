/****************************************************************************
**
** Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
** All rights reserved.
** Contact: Nokia Corporation (qt-info@nokia.com)
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
** In addition, as a special exception, Nokia gives you certain additional
** rights.  These rights are described in the Nokia Qt LGPL Exception
** version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3.0 as published by the Free Software
** Foundation and appearing in the file LICENSE.GPL included in the
** packaging of this file.  Please review the following information to
** ensure the GNU General Public License version 3.0 requirements will be
** met: http://www.gnu.org/copyleft/gpl.html.
**
** If you have questions regarding the use of this file, please contact
** Nokia at qt-info@nokia.com.
** $QT_END_LICENSE$
**
****************************************************************************/

module node;

import
    qt.gui.QRadialGradient,
    qt.gui.QGraphicsItem;

import
    graphwidget,
    edge;

class Node : QGraphicsItem
{
public:
    this(GraphWidget graphWidget)
    {
        graph = graphWidget;
        setFlag(ItemIsMovable);
        setFlag(ItemSendsGeometryChanges);
        setCacheMode(DeviceCoordinateCache);
        setZValue(-1);
    }

    void addEdge(Edge edge)
    {
        edgeList ~= edge;
        edge.adjust();
    }
/*    
    Edge[] edges() const
    {
        return edgeList;
    }
*/
    enum { Type = UserType + 1 };
    int type() const { return Type; }

    void calculateForces()
    {
        if (!scene() || scene().mouseGrabberItem() is this) {
            newPos = pos();
            return;
        }
    
        // Sum up all forces pushing this item away
        qreal xvel = 0;
        qreal yvel = 0;
        foreach (IQGraphicsItem item; scene().items()) {
            auto node = cast(Node)item;
            if (!node)
                continue;

            auto line = QLineF(mapFromItem(node, 0, 0), QPointF(0, 0));
            qreal dx = line.dx();
            qreal dy = line.dy();
            double l = 2.0 * (dx * dx + dy * dy);
            if (l > 0) {
                xvel += (dx * 150.0) / l;
                yvel += (dy * 150.0) / l;
            }
        }

        // Now subtract all forces pulling items together
        double weight = (edgeList.length + 1) * 10;
        foreach (Edge edge; edgeList) {
            QPointF pos;
            if (edge.sourceNode() == this)
                pos = mapFromItem(edge.destNode(), 0, 0);
            else
                pos = mapFromItem(edge.sourceNode(), 0, 0);
            xvel += pos.x() / weight;
            yvel += pos.y() / weight;
        }
        
        if (qAbs(xvel) < 0.1 && qAbs(yvel) < 0.1)
            xvel = yvel = 0;

        QRectF sceneRect = scene().sceneRect();
        newPos = pos() + QPointF(xvel, yvel);
        newPos.x = qMin(qMax(newPos.x(), sceneRect.left() + 10), sceneRect.right() - 10);
        newPos.y = qMin(qMax(newPos.y(), sceneRect.top() + 10), sceneRect.bottom() - 10);

    }
    
    bool advance()
    {
        auto pos_ = pos();
        if (newPos == pos_)
            return false;

        setPos(newPos);
        return true;
    }

    QRectF boundingRect() const
    {
        qreal adjust = 2;
        return QRectF(-10 - adjust, -10 - adjust,
                      23 + adjust, 23 + adjust);
    }
    
    QPainterPath shape() const
    {
        QPainterPath path;
        path.addEllipse(-10, -10, 20, 20);
        return path;
    }
    
    override public void paint(QPainter painter, QStyleOptionGraphicsItem option, QWidget widget = null)
    {
        painter.setPen(Qt.NoPen);
        painter.setBrush(new QBrush(Qt.darkGray));
        painter.drawEllipse(-7, -7, 20, 20);

        auto gradient = new QRadialGradient(-3, -3, 10);
        if (option.state & QStyle.State_Sunken) {
            gradient.setCenter(3, 3);
            gradient.setFocalPoint(3, 3);
            gradient.setColorAt(1, (new QColor(Qt.yellow)).lighter(120));
            gradient.setColorAt(0, (new QColor(Qt.darkYellow)).lighter(120));
        } else {
            gradient.setColorAt(0, new QColor(Qt.yellow));
            gradient.setColorAt(1, new QColor(Qt.darkYellow));
        }
        painter.setBrush(gradient);
        painter.setPen(new QPen(new QBrush(Qt.black), 0));
        painter.drawEllipse(-10, -10, 20, 20);
    }
    
protected:
    override QVariant itemChange(GraphicsItemChange change, QVariant value)
    {
        switch (change)
        {
        case ItemPositionHasChanged:
            foreach (Edge edge; edgeList)
                edge.adjust();
            graph.itemMoved();
            break;
        default:
            break;
        };

        return QGraphicsItem.itemChange(change, value);
    }

    override void mousePressEvent(QGraphicsSceneMouseEvent event)
    {
        update();
        QGraphicsItem.mousePressEvent(event);
    }

    override void mouseReleaseEvent(QGraphicsSceneMouseEvent event)
    {
        update();
        QGraphicsItem.mouseReleaseEvent(event);
    }
    
private:
    Edge[] edgeList;
    QPointF newPos;
    GraphWidget graph;
};
