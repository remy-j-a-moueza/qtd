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
module hoverpoints;

version (QT_OPENGL_SUPPORT)
    import qt.opengl.QGLWidget;

version (D_Version2) {}
else
    import tango.core.Array : sort;

import
    qt.gui.QWidget,
    qtd.Array,
    arthurwidgets;

final class HoverPoints : QObject
{
public:
    enum PointShape {
        CircleShape,
        RectangleShape
    }

    enum LockType {
        LockToLeft   = 0x01,
        LockToRight  = 0x02,
        LockToTop    = 0x04,
        LockToBottom = 0x08
    }

    enum SortType {
        NoSort,
        XSort,
        YSort
    }

    enum ConnectionType {
        NoConnection,
        LineConnection,
        CurveConnection
    }

private:
    QWidget m_widget;

    QPolygonF m_points;
    QRectF m_bounds;
    PointShape m_shape;
    SortType m_sortType;
    ConnectionType m_connectionType;

    uint[] m_locks;

    QSizeF m_pointSize;
    int m_currentIndex;
    bool m_editable;
    bool m_enabled;

    QPen m_pointPen;
    QBrush m_pointBrush;
    QPen m_connectionPen;

public:
    mixin Signal!("pointsChanged", QPolygonF /*points*/);

    this(QWidget widget, PointShape shape)
    {
        super(widget);

        m_widget = widget;
        widget.installEventFilter(this);

        m_connectionType = ConnectionType.CurveConnection;
        m_sortType = SortType.NoSort;
        m_shape = shape;
        m_pointPen = new QPen(new QBrush(new QColor(255, 255, 255, 191)), 1);
        m_connectionPen = new QPen(new QBrush(new QColor(255, 255, 255, 127)), 2);
        m_pointBrush = new QBrush(new QColor(191, 191, 191, 127));
        m_pointSize = QSizeF(11, 11);
        m_currentIndex = -1;
        m_editable = true;
        m_enabled = true;

        pointsChanged.connect(&m_widget.update);
    }

    void setBoundingRect(QRectF boundingRect) { m_bounds = boundingRect; }


    QRectF pointBoundingRect(int i)
    {
        QPointF p = m_points.at(i);
        qreal w = m_pointSize.width();
        qreal h = m_pointSize.height();
        qreal x = p.x() - w / 2;
        qreal y = p.y() - h / 2;
        return new QRectF(x, y, w, h);
    }

    QRectF boundingRect()
    {
        if (m_bounds.isEmpty())
            return new QRectF(m_widget.rect());
        else
            return m_bounds;
    }

    QPolygonF points() { return m_points; }

    QSizeF pointSize() { return m_pointSize; }
    void setPointSize(QSizeF size) { m_pointSize = size; }

    SortType sortType() { return m_sortType; }
    void setSortType(SortType sortType) { m_sortType = sortType; }

    ConnectionType connectionType() { return m_connectionType; }
    void setConnectionType(ConnectionType connectionType) { m_connectionType = connectionType; }

    void setConnectionPen(QPen pen) { m_connectionPen = pen; }
    void setShapePen(QPen pen) { m_pointPen = pen; }
    void setShapeBrush(QBrush brush) { m_pointBrush = brush; }

    void setPointLock(int pos, LockType lock) { m_locks[pos] = lock; }

    void setEditable(bool editable) { m_editable = editable; }
    bool editable() { return m_editable; }

    void setEnabled(bool enabled)
    {
        if (m_enabled != enabled) {
            m_enabled = enabled;
            m_widget.update();
        }
    }


    override bool eventFilter(QObject object, QEvent event)
    {
        if ((object == m_widget) && m_enabled) {
        switch (event.type()) {

            case QEvent.MouseButtonPress:
            {
                QMouseEvent me = cast(QMouseEvent) event;

                QPointF clickPos = me.pos();
                int index = -1;
                for (int i=0; i<m_points.size(); ++i) {
                    auto path = new QPainterPath;
                    if (m_shape == PointShape.CircleShape)
                        path.addEllipse(pointBoundingRect(i));
                    else
                        path.addRect(pointBoundingRect(i));

                    if (path.contains(clickPos)) {
                        index = i;
                        break;
                    }
                }

                if (me.button() == Qt.LeftButton) {
                    if (index == -1) {
                        if (!m_editable)
                            return false;
                        int pos = 0;
                        // Insert sort for x or y
                        if (m_sortType == SortType.XSort) {
                            for (int i=0; i<m_points.size(); ++i)
                                if (m_points.at(i).x() > clickPos.x()) {
                                    pos = i;
                                    break;
                                }
                        } else if (m_sortType == SortType.YSort) {
                            for (int i=0; i<m_points.size(); ++i)
                                if (m_points.at(i).y() > clickPos.y()) {
                                    pos = i;
                                    break;
                                }
                        }

                        // TODO: implement QPoligon(F).insert
                        auto tmpPoints = m_points.toList;
                        tmpPoints.insert(pos, clickPos);
                        m_points = new QPolygonF(tmpPoints);

                        m_locks.insert(pos, 0u);
                        m_currentIndex = pos;
                        firePointChange();
                    } else {
                        m_currentIndex = index;
                    }
                    return true;

                } else if (me.button() == Qt.RightButton) {
                    if ((index >= 0) && m_editable) {
                        if (m_locks[index] == 0) {
                            m_locks.removeAt(index);
                            m_points.remove(index);
                        }
                        firePointChange();
                        return true;
                    }
                }

            }
            break;

            case QEvent.MouseButtonRelease:
                m_currentIndex = -1;
                break;

            case QEvent.MouseMove:
                if (m_currentIndex >= 0)
                    movePoint(m_currentIndex, QPointF((cast(QMouseEvent)event).pos));
                break;

            case QEvent.Resize:
            {
                QResizeEvent e = cast(QResizeEvent) event;
                if (e.oldSize().width() == 0 || e.oldSize().height() == 0)
                    break;
                qreal stretch_x = e.size().width() / cast(qreal)e.oldSize.width;
                qreal stretch_y = e.size().height() / cast(qreal)e.oldSize.height;
                for (int i=0; i<m_points.size(); ++i) {
                    QPointF p = m_points.at(i);
                    movePoint(i, QPointF(p.x() * stretch_x, p.y() * stretch_y), false);
                }

                firePointChange();
                break;
            }

            case QEvent.Paint:
            {
                QWidget that_widget = m_widget;
                m_widget = null;
                QApplication.sendEvent(object, event);
                m_widget = that_widget;
                paintPoints();
                version (QT_OPENGL_SUPPORT)
                {
                    ArthurFrame af = cast(ArthurFrame)(that_widget);
                    if (af && af.usesOpenGL())
                        af.glWidget().swapBuffers();
                }

                return true;
            }
            default:
                break;
            }
        }

        return false;
    }


    void paintPoints()
    {
        scope p = new QPainter;
        version (QT_OPENGL_SUPPORT)
        {
            ArthurFrame af = cast(ArthurFrame)(m_widget);
            if (af && af.usesOpenGL())
                p.begin(af.glWidget());
            else
                p.begin(m_widget);
        }
        else
            p.begin(m_widget);

        p.setRenderHint(QPainter.Antialiasing);

        if (m_connectionPen.style() != Qt.NoPen && m_connectionType != ConnectionType.NoConnection) {
            p.setPen(m_connectionPen);

            if (m_connectionType == ConnectionType.CurveConnection) {
                auto path = new QPainterPath;
                path.moveTo(m_points.at(0));
                for (int i=1; i<m_points.size(); ++i) {
                    QPointF p1 = m_points.at(i-1);
                    QPointF p2 = m_points.at(i);
                    qreal distance = p2.x() - p1.x();

                    path.cubicTo(p1.x() + distance / 2, p1.y(),
                                 p1.x() + distance / 2, p2.y(),
                                 p2.x(), p2.y());
                }
                p.drawPath(path);
            } else {
                p.drawPolyline(m_points);
            }
        }

        p.setPen(m_pointPen);
        p.setBrush(m_pointBrush);

        for (int i=0; i<m_points.size(); ++i) {
            QRectF bounds = pointBoundingRect(i);
            if (m_shape == PointShape.CircleShape)
                p.drawEllipse(bounds);
            else
                p.drawRect(bounds);
        }
    }


    void setPoints(QPolygonF points)
    {
        delete m_points;
        for (int i=0; i<points.size; ++i)
            m_points.append(bound_point(points.at(i), boundingRect(), 0));

        delete m_locks;
        if (m_points.size > 0) {
            m_locks.length = m_points.size;

            m_locks[] = 0;
        }
    }

    void movePoint(int index, QPointF point, bool emitUpdate = true)
    {
        m_points.replace(index, bound_point(point, boundingRect(), m_locks[index]));
        if (emitUpdate)
            firePointChange();
    }

    void firePointChange()
    {
    //    printf("HoverPoints.firePointChange(), current=%d\n", m_currentIndex);

        if (m_sortType != SortType.NoSort) {

            QPointF oldCurrent;
            if (m_currentIndex != -1) {
                oldCurrent = m_points.at(m_currentIndex);
            }

            if (m_sortType == SortType.XSort)
            {
                auto tmpPoints = m_points.toList;
                sort(tmpPoints, &x_less_than);
                m_points = new QPolygonF(tmpPoints);
            }
            else if (m_sortType == SortType.YSort)
            {
                auto tmpPoints = m_points.toList;
                sort(tmpPoints, &y_less_than);
                m_points = new QPolygonF(tmpPoints);
            }

            // Compensate for changed order...
            if (m_currentIndex != -1) {
                for (int i=0; i<m_points.size; ++i) {
                    if (m_points.at(i) == oldCurrent) {
                        m_currentIndex = i;
                        break;
                    }
                }
            }

    //         printf(" - firePointChange(), current=%d\n", m_currentIndex);
        }

    //     for (int i=0; i<m_points.size(); ++i) {
    //         printf(" - point(%2d)=[%.2f, %.2f], lock=%d\n",
    //                i, m_points.at(i).x(), m_points.at(i).y(), m_locks.at(i));
    //     }

        pointsChanged.emit(m_points);
    }
}

private QPointF bound_point(QPointF point, QRectF bounds, int lock)
{
    QPointF p = point;

    qreal left = bounds.left();
    qreal right = bounds.right();
    qreal top = bounds.top();
    qreal bottom = bounds.bottom();

    if (p.x() < left || (lock & HoverPoints.LockType.LockToLeft)) p.x = left;
    else if (p.x() > right || (lock & HoverPoints.LockType.LockToRight)) p.x = right;

    if (p.y() < top || (lock & HoverPoints.LockType.LockToTop)) p.y = top;
    else if (p.y() > bottom || (lock & HoverPoints.LockType.LockToBottom)) p.y = bottom;

    return p;
}

private bool x_less_than(QPointF p1, QPointF p2)
{
    return p1.x() < p2.x();
}

private bool y_less_than(QPointF p1, QPointF p2)
{
    return p1.y() < p2.y();
}
