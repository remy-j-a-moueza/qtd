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
module edge;

import std.math;
import qt.gui.QGraphicsItem;

import node;

static const double Pi = 3.14159265358979323846264338327950288419717;
static double TwoPi = 2.0 * Pi;

class Edge : QGraphicsItem
{
public:
    this(Node sourceNode, Node destNode)
    {
        arrowSize = 10;
        setAcceptedMouseButtons(0);
        source = sourceNode;
        dest = destNode;
        source.addEdge(this);
        dest.addEdge(this);
        adjust();
    }

    Node sourceNode() const
    {
        return cast(Node)source;
    }
    
    void setSourceNode(Node node)
    {
        source = node;
        adjust();
    }

    Node destNode() const
    {
        return cast(Node)dest;
    }
    
    void setDestNode(Node node)
    {
        dest = node;
        adjust();
    }

    void adjust()
    {
        if (!source || !dest)
            return;

        auto line = QLineF(mapFromItem(source, 0, 0), mapFromItem(dest, 0, 0));
        qreal length = line.length();

        prepareGeometryChange();

        if (length > 20.) {
            auto edgeOffset = QPointF((line.dx() * 10) / length, (line.dy() * 10) / length);
            sourcePoint = line.p1() + edgeOffset;
            destPoint = line.p2() - edgeOffset;
        } else {
            sourcePoint = destPoint = line.p1();
        }
    }

    enum { Type = UserType + 2 };
    int type() const { return Type; }
    
protected:
    override QRectF boundingRect() const
    {
        if (!source || !dest)
            return QRectF();

        qreal penWidth = 1;
        qreal extra = (penWidth + arrowSize) / 2.0;

        return QRectF(sourcePoint, QSizeF(destPoint.x() - sourcePoint.x(),
                                          destPoint.y() - sourcePoint.y()))
            .normalized()
            .adjusted(-extra, -extra, extra, extra);
    }
    
    override void paint(QPainter painter, QStyleOptionGraphicsItem option, QWidget widget)
    {
        if (!source || !dest)
            return;

        auto line = QLineF(sourcePoint, destPoint);
        if (qFuzzyCompare(line.length(), 0.))
            return;

        // Draw the line itself
        painter.setPen(new QPen(new QBrush(Qt.black), 1, Qt.SolidLine, Qt.RoundCap, Qt.RoundJoin));
        painter.drawLine(line);

        // Draw the arrows
        double angle = .acos(line.dx() / line.length());
        if (line.dy() >= 0)
            angle = TwoPi - angle;

        QPointF sourceArrowP1 = sourcePoint + QPointF(sin(angle + Pi / 3) * arrowSize,
                                                      cos(angle + Pi / 3) * arrowSize);
        QPointF sourceArrowP2 = sourcePoint + QPointF(sin(angle + Pi - Pi / 3) * arrowSize,
                                                      cos(angle + Pi - Pi / 3) * arrowSize);   
        QPointF destArrowP1 = destPoint + QPointF(sin(angle - Pi / 3) * arrowSize,
                                                  cos(angle - Pi / 3) * arrowSize);
        QPointF destArrowP2 = destPoint + QPointF(sin(angle - Pi + Pi / 3) * arrowSize,
                                                  cos(angle - Pi + Pi / 3) * arrowSize);

        painter.setBrush(new QBrush(Qt.black));
        auto p1 = new QPolygonF();
        p1.append(line.p1());
        p1.append(sourceArrowP1);
        p1.append(sourceArrowP2);
        painter.drawPolygon(p1);
        auto p2 = new QPolygonF();
        p2.append(line.p2());
        p2.append(destArrowP1);
        p2.append(destArrowP2);
        painter.drawPolygon(p2);        
    }
    
private:
    Node source, dest;

    QPointF sourcePoint;
    QPointF destPoint;
    qreal arrowSize;
};

