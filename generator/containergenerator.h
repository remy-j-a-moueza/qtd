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

#ifndef CONTAINERGENERATOR_H
#define CONTAINERGENERATOR_H

#include "dgenerator.h"
#include "metajava.h"
#include "prigenerator.h"

const int NUM_ARRAY_FUNCS = 3;

class ContainerGenerator : public DGenerator
{
    Q_OBJECT

public:
    enum OutputDirectoryType {
        CppDirectory,
        DDirectory,
        HDirectory
    };

    typedef void (ContainerGenerator::*WriteOut)(QTextStream &s, AbstractMetaClass *cls);

    ContainerGenerator(CppImplGenerator *cpp_impl_generator);

    virtual void generate();
    virtual void write(QTextStream &s, const AbstractMetaClass *java_class);
    void writeFile(const QString& fileName, OutputDirectoryType dirType, WriteOut writeOut);

    // base functions for operating with arrays
    void writeHeaderContent(QTextStream &s, AbstractMetaClass *cls);
    void writeCppContent(QTextStream &s, AbstractMetaClass *cls);
    void writeDContent(QTextStream &s, AbstractMetaClass *cls);
    void writeDContent2(QTextStream &s, AbstractMetaClass *cls);

    void buildTypeList();

    void processFunction(const AbstractMetaFunction *d_function);
    void processType(AbstractMetaType *d_type);
    void addTypeEntry(const TypeEntry* te);

    virtual QString subDirectoryForPackage(const QString &package, OutputDirectoryType type) const;

    void setFilenameStub(const QString &stub) { m_filenameStub = stub; }
    QString filenameStub() const { return m_filenameStub; }

    QString headerFilename() const { return filenameStub() + ".h"; }
    QString cppFilename() const { return filenameStub() + "_shell.cpp"; }
    QString dFilename() const { return filenameStub() + ".d"; }

private:
    virtual void writeArrayFunctions(QTextStream &s, const ComplexTypeEntry *centry);
    void writeHeaderArrayFunctions(QTextStream &s, const ComplexTypeEntry *centry);
    void writeNotice(QTextStream &s);

    void setFuncNames(const QString& cls_name);

    QString m_filenameStub;
    QSet<const TypeEntry*> containerTypes;
//    QSet< QPair<const TypeEntry*, AbstractMetaClass*> > containerTypes;
    AbstractMetaClass* m_class;

    QString all_name, ass_name, get_name;
//    QMap<QString, QMap<const TypeEntry*, AbstractMetaType*> > signalEntries;
    QMap<QString, QSet<AbstractMetaType*> > signalEntries;

    CppImplGenerator *m_cpp_impl_generator;
};

#endif // CONTAINERGENERATOR_H
