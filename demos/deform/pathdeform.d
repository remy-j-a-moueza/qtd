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
module pathdeform;


import arthurwidgets,
	qt.gui.QPainterPath,
	qt.gui.QApplication,
	qt.gui.QMouseEvent,
	qt.core.QDateTime,
	qt.core.QTimerEvent,
	qt.core.QBasicTimer,
	qt.gui.QLayout,
	qt.gui.QLineEdit,
	qt.gui.QPainter,
	qt.gui.QSlider,
	qt.gui.QLabel,
	qt.gui.QDesktopWidget,
	qt.gui.QGroupBox,
	qt.gui.QPushButton,
	qt.gui.QVBoxLayout,
	qt.gui.QGridLayout,
	qt.gui.QHBoxLayout,
	qt.gui.QRadialGradient,
	qt.opengl.QGLFormat,
	tango.math.Math;


class PathDeformControls : QWidget
{
	private PathDeformRenderer m_renderer;

	mixin Signal!("okPressed");
	mixin Signal!("quitPressed");

	this(QWidget parent, PathDeformRenderer renderer, bool smallScreen)
	{
		super(parent);
		m_renderer = renderer;

		if (smallScreen)
			layoutForSmallScreen();
		else
			layoutForDesktop();
	}

	void layoutForDesktop()
	{
		QGroupBox mainGroup = new QGroupBox(this);
		mainGroup.setTitle(tr("Controls"));

		QGroupBox radiusGroup = new QGroupBox(mainGroup);
		radiusGroup.setTitle(tr("Lens Radius"));
		QSlider radiusSlider = new QSlider(Qt.Horizontal, radiusGroup);
		radiusSlider.setRange(15, 150);
		radiusSlider.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Fixed);

		QGroupBox deformGroup = new QGroupBox(mainGroup);
		deformGroup.setTitle(tr("Deformation"));
		QSlider deformSlider = new QSlider(Qt.Horizontal, deformGroup);
		deformSlider.setRange(-100, 100);
		deformSlider.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Fixed);

		QGroupBox fontSizeGroup = new QGroupBox(mainGroup);
		fontSizeGroup.setTitle(tr("Font Size"));
		QSlider fontSizeSlider = new QSlider(Qt.Horizontal, fontSizeGroup);
		fontSizeSlider.setRange(16, 200);
		fontSizeSlider.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Fixed);

		QGroupBox textGroup = new QGroupBox(mainGroup);
		textGroup.setTitle(tr("Text"));
		QLineEdit textInput = new QLineEdit(textGroup);

		QPushButton animateButton = new QPushButton(mainGroup);
		animateButton.setText(tr("Animated"));
		animateButton.setCheckable(true);

		QPushButton showSourceButton = new QPushButton(mainGroup);
		showSourceButton.setText(tr("Show Source"));

		version (QT_OPENGL_SUPPORT)
		{
			QPushButton enableOpenGLButton = new QPushButton(mainGroup);
			enableOpenGLButton.setText(tr("Use OpenGL"));
			enableOpenGLButton.setCheckable(true);
			enableOpenGLButton.setChecked(m_renderer.usesOpenGL());
			if (!QGLFormat.hasOpenGL())
				enableOpenGLButton.hide();
		}

		QPushButton whatsThisButton = new QPushButton(mainGroup);
		whatsThisButton.setText(tr("What's This?"));
		whatsThisButton.setCheckable(true);

		mainGroup.setFixedWidth(180);

		QVBoxLayout mainGroupLayout = new QVBoxLayout(mainGroup);
		mainGroupLayout.addWidget(radiusGroup);
		mainGroupLayout.addWidget(deformGroup);
		mainGroupLayout.addWidget(fontSizeGroup);
		mainGroupLayout.addWidget(textGroup);
		mainGroupLayout.addWidget(animateButton);
		mainGroupLayout.addStretch(1);
		version (QT_OPENGL_SUPPORT)
		{
			mainGroupLayout.addWidget(enableOpenGLButton);
		}
		mainGroupLayout.addWidget(showSourceButton);
		mainGroupLayout.addWidget(whatsThisButton);

		QVBoxLayout radiusGroupLayout = new QVBoxLayout(radiusGroup);
		radiusGroupLayout.addWidget(radiusSlider);

		QVBoxLayout deformGroupLayout = new QVBoxLayout(deformGroup);
		deformGroupLayout.addWidget(deformSlider);

		QVBoxLayout fontSizeGroupLayout = new QVBoxLayout(fontSizeGroup);
		fontSizeGroupLayout.addWidget(fontSizeSlider);

		QVBoxLayout textGroupLayout = new QVBoxLayout(textGroup);
		textGroupLayout.addWidget(textInput);

		QVBoxLayout mainLayout = new QVBoxLayout(this);
		mainLayout.addWidget(mainGroup);
		mainLayout.setMargin(0);

		radiusSlider.valueChanged.connect(&m_renderer.setRadius);
		deformSlider.valueChanged.connect(&m_renderer.setIntensity);
		fontSizeSlider.valueChanged.connect(&m_renderer.setFontSize);
		animateButton.clicked.connect(&m_renderer.setAnimated);
		version (QT_OPENGL_SUPPORT)
		{
			enableOpenGLButton.clicked.connect(&m_renderer.enableOpenGL);
		}

		textInput.textChanged.connect(&m_renderer.setText);
		m_renderer.descriptionEnabledChanged.connect(&whatsThisButton.setChecked);
		whatsThisButton.clicked.connect(&m_renderer.setDescriptionEnabled);
		showSourceButton.clicked.connect(&m_renderer.showSource);

		animateButton.animateClick();
		deformSlider.setValue(80);
		fontSizeSlider.setValue(120);
		radiusSlider.setValue(100);
		textInput.setText(tr("Qt"));
	}

	void layoutForSmallScreen()
	{
		QGroupBox mainGroup = new QGroupBox(this);
		mainGroup.setTitle(tr("Controls"));

		QLabel radiusLabel = new QLabel(mainGroup);
		radiusLabel.setText(tr("Lens Radius:"));
		QSlider radiusSlider = new QSlider(Qt.Horizontal, mainGroup);
		radiusSlider.setRange(15, 150);
		radiusSlider.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Fixed);

		QLabel deformLabel = new QLabel(mainGroup);
		deformLabel.setText(tr("Deformation:"));
		QSlider deformSlider = new QSlider(Qt.Horizontal, mainGroup);
		deformSlider.setRange(-100, 100);
		deformSlider.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Fixed);

		QLabel fontSizeLabel = new QLabel(mainGroup);
		fontSizeLabel.setText(tr("Font Size:"));
		QSlider fontSizeSlider = new QSlider(Qt.Horizontal, mainGroup);
		fontSizeSlider.setRange(16, 200);
		fontSizeSlider.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Fixed);

		QPushButton animateButton = new QPushButton(tr("Animated"), mainGroup);
		animateButton.setCheckable(true);

		version (QT_OPENGL_SUPPORT)
		{
			QPushButton enableOpenGLButton = new QPushButton(mainGroup);
			enableOpenGLButton.setText(tr("Use OpenGL"));
			enableOpenGLButton.setCheckable(true);
			enableOpenGLButton.setChecked(m_renderer.usesOpenGL());
			if (!QGLFormat.hasOpenGL())
				enableOpenGLButton.hide();
		}

		QPushButton quitButton = new QPushButton(tr("Quit"), mainGroup);
		QPushButton okButton = new QPushButton(tr("OK"), mainGroup);


		QGridLayout mainGroupLayout = new QGridLayout(mainGroup);
		mainGroupLayout.setMargin(0);
		mainGroupLayout.addWidget(radiusLabel, 0, 0, Qt.AlignRight);
		mainGroupLayout.addWidget(radiusSlider, 0, 1);
		mainGroupLayout.addWidget(deformLabel, 1, 0, Qt.AlignRight);
		mainGroupLayout.addWidget(deformSlider, 1, 1);
		mainGroupLayout.addWidget(fontSizeLabel, 2, 0, Qt.AlignRight);
		mainGroupLayout.addWidget(fontSizeSlider, 2, 1);
		mainGroupLayout.addWidget(animateButton, 3,0, 1,2);
		version (QT_OPENGL_SUPPORT)
		{
			mainGroupLayout.addWidget(enableOpenGLButton, 4,0, 1,2);
		}

		QVBoxLayout mainLayout = new QVBoxLayout(this);
		mainLayout.addWidget(mainGroup);
		mainLayout.addStretch(1);
		mainLayout.addWidget(okButton);
		mainLayout.addWidget(quitButton);

		quitButton.clicked.connect(&emitQuitSignal);
		okButton.clicked.connect(&emitOkSignal);
		radiusSlider.valueChanged.connect(&m_renderer.setRadius);
		deformSlider.valueChanged.connect(&m_renderer.setIntensity);
		fontSizeSlider.valueChanged.connect(&m_renderer.setFontSize);
		animateButton.clicked.connect(&m_renderer.setAnimated);
		version (QT_OPENGL_SUPPORT)
		{
			enableOpenGLButton.clicked.connect(&m_renderer.enableOpenGL);
		}

		animateButton.animateClick();
		deformSlider.setValue(80);
		fontSizeSlider.setValue(120);

		QRect screen_size = QApplication.desktop().screenGeometry();
		radiusSlider.setValue(qMin(screen_size.width(), screen_size.height())/5);
		m_renderer.setText(tr("Qt"));
	}

	void emitQuitSignal()
	{
		quitPressed.emit;
	}
	
	void emitOkSignal()
	{
		okPressed.emit;
	}
}


class PathDeformWidget : QWidget
{
private:

	PathDeformRenderer m_renderer;
	PathDeformControls m_controls;

public:

	this(QWidget parent, bool smallScreen)
	{
		super(parent);

		setWindowTitle(tr("Vector Deformation"));

		m_renderer = new PathDeformRenderer(this, smallScreen);
		m_renderer.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding);

		// Layouts
		QHBoxLayout mainLayout = new QHBoxLayout(this);
		mainLayout.addWidget(m_renderer);

		m_controls = new PathDeformControls(null, m_renderer, smallScreen);
		m_controls.setSizePolicy(QSizePolicy.Fixed, QSizePolicy.Minimum);

		if (!smallScreen)
		mainLayout.addWidget(m_controls);

		m_renderer.loadSourceFile(":res/deform/pathdeform.d");
		m_renderer.loadDescription(":res/deform/pathdeform.html");
		m_renderer.setDescriptionEnabled(false);

		m_renderer.clicked.connect(&showControls);
		m_controls.okPressed.connect(&hideControls);

		m_controls.quitPressed.connect(&QApplication.quit);
	}

	void showControls()
	{
		m_controls.showFullScreen;
	}

	void hideControls()
	{
		m_controls.hide;
	}

	void setWidgetStyle(QStyle style) // TODO: QWidget.setStyle is not virtual
	{
		super.setStyle(style);
		if (m_controls)
		{
			m_controls.setStyle(style);

			QWidget[] widgets = m_controls.findChildren!(QWidget);
			foreach (w; widgets)
				w.setStyle(style);
		}
	}
}

private QRect circle_bounds(QPointF center, qreal radius, qreal compensation)
{
	return QRect(qRound(center.x() - radius - compensation),
		qRound(center.y() - radius - compensation),
		qRound((radius + compensation) * 2),
		qRound((radius + compensation) * 2));
}

enum
{
	LENS_EXTENT = 10
}

class PathDeformRenderer : ArthurFrame
{
private:

	QBasicTimer m_repaintTimer;
	//     QBasicTimer m_fpsTimer;
	//     int m_fpsCounter;
	QTime m_repaintTracker;

	QPainterPath[] m_paths;
	QPointF[] m_advances;
	QRectF m_pathBounds;
	string m_text;

	QPixmap m_lens_pixmap;
	QImage m_lens_image;

	int m_fontSize;
	bool m_animated;

	qreal m_intensity;
	qreal m_radius;
	QPointF m_pos;
	QPointF m_offset;
	QPointF m_direction;
	QPointF m_mousePress;
	bool m_mouseDrag;
	bool m_smallScreen;

public:

	mixin Signal!("clicked");

	this(QWidget widget, bool smallScreen)
	{
		super(widget);
		m_radius = 100;
		m_pos = QPointF(m_radius, m_radius);
		m_direction = QPointF(1, 1);
		m_fontSize = 24;
		m_animated = true;
		m_repaintTimer.start(25, this);
		m_repaintTracker.start();
		m_intensity = 100;
		m_smallScreen = smallScreen;

		//     m_fpsTimer.start(1000, this);
		//     m_fpsCounter = 0;

		generateLensPixmap();
	}

	void setFontSize(int fontSize)
	{
		m_fontSize = fontSize;
		setText(m_text);
	}

	override QSize sizeHint() { return QSize(600, 500); }

	bool animated() { return m_animated; }
	int radius() { return cast(int) m_radius; }
	int fontSize() { return m_fontSize; }
	int intensity() { return cast(int) m_intensity; }
	string text() { return m_text; }

	void setText(string text)
	{
		m_text = text;

		auto f = new QFont("times new roman,utopia");
		f.setStyleStrategy(QFont.ForceOutline);
		f.setPointSize(m_fontSize);
		f.setStyleHint(QFont.Times);

		m_paths = null;
		m_pathBounds = QRectF();

		QPointF advance;
		
		bool do_quick = true;
		for (int i = 0; i < text.length; ++i) {
			if (text[i].unicode() >= 0x4ff && text.at(i).unicode() <= 0x1e00) {
				do_quick = false;
				break;
			}
		}

		if (do_quick) {
			for (int i = 0; i < text.length; ++i) {
				QPainterPath path = new QPainterPath;
				path.addText(advance, f, text.mid(i, 1));
				m_pathBounds |= path.boundingRect();
				m_paths ~= path;
				advance += QPointF(fm.width(text.mid(i, 1)), 0);
			}
		} else {
			QPainterPath path = new QPainterPath;
			path.addText(advance, f, text);
			m_pathBounds |= path.boundingRect();
			m_paths ~= path;
		}

		for (int i = 0; i < m_paths.length; ++i)
			m_paths[i] = m_paths[i] * (new QMatrix(1, 0, 0, 1, -m_pathBounds.x(), -m_pathBounds.y()));

		update();
	}

	void generateLensPixmap()
	{
		qreal rad = m_radius + LENS_EXTENT;

		QRect bounds = circle_bounds(QPointF(), rad, 0);

		QPainter painter = new QPainter;

		if (preferImage()) {
			m_lens_image = new QImage(bounds.size(), QImage.Format_ARGB32_Premultiplied);
			m_lens_image.fill(0);
			painter.begin(m_lens_image);
		} else {
			m_lens_pixmap = new QPixmap(bounds.size());
			m_lens_pixmap.fill(new QColor(Qt.transparent));
			painter.begin(m_lens_pixmap);
		}

		auto gr = new QRadialGradient(rad, rad, rad, 3 * rad / 5, 3 * rad / 5);
		gr.setColorAt(0.0, new QColor(255, 255, 255, 191));
		gr.setColorAt(0.2, new QColor(255, 255, 127, 191));
		gr.setColorAt(0.9, new QColor(150, 150, 200, 63));
		gr.setColorAt(0.95, new QColor(0, 0, 0, 127));
		gr.setColorAt(1, new QColor(0, 0, 0, 0));
		painter.setRenderHint(QPainter.Antialiasing);
		painter.setBrush(gr);
		painter.setPen(Qt.NoPen);
		painter.drawEllipse(0, 0, bounds.width(), bounds.height());
	}

	void setAnimated(bool animated)
	{
		m_animated = animated;

		if (m_animated) {
			//         m_fpsTimer.start(1000, this);
			//         m_fpsCounter = 0;
			m_repaintTimer.start(25, this);
			m_repaintTracker.start();
		} else {
			//         m_fpsTimer.stop();
			m_repaintTimer.stop();
		}
	}

	override void timerEvent(QTimerEvent e)
	{
		if (e.timerId == m_repaintTimer.timerId) 
		{
			if ((QLineF(QPointF(0,0), m_direction)).length() > 1)
				m_direction *= 0.995;
			qreal time = m_repaintTracker.restart();

			QRect rectBefore = circle_bounds(m_pos, m_radius, m_fontSize);

			qreal dx = m_direction.x();
			qreal dy = m_direction.y();
			if (time > 0) {
				dx = dx * time * .1;
				dy = dy * time * .1;
			}

			m_pos += QPointF(dx, dy);

			if (m_pos.x() - m_radius < 0) {
				m_direction.x = -m_direction.x;
				m_pos.x = m_radius;
			} else if (m_pos.x + m_radius > width) {
				m_direction.x = -m_direction.x;
				m_pos.x = width - m_radius;
			}

			if (m_pos.y - m_radius < 0) {
				m_direction.y = -m_direction.y;
				m_pos.y = m_radius;
			} else if (m_pos.y + m_radius > height) {
				m_direction.y = -m_direction.y;
				m_pos.y = height - m_radius;
			}

			void noGLUpdate()
			{
				QRect rectAfter = circle_bounds(m_pos, m_radius, m_fontSize);
				update(rectAfter.united(rectBefore));
				QApplication.syncX();
			}

			version (QT_OPENGL_SUPPORT)
			{
				if (usesOpenGL()) {
					update;
				}
				else
					noGLUpdate;
			}
			else
				noGLUpdate;
		}
		//     else if (e.timerId() == m_fpsTimer.timerId()) {
		//         printf("fps: %d\n", m_fpsCounter);
		//         emit frameRate(m_fpsCounter);
		//         m_fpsCounter = 0;

		//     }
	}

	override void mousePressEvent(QMouseEvent e)
	{
		setDescriptionEnabled(false);

		m_repaintTimer.stop();
		m_offset = QPointF();
		if ((QLineF(m_pos, QPointF(e.pos))).length <= m_radius)
			m_offset = m_pos - QPointF(e.pos);

		m_mousePress = QPointF(e.pos);

		// If we're not running in small screen mode, always assume we're dragging
		m_mouseDrag = !m_smallScreen;

		mouseMoveEvent(e);
	}

	override void mouseReleaseEvent(QMouseEvent e)
	{
		if (e.buttons() == Qt.NoButton && m_animated) {
			m_repaintTimer.start(10, this);
			m_repaintTracker.start();
		}

		if (!m_mouseDrag && m_smallScreen)
			clicked.emit;
	}

	override void mouseMoveEvent(QMouseEvent e)
	{
		auto epos = QPointF(e.pos);

		if (!m_mouseDrag && (QLineF(m_mousePress, QPointF(e.pos))).length() > 25.0)
		m_mouseDrag = true;

		if (m_mouseDrag)
		{
			QRect rectBefore = circle_bounds(m_pos, m_radius, m_fontSize);
			if (e.type() == QEvent.MouseMove) {
				QLineF line = QLineF(m_pos, epos + m_offset);
				line.setLength(line.length() * .1);
				auto dir = QPointF(line.dx(), line.dy());
				m_direction = (m_direction + dir) / 2;
			}
			m_pos = epos + m_offset;

			void noGLUpdate()
			{
				QRect rectAfter = circle_bounds(m_pos, m_radius, m_fontSize);
				update(rectBefore.united(rectAfter));
			}

			version (QT_OPENGL_SUPPORT)
			{
				if (usesOpenGL()) {
					update;
				} else
					noGLUpdate;
			}
			else
				noGLUpdate;
		}
	}

	QPainterPath lensDeform(QPainterPath source, QPointF offset)
	{
		auto path = new QPainterPath;
		path.addPath(source);

		qreal flip = m_intensity / 100.0;

		for (int i=0; i<path.elementCount; ++i)
		{
			auto e = path.elementAt(i);

			qreal x = e.x + offset.x();
			qreal y = e.y + offset.y();

			qreal dx = x - m_pos.x();
			qreal dy = y - m_pos.y();
			qreal len = m_radius - sqrt(dx * dx + dy * dy);

			if (len > 0) {
				path.setElementPositionAt(i,
					  x + flip * dx * len / m_radius,
					  y + flip * dy * len / m_radius);
			} else {
				path.setElementPositionAt(i, x, y);
			}
		}

		return path;
	}

	override void paint(QPainter painter)
	{
		int pad_x = 5;
		int pad_y = 5;

		int skip_x = qRound(m_pathBounds.width() + pad_x + m_fontSize/2);
		int skip_y = qRound(m_pathBounds.height() + pad_y);

		painter.setPen(Qt.NoPen);
		painter.setBrush(new QColor(Qt.black));

		auto clip = painter.clipPath().boundingRect();

		int overlap = pad_x / 2;

		for (int start_y=0; start_y < height(); start_y += skip_y)
		{
			if (start_y > clip.bottom())
			break;

			int start_x = -overlap;
			for (; start_x < width(); start_x += skip_x)
			{
				if (start_y + skip_y >= clip.top() &&
					start_x + skip_x >= clip.left() &&
					start_x <= clip.right())
				{
					for (int i=0; i<m_paths.length; ++i) {
						QPainterPath path = lensDeform(m_paths[i], QPointF(start_x, start_y));
						painter.drawPath(path);
					}
				}
			}
			overlap = skip_x - (start_x - width());
		}

		if (preferImage) {
			painter.drawImage(m_pos - QPointF(m_radius + LENS_EXTENT, m_radius + LENS_EXTENT), m_lens_image);
		} else {
			painter.drawPixmap(m_pos - QPointF(m_radius + LENS_EXTENT, m_radius + LENS_EXTENT), m_lens_pixmap);
		}
	}

	void setRadius(int radius)
	{
		qreal max = max(m_radius, cast(qreal)radius);
		m_radius = radius;
		generateLensPixmap();
		if (!m_animated || m_radius < max)
		{
			auto noGLUpdate = (){ update(circle_bounds(m_pos, max, m_fontSize)); };

			version (QT_OPENGL_SUPPORT)
			{
				if (usesOpenGL())
					update();
				else
					noGLUpdate();
			}
			else
				noGLUpdate();
		}
	}

	void setIntensity(int intensity)
	{
		m_intensity = intensity;
		if (!m_animated)
		{
			auto noGLUpdate = (){ update(circle_bounds(m_pos, m_radius, m_fontSize)); };

			version (QT_OPENGL_SUPPORT)
			{
				if (usesOpenGL()) {
					update();
				} else
					noGLUpdate();
			}
			else
				noGLUpdate();
		}
	}
}
