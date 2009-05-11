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

#include "classlistgenerator.h"

QString ClassListGenerator::fileName() const { return "qtjambi-classes.qdoc"; }

static bool class_sorter(AbstractMetaClass *a, AbstractMetaClass *b)
{
    return a->name() < b->name();
}

void ClassListGenerator::generate()
{
    QFile f(fileName());
    if (f.open(QFile::WriteOnly)) {
        QTextStream s(&f);

        s << "/****************************************************************************" << endl
          << "**" << endl
          << "** This is a generated file, please don't touch." << endl
          << "**" << endl
          << "****************************************************************************/" << endl << endl;

        s << "/*!" << endl
          << "\\page qtjambi-classes.html" << endl << endl
          << "\\title Qt Jambi's classes" << endl << endl
          << "This is a list of all Qt Jambi classes." << endl << endl
          << "\\table 100%" << endl;

        AbstractMetaClassList classes = Generator::classes();
        qSort(classes.begin(), classes.end(), class_sorter);

        int numColumns = 4;
        int numRows = (classes.size() + numColumns - 1) / numColumns;

        for (int i = 0; i < numRows; ++i) {
            s << endl << "\\row ";
            for (int j=0; j<numColumns; ++j) {
                if (classes.value(i + j * numRows)) {
                    s << "\\o \\l{" << classes.value(i + j * numRows)->qualifiedCppName()
                      << "}{" << classes.value(i + j * numRows)->name() << "} ";
                }
            }

        }

        s << endl << "\\endtable" << endl
          << "*/" << endl;
    }
}
