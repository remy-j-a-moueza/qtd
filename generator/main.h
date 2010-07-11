/****************************************************************************
**
** Copyright (C) 1992-2008 Nokia. All rights reserved.
**
** This file is part of Qt Jambi.
**
** * Commercial Usage
* Licensees holding valid Qt Commercial licenses may use this file in
* accordance with the Qt Commercial License Agreement provided with the
* Software or, alternatively, in accordance with the terms contained in
* a written agreement between you and Nokia.
*
*
* GNU General Public License Usage
* Alternatively, this file may be used under the terms of the GNU
* General Public License versions 2.0 or 3.0 as published by the Free
* Software Foundation and appearing in the file LICENSE.GPL included in
* the packaging of this file.  Please review the following information
* to ensure GNU General Public Licensing requirements will be met:
* http://www.fsf.org/licensing/licenses/info/GPLv2.html and
* http://www.gnu.org/copyleft/gpl.html.  In addition, as a special
* exception, Nokia gives you certain additional rights. These rights
* are described in the Nokia Qt GPL Exception version 1.2, included in
* the file GPL_EXCEPTION.txt in this package.
* 
* Qt for Windows(R) Licensees
* As a special exception, Nokia, as the sole copyright holder for Qt
* Designer, grants users of the Qt/Eclipse Integration plug-in the
* right for the Qt/Eclipse Integration to link to functionality
* provided by Qt Designer and its related libraries.
*
*
* If you are unsure which license is appropriate for your use, please
* contact the sales department at qt-sales@nokia.com.

**
** This file is provided AS IS with NO WARRANTY OF ANY KIND, INCLUDING THE
** WARRANTY OF DESIGN, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
**
****************************************************************************/

#ifndef MAIN_H
#define MAIN_H

#include "pp.h"

#include <QFile>
#include <QDir>

struct Preprocess
{
    static bool preprocess(const QString &sourceFile, const QString &targetFile, const QString &commandLineIncludes = QString(),
                           QString qtdir = QString(), QString qtdir_inc = QString())
    {
        rpp::pp_environment env;
        rpp::pp preprocess(env);

        rpp::pp_null_output_iterator null_out;

        const char *ppconfig = ":/trolltech/generator/parser/rpp/pp-qt-configuration";

        QFile file(ppconfig);
        if (!file.open(QFile::ReadOnly)) {
            fprintf(stderr, "Preprocessor configuration file not found '%s'\n", ppconfig);
            return false;
        }

        QByteArray ba = file.readAll();
        file.close();
        preprocess.operator() (ba.constData(), ba.constData() + ba.size(), null_out);

        QStringList includes;
        includes << QString(".");

#if defined(Q_OS_WIN32)
        const char *path_splitter = "*";
#else
        const char *path_splitter = ":";
#endif
        // Environment INCLUDE
        QString includePath = getenv("INCLUDE");
        if (!includePath.isEmpty())
            includes += includePath.split(path_splitter);

        // Includes from the command line
        if (!commandLineIncludes.isEmpty())
            includes += commandLineIncludes.split(path_splitter);

        // Include Qt
        if (qtdir.isEmpty())
            qtdir = getenv ("QTDIR");
        if (qtdir_inc.isEmpty())
            qtdir_inc = getenv ("QTDIR_INC");
        if (qtdir.isEmpty() && qtdir_inc.isEmpty()) {
            qWarning("QTDIR and QTDIR_INC environment variables not set. This may cause problems with finding the necessary include files.");
        } else {
            if (qtdir_inc.isEmpty())
                qtdir_inc = qtdir + "/include";
            includes << (qtdir_inc + "/QtXml");
            includes << (qtdir_inc + "/QtNetwork");
            includes << (qtdir_inc + "/QtCore");
            includes << (qtdir_inc + "/QtGui");
            includes << (qtdir_inc + "/QtOpenGL");
            includes << qtdir_inc;
        }

        foreach (QString include, includes)
            preprocess.push_include_path(QDir::convertSeparators(include).toStdString());

        QString currentDir = QDir::current().absolutePath();
        QFileInfo sourceInfo(sourceFile);
        QDir::setCurrent(sourceInfo.absolutePath());

        std::string result;
        result.reserve (20 * 1024); // 20K

        result += "# 1 \"builtins\"\n";
        result += "# 1 \"";
        result += sourceFile.toStdString();
        result += "\"\n";

        preprocess.file (sourceInfo.fileName().toStdString(),
                         rpp::pp_output_iterator<std::string> (result));

        QDir::setCurrent(currentDir);

        QFile f(targetFile);
        if (!f.open(QIODevice::WriteOnly | QIODevice::Text)) {
            fprintf(stderr, "Failed to write preprocessed file: %s\n", qPrintable(targetFile));
        }
        f.write(result.c_str(), result.length());

        return true;
    }
};

#endif // MAIN_H
