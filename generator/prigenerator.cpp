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

#include "prigenerator.h"
#include "reporthandler.h"
#include "fileout.h"

void PriGenerator::addHeader(QString package, const QString &header)
{
    priHash[package.replace(".", "_")].headers << header;
}

void PriGenerator::addSource(QString package, const QString &source)
{
    priHash[package.replace(".", "_")].sources << source;
}

void PriGenerator::addClass(QString package, const QString &class_name)
{
    priHash[package.replace(".", "_")].classes << class_name;
}

void PriGenerator::generate()
{
    QHashIterator<QString, Pri> pri(priHash);
    while (pri.hasNext()) {
        pri.next();

        FileOut file(m_out_dir + "/cpp/" + pri.key() + "/" + pri.key() + ".txt");
        file.stream << "set (classes \n";
        QStringList list = pri.value().classes;
        qSort(list.begin(), list.end());
        foreach (const QString &entry, list) {
            file.stream << "    " << entry << "\n";
        }
        file.stream << ")\n";

        if (file.done())
            ++m_num_generated_written;
        ++m_num_generated;
    }
}
