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

#ifndef METAINFOGENERATOR_H
#define METAINFOGENERATOR_H

#include "generator.h"
#include "dgenerator.h"
#include "cppgenerator.h"

class MetaInfoGenerator : public DGenerator
{
public:
    MetaInfoGenerator(PriGenerator *pri);

    enum GenerationFlags {
        GeneratedJavaClasses = 0x1,
        GeneratedMetaInfo = 0x2
    };

    enum OutputDirectoryType {
        CppDirectory,
        JavaDirectory
    };

    MetaInfoGenerator();

    virtual void generate();
    virtual QString fileNameForClass(const AbstractMetaClass *java_class) const;
    virtual void write(QTextStream &s, const AbstractMetaClass *java_class);

    void setFilenameStub(const QString &stub) { m_filenameStub = stub; }
    QString filenameStub() const { return m_filenameStub; }

    QString headerFilename() const { return filenameStub() + ".h"; }
    QString cppFilename() const { return filenameStub() + ".cpp"; }

    virtual QString subDirectoryForClass(const AbstractMetaClass *, OutputDirectoryType type) const;
    virtual QString subDirectoryForPackage(const QString &package, OutputDirectoryType type) const;
    virtual bool shouldGenerate(const AbstractMetaClass *) const;

    bool generated(const AbstractMetaClass *cls) const;
    bool generatedJavaClasses(const QString &package) const;
    bool generatedMetaInfo(const QString &package) const;

private:
    void writeCppFile();
    void writeHeaderFile();
    void writeLibraryInitializers();
    void writeInclude(QTextStream &s, const Include &inc);
    void writeIncludeStatements(QTextStream &s, const AbstractMetaClassList &classList, const QString &package);
    void writeInitializationFunctionName(QTextStream &s, const QString &package, bool fullSignature);
    void writeInitialization(QTextStream &s, const TypeEntry *entry, const AbstractMetaClass *cls, bool registerMetaType = true);
    void writeCustomStructors(QTextStream &s, const TypeEntry *entry);
    void writeDestructors(QTextStream &s, const AbstractMetaClass *cls);
    void writeCodeBlock(QTextStream &s, const QString &code);
    void writeSignalsAndSlots(QTextStream &s, const QString &package);
    void writeEnums(QTextStream &s, const QString &package);
    void writeRegisterSignalsAndSlots(QTextStream &s);
    void writeRegisterEnums(QTextStream &s);
    QStringList writePolymorphicHandler(QTextStream &s, const QString &package, const AbstractMetaClassList &clss);
    bool shouldGenerate(const TypeEntry *entry) const;
    void buildSkipList();

#if defined(QTJAMBI_DEBUG_TOOLS)
    void writeNameLiteral(QTextStream &, const TypeEntry *, const QString &fileName);
#endif

    QHash<QString, int> m_skip_list;
    QString m_filenameStub;

    QHash<OutputDirectoryType, QString> m_out_dir;

    const AbstractMetaClass* lookupClassWithPublicDestructor(const AbstractMetaClass *cls);

    PriGenerator *priGenerator;
};

#endif // METAINFOGENERATOR_H
