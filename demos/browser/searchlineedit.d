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

import urllineedit;

import QtGui.QLineEdit;
import QtGui.QAbstractButton;

import searchlineedit;

import QtGui.QPainter;
import QtGui.QMouseEvent;
import QtGui.QMenu;
import QtGui.QStyle;
import QtGui.QStyleOptionFrameV2;

/*
QT_BEGIN_NAMESPACE
class QMenu;
QT_END_NAMESPACE

class SearchButton;
*/

/*
    Clear button on the right hand side of the search widget.
    Hidden by default
    "A circle with an X in it"
 */
class ClearButton : public QAbstractButton
{
    Q_OBJECT

public:
    this(QWidget *parent = null)
{
	super(parent);
    setCursor(Qt.ArrowCursor);
    setToolTip(tr("Clear"));
    setVisible(false);
    setFocusPolicy(Qt.NoFocus);
}
    void paintEvent(QPaintEvent *event)
{
    Q_UNUSED(event);
    QPainter painter(this);
    int height = this.height();

    painter.setRenderHint(QPainter::Antialiasing, true);
    QColor color = palette().color(QPalette.Mid);
    painter.setBrush(isDown()
                     ? palette().color(QPalette.Dark)
                     : palette().color(QPalette.Mid));
    painter.setPen(painter.brush().color());
    int size = width();
    int offset = size / 5;
    int radius = size - offset * 2;
    painter.drawEllipse(offset, offset, radius, radius);

    painter.setPen(palette().color(QPalette.Base));
    int border = offset * 2;
    painter.drawLine(border, border, width() - border, height - border);
    painter.drawLine(border, height - border, width() - border, border);
}

public slots:
    void textChanged(QString &text)
{
    setVisible(!text.isEmpty());
}

}

/*
    Search icon on the left hand side of the search widget
    When a menu is set a down arrow appears
 */
class SearchButton : public QAbstractButton {
public:
    SearchButton(QWidget *parent = null)
{
	super(parent);
	m_menu = 0;
    setObjectName(QLatin1String("SearchButton"));
    setCursor(Qt.ArrowCursor);
    setFocusPolicy(Qt.NoFocus);
}

    void paintEvent(QPaintEvent *event)
{
    Q_UNUSED(event);
    QPainterPath myPath;

    int radius = (height() / 5) * 2;
    QRect circle(height() / 3 - 1, height() / 4, radius, radius);
    myPath.addEllipse(circle);

    myPath.arcMoveTo(circle, 300);
    QPointF c = myPath.currentPosition();
    int diff = height() / 7;
    myPath.lineTo(qMin(width() - 2, (int)c.x() + diff), c.y() + diff);

    QPainter painter(this);
    painter.setRenderHint(QPainter::Antialiasing, true);
    painter.setPen(QPen(Qt.darkGray, 2));
    painter.drawPath(myPath);

    if (m_menu) {
        QPainterPath dropPath;
        dropPath.arcMoveTo(circle, 320);
        QPointF c = dropPath.currentPosition();
        c = QPointF(c.x() + 3.5, c.y() + 0.5);
        dropPath.moveTo(c);
        dropPath.lineTo(c.x() + 4, c.y());
        dropPath.lineTo(c.x() + 2, c.y() + 2);
        dropPath.closeSubpath();
        painter.setPen(Qt.darkGray);
        painter.setBrush(Qt.darkGray);
        painter.setRenderHint(QPainter::Antialiasing, false);
        painter.drawPath(dropPath);
    }
    painter.end();
}
    QMenu *m_menu;

protected:
    void mousePressEvent(QMouseEvent *event)
{
    if (m_menu && event.button() == Qt.LeftButton) {
        QWidget *p = parentWidget();
        if (p) {
            QPoint r = p.mapToGlobal(QPoint(0, p.height()));
            m_menu.exec(QPoint(r.x() + height() / 2, r.y()));
        }
        event.accept();
    }
    QAbstractButton::mousePressEvent(event);
}
}

class SearchLineEdit : public ExLineEdit
{
    Q_OBJECT
    Q_PROPERTY(QString inactiveText READ inactiveText WRITE setInactiveText)

signals:
    void textChanged(QString &text);

public:
/*
    SearchLineEdit is an enhanced QLineEdit
    - A Search icon on the left with optional menu
    - When there is no text and doesn't have focus an "inactive text" is displayed
    - When there is text a clear button is displayed on the right hand side
 */
this(QWidget *parent = null) : ExLineEdit(parent),
    m_searchButton(new SearchButton(this))
{
    connect(lineEdit(), SIGNAL(textChanged(QString &)),
            this, SIGNAL(textChanged(QString &)));
    setLeftWidget(m_searchButton);
    m_inactiveText = tr("Search");

    QSizePolicy policy = sizePolicy();
    setSizePolicy(QSizePolicy::Preferred, policy.verticalPolicy());
}

    QString inactiveText()
{
    return m_inactiveText;
}

    void setInactiveText(QString &text)
{
    m_inactiveText = text;
}

    QMenu *menu()
{
    if (!m_searchButton.m_menu) {
        m_searchButton.m_menu = new QMenu(m_searchButton);
        if (isVisible())
            (const_cast<SearchLineEdit*>(this)).updateGeometries();
    }
    return m_searchButton.m_menu;
}

    void setMenu(QMenu *menu)
{
    if (m_searchButton.m_menu)
        m_searchButton.m_menu.deleteLater();
    m_searchButton.m_menu = menu;
    updateGeometries();
}

protected:
    void resizeEvent(QResizeEvent *event)
{
    updateGeometries();
    ExLineEdit.resizeEvent(event);
}

    void paintEvent(QPaintEvent *event)
{
    if (lineEdit().text().isEmpty() && !hasFocus() && !m_inactiveText.isEmpty()) {
        ExLineEdit.paintEvent(event);
        QStyleOptionFrameV2 panel;
        initStyleOption(&panel);
        QRect r = style().subElementRect(QStyle::SE_LineEditContents, &panel, this);
        QFontMetrics fm = fontMetrics();
        int horizontalMargin = lineEdit().x();
        QRect lineRect(horizontalMargin + r.x(), r.y() + (r.height() - fm.height() + 1) / 2,
                       r.width() - 2 * horizontalMargin, fm.height());
        QPainter painter(this);
        painter.setPen(palette().brush(QPalette.Disabled, QPalette.Text).color());
        painter.drawText(lineRect, Qt.AlignLeft|Qt.AlignVCenter, m_inactiveText);
    } else {
        ExLineEdit.paintEvent(event);
    }
}

private:
    void updateGeometries()
{
    int menuHeight = height();
    int menuWidth = menuHeight + 1;
    if (!m_searchButton.m_menu)
        menuWidth = (menuHeight / 5) * 4;
    m_searchButton.resize(QSize(menuWidth, menuHeight));
}

    SearchButton *m_searchButton;
    QString m_inactiveText;
}
