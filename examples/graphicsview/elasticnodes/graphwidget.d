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

import
    std.math;

import
    qt.gui.QLinearGradient,
    qt.gui.QGraphicsView,
    qt.gui.QGraphicsScene;

import
    edge,
    node;

class GraphWidget : QGraphicsView
{
public:
    this()
    {
        auto scene = new QGraphicsScene(this);
        scene.setItemIndexMethod(QGraphicsScene.NoIndex);
        scene.setSceneRect(-200, -200, 400, 400);
        setScene(scene);
        setCacheMode(CacheBackground);
        setViewportUpdateMode(BoundingRectViewportUpdate);
        setRenderHint(QPainter.Antialiasing);
        setTransformationAnchor(AnchorUnderMouse);
        setResizeAnchor(AnchorViewCenter);

        Node node1 = new Node(this);
        Node node2 = new Node(this);
        Node node3 = new Node(this);
        Node node4 = new Node(this);
        centerNode = new Node(this);
        Node node6 = new Node(this);
        Node node7 = new Node(this);
        Node node8 = new Node(this);
        Node node9 = new Node(this);
        scene.addItem(node1);
        scene.addItem(node2);
        scene.addItem(node3);
        scene.addItem(node4);
        scene.addItem(centerNode);
        scene.addItem(node6);
        scene.addItem(node7);
        scene.addItem(node8);
        scene.addItem(node9);
        scene.addItem(new Edge(node1, node2));
        scene.addItem(new Edge(node2, node3));
        scene.addItem(new Edge(node2, centerNode));
        scene.addItem(new Edge(node3, node6));
        scene.addItem(new Edge(node4, node1));
        scene.addItem(new Edge(node4, centerNode));
        scene.addItem(new Edge(centerNode, node6));
        scene.addItem(new Edge(centerNode, node8));
        scene.addItem(new Edge(node6, node9));
        scene.addItem(new Edge(node7, node4));
        scene.addItem(new Edge(node8, node7));
        scene.addItem(new Edge(node9, node8));

        node1.setPos(-50, -50);
        node2.setPos(0, -50);
        node3.setPos(50, -50);
        node4.setPos(-50, 0);
        centerNode.setPos(0, 0);
        node6.setPos(50, 0);
        node7.setPos(-50, 50);
        node8.setPos(0, 50);
        node9.setPos(50, 50);

        scale(0.8, 0.8);
        setMinimumSize(400, 400);
        setWindowTitle(tr("Elastic Nodes"));        
    }

    void itemMoved()
    {    
        if (!timerId)
            timerId = startTimer(1000 / 25);
    }
    
protected:
    void keyPressEvent(QKeyEvent event)
    {
        switch (event.key()) {
        case Qt.Key_Up:
            centerNode.moveBy(0, -20);
            break;
        case Qt.Key_Down:
            centerNode.moveBy(0, 20);
            break;
        case Qt.Key_Left:
            centerNode.moveBy(-20, 0);
            break;
        case Qt.Key_Right:
            centerNode.moveBy(20, 0);
            break;
        case Qt.Key_Plus:
            scaleView(1.2);
            break;
        case Qt.Key_Minus:
            scaleView(1 / 1.2);
            break;
        case Qt.Key_Space:
        case Qt.Key_Enter:
            foreach (IQGraphicsItem item; scene().items()) {
                if (cast(Node)item)
                    item.setPos(-150 + qrand() % 300, -150 + qrand() % 300);
            }
            break;
        default:
            super.keyPressEvent(event);
        }
    }
    
    void timerEvent(QTimerEvent event)
    {
        Node[] nodes;
        foreach (IQGraphicsItem item; scene().items()) {
            if (auto node = cast(Node)item)
                nodes ~= node;
        }

        foreach (Node node; nodes)
            node.calculateForces();

        bool itemsMoved = false;
        foreach (Node node; nodes) {
            if (node.advance())
                itemsMoved = true;
        }

        if (!itemsMoved) {
            killTimer(timerId);
            timerId = 0;
        }
    }

    void wheelEvent(QWheelEvent event)
    {
        scaleView(pow(cast(float)2, cast(float)(-event.delta() / 240.0)));
    }
    
    void drawBackground(QPainter painter, const QRectF rect)
    {
        // Shadow
        QRectF sceneRect = this.sceneRect();
        auto rightShadow = QRectF(sceneRect.right(), sceneRect.top() + 5, 5, sceneRect.height());
        auto bottomShadow = QRectF(sceneRect.left() + 5, sceneRect.bottom(), sceneRect.width(), 5);
        if (rightShadow.intersects(rect) || rightShadow.contains(rect))
	    painter.fillRect(rightShadow, Qt.darkGray);
        if (bottomShadow.intersects(rect) || bottomShadow.contains(rect))
	    painter.fillRect(bottomShadow, Qt.darkGray);

        // Fill
        auto gradient = new QLinearGradient(sceneRect.topLeft(), sceneRect.bottomRight());
        gradient.setColorAt(0, new QColor(Qt.white));
        gradient.setColorAt(1, new QColor(Qt.lightGray));
        painter.fillRect(rect.intersected(sceneRect), new QBrush(gradient));
        painter.setBrush(Qt.NoBrush);
        painter.drawRect(sceneRect);

        // Text
        auto textRect = QRectF(sceneRect.left() + 4, sceneRect.top() + 4,
                        sceneRect.width() - 4, sceneRect.height() - 4);
        string message = tr("Click and drag the nodes around, and zoom with the mouse "
                           "wheel or the '+' and '-' keys");

        QFont font = painter.font();
        font.setBold(true);
        font.setPointSize(14);
        painter.setFont(font);
        painter.setPen(new QColor(Qt.lightGray));
        painter.drawText(textRect.translated(2, 2), message);
        painter.setPen(new QColor(Qt.black));
        painter.drawText(textRect, message);
    }

    void scaleView(qreal scaleFactor)
    {
        qreal factor = matrix().scale(scaleFactor, scaleFactor).mapRect(QRectF(0, 0, 1, 1)).width();
        if (factor < 0.07 || factor > 100)
            return;

        scale(scaleFactor, scaleFactor);
    }

private:
    int timerId;
    Node centerNode;

    mixin Q_OBJECT;
};
