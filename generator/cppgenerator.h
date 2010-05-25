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

#ifndef CPPGENERATOR_H
#define CPPGENERATOR_H

#include "generator.h"
#include "metajava.h"
#include "prigenerator.h"

class CppGenerator : public Generator
{
    Q_OBJECT

public:
    static inline QString subDirectoryForPackage(const QString &package) {
        return QLatin1String("cpp/") + QString(package).replace(".", "_");
    }

    virtual QString subDirectoryForClass(const AbstractMetaClass *cls) const
    {
        return subDirectoryForPackage(cls->package()) + "/";
    }

    static QString fixNormalizedSignatureForQt(const QString &signature);
    static void writeTypeInfo(QTextStream &s, const AbstractMetaType *type, Option option = NoOption);
    static void writeFunctionSignature(QTextStream &s, const AbstractMetaFunction *java_function,
                                const AbstractMetaClass *implementor = 0,
                                const QString &name_prefix = QString(),
                                Option option = NoOption,
                                const QString &classname_prefix = QString(),
                                const QStringList &extra_arguments = QStringList(),
                                int numArguments = -1);
    static void writeFunctionArguments(QTextStream &s, const AbstractMetaArgumentList &arguments,
                                Option option = NoOption,
                                int numArguments = -1);
    static void writeInclude(QTextStream &s, Include inc);

    QString signalWrapperPrefix() const { return "__qt_signalwrapper_"; }

    bool shouldGenerate(const AbstractMetaClass *java_class) const {
        return (!java_class->isNamespace() || java_class->functionsInTargetLang().size() > 0) && !java_class->isInterface()
            && !java_class->typeEntry()->isVariant()
            && (java_class->typeEntry()->codeGeneration() & TypeEntry::GenerateCpp)
            && !(java_class->attributes() & AbstractMetaAttributes::Fake);
    }

    static QString shellClassName(const AbstractMetaClass *java_class) {
        return java_class->generateShellClass()
               ? java_class->name() + "_QtDShell"
               : java_class->qualifiedCppName();
    }

 protected:
    PriGenerator *priGenerator;

};

#endif // CPPGENERATOR_H
