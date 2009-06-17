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
module arthurwidgets;


import qt.core.QFile,
    qt.gui.QApplication,
    qt.gui.QPainter,
    qt.gui.QPainterPath,
    qt.gui.QPixmapCache,
    qt.gui.QTextDocument,
    qt.gui.QAbstractTextDocumentLayout,
    qt.gui.QLinearGradient,
    qt.gui.QTextBrowser,
    qt.gui.QBoxLayout,
    qt.opengl.QGL,
    qt.Signal,
    tango.text.Util;

import tango.text.Regex : Regex;

//#include <private/qpixmapdata_p.h>

//extern QPixmap cached(const QString &img);

version (QT_OPENGL_SUPPORT)
{
    import qt.opengl.QGLWidget;
    class GLWidget : QGLWidget
    {
        this(QWidget parent)
        {
            super(new QGLFormat(QGL.SampleBuffers), parent);
        }

        void disableAutoBufferSwap() { setAutoBufferSwap(false); }
        override void paintEvent(QPaintEvent) { parentWidget().update(); }
    }
}

class ArthurFrame : QWidget
{
protected:

    version(QT_OPENGL_SUPPORT)
    {
        GLWidget glw;
        bool m_use_opengl;
    }

    QPixmap m_tile;

    bool m_show_doc;
    bool m_prefer_image;
    QTextDocument m_document;

    string m_sourceFileName;

public:
    mixin Signal!("descriptionEnabledChanged", bool);

    bool preferImage() { return m_prefer_image; }

    void paint(QPainter) {}

    this(QWidget parent)
    {
        super(parent);

        version (QT_OPENGL_SUPPORT)
        {
            QGLFormat f = QGLFormat.defaultFormat();
            f.setSampleBuffers(true);
            f.setStencil(true);
            f.setAlpha(true);
            f.setAlphaBufferSize(8);
            QGLFormat.setDefaultFormat(f);
        }

        m_tile = new QPixmap(128, 128);
        m_tile.fill(new QColor(Qt.white));
        scope pt = new QPainter(m_tile);
        auto color = new QColor(230, 230, 230);
        pt.fillRect(0, 0, 64, 64, color);
        pt.fillRect(64, 64, 64, 64, color);
        pt.end();

    //     QPalette pal = palette();
    //     pal.setBrush(backgroundRole(), m_tile);
    //     setPalette(pal);

        version (Q_WS_X11)
        {
            auto xRenderPixmap = new QPixmap(1, 1);
            m_prefer_image = xRenderPixmap.pixmapData().classId() == QPixmapData.X11Class && !xRenderPixmap.x11PictureHandle();
        }
    }

    version (QT_OPENGL_SUPPORT)
    {
        void enableOpenGL(bool use_opengl)
        {
            m_use_opengl = use_opengl;

            if (!glw) {
                glw = new GLWidget(this);
                glw.setAutoFillBackground(false);
                glw.disableAutoBufferSwap();
                QApplication.postEvent(this, new QResizeEvent(size(), size()));
            }

            if (use_opengl) {
                glw.show();
            } else {
                glw.hide();
            }

            update();
        }

        bool usesOpenGL() { return m_use_opengl; }
        QGLWidget glWidget(){ return glw; }
    }

    override void paintEvent(QPaintEvent e)
    {
        version (Q_WS_QWS)
            static QPixmap static_image;
        else
            static QImage static_image;

        auto painter = new QPainter;

        version (QT_OPENGL_SUPPORT)
            auto prefImage = preferImage && !m_use_opengl;
        else
            auto prefImage = preferImage;

        if (prefImage) {
            if (!static_image || static_image.size() != size()) {
                delete static_image;
                version (Q_WS_QWS)
                    static_image = new QPixmap(size());
                else
                    static_image = new QImage(size(), QImage.Format_RGB32);
            }
            painter.begin(static_image);

            int o = 10;

            QBrush bg = palette().brush(QPalette.Window);
            painter.fillRect(0, 0, o, o, bg);
            painter.fillRect(width() - o, 0, o, o, bg);
            painter.fillRect(0, height() - o, o, o, bg);
            painter.fillRect(width() - o, height() - o, o, o, bg);
        } else {
            version (QT_OPENGL_SUPPORT)
            {
                if (m_use_opengl) {
                    painter.begin(glw);
                    painter.fillRect(new QRectF(0, 0, glw.width(), glw.height()), palette().color(backgroundRole()));
                } else {
                    painter.begin(this);
                }
            }
            else
                painter.begin(this);
        }

        painter.setClipRect(e.rect());

        painter.setRenderHint(QPainter.Antialiasing);

        auto clipPath = new QPainterPath;

        QRect r = rect();
        qreal left = r.x() + 1;
        qreal top = r.y() + 1;
        qreal right = r.right();
        qreal bottom = r.bottom();
        qreal radius2 = 8 * 2;

        clipPath.moveTo(right - radius2, top);
        clipPath.arcTo(right - radius2, top, radius2, radius2, 90, -90);
        clipPath.arcTo(right - radius2, bottom - radius2, radius2, radius2, 0, -90);
        clipPath.arcTo(left, bottom - radius2, radius2, radius2, 270, -90);
        clipPath.arcTo(left, top, radius2, radius2, 180, -90);
        clipPath.closeSubpath();

        painter.save();
        painter.setClipPath(clipPath, Qt.IntersectClip);

        painter.drawTiledPixmap(rect(), m_tile);

        // client painting

        paint(painter);
        painter.restore();

        painter.save();
        if (m_show_doc)
            paintDescription(painter);
        painter.restore();

        int level = 180;
        painter.setPen(new QPen(new QBrush(new QColor(level, level, level)), 2));
        painter.setBrush(Qt.NoBrush);
        painter.drawPath(clipPath);

        if (prefImage) {
            painter.end();
            painter.begin(this);
            version (Q_WS_QWS)
                painter.drawPixmap(e.rect(), static_image, e.rect());
            else
                painter.drawImage(e.rect(), static_image, e.rect());
        }

        // TODO: this sucks
        version (QT_OPENGL_SUPPORT) {
            if (m_use_opengl && (inherits("PathDeformRenderer") || inherits("PathStrokeRenderer") || inherits("CompositionRenderer") || m_show_doc))
                glw.swapBuffers();
        }
    }

    void resizeEvent(QResizeEvent e)
    {
        version (QT_OPENGL_SUPPORT)
        {
            if (glw)
                glw.setGeometry(0, 0, e.size().width()-1, e.size().height()-1);
        }
        super.resizeEvent(e);
    }

    void setDescriptionEnabled(bool enabled)
    {
        if (m_show_doc != enabled) {
            m_show_doc = enabled;
            descriptionEnabledChanged.emit(m_show_doc);
            update();
        }
    }

    void loadDescription(string fileName)
    {
        auto textFile = new QFile(fileName);
        string text;
        if (!textFile.open(QFile.ReadOnly))
            text = "Unable to load resource file: " ~ fileName;
        else
            text = textFile.readAll().toString; // TODO: excessive copying
        setDescription(text);
    }

    void setDescription(string text)
    {
        m_document = new QTextDocument(this);
        m_document.setHtml(text);
    }

    void paintDescription(QPainter painter)
    {
        if (!m_document)
            return;

        int pageWidth = qMax(width() - 100, 100);
        int pageHeight = qMax(height() - 100, 100);
        if (pageWidth != m_document.pageSize().width()) {
            m_document.setPageSize(QSizeF(pageWidth, pageHeight));
        }

        auto textRect = new QRect(width() / 2 - pageWidth / 2,
                       height() / 2 - pageHeight / 2,
                       pageWidth,
                       pageHeight);
        int pad = 10;
        QRect clearRect = textRect.adjusted(-pad, -pad, pad, pad);
        painter.setPen(Qt.NoPen);
        painter.setBrush(new QColor(0, 0, 0, 63));
        int shade = 10;
        painter.drawRect(clearRect.x() + clearRect.width() + 1,
                          clearRect.y() + shade,
                          shade,
                          clearRect.height() + 1);
        painter.drawRect(clearRect.x() + shade,
                          clearRect.y() + clearRect.height() + 1,
                          clearRect.width() - shade + 1,
                          shade);

        painter.setRenderHint(QPainter.Antialiasing, false);
        painter.setBrush(new QColor(255, 255, 255, 220));
        painter.setPen(new QColor(Qt.black));
        painter.drawRect(clearRect);

        painter.setClipRect(textRect, Qt.IntersectClip);
        painter.translate(textRect.topLeft());

        auto ctx = new QAbstractTextDocumentLayout_PaintContext;

        auto g = new QLinearGradient(0, 0, 0, textRect.height());
        g.setColorAt(0, new QColor(Qt.black));
        g.setColorAt(0.9, new QColor(Qt.black));
        g.setColorAt(1, new QColor(Qt.transparent));

        QPalette pal = palette();
        pal.setBrush(QPalette.Text, new QBrush(g));

        ctx.setPalette(pal);
        ctx.setClip(new QRectF(0, 0, textRect.width(), textRect.height()));
        m_document.documentLayout().draw(painter, ctx);
    }

    void loadSourceFile(string sourceName)
    {
        m_sourceFileName = sourceName;
    }

    void showSource()
    {
        // Check for existing source
        if (findChild!(QTextBrowser))
            return;

        string contents;
        if (!m_sourceFileName.length) {
            contents = "No source for widget: " ~ objectName();
        } else {
            auto f = new QFile(m_sourceFileName);
            if (!f.open(QFile.ReadOnly))
                contents = "Could not open file: " ~ m_sourceFileName;
            else
                contents = f.readAll.toString;
        }

        contents = contents.substitute("&", "&amp;");
        contents = contents.substitute("<", "&lt;");
        contents = contents.substitute(">", "&gt;");

        static const string[] keywords =
            ["for ", "if ", "switch ", " int ", "#include ", "const"
                , "void ", "uint ", "case ", "double ", "#define ", "static"
                , "new", "this"];

        foreach (keyword; keywords)
            contents = contents.substitute(keyword, "<font color=olive>" ~ keyword ~ "</font>");
        contents = contents.substitute("(int ", "(<font color=olive><b>int </b></font>");

        static const string[] ppKeywords =
            ["#ifdef", "#ifndef", "#if", "#endif", "#else"];

        foreach (keyword; ppKeywords)
            contents = contents.substitute(keyword, "<font color=navy>" ~ keyword ~ "</font>");

        auto ddRe = new Regex("(\\d\\d?)");
        contents = ddRe.replaceAll(contents, "<font color=navy>\\1</font>");

        auto commentRe = new Regex("(//.+?)\\n");
        contents = commentRe.replaceAll(contents, "<font color=red>\\1</font>\n");

        auto stringLiteralRe = new Regex("(\".+?\")");
        contents = stringLiteralRe.replaceAll(contents, "<font color=green>\\1</font>");

        auto html = contents.dup;
        html = "<html><pre>" ~ html ~ "</pre></html>";

        QTextBrowser sourceViewer = new QTextBrowser(null);
        sourceViewer.setWindowTitle("Source: " ~ m_sourceFileName[5..$]);
        sourceViewer.setParent(this, Qt.Dialog);
        sourceViewer.setAttribute(Qt.WA_DeleteOnClose);
        sourceViewer.setLineWrapMode(QTextEdit.NoWrap);
        sourceViewer.setHtml(html);
        sourceViewer.resize(600, 600);
        sourceViewer.show();
    }
}
