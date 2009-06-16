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
module norwegianwoodstyle;


import qt.gui.QMotifStyle;
import qt.gui.QPalette;
import qt.gui.QPainterPath;
import qt.gui.QPushButton;
import qt.gui.QComboBox;


class NorwegianWoodStyle : public QMotifStyle
{
public:

	this() {}

	void polish(QPalette palette)
	{
		auto brown = new QColor(212, 140, 95);
		auto beige = new QColor(236, 182, 120);
		auto slightlyOpaqueBlack = new QColor(0, 0, 0, 63);

		auto backgroundImage = new QPixmap(":/images/woodbackground.png");
		auto buttonImage = new QPixmap(":/images/woodbutton.png");
		QPixmap midImage = buttonImage;

		auto painter = new QPainter;
		painter.begin(midImage);
		painter.setPen(Qt.NoPen);
		painter.fillRect(midImage.rect(), slightlyOpaqueBlack);
		painter.end();

		palette = new QPalette(brown);

		palette.setBrush(QPalette.BrightText, new QBrush(QColor.White));
		palette.setBrush(QPalette.Base, new QBrush(beige));
		palette.setBrush(QPalette.Highlight, new QBrush(QColor.DarkGreen));
		setTexture(palette, QPalette.Button, buttonImage);
		setTexture(palette, QPalette.Mid, midImage);
		setTexture(palette, QPalette.Window, backgroundImage);

		QBrush brush = palette.brush(QPalette.Window); //.background();
		brush.setColor(brush.color().darker());

		palette.setBrush(QPalette.Disabled, QPalette.WindowText, brush);
		palette.setBrush(QPalette.Disabled, QPalette.Text, brush);
		palette.setBrush(QPalette.Disabled, QPalette.ButtonText, brush);
		palette.setBrush(QPalette.Disabled, QPalette.Base, brush);
		palette.setBrush(QPalette.Disabled, QPalette.Button, brush);
		palette.setBrush(QPalette.Disabled, QPalette.Mid, brush);
	}

	void polish(QWidget widget)
	{
		if (cast(QPushButton) widget || cast(QComboBox) widget)
			widget.setAttribute(Qt.WA_Hover, true);
	}

	void unpolish(QWidget widget)
	{
		if (cast(QPushButton) widget || cast(QComboBox) widget)
			widget.setAttribute(Qt.WA_Hover, false);
	}

	int pixelMetric(PixelMetric metric, QStyleOption option, QWidget widget)
	{
		switch (metric) {
			case PM_ComboBoxFrameWidth:
				return 8;
			case PM_ScrollBarExtent:
				return QMotifStyle.pixelMetric(metric, option, widget) + 4;
			default:
				return QMotifStyle.pixelMetric(metric, option, widget);
		}
	}

	int styleHint(StyleHint hint, QStyleOption option, QWidget widget, QStyleHintReturn returnData)
	{
		switch (hint) {
			case SH_DitherDisabledText:
				return cast(int) false;
			case SH_EtchDisabledText:
				return cast(int) true;
			default:
				return QMotifStyle.styleHint(hint, option, widget, returnData);
		}
	}

	void drawPrimitive(PrimitiveElement element, QStyleOption option, QPainter painter, QWidget widget)
	{
		switch (element) {
			case PE_PanelButtonCommand:
			{
				int delta = (option.state & State_MouseOver) ? 64 : 0;
				auto slightlyOpaqueBlack = new QColor(0, 0, 0, 63);
				auto semiTransparentWhite = new QColor(255, 255, 255, 127 + delta);
				auto semiTransparentBlack = new QColor(0, 0, 0, 127 - delta);

				int x, y, width, height;
				option.rect.getRect(&x, &y, &width, &height);

				QPainterPath roundRect = roundRectPath(option.rect);
				int radius = qMin(width, height) / 2;

				QBrush brush;
				bool darker;

				QStyleOptionButton buttonOption = cast(QStyleOptionButton) option;
				if (buttonOption && (buttonOption.features & QStyleOptionButton.Flat)) {
					brush = option.palette.brush(QPalette.Window); //background();
					darker = cast(bool) (option.state & (State_Sunken | State_On));
				} else {
					if (option.state & (State_Sunken | State_On)) {
						brush = option.palette.mid();
						darker = !(option.state & State_Sunken);
					} else {
						brush = option.palette.button();
						darker = false;
					}
				}

				painter.save();
				painter.setRenderHint(QPainter.Antialiasing, true);
				painter.fillPath(roundRect, brush);
				if (darker)
					painter.fillPath(roundRect, new QBrush(slightlyOpaqueBlack));

				int penWidth;

				if (radius < 10)
					penWidth = 3;
				else if (radius < 20)
					penWidth = 5;
				else
					penWidth = 7;

				auto topPen = new QPen(semiTransparentWhite);
				auto bottomPen = new QPen(semiTransparentBlack);

				topPen.setWidth(penWidth);
				bottomPen.setWidth(penWidth);

				if (option.state & (State_Sunken | State_On))
					qSwap(topPen, bottomPen);

				int x1 = x;
				int x2 = x + radius;
				int x3 = x + width - radius;
				int x4 = x + width;

				if (option.direction == Qt.RightToLeft) {
					qSwap(x1, x4);
					qSwap(x2, x3);
				}

				auto topHalf = new QPolygon();
				topHalf.append(QPoint(x1, y));
				topHalf.append(QPoint(x4, y));
				topHalf.append(QPoint(x3, y + radius));
				topHalf.append(QPoint(x2, y + height - radius));
				topHalf.append(QPoint(x1, y + height));

				painter.setClipPath(roundRect);
				painter.setClipRegion(new QRegion(topHalf), Qt.IntersectClip);
				painter.setPen(topPen);
				painter.drawPath(roundRect);

				QPolygon bottomHalf = topHalf;
				bottomHalf.replace(0, QPoint(x4, y + height));

				painter.setClipPath(roundRect);
				painter.setClipRegion(new QRegion(bottomHalf), Qt.IntersectClip);
				painter.setPen(bottomPen);
				painter.drawPath(roundRect);

				painter.setPen(option.palette.brush(QPalette.WindowText).color());
				painter.setClipping(false);
				painter.drawPath(roundRect);

				painter.restore();
			}
				break;
			default:
				QMotifStyle.drawPrimitive(element, option, painter, widget);
		}
	}

	void drawControl(ControlElement element, QStyleOption option, QPainter painter, QWidget widget)
	{
		switch (element) {
			case CE_PushButtonLabel:
			{
				QStyleOptionButton myButtonOption;
				QStyleOptionButton buttonOption = cast(QStyleOptionButton) option;
				if (buttonOption) {
					myButtonOption = buttonOption;
					if (myButtonOption.palette.currentColorGroup() != QPalette.Disabled) {
						if (myButtonOption.state & (State_Sunken | State_On)) {
							myButtonOption.palette.setBrush(QPalette.ButtonText,
							myButtonOption.palette.brightText());
						}
					}
				}
				QMotifStyle.drawControl(element, myButtonOption, painter, widget);
				}
				break;
			default:
				QMotifStyle.drawControl(element, option, painter, widget);
		}
	}

private:

	static void setTexture(QPalette palette, QPalette.ColorRole role, QPixmap pixmap)
	{
		for (int i = 0; i < QPalette.NColorGroups; ++i) {
			QColor color = palette.brush(cast(QPalette.ColorGroup) i, role).color();
			palette.setBrush(cast(QPalette.ColorGroup) i, role, new QBrush(color, pixmap));
		}
	}
	
	static QPainterPath roundRectPath(QRect rect)
	{
		int radius = qMin(rect.width(), rect.height()) / 2;
		int diam = 2 * radius;

		int x1, y1, x2, y2;
		rect.getCoords(&x1, &y1, &x2, &y2);

		auto path = new QPainterPath;
		path.moveTo(x2, y1 + radius);
		path.arcTo(QRectF(x2 - diam, y1, diam, diam), 0.0, +90.0);
		path.lineTo(x1 + radius, y1);
		path.arcTo(QRectF(x1, y1, diam, diam), 90.0, +90.0);
		path.lineTo(x1, y2 - radius);
		path.arcTo(QRectF(x1, y2 - diam, diam, diam), 180.0, +90.0);
		path.lineTo(x1 + radius, y2);
		path.arcTo(QRectF(x2 - diam, y2 - diam, diam, diam), 270.0, +90.0);
		path.closeSubpath();
		return path;
	}
}
