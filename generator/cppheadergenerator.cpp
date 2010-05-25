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

#include "cppheadergenerator.h"

#include <QtCore/QDir>

#include <qdebug.h>

QString CppHeaderGenerator::fileNameForClass(const AbstractMetaClass *java_class) const
{
    return QString("%1_shell.h").arg(java_class->name());
}

void CppHeaderGenerator::writeFieldAccessors(QTextStream &s, const AbstractMetaField *java_field)
{
    Q_ASSERT(java_field->isProtected());

    const AbstractMetaFunction *setter = java_field->setter();
    const AbstractMetaFunction *getter = java_field->getter();

    // qtd2
    if(notWrappedYet(getter))
        return;

    if (getter->isModifiedRemoved(TypeSystem::ShellCode))
        return;

    s << "    ";
    writeFunctionSignature(s, getter, 0, QString(), Option(ShowStatic));
    s << ";" << endl;

    // qtd2
    if(notWrappedYet(setter))
        return;

    if (!java_field->type()->isConstant()) {
        if (setter->isModifiedRemoved(TypeSystem::ShellCode))
            return;

        s << "    ";
        writeFunctionSignature(s, setter, 0, QString(), Option(ShowStatic));
        s << ";" << endl;
    }
}

void CppHeaderGenerator::writeSignalWrapper(QTextStream &s, const AbstractMetaFunction *signal)
{
    s << "    ";
    writeFunctionSignature(s, signal, 0, signalWrapperPrefix(),
                           Option(NormalizeAndFixTypeSignature | OriginalName | OriginalTypeDescription | IncludeDefaultExpression));
    s << ";" << endl;
}

void CppHeaderGenerator::writeSignalWrappers(QTextStream &s, const AbstractMetaClass *java_class)
{
    AbstractMetaFunctionList signal_funcs = signalFunctions(java_class);
    if (signal_funcs.size() > 0) {
        s << endl << "public slots:" << endl;
        foreach (const AbstractMetaFunction *signal, signal_funcs) {
            writeSignalWrapper(s, signal);
        }
    }
}

void CppHeaderGenerator::writeWrapperClass(QTextStream &s, const AbstractMetaClass *java_class)
{
    AbstractMetaFunctionList signal_functions =
        java_class->queryFunctions(AbstractMetaClass::Signals | AbstractMetaClass::Visible | AbstractMetaClass::NotRemovedFromTargetLang);
    if (signal_functions.size() == 0)
        return ;

    s << "class QtJambi_SignalWrapper_" << java_class->name() << ": public QObject" << endl
      << "{" << endl
      << "  Q_OBJECT" << endl;
    writeSignalWrappers(s, java_class);
    s << endl << "public:" << endl
      << "    QtJambiSignalInfo m_signals[" << signal_functions.size() << "];" << endl
      << "    QtJambiLink *link;" << endl
      << "};" << endl << endl;
}

void CppHeaderGenerator::write(QTextStream &s, const AbstractMetaClass *java_class)
{
    QString include_block = java_class->name().toUpper() + "_SHELL_H";

    s << "#ifndef " << include_block << endl
      << "#define " << include_block << endl << endl
//      << "#include <qtjambi_core.h>" << endl
      << "#include <QtCore/QHash>" << endl
      << "#include <qtd_core.h>" << endl;

    Include inc = java_class->typeEntry()->include();
    s << "#include ";
    if (inc.type == Include::IncludePath)
        s << "<";
    else
        s << "\"";
    s << inc.name;
    if (inc.type == Include::IncludePath)
        s << ">";
    else
        s << "\"";
    s << endl << endl;

    IncludeList list = java_class->typeEntry()->extraIncludes();
    qSort(list.begin(), list.end());
    foreach (const Include &inc, list) {
        if (inc.type == Include::TargetLangImport)
            continue;

        s << "#include ";
        if (inc.type == Include::LocalPath)
            s << "\"";
        else
            s << "<";

        s << inc.name;

        if (inc.type == Include::LocalPath)
            s << "\"";
        else
            s << ">";

        s << endl;
    }

/* qtd    writeForwardDeclareSection(s, java_class);

    writeWrapperClass(s, java_class);
*/
    s << endl;
    

    if (!java_class->generateShellClass()) {
        s << "#endif" << endl << endl;
        priGenerator->addHeader(java_class->package(), fileNameForClass(java_class));
        return ;
    }

    s << "class " << shellClassName(java_class)
      << " : public " << java_class->qualifiedCppName();
    if (java_class->isQObject()) {
        s << ", public QObjectLink";
    }
    else if (java_class->isPolymorphic())
        s << ", public QtdObjectLink";
    s << endl  << "{" << endl;

    if (java_class->isQObject()) {
      s << "public:" << endl
        << "  Q_OBJECT_CHECK" << endl
//        << "  mutable const QMetaObject *m_meta_object;" << endl;

/*      if (java_class->hasVirtualSlots()) {
          s << "  mutable QHash<int,int> m_map;" << endl;
      }
*/
//      s << "  const QMetaObject *metaObject() const;" << endl
//        << "  void *qt_metacast(const char *);" << endl
//        << "  QT_TR_FUNCTIONS" << end
      << "  virtual int qt_metacall(QMetaObject::Call, int, void **);" << endl
      << "  int __override_qt_metacall(QMetaObject::Call _c, int _id, void **_a);" << endl
      << "  virtual const QMetaObject *metaObject() const;" << endl

      << "private:" << endl;
    }


    s << "public:" << endl;
    // constructor
    foreach (const AbstractMetaFunction *function, java_class->functions()) {
        if (function->isConstructor() && !function->isPrivate())
            writeFunction(s, function);
    }

    s << "    ~" << shellClassName(java_class) << "();" << endl;
    s << endl;

    // All functions in original class that should be reimplemented in shell class
    AbstractMetaFunctionList shell_functions = java_class->functionsInShellClass();
    foreach (const AbstractMetaFunction *function, shell_functions) {
        if(notWrappedYet(function))
            continue;
        writeFunction(s, function);
    }

    // Public call throughs for protected functions
    AbstractMetaFunctionList public_overrides = java_class->publicOverrideFunctions();
    foreach (const AbstractMetaFunction *function, public_overrides) {
        if(notWrappedYet(function))
            continue;
        writePublicFunctionOverride(s, function);
    }

    // Override all virtual functions to get the decision on static/virtual call
    AbstractMetaFunctionList virtual_functions = java_class->virtualOverrideFunctions();
    foreach (const AbstractMetaFunction *function, virtual_functions) {
        if(notWrappedYet(function))
            continue;

        writeVirtualFunctionOverride(s, function);
    }

    // Field accessors
    foreach (const AbstractMetaField *field, java_class->fields()) {
        if (field->isProtected())
            writeFieldAccessors(s, field);
    }
/* qtd
    writeVariablesSection(s, java_class);
*/
    writeInjectedCode(s, java_class);

    s  << "};" << endl << endl
       << "#endif // " << include_block << endl;

    priGenerator->addHeader(java_class->package(), fileNameForClass(java_class));
    priGenerator->addClass(java_class->package(), java_class->name());
}


/*!
    Writes out declarations of virtual C++ functions so that they
    can be reimplemented from the java side.
*/
void CppHeaderGenerator::writeFunction(QTextStream &s, const AbstractMetaFunction *java_function)
{
    if (java_function->isModifiedRemoved(TypeSystem::ShellCode))
        return;

    s << "    ";
    writeFunctionSignature(s, java_function, 0, QString(), Option(OriginalName | ShowStatic));
    s << ";" << endl;
}

void CppHeaderGenerator::writePublicFunctionOverride(QTextStream &s,
                                                     const AbstractMetaFunction *java_function)
{
    s << "    ";
    writeFunctionSignature(s, java_function, 0, "__public_", Option(EnumAsInts | ShowStatic | UnderscoreSpaces));
    s << ";" << endl;
}


void CppHeaderGenerator::writeVirtualFunctionOverride(QTextStream &s,
                                                      const AbstractMetaFunction *java_function)
{
    if (java_function->isModifiedRemoved(TypeSystem::NativeCode))
        return;

    s << "    ";
    writeFunctionSignature(s, java_function, 0, "__override_", Option(EnumAsInts | ShowStatic | UnderscoreSpaces), QString(), QStringList() << "bool static_call");
    s << ";" << endl;
}


void CppHeaderGenerator::writeForwardDeclareSection(QTextStream &s, const AbstractMetaClass *)
{
    s << endl
      << "class QtJambiFunctionTable;" << endl
      << "class QtJambiLink;" << endl;
}


void CppHeaderGenerator::writeVariablesSection(QTextStream &s, const AbstractMetaClass *)
{
    s << endl
      << "    QtJambiFunctionTable *m_vtable;" << endl
      << "    QtJambiLink *m_link;" << endl;
}

void CppHeaderGenerator::writeInjectedCode(QTextStream &s, const AbstractMetaClass *java_class)
{
    CodeSnipList code_snips = java_class->typeEntry()->codeSnips();
    foreach (const CodeSnip &cs, code_snips) {
        if (cs.language == TypeSystem::ShellDeclaration) {
            s << cs.code() << endl;
        }
    }
}
