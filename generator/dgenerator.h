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

#ifndef DGENERATOR_H
#define DGENERATOR_H

#include "generator.h"
#include "metajava.h"
#include "cppimplgenerator.h"

#include <QTextStream>
#include <QStack>

class DocParser;

class DGenerator : public Generator
{
    Q_OBJECT

public:
    DGenerator();

    static QString translateType(const AbstractMetaType *d_type, const AbstractMetaClass *context, Option option = NoOption);

    void writeInjectedCode(QTextStream &s,
                           const AbstractMetaFunction *d_function,
                           CodeSnip::Position position);
    static void writeArgument(QTextStream &s,
                       const AbstractMetaFunction *d_function,
                       const AbstractMetaArgument *d_argument,
                       uint options = 0);
    static QString argumentString(const AbstractMetaFunction *d_function,
                                  const AbstractMetaArgument *d_argument,
                                  uint options = 0);
    void writeEnum(QTextStream &s, const AbstractMetaEnum *d_enum, bool withAliases = false);
    void writeIntegerEnum(QTextStream &s, const AbstractMetaEnum *d_enum);
    void writeSignal(QTextStream &s, const AbstractMetaFunction *d_function);
    void writeFunction(QTextStream &s, const AbstractMetaFunction *d_function,
                       uint included_attributes = 0, uint excluded_attributes = 0);
    void writeFieldAccessors(QTextStream &s, const AbstractMetaField *field);
    void writeNativeField(QTextStream &s, const AbstractMetaField *field);

    void write(QTextStream &s, const AbstractMetaClass *d_class);

    void writeFunctionOverloads(QTextStream &s, const AbstractMetaFunction *d_function,
                                uint included_attributes, uint excluded_attributes);
    void writeEnumOverload(QTextStream &s, const AbstractMetaFunction *d_function,
                           uint include_attributes, uint exclude_attributes);
    void writeExtraFunctions(QTextStream &s, const AbstractMetaClass *d_class);
    void writeToStringFunction(QTextStream &s, const AbstractMetaClass *d_class);
    void writeCloneFunction(QTextStream &s, const AbstractMetaClass *d_class);
    void writeFunctionAttributes(QTextStream &s, const AbstractMetaFunction *d_function,
                                 uint included_attributes = 0, uint excluded_attributes = 0,
                                 uint options = 0);
    void writeConstructorContents(QTextStream &s, const AbstractMetaFunction *d_function);
    void writeFunctionArguments(QTextStream &s, const AbstractMetaFunction *d_function,
        int count = -1, uint options = 0);
    void writeJavaCallThroughContents(QTextStream &s, const AbstractMetaFunction *d_function, uint attributes = 0);
    void writeOwnershipForContainer(QTextStream &s, TypeSystem::Ownership ownership, AbstractMetaArgument *arg);
    void writeOwnershipForContainer(QTextStream &s, TypeSystem::Ownership ownership, AbstractMetaType *type,
                                    const QString &arg_name);
    void writePrivateNativeFunction(QTextStream &s, const AbstractMetaFunction *d_function);
    void writeJavaLangObjectOverrideFunctions(QTextStream &s, const AbstractMetaClass *cls);
    void writeReferenceCount(QTextStream &s, const ReferenceCount &refCount, const QString &argumentName, AbstractMetaType *argumentType = 0);
    void retrieveModifications(const AbstractMetaFunction *f, const AbstractMetaClass *d_class,
         uint *exclude_attributes, uint *include_attributes) const;
    QString functionSignature(const AbstractMetaFunction *d_function,
                              uint included_attributes,
                              uint excluded_attributes,
                              Option option = NoOption,
                              int arg_count = -1);
    void setupForFunction(const AbstractMetaFunction *d_function,
       uint *included_attributes, uint *excluded_attributes) const;

    virtual QString subDirectoryForClass(const AbstractMetaClass *d_class) const
    { return subDirectoryForPackage(d_class->package()); }

    virtual QString fileNameForClass(const AbstractMetaClass *d_class) const;

    bool isComparable(const AbstractMetaClass *cls) const;

#if 0
    void write1_dot_5_enum(QTextStream &s, const AbstractMetaEnum *d_enum);
#endif

    bool shouldGenerate(const AbstractMetaClass *d_class) const {
        return !d_class->typeEntry()->isContainer() && !d_class->typeEntry()->isVariant()
               && (d_class->typeEntry()->codeGeneration() & TypeEntry::GenerateTargetLang);
    }

    QString documentationDirectory() const { return m_doc_directory; }
    void setDocumentationDirectory(const QString &docDir) { m_doc_directory = docDir; }

    bool documentationEnabled() const { return m_docs_enabled; }
    void setDocumentationEnabled(bool e) { m_docs_enabled = e; }
    void generate();

    inline bool nativeJumpTable() const { return m_native_jump_table; }
    inline void setNativeJumpTable(bool n) { m_native_jump_table = n; }

    void writeShellVirtualFunction(QTextStream &s, const AbstractMetaFunction *function,
                                          const AbstractMetaClass *implementor, int id);
    void marshalFromCppToD(QTextStream &s, const ComplexTypeEntry* ctype);

    // generates output analogous to that of qtd.Core.qtdExport
    static void writeDExport(QTextStream &s, QString retType, QString name, QString args, QString body);

private:
    QString subDirectoryForPackage(const QString &package) const { return QString(package).replace(".", "/"); }
    void writeInstantiatedType(QTextStream &s, const AbstractMetaType *abstractMetaType) const;

    // qtd
    void addTypeEntry(const AbstractMetaClass *d_class, const AbstractMetaFunction *function, QSet<const TypeEntry*> &typeEntries);
    void fillRequiredImports(const AbstractMetaClass *d_class);
    void addInstantiations(const AbstractMetaType* d_type);
    void writeRequiredImports(QTextStream &s, const AbstractMetaClass *d_class);
    const TypeEntry* fixedTypeEntry(const TypeEntry *type);
    AbstractMetaFunctionList generatedClassFunctions(const AbstractMetaClass *d_class);

    void writeDestructor(QTextStream &s, const AbstractMetaClass *d_class);
    void writeOwnershipSetter(QTextStream &s, const AbstractMetaClass *d_class);
    void writeSignalHandlers(QTextStream &s, const AbstractMetaClass *d_class);
    void writeEnumAliases(QTextStream &s, const AbstractMetaEnum *d_enum);
    void writeSignalSignatures(QTextStream &s, const AbstractMetaClass *d_class, AbstractMetaFunctionList signal_funcs);
    void writeMetaMethodArguments(QTextStream &s, const AbstractMetaFunction *d_function, int reduce = -1);
    void writeQObjectFunctions(QTextStream &s, const AbstractMetaClass *d_class);
    void writeQObjectFreeFunctions(QTextStream &s, const AbstractMetaClass *d_class);
    void writeConversionFunction(QTextStream &s, const AbstractMetaClass *d_class);
    void writeValueFreeFunctions(QTextStream &s, const AbstractMetaClass *d_class);
    void writeValueFunctions(QTextStream &s, const AbstractMetaClass *d_class);

//    void writeMarshallFunction(QTextStream &s, const AbstractMetaClass *d_class);

    int m_recursive;
    bool m_isRecursive;
    QStack<const AbstractMetaClass*> m_recursionStack;
    QSet<const TypeEntry*> typeEntries; // imports
    QSet<const TypeEntry*> typeEntriesEnums; // imports for enums
    QSet<QString> excludedTypes2;

protected:
    void writeImportString(QTextStream &s, const TypeEntry* typeEntry);

    QSet<QString> excludedTypes;
    QString m_package_name;
    QString m_doc_directory;
    DocParser *m_doc_parser;
    bool m_docs_enabled;
    bool m_native_jump_table;
    QList<const AbstractMetaFunction *> m_nativepointer_functions;
    QList<const AbstractMetaFunction *> m_resettable_object_functions;
    QList<const AbstractMetaFunction *> m_reference_count_candidate_functions;
};

class ClassFromEntry : Generator
{
    Q_OBJECT

private:
    ClassFromEntry();
    void buildHash();
    QHash<const TypeEntry *, AbstractMetaClass *> classFromEntry;
    static ClassFromEntry* m_instance;

public:
    static AbstractMetaClass* get(const TypeEntry *te);
    static void print(QTextStream &s);
    static void construct(const AbstractMetaClassList &classes);

};
#endif // DGENERATOR_H
