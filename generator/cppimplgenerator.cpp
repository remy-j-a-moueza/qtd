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

#include "global.h"
#include "cppimplgenerator.h"
#include "dgenerator.h"
#include "reporthandler.h"

#include <QDir>
#include <QtDebug>
#include <QVariant>
#include <iostream>
#define VOID_POINTER_ORDINAL 8

static Indentor INDENT;

QString jni_signature(const AbstractMetaFunction *function, JNISignatureFormat format)
{
    QString returned = "(";
    AbstractMetaArgumentList arguments = function->arguments();
    foreach (const AbstractMetaArgument *argument, arguments) {
        if (!function->argumentRemoved(argument->argumentIndex() + 1)) {
            QString modified_type = function->typeReplaced(argument->argumentIndex()+1);

            if (modified_type.isEmpty())
                returned += jni_signature(argument->type(), format);
            else
                returned += jni_signature(modified_type, format);
        }
    }

    returned += ")";

    QString modified_type = function->typeReplaced(0);
    if (modified_type.isEmpty())
        returned += jni_signature(function->type(), format);
    else
        returned += jni_signature(modified_type, format);

    return returned;
}

QString jni_signature(const QString &_full_name, JNISignatureFormat format)
{
    QString signature;
    QString full_name = _full_name;

    if (full_name.endsWith("[]")) {
        full_name.chop(2);
        signature = "[";
    }

    int start = 0, end = -1;
    while ( (start = full_name.indexOf("<")) >= 0 && (end = full_name.indexOf(">")) >= 0 ) {
        full_name.remove(start, end - start + 1);
    }

    static QHash<QString, QString> table;
    if (table.isEmpty()) {
        table["boolean"] = "Z";
        table["byte"] = "B";
        table["char"] = "C";
        table["short"] = "S";
        table["int"] = "I";
        table["long"] = "J";
        table["float"] = "F";
        table["double"] = "D";
    }

    if (format == Underscores)
        signature.replace("[", "_3");

    if (table.contains(full_name)) {
        signature += table[full_name];
    } else if (format == Underscores) {
        signature.replace("[", "_3");
        signature += "L";
        signature += QString(full_name).replace("_", "_1").replace('.', '_').replace("$", "_00024");
        signature += "_2";
    } else {
        signature += "L";
        signature += QString(full_name).replace('.', '/');
        signature += ";";
    }

    return signature;
}

QString jni_signature(const AbstractMetaType *java_type, JNISignatureFormat format)
{
    if (!java_type)
        return "V";

    if (java_type->isArray()) {
        return "_3" + jni_signature(java_type->arrayElementType(), format);
    } else if (java_type->isNativePointer()) {
        if (format == Underscores)
            return "Lcom_trolltech_qt_QNativePointer_2";
        else
            return "Lcom/trolltech/qt/QNativePointer;";
    } else if (java_type->isIntegerEnum() || java_type->isIntegerFlags()
               || (format == Underscores && (java_type->isEnum() || java_type->isFlags()))) {
        return "I";
    } else if (java_type->isThread()) {
        if (format == Underscores)
            return "Ljava_lang_Thread_2";
        else
            return "Ljava/lang/Thread;";
    }



    QString name = java_type->name();
    if (java_type->isObject()) {
        if (const InterfaceTypeEntry *ie
            = static_cast<const ObjectTypeEntry *>(java_type->typeEntry())->designatedInterface())
            name = ie->targetLangName();
    } else if (java_type->isTargetLangEnum()) {
        const EnumTypeEntry *et = static_cast<const EnumTypeEntry *>(java_type->typeEntry());
        name = et->javaQualifier() + "$" + et->targetLangName();

    } else if (java_type->isTargetLangFlags()) {
        const FlagsTypeEntry *ft = static_cast<const FlagsTypeEntry *>(java_type->typeEntry());
        name = ft->originator()->javaQualifier() + "$" + ft->targetLangName();
    }

    return jni_signature( (java_type->package().isEmpty() ? QString() : java_type->package() + ".") + name, format);
}

static QHash<QString, QString> table;
QString default_return_statement_qt(const AbstractMetaType *java_type, Generator::Option options = Generator::NoOption)
{
    QString returnStr = ((options & Generator::NoReturnStatement) == 0 ? "return" : "");
    if (!java_type)
        return returnStr;

    if (table.isEmpty()) {
        table["bool"] = "false";
        table["byte"] = "0";
        table["char"] = "0";
        table["short"] = "0";
        table["int"] = "0";
        table["long"] = "0";
        table["float"] = "0f";
        table["double"] = "0.0";
        table["size_t"] = "0";
        table["java.lang.Object"] = "0";
    }

    QString signature = table.value(java_type->typeEntry()->targetLangName());

    if (!signature.isEmpty())
        return returnStr + " " + signature;

    Q_ASSERT(!java_type->isPrimitive());

    if (java_type->isJObjectWrapper())
        return returnStr + " JObjectWrapper()";
    if (java_type->isVariant())
        return returnStr + " QVariant()";
    if (java_type->isTargetLangString())
        return returnStr + " QString()";
    if (java_type->isTargetLangChar())
        return returnStr + " QChar()";
    else if (java_type->isEnum())
        return returnStr + " " + java_type->typeEntry()->name() + "(0)";
    else if (java_type->isContainer() && ((ContainerTypeEntry *)java_type->typeEntry())->type() == ContainerTypeEntry::StringListContainer)
        return returnStr + " " + java_type->typeEntry()->name() + "()";
    else if (java_type->isValue() || java_type->isContainer())
        return returnStr + " " + java_type->cppSignature() + "()";
    else
        return returnStr + " 0";
}

QString default_return_statement_java(const AbstractMetaType *java_type)
{
    if (!java_type)
        return "return";
    if (java_type->isArray())
        return "return null";

    if (table.isEmpty()) {
        table["boolean"] = "false";
        table["byte"] = "0";
        table["char"] = "0";
        table["short"] = "0";
        table["int"] = "0";
        table["long"] = "0";
        table["float"] = "0f";
        table["double"] = "0.0";
        table["java.lang.Object"] = "0";
    }

    QString signature = table.value(java_type->typeEntry()->targetLangName());
    if (!signature.isEmpty())
        return "return " + signature;

    Q_ASSERT(!java_type->isPrimitive());
    return "return 0";
}

/* Used to decide how which of the Call[Xxx]Method functions to call
 */
QByteArray jniTypeName(const QString &name) {
    static QHash<QString, const char *> table;
    if (table.isEmpty()) {
        table["jboolean"] = "Boolean";
        table["jbyte"] = "Byte";
        table["jchar"] = "Char";
        table["jshort"] = "Short";
        table["jint"] = "Int";
        table["jlong"] = "Long";
        table["jfloat"] = "Float";
        table["jdouble"] = "Double";
        table["jobject"] = "Object";
    }

    return table[name];
}

QByteArray jniName(const QString &name) {
    TypeEntry *entry = TypeDatabase::instance()->findType(name);
    if (entry)
        return entry->name().toLatin1();
    else
        return "void *";
}

QString CppImplGenerator::jniReturnName(const AbstractMetaFunction *java_function, uint options, bool d_export)
{
    AbstractMetaType *f_type = java_function->type();

    QString return_type = translateType(f_type, EnumAsInts, d_export);
    QString new_return_type = java_function->typeReplaced(0);
    if (!new_return_type.isEmpty()) {
        if(f_type && f_type->isPrimitive()) {
            if (d_export)
                return_type = new_return_type;
        } else
            return_type = jniName(new_return_type);
    }

    // qtd
    if (f_type) {
        if (f_type->name() == "QModelIndex" || f_type->typeEntry()->isStructInD())
            return_type = "void";
        else if (f_type->isObject() || f_type->isReference() || f_type->isValue() || f_type->isQObject())
            return_type = "void*";
        if (f_type->isVariant())
            return_type = "void*";
    }

    if (options & CppImplGenerator::ExternC && java_function->isConstructor())
        return_type = "void*";
    if (options & CppImplGenerator::ExternC && f_type)
        if (f_type->isTargetLangString() || f_type->typeEntry()->isContainer())
            return_type = "void";
    // qtd end

    return return_type;
}

QString CppImplGenerator::jniReturnType(const AbstractMetaType *f_type, uint options)
{
    QString return_type = translateType(f_type, EnumAsInts);

    // qtd
    if (f_type) {
        if (f_type->typeEntry()->isStructInD())
            return_type = f_type->typeEntry()->qualifiedCppName();
        else if (f_type->isObject() || f_type->isReference() || f_type->isValue() || f_type->isQObject())
            return_type = "void*";
        if (f_type->isVariant())
            return_type = "void*";
    }

    if (options & CppImplGenerator::ExternC && f_type)
        if (f_type->isTargetLangString())
            return_type = "void";
    // qtd end
    return return_type;
}

QByteArray jniTypeName(const AbstractMetaType *java_type)
{
    if (!java_type) {
        return "Void";
    } else if (java_type->isTargetLangChar()) {
        return "Char";
    } else if (java_type->isPrimitive()) {
        return jniTypeName(java_type->typeEntry()->jniName());
    } else if (java_type->isIntegerEnum() || java_type->isIntegerFlags()) {
        return "Int";
    } else {
        return "Object";
    }
}

QByteArray newXxxArray(const AbstractMetaType *java_type)
{
    return "New" + jniTypeName(java_type) + "Array";
}

QByteArray setXxxArrayElement(const AbstractMetaType *java_type)
{
    Q_ASSERT(java_type);
    return "Set" + jniTypeName(java_type) + "ArrayElement";
}

QByteArray getXxxArrayElement(const AbstractMetaType *java_type)
{
    Q_ASSERT(java_type);
    return "Get" + jniTypeName(java_type) + "ArrayElement";
}

QByteArray getXxxArrayRegion(const AbstractMetaType *java_type)
{
    Q_ASSERT(java_type);
    return "Get" + jniTypeName(java_type) + "ArrayRegion";
}

QByteArray setXxxArrayRegion(const AbstractMetaType *java_type)
{
    Q_ASSERT(java_type);
    return "Set" + jniTypeName(java_type) + "ArrayRegion";
}

QByteArray callXxxMethod(const AbstractMetaType *java_type)
{
    return "Call" + jniTypeName(java_type) + "Method";
}

QByteArray callXxxMethod(const QString &name) {
    TypeEntry *entry = TypeDatabase::instance()->findType(name);
    if (entry && entry->isPrimitive())
        return "Call" + jniTypeName(entry->jniName()) + "Method";
    else
        return "CallObjectMethod";
}

QString jni_function_signature(QString package, QString class_name,
                               const QString &function_name,
                               const QString &return_type,
                               const QString &mangled_arguments = QString(),
                               uint options = CppImplGenerator::StandardJNISignature)
{
    QString s;

    if (options & CppImplGenerator::ExternC)
        s += "QTD_EXTERN QTD_EXPORT ";
/* qtd
    if (options & CppImplGenerator::JNIExport)
        s += "Q_DECL_EXPORT ";
*/
    if (options & CppImplGenerator::ReturnType)
        s += return_type + " ";
    else
        s += "void ";
/* qtd
    if (options & CppImplGenerator::JNIExport)
        s += "JNICALL QTJAMBI_FUNCTION_PREFIX(";

    s += "Java_";

    s += package.replace(".", "_"); // qtd .replace("_", "_1")
    s += '_';
    s += class_name; // qtd .replace("_", "_1");
    s += '_';
*/
    s += QString(function_name); //.replace("_", "_1");
//    s += mangled_arguments;

/* qtd
    if (options & CppImplGenerator::JNIExport)
        s += ")";
*/
    return s;
}

QString CppImplGenerator::fileNameForClass(const AbstractMetaClass *java_class) const
{
    return QString("%1_shell.cpp").arg(java_class->name());
}

void CppImplGenerator::writeSignalFunction(QTextStream &s, const AbstractMetaFunction *signal, const AbstractMetaClass *cls,
                                           int pos)
{
    writeFunctionSignature(s, signal, cls, signalWrapperPrefix(),
                           Option(OriginalName | OriginalTypeDescription),
                           "QtJambi_SignalWrapper_");
    s << endl << "{" << endl;
    {
        AbstractMetaArgumentList arguments = signal->arguments();
        Indentation indent(INDENT);

        if (arguments.size() > 0)
            s << INDENT << "jvalue arguments[" << arguments.size() << "];" << endl;
        else
            s << INDENT << "jvalue *arguments = 0;" << endl;
        s << INDENT << "JNIEnv *__jni_env = qtjambi_current_environment();" << endl
          << INDENT << "__jni_env->PushLocalFrame(100);" << endl;

        for (int i=0; i<arguments.size(); ++i) {
            const AbstractMetaArgument *argument = arguments.at(i);
            writeQtToJava(s,
                          argument->type(),
                          argument->indexedName(),
                          "__java_" + argument->indexedName(),
                          signal,
                          argument->argumentIndex() + 1,
                          BoxedPrimitive);
            s << INDENT << "arguments[" << i << "].l = __java_" << argument->indexedName() << ";" << endl;
        }
        s << INDENT << "qtjambi_call_java_signal(__jni_env, m_signals[" << pos << "], arguments);"
                    << endl;

        s << INDENT << "__jni_env->PopLocalFrame(0);" << endl;

        if (signal->type() != 0)
            s << INDENT << default_return_statement_qt(signal->type()) << ";" << endl;
    }
    s << "}" << endl << endl;

    if (signal->implementingClass() == signal->ownerClass())
        writeFinalFunction(s, signal, cls);
}

bool CppImplGenerator::hasCustomDestructor(const AbstractMetaClass *java_class) const
{
    return !java_class->isQObject() && !java_class->typeEntry()->isValue();
}

void CppImplGenerator::writeInterfaceCasts(QTextStream &s, const AbstractMetaClass *java_class)
{
        // pointers to native interface objects for classes that implement interfaces
        // initializing
        AbstractMetaClassList interfaces = java_class->interfaces();
        if (!interfaces.isEmpty()) {
            for (int i=0; i<interfaces.size(); ++i) {
                AbstractMetaClass *iface = interfaces.at(i);

                // in case of renamed class
                InterfaceTypeEntry *ite = static_cast<InterfaceTypeEntry*>(iface->typeEntry());
                QString real_name = ite->origin()->qualifiedCppName();

                s << "QTD_EXTERN QTD_EXPORT " << real_name << "* qtd_" << java_class->name() << "_cast_to_" << iface->qualifiedCppName()
                  << "(" << java_class->qualifiedCppName() << " *ptr)" << endl << "{" << endl;
                Indentation indent(INDENT);
                s << INDENT << "return dynamic_cast<" << real_name << "*>(ptr);" << endl;
                s << "}" << endl << endl;
            }
        }
}

void CppImplGenerator::write(QTextStream &s, const AbstractMetaClass *java_class)
{

    bool shellClass = java_class->generateShellClass();

    // Includes
    writeExtraIncludes(s, java_class);
    bool shellInclude = (java_class->generateShellClass()
        || java_class->queryFunctions(AbstractMetaClass::Signals | AbstractMetaClass::Visible | AbstractMetaClass::NotRemovedFromShell).size() > 0);

    // need to include QPainter for all widgets...
    {
        const AbstractMetaClass *qwidget = java_class;
        while (qwidget && qwidget->name() != "QWidget") {
            qwidget = qwidget->baseClass();
        }
        if (qwidget)
            s << "#include <QPainter>" << endl << endl;
    }
/*
#if defined(QTJAMBI_DEBUG_TOOLS)
    s << "#include <qtjambidebugtools_p.h>" << endl << endl;
#endif
*/
    if (shellInclude)
        s << "#include \"" << java_class->name() << "_shell" << ".h\"" << endl;
/* qtd
    if (java_class->isQObject())
        s << "#include <qtdynamicmetaobject.h>" << endl;
*/

    s << "#include <iostream>" << endl;

    writeInclude(s, java_class->typeEntry()->include());

    s << endl; // qtd
    s << "#include \"qtd_core.h\"" << endl
      << "#include \"ArrayOpsPrimitive.h\"" << endl
      << "#include \"ArrayOps_qt_core.h\"" << endl;

    // qtd2 hack!!
    if (java_class->package() == "qt.svg")
        s << "#include \"ArrayOps_qt_gui.h\"" << endl;

    QString pkg_name = QString(java_class->package()).replace(".", "_");
    s << QString("#include \"ArrayOps_%1.h\"").arg(pkg_name) << endl;

    s << endl;

    writeInterfaceCasts(s, java_class);

    /* qtd2
    writeShellSignatures(s, java_class);

    writeDefaultConstructedValues(s, java_class);

    if (hasCustomDestructor(java_class)) */

    writeFinalDestructor(s, java_class);

    if (java_class->isQObject()) {
        writeQObjectEntity(s, java_class);        
    }
    if (shellClass) {
        foreach (AbstractMetaFunction *function, java_class->functions()) {
            if (function->isConstructor() && !function->isPrivate())
                writeShellConstructor(s, function);
        }

        writeShellDestructor(s, java_class);

        if (!java_class->isQObject() && java_class->hasVirtualFunctions())
            writeQtdEntityFunction(s, java_class);

        if (java_class->isQObject())
            writeQObjectFunctions(s, java_class);

        // Virtual overrides
        s << "// Virtual overrides" << endl;
        AbstractMetaFunctionList virtualFunctions = java_class->virtualFunctions();
        for (int pos = 0; pos<virtualFunctions.size(); ++pos) {
            const AbstractMetaFunction *function = virtualFunctions.at(pos);
            // qtd            writeShellFunction(s, function, java_class, pos);
            writeShellVirtualFunction(s, function, java_class, pos);
        }

        if (global.cppShared)
            writeInitCallbacks(s, java_class);

        // Functions in shell class
        s << "// Functions in shell class" << endl;
        AbstractMetaFunctionList shellFunctions = java_class->nonVirtualShellFunctions();
        for (int i=0; i<shellFunctions.size(); ++i) {
            const AbstractMetaFunction *function = shellFunctions.at(i);
            writeShellFunction(s, function, java_class, -1);
        }

        // Write public overrides for functions that are protected in the base class
        // so they can be accessed from the native callback
        s << "// public overrides for functions that are protected in the base class" << endl;
        AbstractMetaFunctionList public_override_functions = java_class->publicOverrideFunctions();
        foreach (AbstractMetaFunction *function, public_override_functions) {
            if(notWrappedYet(function))
                continue;
            writePublicFunctionOverride(s, function, java_class);
        }

        // Write virtual function overries used to decide on static/virtual calls
        s << "// Write virtual function overries used to decide on static/virtual calls" << endl;
        AbstractMetaFunctionList virtual_functions = java_class->virtualOverrideFunctions();
        foreach (const AbstractMetaFunction *function, virtual_functions) {
            if(notWrappedYet(function))
                continue;
            writeVirtualFunctionOverride(s, function, java_class);
        }
    }

    writeExtraFunctions(s, java_class);
/* qtd2
    writeToStringFunction(s, java_class);

    if (java_class->hasCloneOperator()) {
        writeCloneFunction(s, java_class);
    }
*/
    // Signals emitters
    AbstractMetaFunctionList signal_functions = signalFunctions(java_class, false);
    for (int i=0; i<signal_functions.size(); ++i)
    {
        const AbstractMetaFunction *function = signal_functions.at(i);
        if(!function->isPrivate())
            writeFinalFunction(s, signal_functions.at(i), java_class);
    }
    s << "// ---externC---" << endl;

    // Native callbacks (all java functions require native callbacks)
    AbstractMetaFunctionList class_funcs = java_class->functionsInTargetLang();
    foreach (AbstractMetaFunction *function, class_funcs) {
        if (!function->isEmptyFunction())
            writeFinalFunction(s, function, java_class);
    }
    s << "// ---externC---end" << endl;


    class_funcs = java_class->queryFunctions(AbstractMetaClass::NormalFunctions | AbstractMetaClass::AbstractFunctions | AbstractMetaClass::NotRemovedFromTargetLang);
    foreach (AbstractMetaFunction *function, class_funcs) {
        if (function->implementingClass() != java_class) {
            writeFinalFunction(s, function, java_class);
        }
    }

    // Field accessors
    s << "// Field accessors" << endl;
    foreach (AbstractMetaField *field, java_class->fields()) {
        if (field->wasPublic() || (field->wasProtected() && !java_class->isFinal()))
            writeFieldAccessors(s, field);
    }
/*
    s << "// writeFromNativeFunction" << endl;
    writeFromNativeFunction(s, java_class);

    if (java_class->isQObject())
        writeOriginalMetaObjectFunction(s, java_class);

    if (java_class->typeEntry()->isValue())
        writeFromArrayFunction(s, java_class);

    // generate the __qt_cast_to_Xxx functions
    if (!java_class->isNamespace() && !java_class->isInterface()) {
        AbstractMetaClassList interfaces = java_class->interfaces();
        foreach (AbstractMetaClass *iface, interfaces)
            writeInterfaceCastFunction(s, java_class, iface);
    }

    writeSignalInitialization(s, java_class);
*/
// qtd    writeJavaLangObjectOverrideFunctions(s, java_class);

    if (java_class->typeEntry()->isValue())
        writeValueFunctions(s, java_class);

    if (java_class->isQObject())
    {
        s << endl << endl
          << "QTD_EXTERN QTD_EXPORT void* qtd_" << java_class->name() << "_staticMetaObject() {" << endl
          << "    return (void*)&" << java_class->name() << "::staticMetaObject;" << endl
          << "}" << endl;
    }

    if (java_class->typeEntry()->isValue())
    {
        if (!java_class->typeEntry()->hasPrivateCopyConstructor())  // can do a copy if we have a public ctor or don't have any
        {
            QString argName = "orig";
            s << endl << endl
              << "QTD_EXTERN QTD_EXPORT void qtd_" << java_class->name() << "_placed_copy(void* "
              << argName << ", void* place) {" << endl
              << QString("    const %1&  __qt_%2 = (const %1& ) *(%1 *)%2;").arg(shellClassName(java_class)).arg(argName) << endl
              << QString("    %1 *result = new (place) %1 (__qt_%2);").arg(java_class->qualifiedCppName()).arg(argName) << endl;
//            writeFinalConstructor(s, ctor, "result", "original", "(place)");
            s << "}";

            s << endl << endl
              << "QTD_EXTERN QTD_EXPORT void* qtd_" << java_class->name() << "_native_copy(void* " << argName << ") {" << endl
              << QString("    const %1&  __qt_%2 = (const %1& ) *(%1 *)%2;").arg(shellClassName(java_class)).arg(argName) << endl
              << QString("    %1 *result = new %1 (__qt_%2);").arg(java_class->qualifiedCppName()).arg(argName) << endl
              << "    return result;" << endl;
            s << "}";
        }
    }
    
    s << endl << endl;

    priGenerator->addSource(java_class->package(), fileNameForClass(java_class));
}

void CppImplGenerator::writeValueFunctions(QTextStream &s, const AbstractMetaClass *java_class)
{
    s << QString("QTD_EXTERN QTD_EXPORT bool qtd_%1_QTypeInfo_isComplex() { return (bool) QTypeInfo<%2>::isComplex; }\n").arg(java_class->name()).arg(java_class->qualifiedCppName());
    s << QString("QTD_EXTERN QTD_EXPORT bool qtd_%1_QTypeInfo_isStatic() { return (bool) QTypeInfo<%2>::isStatic; }\n").arg(java_class->name()).arg(java_class->qualifiedCppName());
    s << QString("QTD_EXTERN QTD_EXPORT bool qtd_%1_QTypeInfo_isLarge() { return (bool) QTypeInfo<%2>::isLarge; }\n").arg(java_class->name()).arg(java_class->qualifiedCppName());
    s << QString("QTD_EXTERN QTD_EXPORT bool qtd_%1_QTypeInfo_isPointer() { return (bool) QTypeInfo<%2>::isPointer; }\n").arg(java_class->name()).arg(java_class->qualifiedCppName());
    s << QString("QTD_EXTERN QTD_EXPORT bool qtd_%1_QTypeInfo_isDummy() { return (bool) QTypeInfo<%2>::isDummy; }\n").arg(java_class->name()).arg(java_class->qualifiedCppName());
}

void CppImplGenerator::writeVirtualDispatchFunction(QTextStream &s, const AbstractMetaFunction *function, const AbstractMetaClass *java_class, bool d_export)
{
    uint options2 = ReturnType | ExternC;
    QString return_type = jniReturnName(function, options2);

    AbstractMetaFunction::Options opts(AbstractMetaFunction::NoExternNamespace | AbstractMetaFunction::DeclaringClass);
    QString f_name = function->marshalledName(opts) + "_dispatch";

    if (d_export) {
        QString qtdExtern = "extern(C)";
        QString qtdExport;
        if (global.targetPlatform == Global::Win32Target)
            qtdExport = "export ";


        if (global.cppShared) {

            s << qtdExtern << "{ extern " << qtdExport << return_type << " function";
            writeVirtualDispatchArguments(s, function, d_export);
            s << " qtd_" << f_name << "; }" << endl;

            s << qtdExtern << " " << return_type << " qtd_export_" << f_name;
            writeVirtualDispatchArguments(s, function, d_export);

        } else {
            s << qtdExtern << " " << return_type << " qtd_" << f_name;
            writeVirtualDispatchArguments(s, function, d_export);
        }
    } else {
        QString module = packageToQtModule(java_class->package());
        s << "QTD_FUNC_DECL(" << module << ", " << return_type << ", " << f_name << ", ";
        writeVirtualDispatchArguments(s, function, d_export);
        s << ")" << endl;

        if (function->declaringClass() == java_class) {
            s << "QTD_FUNC(" << module << ", " << f_name << ")" << endl;
        }
    }
}

void CppImplGenerator::writeShellVirtualFunction(QTextStream &s, const AbstractMetaFunction *function,
                                          const AbstractMetaClass *implementor, int id)
{
            // ----------------------------
            if(notWrappedYet(function))
                return;

            AbstractMetaType *f_type = function->type();
            QString new_return_type = function->typeReplaced(0);
            bool has_function_type = ((f_type != 0
                                      || !new_return_type.isEmpty())
                                      && new_return_type != "void");

            writeVirtualDispatchFunction(s, function, implementor);

            writeFunctionSignature(s, function, implementor, QString(), OriginalName);

            s << endl
              << "{" << endl;

            Option options = NoOption;

            Indentation indent(INDENT);
            //bool static_call = !(options & VirtualCall);
//s << "std::cout << \"entering " << function->marshalledName() << " \\n\"; " << endl;

            if (f_type) {
                if (f_type->isTargetLangString())
                      s << INDENT << "DArray ret_str;" << endl;

                if (f_type->name() == "QModelIndex")
                    s << INDENT << "QModelIndexAccessor __d_return_value;" << endl;
                else if (f_type->typeEntry()->isStructInD())
                    s << INDENT << f_type->typeEntry()->qualifiedCppName() << " __d_return_value;" << endl;

                if (f_type->isContainer())
                {
                    if (isNativeContainer(f_type))
                    {
                        s << INDENT;
                        writeTypeInfo(s, f_type, ForceValueType);
                        s << "__d_return_value;" << endl;
                    }
                    else
                        s << INDENT << "void* __d_return_value;" << endl
                          << INDENT << "size_t __d_return_value_size;" << endl;
                }
            }

            AbstractMetaArgumentList arguments = function->arguments();
            foreach (AbstractMetaArgument *argument, arguments) {
                if (!function->argumentRemoved(argument->argumentIndex()+1)) {
                    AbstractMetaType *atype = argument->type();
                    if (!atype->isPrimitive()
                        || !function->conversionRule(TypeSystem::NativeCode, argument->argumentIndex()+1).isEmpty()) {
                        if(atype->isContainer()) {
                            QString arg_name = argument->indexedName();
                            if(!isNativeContainer(atype))
                                writeQtToJava(s,
                                              argument->type(),
                                              arg_name,
                                              "__d_" + arg_name,
                                              function,
                                              argument->argumentIndex() + 1,
                                              Option(VirtualDispatch));
                        }
                    }
                }
            }

            if ((options & NoReturnStatement) == 0)
                s << INDENT;
            /* qtd if (function->isAbstract() && static_call) {
                s << default_return_statement_qt(function->type(), options) << ";" << endl;
            } else */
            {
                if (f_type) {
                    if (f_type->isTargetLangString() || f_type->isContainer())
                        ;
                    else if ((f_type->isValue() && !f_type->typeEntry()->isStructInD()) ||
                            f_type->isVariant() )
                        s << f_type->name() << " *__qt_return_value = (" << f_type->name() << "*) ";
                    else if (f_type->isObject() || f_type->isQObject())
                        s << "return (" << f_type->name() <<"*) ";
                    else if (f_type->name() == "QModelIndex" || f_type->typeEntry()->isStructInD())
                        ;
                    else if ((options & NoReturnStatement) == 0)
                        s << "return ";

                    if (f_type->isEnum() || f_type->isFlags())
                        s << "(" << f_type->typeEntry()->qualifiedCppName() <<") ";
                }

                s << function->marshalledName(AbstractMetaFunction::DeclaringClass) << "_dispatch(";
                if (implementor->isQObject())
                    s << "QObjectLink::getLink(this)->dId";
                else
                    s << "this->dId";

                if (f_type) {
                    if (f_type->isTargetLangString())
                        s << ", &ret_str";
                    if (f_type->name() == "QModelIndex" || f_type->typeEntry()->isStructInD())
                        s << ", &__d_return_value";       // TODO should both be refactored into isNativeType function
                    if (f_type->isContainer()) {
                        if ( ((const ContainerTypeEntry *)f_type->typeEntry())->isQList() )
                            s << ", &__d_return_value";
                        else
                            s << ", &__d_return_value, &__d_return_value_size";
                    }
                }

                if (function->arguments().size() > 0)
                    s << ", ";
                writeFunctionCallArguments(s, function, QString(), Option(options | ForceEnumCast | SkipRemovedArguments | ExcludeConst | VirtualDispatch));

                s << ");" << endl;

//s << "std::cout << \"leaving " << function->marshalledName() << " \\n\"; " << endl;

                if (f_type) {
                    if (f_type->name() == "QModelIndex") {
                        s << INDENT << "QModelIndex __qt_return_value = qtd_to_QModelIndex( __d_return_value );" << endl;
                        s << INDENT << "return __qt_return_value;" << endl;
                    } else if (f_type->typeEntry()->isStructInD())
                        s << INDENT << "return __d_return_value;" << endl;

                    if (f_type->isContainer()) {
                        if (isNativeContainer(f_type))
                            s << INDENT << "return __d_return_value;" << endl;
                        else
                        {
                            writeJavaToQt(s, f_type, "__qt_return_value", "__d_return_value",
                                          function, 0, GlobalRefJObject);
                            s << INDENT << "return __qt_return_value;" << endl;
                        }
                    }

                    if (f_type->isTargetLangString())
                        s << INDENT << "return " << "QString::fromUtf8((const char*) ret_str.ptr, ret_str.length);" << endl;

                    if ( ( f_type->isValue() && !f_type->typeEntry()->isStructInD() ) || f_type->isVariant() )
                        s << INDENT << "return " << f_type->name() << "(*__qt_return_value);" << endl; //" __qt_return_value = ";
                }
            }

            s << "}" << endl << endl;
            // ----------------------------
}

void CppImplGenerator::writeInitCallbacks(QTextStream &s, const  AbstractMetaClass *java_class)
{
    QString initArgs = "VoidFunc *virts";
    if (java_class->name() == "QObject")
        initArgs += ", VoidFunc *sigs";

    s << "QTD_EXTERN QTD_EXPORT void qtd_" << java_class->name()
      << QString("_initCallBacks(%1) {").arg(initArgs) << endl;

    // virtual functions handlers
    AbstractMetaFunctionList virtualFunctions = java_class->virtualFunctions();
    AbstractMetaFunction::Options opts(AbstractMetaFunction::DeclaringClass | AbstractMetaFunction::NoExternNamespace);

    size_t virtual_index = 0;
    foreach (const AbstractMetaFunction *function, virtualFunctions) {        
        if (!notWrappedYet(function) && java_class == function->declaringClass()) { // qtd2
            QString mName = function->marshalledName(opts);
            s << "    qtd_" << mName << "_dispatch = "
                 "(qtd_" << mName << "_dispatch_t) virts[" << virtual_index << "];" << endl;
            virtual_index++;
        }
    }
    // D-side signal callbacks
    if (java_class->name() == "QObject") {
        s << "    qtd_QObject_qt_metacall_dispatch = (QtMetacallCallback)sigs[0];" << endl
          << "    qtd_QObject_metaObject_dispatch = (MetaObjectCallback)sigs[1];" << endl;
    }
    s << "}" << endl;
}

void CppImplGenerator::writeVirtualDispatchArguments(QTextStream &s, const AbstractMetaFunction *d_function, bool d_export)
{
    uint nativeArgCount = 0;
    AbstractMetaType *ret_type = d_function->type();

    s << "(void *dId";

    if (ret_type) {
        if (ret_type->isTargetLangString()) {
            if (d_export)
                s << ", string* ret_str";
            else
                s << ", DArray* ret_str";
        }
        if (ret_type->name() == "QModelIndex")
            s << ", QModelIndexAccessor *__d_return_value";
        else if(ret_type->typeEntry()->isStructInD())
            s << ", " << ret_type->typeEntry()->qualifiedCppName() << " *__d_return_value";

        if (ret_type->isContainer()) {
            if(isNativeContainer(ret_type)) {
                if(d_export)
                    s << ", " << DGenerator::translateType(ret_type, d_function->ownerClass(), NoOption) << "* __d_arr";
                else
                    s << ", void * __d_arr";
            }
            else
                s << ", void** __d_arr_ptr, size_t* __d_arr_size";
        }
    }

    if (d_function->arguments().size() > 0)
        s << ", ";


    // the function arguments
    AbstractMetaArgumentList arguments = d_function->arguments();
    foreach (const AbstractMetaArgument *argument, arguments) {
        if (!d_function->argumentRemoved(argument->argumentIndex() + 1)) {
            if (nativeArgCount > 0)
                s << "," << " ";

            AbstractMetaType *d_type = argument->type();
            QString arg_name = argument->indexedName();

            if (d_type->name() == "QModelIndex")
                s << "QModelIndexAccessor" << QString(d_type->actualIndirections(), '*') << " " << arg_name;
            else if (d_type->isContainer()) {
                if ( isNativeContainer(d_type) )
                    s << "void* ";
                else if (d_export)
                    s << DGenerator::translateType(d_type, d_function->ownerClass(), NoOption) << "* ";
                else
                    s << "DArray* ";
                s << arg_name;
            } else if (d_type->typeEntry()->isStructInD())
                s << d_type->typeEntry()->qualifiedCppName() << QString(d_type->actualIndirections(), '*')
                  << " " << arg_name;
            else if (d_type->isTargetLangString()) {
                if (d_export)
                    s << "wchar* ";
                else
                    s << "const unsigned short* ";
                s << QString("%1, int %1_size").arg(arg_name);
            } else {
                if(d_type->isVariant())
                     s << "void*";
                else if (!d_type->hasNativeId())
                {
                   const ComplexTypeEntry *ctype = static_cast<const ComplexTypeEntry *>(d_type->typeEntry());
                   if(d_type->typeEntry()->isObject() && ctype->isAbstract() && d_export)
                   {
                        QString d_name = d_type->typeEntry()->qualifiedCppName();
                        s << d_name + "_ConcreteWrapper" + QString(d_type->indirections(),'*');
                   }
                   else
                        s << translateType(d_type, EnumAsInts, d_export);
                }
                else
                    s << "void*";
                s << " " << argument->indexedName();
            }
            nativeArgCount++;
        }
    }
    s << ")";
}

void CppImplGenerator::writeJavaLangObjectOverrideFunctions(QTextStream &s, const AbstractMetaClass *cls)
{
    if (cls->hasHashFunction()) {
        AbstractMetaFunctionList hashcode_functions = cls->queryFunctionsByName("hashCode");
        bool found = false;
        foreach (const AbstractMetaFunction *function, hashcode_functions) {
            if (function->actualMinimumArgumentCount() == 0) {
                found = true;
                break;
            }
        }

        if (!found) {
            s << endl
              << INDENT << jni_function_signature(cls->package(), cls->name(), "__qt_hashCode", "jint")
              << "(JNIEnv *__jni_env, jobject, jlong __this_nativeId)" << endl
              << INDENT << "{" << endl;
            {
                Indentation indent(INDENT);
                s << INDENT << "Q_UNUSED(__jni_env);" << endl
                  << INDENT << cls->qualifiedCppName() << " *__qt_this = ("
                  << cls->qualifiedCppName() << " *) qtjambi_from_jlong(__this_nativeId);" << endl
                  << INDENT << "QTJAMBI_EXCEPTION_CHECK(__jni_env);" << endl
                  << INDENT << "Q_ASSERT(__qt_this);" << endl
                  << INDENT << "return qHash(*__qt_this);" << endl;
            }
            s << INDENT << "}" << endl;
        }
    }

    // Qt has a standard toString() conversion in QVariant?
    QVariant::Type type = QVariant::nameToType(cls->qualifiedCppName().toLatin1());
    if (QVariant(type).canConvert(QVariant::String) && !cls->hasToStringCapability()) {
        AbstractMetaFunctionList tostring_functions = cls->queryFunctionsByName("toString");
        bool found = false;
        foreach (const AbstractMetaFunction *function, tostring_functions) {
            if (function->actualMinimumArgumentCount() == 0) {
                found = true;
                break;
            }
        }

        if (!found) {
            s << endl
              << INDENT << jni_function_signature(cls->package(), cls->name(), "__qt_toString", "jstring")
              << "(JNIEnv *__jni_env, jobject, jlong __this_nativeId)" << endl
              << INDENT << "{" << endl;
            {
                Indentation indent(INDENT);
                s << INDENT << cls->qualifiedCppName() << " *__qt_this = ("
                  << cls->qualifiedCppName() << " *) qtjambi_from_jlong(__this_nativeId);" << endl
                  << INDENT << "QTJAMBI_EXCEPTION_CHECK(__jni_env);" << endl
                  << INDENT << "Q_ASSERT(__qt_this);" << endl
                  << INDENT << "return qtjambi_from_qstring(__jni_env, QVariant(*__qt_this).toString());" << endl;
            }
            s << INDENT << "}" << endl;
        }
    }
}

void CppImplGenerator::writeExtraFunctions(QTextStream &s, const AbstractMetaClass *java_class)
{
    const ComplexTypeEntry *class_type = java_class->typeEntry();
    Q_ASSERT(class_type);

    CodeSnipList code_snips = class_type->codeSnips();
    foreach (const CodeSnip &snip, code_snips) {
        if (snip.language == TypeSystem::ShellCode || snip.language == TypeSystem::NativeCode) {
            snip.formattedCode(s, INDENT) << endl;
        }
    }
}

void CppImplGenerator::writeToStringFunction(QTextStream &s, const AbstractMetaClass *java_class)
{
    FunctionModelItem fun = java_class->hasToStringCapability();
    bool core = java_class->package() == QLatin1String("qt.core");
    bool qevent = false;

    const AbstractMetaClass *cls = java_class;
    while (cls) {
        if (cls->name() == "QEvent") {
            qevent = true;
            fun = cls->hasToStringCapability();
            break;
        }
        cls = cls->baseClass();
    }

    if (!java_class->hasDefaultToStringFunction() && fun && !(qevent && core)) {

        int indirections = fun->arguments().at(1)->type().indirections();
        QString deref = QLatin1String(indirections == 0 ? "*" : "");

        s << endl;
        s << "#include <QDebug>" << endl;
        s << jni_function_signature(java_class->package(), java_class->name(), "__qt_toString", "jstring")
          << "(JNIEnv *__jni_env, jobject, jlong __this_nativeId)" << endl
          << INDENT << "{" << endl;
        {
            Indentation indent(INDENT);
            s << INDENT << java_class->qualifiedCppName() << " *__qt_this = ("
              << java_class->qualifiedCppName() << " *) qtjambi_from_jlong(__this_nativeId);" << endl
              << INDENT << "QTJAMBI_EXCEPTION_CHECK(__jni_env);" << endl
              << INDENT << "Q_ASSERT(__qt_this);" << endl

              << INDENT << "QString res;" << endl
              << INDENT << "QDebug d(&res);" << endl
              << INDENT << "d << " << deref << "__qt_this;" << endl;
            s << INDENT << "return qtjambi_from_qstring(__jni_env, res);" << endl;
        }
        s << INDENT << "}" << endl << endl;
    }
}

void CppImplGenerator::writeCloneFunction(QTextStream &s, const AbstractMetaClass *java_class)
{
    s << endl
      << jni_function_signature(java_class->package(), java_class->name(), "__qt_clone", "jobject") << endl
      << "(JNIEnv *__jni_env, jobject, jlong __this_nativeId)" << endl
      << INDENT << "{" << endl;
    {
        Indentation indent(INDENT);
        s << INDENT << java_class->qualifiedCppName() << " *__qt_this = ("

          << java_class->qualifiedCppName() << " *) qtjambi_from_jlong(__this_nativeId);" << endl
          << INDENT << "QTJAMBI_EXCEPTION_CHECK(__jni_env);" << endl
          << INDENT << "Q_ASSERT(__qt_this);" << endl
          << INDENT << java_class->qualifiedCppName() << " *res = __qt_this;" << endl
          << INDENT << "return qtjambi_from_object(__jni_env, res, \"" << java_class->name() << "\", \"" << java_class->package().replace(".", "/") << "/\", true);" << endl;
    }
    s << INDENT << "}" << endl << endl;
}

void CppImplGenerator::writeShellSignatures(QTextStream &s, const AbstractMetaClass *java_class)
{
    bool has_constructors = java_class->hasConstructors();

    // Write the function names...
    if (has_constructors && java_class->hasVirtualFunctions()) {
        AbstractMetaFunctionList virtual_functions = java_class->virtualFunctions();
        {
            Indentation indent(INDENT);

            int pos = -1;
            foreach (AbstractMetaFunction *function, virtual_functions) {
                ++pos;

                if (pos == 0)
                    s << "static const char *qtjambi_method_names[] = {";
                else
                    s << ",";
                s << endl
                  << "/* " << QString("%1").arg(QString::number(pos), 3) << " */ "
                  << "\"" << function->name() << "\"";
            }
            if (pos >= 0)
                s << endl << "};" << endl << endl;
            else
                s << "static const char **qtjambi_method_names = 0;" << endl;
        }

        // Write the function signatures
        {
            Indentation indent(INDENT);

            int pos = -1;
            foreach (AbstractMetaFunction *function, virtual_functions) {
                ++pos;

                if (pos == 0)
                    s << "static const char *qtjambi_method_signatures[] = {";
                else
                    s << ",";
                s << endl
                  << "/* " << QString("%1").arg(QString::number(pos), 3) << " */ "
                  << "\""
                  << jni_signature(function, SlashesAndStuff)
                  << "\"";
            }
            if (pos >= 0)
                s << endl << "};" << endl;
            else
                s << "static const char **qtjambi_method_signatures = 0;" << endl;
            s << "static const int qtjambi_method_count = " << QString::number(pos + 1) << ";" << endl
              << endl;
        }
    }

    if (has_constructors && java_class->hasInconsistentFunctions()) {
        AbstractMetaFunctionList inconsistents = java_class->cppInconsistentFunctions();
        // Write the inconsistent function names...
        {
            Indentation indent(INDENT);
            s << "static const char *qtjambi_inconsistent_names[] = {";
            for (int i=0; i<inconsistents.size(); ++i) {
                if (i != 0)
                    s << ",";
                s << endl << INDENT << "\"" << inconsistents.at(i)->name() << "\"";
            }
            s << endl << "};" << endl << endl;
        }

        // Write the function signatures
        {
            Indentation indent(INDENT);
            s << "static const char *qtjambi_inconsistent_signatures[] = {";
            for (int i=0; i<inconsistents.size(); ++i) {
                const AbstractMetaFunction *function = inconsistents.at(i);

                if (i != 0)
                    s << ",";
                s << endl << INDENT << "\""
                  << jni_signature(function, SlashesAndStuff)
                  << "\"";
            }
            s << endl << "};" << endl << endl;
        }
        s << "static const int qtjambi_inconsistent_count = " << inconsistents.size() << ";" << endl
          << endl;
    }


    AbstractMetaFunctionList signal_functions = java_class->cppSignalFunctions();
    if (signal_functions.size()) {
        Indentation indent(INDENT);
        s << "static const char *qtjambi_signal_names[] = {";
        for (int i=0; i<signal_functions.size(); ++i) {
            if (i != 0)
                s << ",";

            const AbstractMetaFunction *f = signal_functions.at(i);

            QString signalName = f->name();

            s << endl << INDENT << "\"" << signalName << "\"";
        }
        s << endl << "};" << endl << endl;

        s << "static const int qtjambi_signal_argumentcounts[] = {";
        for (int i=0; i<signal_functions.size(); ++i) {
            if (i != 0)
                s << ",";
            s << endl << INDENT << signal_functions.at(i)->arguments().count();
        }
        s << endl << "};" << endl << endl;
        s << "static const int qtjambi_signal_count = " << signal_functions.size() << ";" << endl
          << endl;
    }
}

void CppImplGenerator::writeQObjectEntity(QTextStream &s, const AbstractMetaClass *java_class)
{
    QString entityName = java_class->name() + "Entity";
    QString className = java_class->name();

    s << "class " << entityName << " : public QObject, public QObjectLink" << endl
      << "{" << endl
      << "public:" << endl
      << "    Q_OBJECT_CHECK" << endl
      << "//    virtual int qt_metacall(QMetaObject::Call, int, void **);" << endl << endl

      << "    " << entityName << "(QObject *qObject, void *dId) : QObject(), QObjectLink(qObject, dId) {}" << endl
      << "};" << endl << endl;

/*    // QObject_Link::qt_metacall()
    s << "int " << entityName << "::qt_metacall(QMetaObject::Call _c, int _id, void **_a)" << endl
      << "{" << endl      
      << "    _id = QObject::qt_metacall(_c, _id, _a);" << endl
      << "    if (_id < 0 || _c != QMetaObject::InvokeMetaMethod)" << endl
      << "        return _id;" << endl
      << "    emit_callbacks_" << java_class->name() << "[_id](dId, _a);" << endl      
      << "    return -1;" << endl
      << "}" << endl << endl;
*/
    s << "QTD_EXTERN QTD_EXPORT void qtd_" << className << "_createEntity(void *nativeId, void* dId)" << endl
      << "{" << endl
      << "    new " << entityName << "((QObject*)nativeId, dId);" << endl
      << "}" << endl << endl;
}

void CppImplGenerator::writeQObjectFunctions(QTextStream &s, const AbstractMetaClass *java_class)
{
    // QObject::metaObject()
/*    s << "const QMetaObject *" << shellClassName(java_class) << "::metaObject() const" << endl
      << "{" << endl
      << "  if (m_meta_object == 0) {" << endl
      << "      JNIEnv *__jni_env = qtjambi_current_environment();" << endl
      << "      jobject __obj = m_link != 0 ? m_link->javaObject(__jni_env) : 0;" << endl
      << "      if (__obj == 0) return " << java_class->qualifiedCppName() << "::metaObject();" << endl
      << "      else m_meta_object = qtjambi_metaobject_for_class(__jni_env, __jni_env->GetObjectClass(__obj), " << java_class->qualifiedCppName() << "::metaObject());" << endl;


    AbstractMetaFunctionList virtualFunctions = java_class->virtualFunctions();
    for (int pos=0; pos<virtualFunctions.size(); ++pos) {
        const AbstractMetaFunction *virtualFunction = virtualFunctions.at(pos);
        if (virtualFunction->isVirtualSlot()) {
            QStringList introspectionCompatibleSignatures = virtualFunction->introspectionCompatibleSignatures();
            foreach (QString introspectionCompatibleSignature, introspectionCompatibleSignatures) {
                s << "      {" << endl
                  << "          int idx = "
                  << java_class->qualifiedCppName() << "::metaObject()->indexOfMethod(\""
                  << introspectionCompatibleSignature << "\");" << endl;

                s << "          if (idx >= 0) m_map.insert(idx, " << pos << ");" << endl
                  << "      }" << endl;
            }
        }

    }

    s << "  }" << endl
      << "  return m_meta_object;" << endl
      << "}" << endl << endl;

    // QObject::qt_metacast()
    s << "void *" << shellClassName(java_class) << "::qt_metacast(const char *_clname)" << endl
      << "{" << endl
      << "  if (!_clname) return 0;" << endl
      << "  if (!strcmp(_clname, \"" << shellClassName(java_class) << "\"))" << endl
      << "     return static_cast<void*>(const_cast<" << shellClassName(java_class) << "*>(this));" << endl
      << "  return " << java_class->qualifiedCppName() << "::qt_metacast(_clname);" << endl
      << "}" << endl << endl;
*/
/*
    s << "int " << shellClassName(java_class) << "::qt_metacall(QMetaObject::Call _c, int _id, void **_a)" << endl
      << "{" << endl
      << "    _id = " << java_class->qualifiedCppName() << "::qt_metacall(_c, _id, _a);" << endl
      << "    if (_id < 0 || _c != QMetaObject::InvokeMetaMethod)" << endl
      << "        return _id;" << endl      
      << "    emit_callbacks_" << java_class->name() << "[_id](this->dId, _a);" << endl      
      << "    return -1;" << endl
      << "}" << endl << endl;
      */

    QString module = packageToQtModule(java_class->package());

    s << "QTD_FUNC_DECL(" << module << ", const QMetaObject*, QObject_metaObject_dispatch, (void *dId))" << endl
      << "QTD_FUNC_DECL(" << module << ", int, QObject_qt_metacall_dispatch, (void *dId, QMetaObject::Call _c, int _id, void **_a))" << endl;

    if (java_class->name() == "QObject") {
        s << "QTD_FUNC(" << module << ", QObject_metaObject_dispatch)" << endl
          << "QTD_FUNC(" << module << ", QObject_qt_metacall_dispatch)" << endl;
    }

    // TODO: QMetaObject should be included in the typesystem
    s << endl
      << "const QMetaObject * " << shellClassName(java_class) << "::metaObject() const" << endl
      << "{" << endl
      << "    void* dId = QObjectLink::getDId(this);" << endl
      << "    if (dId)" << endl
      << "        return qtd_QObject_metaObject_dispatch(dId);" << endl
      << "    else" << endl
      << "        return " << java_class->qualifiedCppName() << "::metaObject();" << endl
      << "}" << endl << endl
      << "int " << shellClassName(java_class) << "::qt_metacall(QMetaObject::Call _c, int _id, void **_a)" << endl
      << "{" << endl
      << "    void* dId = QObjectLink::getDId(this);" << endl
      << "    if (dId)" << endl
      << "        return qtd_QObject_qt_metacall_dispatch(dId, _c, _id, _a);" << endl
      << "    else" << endl
      << "        return " << java_class->qualifiedCppName() << "::qt_metacall(_c, _id, _a);" << endl
      << "}" << endl << endl

      << "int " << shellClassName(java_class) << "::__override_qt_metacall(QMetaObject::Call _c, int _id, void **_a)" << endl
      << "{" << endl
      << "    return " << java_class->qualifiedCppName() << "::qt_metacall(_c, _id, _a);"
      << "}" << endl << endl

      << "QTD_EXTERN QTD_EXPORT int qtd_" << java_class->name() << "_qt_metacall(void* __this_nativeId, QMetaObject::Call _c, int _id, void **_a)"
      << "{" << endl
      << "    " << shellClassName(java_class) << " *__qt_this = (" << shellClassName(java_class) << " *) __this_nativeId;" << endl
      << "    return __qt_this->__override_qt_metacall(_c, _id, _a);" << endl
      << "}" << endl << endl;
}

void CppImplGenerator::writeSignalEmitter(QTextStream &s, const AbstractMetaClass *d_class, AbstractMetaFunction *function)
{
    Q_ASSERT(d_class);

    if (function->isModifiedRemoved(TypeSystem::NativeCode))
        return;

    const AbstractMetaClass *cls = d_class ? d_class : function->ownerClass();

    QString function_signature = cls->name() + "::" + function->signature();

    s << "// " << function_signature << endl;

    const QString qt_object_name = function->isStatic() ? shellClassName(cls) : "__qt_this";

    // we are not wrapping some functions depending on arguments because API is not yet full
    if (notWrappedYet(function))
        return;

    // function signature...
    bool callThrough = function->needsCallThrough();
 //   uint options = m_native_jump_table ? ReturnType | ExternC : StandardJNISignature;
    writeFunctionName(s, function, cls, ExternC);
    s << endl;
    writeFinalFunctionArguments(s, function);
    s << endl << "{" << endl;
    Indentation indent(INDENT);

    writeFinalFunctionSetup(s, function, qt_object_name, cls);

    s << "void *args[] = {NULL";
    // create an array of pointers to args
/*    AbstractMetaArgumentList arguments = java_function->arguments();
    foreach (const AbstractMetaArgument *argument, arguments) {
        s << ", ";
        if (!argument->type()->isPrimitive()
            || !java_function->conversionRule(TypeSystem::NativeCode, argument->argumentIndex() + 1).isEmpty()) {
                // s << &qt_arg + n
        }
    }
*/
    s << endl << "}";
    s << endl << endl;
}

void CppImplGenerator::writeShellConstructor(QTextStream &s, const AbstractMetaFunction *java_function)
{
    if (java_function->isModifiedRemoved(TypeSystem::ShellCode))
        return;

    const AbstractMetaClass *cls = java_function->ownerClass();
    AbstractMetaArgumentList arguments = java_function->arguments();

    writeFunctionSignature(s, java_function, cls);

    s << endl;
    s << "    : " << cls->qualifiedCppName() << "(";
    for (int i=0; i<arguments.size(); ++i) {
        s << arguments.at(i)->indexedName();
        if (i != arguments.size() - 1)
            s << ", ";
    }
    s << ")";
    if (cls->isQObject()) {
        s << "," << endl << "      QObjectLink(this, d_ptr)";
    }
    else if (cls->isPolymorphic())
        s << "," << endl << "      QtdObjectLink(d_ptr)";
/* qtd        s << "    m_meta_object(0)," << endl;
    s << "      m_vtable(0)," << endl
      << "      m_link(0)" << endl;
*/
    s << endl;
    s << "{" << endl;
    {
        Indentation indent(INDENT);

        writeCodeInjections(s, java_function, cls, CodeSnip::Beginning, TypeSystem::ShellCode);
        writeCodeInjections(s, java_function, cls, CodeSnip::End, TypeSystem::ShellCode);
    }
    s << "}" << endl << endl;
}

void CppImplGenerator::writeShellDestructor(QTextStream &s, const AbstractMetaClass *java_class)
{
    QString className = shellClassName(java_class);
    s << className << "::~" << className << "() {" << endl;

    if (java_class->isQObject()) {
        s << "    destroyLink(this);" << endl;
    }
    /*
    else if (java_class->isPolymorphic())
        s << "    qtd_delete_d_object(dId);" << endl;
    */

    s << "}" << endl << endl;
}

void CppImplGenerator::writeCodeInjections(QTextStream &s, const AbstractMetaFunction *java_function,
                                           const AbstractMetaClass *implementor, CodeSnip::Position position,
                                           TypeSystem::Language language)
{

    FunctionModificationList mods;
    const AbstractMetaClass *cls = implementor;
    while (cls != 0) {
        mods += java_function->modifications(cls);

        if (cls == cls->baseClass())
            break;
        cls = cls->baseClass();
    }

    foreach (FunctionModification mod, mods) {
        if (mod.snips.count() <= 0)
            continue ;

        foreach (CodeSnip snip, mod.snips) {
            if (snip.position != position)
                continue ;

            if ((snip.language & language) == false)
                continue ;

            if (position == CodeSnip::End)
                s << endl;

            QString code;
            QTextStream tmpStream(&code);
            snip.formattedCode(tmpStream, INDENT);
            ArgumentMap map = snip.argumentMap;
            ArgumentMap::iterator it = map.begin();
            for (;it!=map.end();++it) {
                int pos = it.key() - 1;
                QString meta_name = it.value();

                if (pos >= 0 && pos < java_function->arguments().count()) {
                    code = code.replace(meta_name, java_function->arguments().at(pos)->indexedName());
                } else {
                    QString debug = QString("argument map specifies invalid argument index %1"
                                            "for function '%2'")
                                            .arg(pos + 1).arg(java_function->name());
                    ReportHandler::warning(debug);
                }

            }
            s << code;
            if (position == CodeSnip::Beginning)
                s << endl;
        }
    }
}

static QString function_call_for_ownership(TypeSystem::Ownership owner, const QString &var_name)
{
    if (owner == TypeSystem::CppOwnership) {
        return "setCppOwnership(__jni_env, " + var_name + ")";
    } else if (owner == TypeSystem::TargetLangOwnership) {
        return "setJavaOwnership(__jni_env, " + var_name + ")";
    } else if (owner == TypeSystem::DefaultOwnership) {
        return "setDefaultOwnership(__jni_env, " + var_name + ")";
    } else {
        Q_ASSERT(false);
        return "bogus()";
    }
}

void CppImplGenerator::writeOwnership(QTextStream &s,
                                      const AbstractMetaFunction *java_function,
                                      const QString &var_name,
                                      int var_index,
                                      const AbstractMetaClass *implementor)
{
    TypeSystem::Ownership owner = TypeSystem::InvalidOwnership;
    const AbstractMetaClass *cls = implementor;
    while (cls != 0 && owner == TypeSystem::InvalidOwnership) {
        owner = java_function->ownership(cls, TypeSystem::ShellCode, var_index);
        cls = cls->baseClass();
    }

    if (owner == TypeSystem::InvalidOwnership)
        return;

    if (var_index != -1) {
        s << INDENT << "if (" << var_name << " != 0) {" << endl;
        {
            Indentation indent(INDENT);
            s << INDENT << "QtJambiLink *__link = QtJambiLink::findLink(__jni_env, "
                        << var_name << ");" << endl
            << INDENT << "Q_ASSERT(__link != 0);" << endl;

            s << INDENT << "__link->" << function_call_for_ownership(owner, var_name) << ";" << endl;
        }
        s << INDENT << "}" << endl;
    } else {
        s << INDENT << "if (m_link) {" << endl;
        {
            Indentation indent(INDENT);
            s << INDENT << "m_link->" << function_call_for_ownership(owner, "m_link->javaObject(__jni_env)") << ";" << endl;
        }
        s << INDENT << "}" << endl;
    }

}

void CppImplGenerator::writeShellFunction(QTextStream &s, const AbstractMetaFunction *java_function,
                                          const AbstractMetaClass *implementor, int id)
{
    writeFunctionSignature(s, java_function, implementor, QString(), OriginalName);

    s << endl
      << "{" << endl;

    Indentation indent(INDENT);

    QString java_function_signature = java_function->signature();
/*    s << INDENT << "QTJAMBI_DEBUG_TRACE(\"(shell) entering: " << implementor->name() << "::"
      << java_function_signature << "\");" << endl;
*/
    writeCodeInjections(s, java_function, implementor, CodeSnip::Beginning, TypeSystem::ShellCode);

    //     s << "    printf(\"%s : %s\\n\", \"" << java_function->enclosingClass()->name() << "\""
    //       << ", \"" << java_function->name() << "\");" << endl;

    if (!java_function->isFinalInCpp() || java_function->isVirtualSlot()) {
        s << INDENT << "jmethodID method_id = m_vtable->method(" << id << ");" << endl;
        s << INDENT << "if (method_id) {" << endl;

        {
            Indentation indent(INDENT);
            s << INDENT << "JNIEnv *__jni_env = qtjambi_current_environment();" << endl;

            // This nasty case comes up when we're shutting down while receiving virtual
            // calls.. With these checks we safly abort...
            s << INDENT << "if (!__jni_env) {" << endl
              << "    ";
            writeBaseClassFunctionCall(s, java_function, implementor);
            if (!java_function->type()) {
                s << INDENT << "    return;" << endl;
            }
            s << INDENT << "}" << endl;

            // otherwise, continue with the function call...
            s << INDENT << "__jni_env->PushLocalFrame(100);" << endl;

            AbstractMetaArgumentList arguments = java_function->arguments();
            AbstractMetaArgumentList argumentsToReset;
            foreach (AbstractMetaArgument *argument, arguments) {
                if (!java_function->argumentRemoved(argument->argumentIndex()+1)) {
                    if (!argument->type()->isPrimitive()
                        || !java_function->conversionRule(TypeSystem::NativeCode, argument->argumentIndex()+1).isEmpty()) {
                        writeQtToJava(s,
                                    argument->type(),
                                    argument->indexedName(),
                                    "__java_" + argument->indexedName(),
                                    java_function,
                                    argument->argumentIndex() + 1);
                    }

                    if (java_function->resetObjectAfterUse(argument->argumentIndex()+1))
                        argumentsToReset.append(argument);
                }
            }

            for (int i=0; i<arguments.size(); ++i)
                writeOwnership(s, java_function, "__java_" + arguments.at(i)->indexedName(), i+1, implementor);


            AbstractMetaType *function_type = java_function->type();
            QString new_return_type = java_function->typeReplaced(0);
            bool has_function_type = ((function_type != 0
                                      || !new_return_type.isEmpty())
                                      && new_return_type != "void");

            s << INDENT;
            if (has_function_type) {
                if (new_return_type.isEmpty()) {
                    s << translateType(function_type);
                } else {
                    s << jniName(new_return_type);
                }
                s << " " << "__d_return_value = ";
            }

            s << "__jni_env->";
            if (new_return_type.isEmpty()) {
                s << callXxxMethod(java_function->type());
            } else if (!has_function_type) {
                s << "CallVoidMethod";
            } else {
                s << callXxxMethod(new_return_type);
            }

            s << "(m_link->javaObject(__jni_env), method_id";
            if (arguments.size() > 0)
                s << ", ";
            writeFunctionCallArguments(s, java_function, "__java_", Option(NoCasts | SkipRemovedArguments));
            s << ");" << endl
              << INDENT << "qtjambi_exception_check(__jni_env);" << endl;

            if (has_function_type) {
                writeJavaToQt(s, function_type, "__qt_return_value", "__d_return_value",
                              java_function, 0, GlobalRefJObject);

                if (java_function->nullPointersDisabled()) {
                    s << INDENT << "if (__d_return_value == 0) {" << endl;
                    {
                        Indentation indent(INDENT);
                        s << INDENT << "fprintf(stderr, \"QtJambi: Unexpected null pointer returned from override of '" << java_function->name() << "' in class '%s'\\n\"," << endl
                          << INDENT << "        qPrintable(qtjambi_object_class_name(__jni_env, m_link->javaObject(__jni_env))));" << endl;
                        s << INDENT << "__qt_return_value = ";
                        QString defaultValue = java_function->nullPointerDefaultValue();
                        if (!defaultValue.isEmpty())
                            s << defaultValue << ";";
                        else
                            writeBaseClassFunctionCall(s, java_function, implementor, NoReturnStatement);
                        s << endl;
                    }

                    s << INDENT << "}" << endl;
                }
            } else if (!java_function->conversionRule(TypeSystem::ShellCode, 0).isEmpty()) {
                writeConversionRule(s, TypeSystem::ShellCode, java_function, 0, "<invalid>", "<invalid>");
            }

            writeOwnership(s, java_function, "this", -1, implementor);
            writeOwnership(s, java_function, "__d_return_value", 0, implementor);

            foreach (AbstractMetaArgument *argumentToReset, argumentsToReset) {

                QString argumentName = "__java_" + argumentToReset->indexedName();

                s << INDENT;
                if (argumentToReset->type()->isContainer())
                    s << "qtjambi_invalidate_collection(";
                else
                    s << "qtjambi_invalidate_object(";

                s << "__jni_env, " << argumentName << ");" << endl;
            }

            s << INDENT << "__jni_env->PopLocalFrame(0);" << endl;

            s << INDENT << "QTJAMBI_DEBUG_TRACE(\"(shell) -> leaving: "  << implementor->name()
              << "::" << java_function_signature << "\");" << endl;

            if (function_type)
                s << INDENT << "return __qt_return_value;" << endl;

        }

        s << INDENT << "} else {" << endl;

        {
            Indentation indent(INDENT);
            s << INDENT << "QTJAMBI_DEBUG_TRACE(\"(shell) -> super() and leaving: "
              << implementor->name() << "::" << java_function_signature << "\");" << endl;
            writeBaseClassFunctionCall(s, java_function, implementor);
        }


        s << INDENT << "}" << endl;

        writeCodeInjections(s, java_function, implementor, CodeSnip::End, TypeSystem::ShellCode);

        // A little trick to close open painters on a widget
        if (java_function->name() == "paintEvent") {
            s << INDENT << "JNIEnv *env = qtjambi_current_environment();" << endl
              << INDENT << "qtjambi_end_paint(env, m_link->javaObject(env));" << endl;
        }

    } else {
        if(java_function->isRemovedFrom(implementor, TypeSystem::TargetLangCode)){
            // Avoid compiler warnings for unused parameters
            AbstractMetaArgumentList arguments = java_function->arguments();

            foreach (const AbstractMetaArgument *argument, arguments) {
                s << INDENT << "Q_UNUSED(" << argument->indexedName() << ")" << endl;
            }
        }
        writeBaseClassFunctionCall(s, java_function, implementor);
        writeCodeInjections(s, java_function, implementor, CodeSnip::End, TypeSystem::ShellCode);
    }

    s << "}" << endl << endl;

}

// ### kill implementor

void CppImplGenerator::writePublicFunctionOverride(QTextStream &s,
                                                   const AbstractMetaFunction *java_function,
                                                   const AbstractMetaClass *implementor)
{
    Q_ASSERT(java_function->originalAttributes()
             & (AbstractMetaAttributes::Protected
                | AbstractMetaAttributes::Final));

    // The write a public override version of this function to be used by native functions
    writeFunctionSignature(s, java_function, implementor, "__public_",
                           Option(EnumAsInts | UnderscoreSpaces
                           | (java_function->isAbstract() ? SkipName : NoOption)));
    s << endl
      << "{" << endl;
    Indentation indent(INDENT);
    writeBaseClassFunctionCall(s, java_function, implementor);
    s << "}" << endl << endl;
}

void CppImplGenerator::writeQtdEntityFunction(QTextStream &s, const AbstractMetaClass *java_class)
{
    s << "QTD_EXTERN QTD_EXPORT void *__" << java_class->name() << "_entity(void *q_ptr)" << endl;
    s << "{" << endl;
    {
        Indentation indent(INDENT);
            s << INDENT << "QtdObjectLink* a = dynamic_cast<QtdObjectLink*>((" << java_class->qualifiedCppName() << "*)q_ptr);" << endl
              << INDENT << "if (a != NULL)" << endl
              << INDENT << "    return a->dId;" << endl
              << INDENT << "else" << endl
              << INDENT << "    return NULL;" << endl;
    }
    s << "}" << endl << endl;
}

void CppImplGenerator::writeVirtualFunctionOverride(QTextStream &s,
                                                    const AbstractMetaFunction *java_function,
                                                    const AbstractMetaClass *implementor)
{
    Q_ASSERT(!java_function->isFinalInCpp());

    Option options = Option(EnumAsInts | UnderscoreSpaces);

    // The write a public override version of this function to be used by native functions
    writeFunctionSignature(s, java_function, implementor, "__override_",
                           options,
                           QString(), // the class prefix
                           QStringList() << "bool static_call");
    s << endl
      << "{" << endl;
    Indentation indent(INDENT);
    s << INDENT << "if (static_call) {" << endl;
    {
        Indentation indent(INDENT);
        writeBaseClassFunctionCall(s, java_function, implementor);
    }
    s << INDENT << "} else {" << endl;
    {
        Indentation indent(INDENT);
        writeBaseClassFunctionCall(s, java_function, implementor, VirtualCall);
    }

    s << INDENT << "}" << endl;
    s << "}" << endl << endl;
}


void CppImplGenerator::writeBaseClassFunctionCall(QTextStream &s,
                                                  const AbstractMetaFunction *java_function,
                                                  const AbstractMetaClass *,
                                                  Option options)
{
    bool static_call = !(options & VirtualCall);
    if ((options & NoReturnStatement) == 0)
        s << INDENT;
    if (java_function->isAbstract() && static_call) {
        s << default_return_statement_qt(java_function->type(), options) << ";" << endl;
    } else {
        if (java_function->type() && (options & NoReturnStatement) == 0)
            s << "return ";
        if (static_call) {
            const AbstractMetaClass *implementor = java_function->implementingClass();
            if (java_function->isInterfaceFunction())
                implementor = java_function->interfaceClass()->primaryInterfaceImplementor();
            s << implementor->qualifiedCppName() << "::";
        }
        s << java_function->originalName() << "(";
        writeFunctionCallArguments(s, java_function, QString(), Option(options | ForceEnumCast));
        s << ");" << endl;
    }
}


void CppImplGenerator::writeFunctionName(QTextStream &s,
                                         const AbstractMetaFunction *java_function,
                                         const AbstractMetaClass *java_class,
                                         uint options)
{
    const AbstractMetaClass *cls = java_class ? java_class : java_function->ownerClass();
    AbstractMetaArgumentList arguments = java_function->arguments();

    // Function signature
    QString return_type = jniReturnName(java_function, options);

    QString function_name;

    bool callThrough = java_function->needsCallThrough();
/* qtd    if (!callThrough)
        function_name = java_function->name();
    else */
    function_name = java_function->marshalledName();

    QString args = "__";

    if (callThrough && !java_function->isStatic() && !java_function->isConstructor())
        args += "J";

    if (!arguments.isEmpty()) {
        foreach (const AbstractMetaArgument *argument, arguments) {
            if (!java_function->argumentRemoved(argument->argumentIndex() + 1)) {
                if (!argument->type()->hasNativeId()) {
                    QString modified_type = java_function->typeReplaced(argument->argumentIndex()+1);
                    if (modified_type.isEmpty())
                        args += jni_signature(argument->type(), Underscores);
                    else
                        args += jni_signature(modified_type, Underscores);
                } else {
                    args += "J";
                }
            }
        }
    }

    s << jni_function_signature(cls->package(), cls->name(), function_name,
                                return_type, args, options);

}

void CppImplGenerator::writeFinalFunctionArguments(QTextStream &s, const AbstractMetaFunction *java_function, bool d_export)
{
    bool callThrough = java_function->needsCallThrough();
    s << "(";
/* qtd
      << "JNIEnv *__jni_env," << endl;
    if (!java_function->isConstructor()) {
        if (java_function->isStatic())
            s << " jclass";
        else
            s << " jobject";
    } else
        s << " jobject " << java_object_name;
*/
    uint nativeArgCount = 0;
    const AbstractMetaClass *cls = java_function->ownerClass();
    if (java_function->isConstructor() &&
        ( cls->isPolymorphic()
        || cls->typeEntry()->isObject() ) )
    {
        s << "void *d_ptr";
        nativeArgCount++;
    }

    // passing pointer to C++ object
    bool hasNativeId = callThrough && !java_function->isStatic() && !java_function->isConstructor();
    if (hasNativeId) {
        if (nativeArgCount > 0)
            s << "," << endl << " ";
        /* qtd << "," << endl */ s << "void* __this_nativeId";
        nativeArgCount++;
    }

    AbstractMetaType *f_type = java_function->type();

    // return values as strings, arrays or QModelIndex'es we return as arguments
    bool return_arg = false;
    if (f_type) {
        if (f_type->isTargetLangString() ||
            f_type->isContainer() ||
            f_type->name() == "QModelIndex" ||
            f_type->typeEntry()->isStructInD())
            return_arg = true;

        if (return_arg && nativeArgCount > 0)
                s << "," << endl << " ";

        if (f_type->isTargetLangString() || f_type->isContainer())
            s << "void*";
        else if (f_type->name() == "QModelIndex")
            s << "QModelIndexAccessor*";
        else if (f_type->typeEntry()->isStructInD())
            s << f_type->typeEntry()->qualifiedCppName() << " *";

        if(return_arg) {
            s << " __d_return_value";
            nativeArgCount++;
        }
    }

    // the function arguments
    AbstractMetaArgumentList arguments = java_function->arguments();
    foreach (const AbstractMetaArgument *argument, arguments) {
        if (!java_function->argumentRemoved(argument->argumentIndex() + 1)) {
            AbstractMetaType *d_type = argument->type();
            const TypeEntry *te = d_type->typeEntry();

            QString arg_name = argument->indexedName();

            if (nativeArgCount > 0)
                s << "," << endl << " ";

            // if QString argument we have to pass DArray
            if ((te && te->qualifiedCppName() == "QString") || d_type->isTargetLangString()) {
                if (d_export)
                    s << "string " << arg_name;
                else
                    s << "DArray " << arg_name;
            } else if (d_type->isContainer()) {
                const ContainerTypeEntry *cte =
                        static_cast<const ContainerTypeEntry *>(te);
                if(cte->isQList())
                    s << "void* " << arg_name;
                else if(isLinearContainer(cte))
                    s << "DArray* " << arg_name;
            } else {
                if (!d_type->hasNativeId()) {
                    if(d_type->isVariant()) {
                        if (d_export) s << "void*";
                        else s << "QVariant*";
                    } else
                        s << translateType(argument->type(), EnumAsInts, d_export);
                }
                else if (d_type->name() == "QModelIndex") {
                    if(d_export && global.dVersion == 2 && d_type->isConstant())
                        s << "const(QModelIndexAccessor)";
                    else
                        s << "QModelIndexAccessor";
                } else if (te->isStructInD())
                    s << te->qualifiedCppName();
                else
                    s << "void*";

                s << " " << arg_name;
            }
            nativeArgCount++;
        }
    }
    s << ")";
}


/*!
    Generates type conversion from Java -> Qt for all the arguments
    that are to be to be passed to the function
*/
void CppImplGenerator::writeFinalFunctionSetup(QTextStream &s, const AbstractMetaFunction *java_function,
                                               const QString &qt_object_name,
                                               const AbstractMetaClass *cls)
{

    // Translate each of the function arguments into qt types
    AbstractMetaArgumentList arguments = java_function->arguments();
    foreach (const AbstractMetaArgument *argument, arguments) {
        if (!argument->type()->isPrimitive()
            || !java_function->conversionRule(TypeSystem::NativeCode, argument->argumentIndex() + 1).isEmpty()) {
                writeJavaToQt(s,
                            argument->type(),
                            "__qt_" + argument->indexedName(),
                            argument->indexedName(),
                            java_function,
                            argument->argumentIndex() + 1,
                            Option(UseNativeIds | EnumAsInts));
        }
    }

    // Extract the qt equivalent to the this pointer and name it "qt_object_name"
    if (!java_function->isStatic() && !java_function->isConstructor()) {
// qtd2        QString className = java_function->isFinalOverload() ? cls->name() : shellClassName(cls);
        QString className = java_function->isFinalOverload() ? cls->name() : shellClassName(cls);
        s << INDENT
          << className << " *" << qt_object_name
          << " = (" << className << " *) __this_nativeId;"
          << endl;
//          << INDENT << "QTJAMBI_EXCEPTION_CHECK(__jni_env);" << endl
// qtd          << INDENT << "Q_ASSERT(" << qt_object_name << ");" << endl;
    }
}

void CppImplGenerator::writeFinalFunction(QTextStream &s, const AbstractMetaFunction *java_function,
                                          const AbstractMetaClass *java_class)
{
    Q_ASSERT(java_class);

    if (java_function->isModifiedRemoved(TypeSystem::NativeCode))
        return;

    const AbstractMetaClass *cls = java_class ? java_class : java_function->ownerClass();

    QString java_function_signature = cls->name() + "::" + java_function->signature();

    s << "// " << java_function_signature << endl;

    const AbstractMetaType *function_type = java_function->type();
    QString new_return_type = java_function->typeReplaced(0);
    bool has_function_type = new_return_type != "void"
                             && (!new_return_type.isEmpty() || function_type != 0)
                         && java_function->argumentReplaced(0).isEmpty();

    const QString qt_object_name = java_function->isStatic() ? shellClassName(cls) : "__qt_this";
    const QString java_object_name = java_function->isStatic() ? "__jni_class" : "__jni_object";

    // we are not wrapping some functions depending on arguments because API is not yet full
    if (notWrappedYet(java_function))
        return;

    // function signature...
    bool callThrough = java_function->needsCallThrough();
    uint options = m_native_jump_table ? ReturnType | ExternC : StandardJNISignature;
    writeFunctionName(s, java_function, cls, options);
    s << endl;
    writeFinalFunctionArguments(s, java_function);
    s << endl << "{" << endl;
    Indentation indent(INDENT);

// qtd2    s << INDENT << "QTJAMBI_DEBUG_TRACE(\"(native) entering: " << java_function_signature << "\");" << endl;
    bool hasNativeId = (callThrough && !java_function->isStatic() && !java_function->isConstructor());
/*    if (hasNativeId)
        s << INDENT << "Q_UNUSED(__this_nativeId)" << endl;
    // Avoid compiler warnings when the variables are unused
    {
        s << INDENT << "Q_UNUSED(__jni_env)" << endl;

        if (java_function->isConstructor())
            s << INDENT << "Q_UNUSED(" << java_object_name << ")" << endl;

        bool hasNativeId = (callThrough && !java_function->isStatic() && !java_function->isConstructor());
        if (hasNativeId)
            s << INDENT << "Q_UNUSED(__this_nativeId)" << endl;
    }
*/

    if (cls->isFinal() && (!java_function->isAbstract() || !java_function->isFinalInTargetLang()) && !java_function->wasPublic()) {
        QString debug = QString("protected function '%1' in final class '%2'")
            .arg(java_function->signature()).arg(java_class->name());
        ReportHandler::warning(debug);
        // Avoid compiler warnings for unused parameters
        AbstractMetaArgumentList arguments = java_function->arguments();

        foreach (const AbstractMetaArgument *argument, arguments) {
            s << INDENT << "Q_UNUSED(" << argument->indexedName() << ")" << endl;
        }
        s << INDENT << default_return_statement_qt(java_function->type()) << "";
    } else {
        writeFinalFunctionSetup(s, java_function, qt_object_name, cls);

        writeCodeInjections(s, java_function, java_function->implementingClass(), CodeSnip::Beginning, TypeSystem::NativeCode);

        if (java_function->isConstructor()) {
            writeFinalConstructor(s, java_function, qt_object_name, java_object_name);
        } else {

            QString function_prefix = "";
            QStringList extra_param;
            Option option = NoOption;

            bool hasShell = cls->generateShellClass();

            if (java_function->isFinalOverload()) {
                // no prefix
            } else if (java_function->isFinalInCpp() && !java_function->wasPublic() && hasShell) {
                function_prefix = "__public_";
            } else if (!java_function->isFinalInCpp() && !java_function->isStatic() && hasShell) {
                function_prefix = "__override_";
                extra_param.append("__do_static_call");
                s << INDENT
                  << "bool __do_static_call = "
                  << "dynamic_cast<QtdObjectLink*>((" << java_class->polymorphicBase()->qualifiedCppName() << "*)__this_nativeId) != NULL;" << endl;
            } else {
                option = OriginalName;
            }

            // Call the Qt function on the java object
            s << "    ";
            if (has_function_type) {
                const QString qt_return_value = "__qt_return_value";
                const QString java_return_value = "__d_return_value";
                if (function_type) {
                    writeTypeInfo(s, function_type, EnumAsInts);
                    s << " " << qt_return_value
                      << " = ";
                }

                writeFunctionCall(s, qt_object_name, java_function, function_prefix, option,
                                  extra_param);
                s << endl;

                writeRefArguments(s, java_function);

                writeQtToJava(s, function_type, qt_return_value, java_return_value,
                              java_function, 0, EnumAsInts);

// qtd                s << INDENT << "QTJAMBI_DEBUG_TRACE(\"(native) -> leaving: "
//                  << java_function_signature << "\");";

                if (function_type && function_type->name() != "QModelIndex") {
                    if(function_type->typeEntry()->isStructInD())
                        ; //s << endl << INDENT << "return " << qt_return_value << ";";
                    else if (!function_type->isTargetLangString() && !function_type->isContainer())
                        s << endl << INDENT << "return " << java_return_value << ";";
                }

            } else {
                writeFunctionCall(s, qt_object_name, java_function, function_prefix, option,
                                  extra_param);
                writeRefArguments(s, java_function);
            }
        }
    }
    if(!java_function->argumentReplaced(0).isEmpty()) {
    s << INDENT << "return 0;" << endl;
    }

    s << endl << "}";
    s << endl << endl;
}

void CppImplGenerator::writeRefArguments(QTextStream &s, const AbstractMetaFunction *java_function)
{
    AbstractMetaArgumentList arguments = java_function->arguments();
    foreach (const AbstractMetaArgument *argument, arguments) {
        AbstractMetaType *d_type = argument->type();
        const TypeEntry *te = d_type->typeEntry();
        if ((te && d_type->isNativePointer() && te->name() == "QString"))
            s << QString("    qtd_toUtf8(__qt_%1.utf16(), __qt_%1.size(), &%1);").arg(argument->indexedName()) << endl;
    }
}

void CppImplGenerator::writeAssignment(QTextStream &s, const QString &destName, const QString &srcName,
                                       const AbstractMetaType *java_type)
{
    if (java_type->isArray()) {
        for (int i=0; i<java_type->arrayElementCount(); ++i) {
            writeAssignment(s, destName + "[" + QString::number(i) + "]",
                srcName + "[" + QString::number(i) + "]", java_type->arrayElementType());
        }
    } else {
        s << INDENT << destName << " = " << srcName << ";" << endl;
    }
}

void CppImplGenerator::writeFieldAccessors(QTextStream &s, const AbstractMetaField *java_field)
{
    Q_ASSERT(java_field);
    Q_ASSERT(java_field->isPublic() || java_field->isProtected());

    const AbstractMetaFunction *setter = java_field->setter();
    const AbstractMetaFunction *getter = java_field->getter();

    const AbstractMetaClass *cls = java_field->enclosingClass();
    FieldModification mod = cls->typeEntry()->fieldModification(java_field->name());

    if(notWrappedYet(getter))
        return;

    if (mod.isReadable()) {
        // Getter
        if (getter->wasProtected()) {
            writeFunctionSignature(s, getter, getter->ownerClass());
            s << endl
              << "{" << endl;
            {
                Indentation indent(INDENT);
                s << INDENT << "return " << java_field->name() << ";" << endl;
            }
            s << "}" << endl << endl;
        }


        writeFunctionName(s, getter, getter->ownerClass());
        s << endl;
        writeFinalFunctionArguments(s, getter);
        s << "{" << endl;
        {
            Indentation indent(INDENT);


            writeFinalFunctionSetup(s, getter, "__qt_object", getter->ownerClass());

            const QString java_return_value = "__d_return_value";
            QString qt_return_value;
            if (setter->isStatic())
                qt_return_value = shellClassName(setter->ownerClass()) + "::";
            else
                qt_return_value = "__qt_object->";


            // To avoid "taking address of tmp"
            s << INDENT;
            writeTypeInfo(s, getter->type(), Option(ArrayAsPointer));
            QString tmp_name = "__tmp_" + getter->name();
            s << tmp_name << " = ";

            if (getter->wasPublic())
                qt_return_value += java_field->name();
            else
                qt_return_value += getter->name() + "_getter()";
            s << qt_return_value << ";" << endl;

            writeQtToJava(s, getter->type(), tmp_name, java_return_value, 0, -1, EnumAsInts);
            if (getter->type()->isTargetLangString() || getter->type()->name() == "QModelIndex")
                ;
            else if(getter->type()->typeEntry()->isStructInD())
                ; //s << INDENT << "return " << tmp_name << ";" << endl;
            else
                s << INDENT << "return " << java_return_value << ";" << endl;
        }
        s << "}" << endl << endl;
    }

    if(notWrappedYet(setter))
        return;

    // Setter
    if (mod.isWritable() && !java_field->type()->isConstant()) {
        // Write public override for protected fields
        if (setter->wasProtected()) {
            writeFunctionSignature(s, setter, setter->ownerClass());
            s << endl
              << "{" << endl;
            {
                Indentation indent(INDENT);

                Q_ASSERT(setter->arguments().count() > 0);
                const AbstractMetaArgument *argument = setter->arguments().at(0);

                QString thisRef = java_field->isStatic()
                    ? setter->ownerClass()->qualifiedCppName() + QString("::")
                    : QString("this->");
                writeAssignment(s, thisRef + java_field->name(), argument->indexedName(), argument->type());
            }
            s << "}" << endl << endl;
        }

        writeFunctionName(s, setter, setter->ownerClass());
        s << endl;
        writeFinalFunctionArguments(s, setter);
        s  << "{" << endl;

        {
            Indentation indent(INDENT);

            writeFinalFunctionSetup(s, setter, "__qt_object", setter->ownerClass());

            Q_ASSERT(setter->arguments().count() == 1);
            const AbstractMetaArgument *argument = setter->arguments().at(0);

            QString dest;
            if (setter->isStatic())
                dest = shellClassName(setter->ownerClass()) + "::";
            else
                dest = "__qt_object->";

            QString src;
            if (!argument->type()->isPrimitive() && !argument->type()->typeEntry()->isStructInD()) {
                src = "__qt_" + argument->indexedName();
            } else if (argument->type()->name() == "QModelIndex") {
                src = "qtd_to_QModelIndex(" + argument->indexedName() + ")";
            } else
                src = argument->indexedName();

            if (setter->wasPublic())
                writeAssignment(s, dest + java_field->name(), src, argument->type());
            else
                s << INDENT << dest << setter->name() << "_setter(" << src << ");" << endl;
        }
        s << "}" << endl << endl;
    }
}

void CppImplGenerator::writeFinalDestructor(QTextStream &s, const AbstractMetaClass *cls)
{
    if (cls->hasConstructors() && cls->isDestructorBase()) {
        s << INDENT << "QTD_EXTERN QTD_EXPORT void qtd_" << cls->name() << "_delete(void* nativeId)" << endl
          << INDENT << "{" << endl
          << INDENT << "    delete (" << shellClassName(cls) << "*)nativeId;" << endl
          << INDENT << "}" << endl << endl;

        s << INDENT << "QTD_EXTERN QTD_EXPORT void qtd_" << cls->name() << "_destroy(void* nativeId)" << endl
          << INDENT << "{" << endl
          << INDENT << "    call_destructor((" << shellClassName(cls) << "*)nativeId);" << endl
          << INDENT << "}" << endl << endl;
    }
}

void CppImplGenerator::writeFinalConstructor(QTextStream &s,
                                         const AbstractMetaFunction *java_function,
                                         const QString &qt_object_name,
                                         const QString &java_object_name,
                                         const QString &place)
{
    const AbstractMetaClass *cls = java_function->ownerClass();
    AbstractMetaArgumentList arguments = java_function->arguments();
    QString className = cls->typeEntry()->qualifiedCppName();

    bool hasShellClass = cls->generateShellClass();

    s << INDENT << shellClassName(cls) << " *" << qt_object_name
      << " = new " << place << shellClassName(cls)
      << "(";
    writeFunctionCallArguments(s, java_function, "__qt_");
    s << ");" << endl;
    s << INDENT << "return (void *) " << qt_object_name << ";" << endl; // qtd

/* qtd    s << INDENT << "QtJambiLink *__qt_java_link = ";
    if (cls->isQObject()) {
        s << "qtjambi_construct_qobject(__jni_env, " << java_object_name << ", "
          << qt_object_name << ")";
    } else {
        s << "qtjambi_construct_object(__jni_env, " << java_object_name << ", " << qt_object_name;
        if (cls->typeEntry()->isValue())
            s << ", \"" << className << "\")";
        else // non-QObject, object type
            s << ", QMetaType::Void, QLatin1String(\"" << cls->fullName().replace(".", "/") << "\"), true)";
    }
    s << ";" << endl
      << INDENT << "if (!__qt_java_link) {" << endl;
    {
        Indentation indent(INDENT);
        s << INDENT << "qWarning(\"object construction failed for type: "
          << className << "\");" << endl
          << INDENT << "return;" << endl;
    }
    s << INDENT << "}" << endl;


    if (cls->isQObject()) {
        // Make sure all qobjects created by Java are owned by java only if
        // parent object has not been set.
        // All other objects will default to split ownership.
        s << INDENT << "if(!__qt_this->QObject::parent()){" << endl;
        s << INDENT << "    __qt_java_link->setJavaOwnership(__jni_env, " << java_object_name << ");" << endl;
        s << INDENT << "}" << endl;
    } else {
        // All non-qobjects created by Java are owned by java
        s << INDENT << "__qt_java_link->setJavaOwnership(__jni_env, " << java_object_name << ");" << endl;
    }

    if (hasCustomDestructor(cls)) {
        s << INDENT << "__qt_java_link->setDestructorFunction(qtjambi_destructor);" << endl;
    }

    if (cls->typeEntry()->typeFlags() & ComplexTypeEntry::DeleteInMainThread)
        s << INDENT << "__qt_java_link->setDeleteInMainThread(true);" << endl;

    if (!cls->hasVirtualFunctions() && !cls->hasInconsistentFunctions() && !cls->typeEntry()->isObject())
        return;

    if (hasShellClass) {
        // Set up the link object
        s << INDENT << qt_object_name << "->m_link = __qt_java_link;" << endl;

        // Make sure the user data in the QObject has bindings to the qobject's meta object
        // (this has to be done after the link is set, so that the fake meta object
        //  can access the java object, for which it gets a reference in the link)
        if (cls->isQObject())
            s << INDENT << qt_object_name << "->m_link->setMetaObject(" << qt_object_name << "->metaObject());" << endl;

        s << INDENT << qt_object_name << "->m_link->setCreatedByJava(true);" << endl;



        AbstractMetaClassList interfaces = cls->interfaces();
        if (interfaces.size() + (cls->baseClass() != 0 ? 1 : 0) > 1)  {
            if (cls->baseClass() != 0)
                interfaces += cls->baseClass();
            foreach (AbstractMetaClass *iface, interfaces) {
                AbstractMetaClass *impl = iface->isInterface() ? iface->primaryInterfaceImplementor() : iface;
                s << INDENT << qt_object_name << "->m_link->registerSubObject((" << impl->qualifiedCppName() << " *) " << qt_object_name << ");" << endl;
            }
        }
    }

    if (!cls->hasVirtualFunctions() && !cls->hasInconsistentFunctions())
        return;

    // Set up the vtable
    s << INDENT;
    QString space(24, ' ');
    if (hasShellClass)
        s << qt_object_name << "->m_vtable = ";
    s << "qtjambi_setup_vtable(__jni_env, " << endl << space << "__jni_object, " << endl;

    if (cls->hasInconsistentFunctions()) {
        s << space << "qtjambi_inconsistent_count, " << endl
          << space << "qtjambi_inconsistent_names, " << endl
          << space << "qtjambi_inconsistent_signatures, " << endl;
    } else {
        s << space << "0, 0, 0, // no inconsistent functions" << endl;
    }

    if (cls->hasVirtualFunctions()) {
        s << space << "qtjambi_method_count, " << endl
          << space << "qtjambi_method_names, " << endl
          << space << "qtjambi_method_signatures" << endl;
    } else {
        s << space << "0, 0, 0 // no virtual functions" << endl;
    }

    s << space << ");" << endl; */
}

void CppImplGenerator::writeSignalInitialization(QTextStream &s, const AbstractMetaClass *java_class)
{
    if (!java_class->isQObject()
        || java_class->queryFunctions(AbstractMetaClass::Signals | AbstractMetaClass::Visible | AbstractMetaClass::NotRemovedFromTargetLang).size() == 0) {
        return ;
    }

    s << jni_function_signature(java_class->package(), java_class->name(), "__qt_signalInitialization", "jboolean")
      << endl << "(JNIEnv *__jni_env, jobject java_object, jlong ptr, jstring java_signal_name)" << endl
      << "{" << endl
      << "   QtJambiLink *link = (QtJambiLink *) ptr;" << endl
      << "   if (link == 0)" << endl
      << "       return true;" << endl << endl
      << "   QObject *qt_this = link->qobject();" << endl
      << "   Q_ASSERT(qt_this);" << endl << endl
      << "   QtJambi_SignalWrapper_" << java_class->name() << " *qt_wrapper = "
      << "   (QtJambi_SignalWrapper_" << java_class->name() << " *) link->signalWrapper();" << endl
      << "   if (qt_wrapper == 0) {" << endl
      << "       qt_wrapper = new QtJambi_SignalWrapper_" << java_class->name() << ";" << endl
      << "       link->setSignalWrapper(qt_wrapper);" << endl
      << "       qt_wrapper->link = link;" << endl << endl
      << "       qtjambi_resolve_signals(__jni_env," << endl
      << "                               java_object," << endl
      << "                               qt_wrapper->m_signals," << endl
      << "                               qtjambi_signal_count," << endl
      << "                               (char **) qtjambi_signal_names," << endl
      << "                               (int *) qtjambi_signal_argumentcounts);" << endl
      << "   }" << endl
      << "   QString signal_name = qtjambi_to_qstring(__jni_env, java_signal_name);" << endl
      << "   return qtjambi_connect_cpp_to_java(__jni_env," << endl
      << "                                      signal_name," << endl
      << "                                      qt_this," << endl
      << "                                      qt_wrapper," << endl
      << "                                      QLatin1String(\"" << java_class->fullName() << "\")," << endl
      << "                                      QLatin1String(\"" << signalWrapperPrefix() << "\"));" << endl
      << "}";
}

QString CppImplGenerator::fromObject(const TypeEntry *entry,
                                     const QString &var_name)
{
    QString returned;
    QString package = entry->javaPackage();
    const ComplexTypeEntry *centry = entry->isComplex()
                                     ? static_cast<const ComplexTypeEntry *>(entry)
                                     : 0;

    if (centry == 0 || centry->polymorphicIdValue().isEmpty()) {
/* qtd        returned = "qtjambi_from_object(__jni_env, " + var_name + ", \""
                   + entry->lookupName()
                   + "\", \"" + QString(package).replace(".", "/") + "/\", true);";
*/
        if(entry->isObject())
            returned = var_name + ";";
        else
            returned = "new " + entry->lookupName() + "(" + var_name +");";
    } else {
        AbstractMetaClass *cls = classes().findClass(centry->qualifiedCppName());
        if (!cls) {
            qFatal("CppImplGenerator::fromObject(): class '%s' could not be resolved...",
                   qPrintable(centry->qualifiedCppName()));
        }

        while (cls != 0 && !cls->typeEntry()->isPolymorphicBase())
            cls = cls->baseClass();

        QString full_name;
        if (cls != 0) {
            full_name = cls->fullName();
        } else {
            ReportHandler::warning(QString("class '%1' has polymorphic id but does not inherit a polymorphic class")
                                   .arg(centry->qualifiedCppName()));
        }
/* qtd
        returned = "qtjambi_from_object(__jni_env, " + var_name + ", \""
                   + centry->lookupName()
                   + "\", \"" + QString(package).replace(".", "/") + "/\","
                   + "\"" + jni_signature(full_name, Underscores) + "\", true); // fucking complex";
*/
        if(entry->isObject())
            returned = var_name + "; // complex entry";
        else
            returned = "new " + centry->lookupName() + "(" + var_name +");  // complex entry";
    }

    return returned;
}

void CppImplGenerator::writeOriginalMetaObjectFunction(QTextStream &s, const AbstractMetaClass *java_class)
{
    Q_ASSERT(java_class->isQObject());

    s << jni_function_signature(java_class->package(),
                                java_class->name(),
                                "originalMetaObject",
                                "jlong");

    s << endl
      << "(JNIEnv *," << endl
      << " jclass)" << endl
      << "{" << endl;
    {
        Indentation indent(INDENT);
        s << INDENT << "return reinterpret_cast<jlong>(&" << java_class->qualifiedCppName() << "::staticMetaObject);" << endl;
    }
    s << "}" << endl << endl;
}

void CppImplGenerator::writeFromNativeFunction(QTextStream &s, const AbstractMetaClass *java_class)
{
    s << jni_function_signature(java_class->package(),
                                java_class->name(),
                                "fromNativePointer",
                                "jobject");
    s << endl
      << "(JNIEnv *__jni_env," << endl
      << " jclass," << endl
      << " jobject nativePointer)" << endl
      << "{" << endl;
    {
        Indentation indent(INDENT);
        s << INDENT << "void *ptr = qtjambi_to_cpointer(__jni_env, nativePointer, 1);" << endl
            << INDENT << "return " << fromObject(java_class->typeEntry(), "ptr") << endl
          << "}" << endl;
    }
}

void CppImplGenerator::writeFromArrayFunction(QTextStream &s, const AbstractMetaClass *java_class)
{
    s << jni_function_signature(java_class->package(),
                                java_class->name(),
                                "nativePointerArray",
                                "jobject");
    s << endl
      << "(JNIEnv *__jni_env," << endl
      << " jclass," << endl
      << " jobjectArray array)" << endl
      << "{" << endl;
    {
        Indentation indent(INDENT);
        s << INDENT << "return qtjambi_array_to_nativepointer(__jni_env, " << endl
          << INDENT << "                                     array, " << endl
          << INDENT << "                                     sizeof("
                    << java_class->qualifiedCppName() << "));" << endl;
    }
    s << "}" << endl;
}


void CppImplGenerator::writeInterfaceCastFunction(QTextStream &s,
                                                  const AbstractMetaClass *java_class,
                                                  const AbstractMetaClass *interface)
{
    Q_ASSERT(interface->isInterface());
    const InterfaceTypeEntry *ie = static_cast<const InterfaceTypeEntry *>(interface->typeEntry());
    QString interface_name = ie->origin()->targetLangName();

    s << endl
      << jni_function_signature(java_class->package(),
                                java_class->name(),
                                QString("__qt_cast_to_%1").arg(interface_name),
                                "jlong",
                                "__J");

    s << endl
      << "(JNIEnv *," << endl
      << " jobject," << endl
      << " jlong ptr)" << endl
      << "{" << endl
      << "    return (jlong) (" << interface->primaryInterfaceImplementor()->qualifiedCppName() << " *) "
      << "(" << java_class->qualifiedCppName() << " *) ptr;" << endl
      << "}" << endl;
}

bool CppImplGenerator::writeConversionRule(QTextStream &s,
                                           TypeSystem::Language target_language,
                                           const AbstractMetaFunction *java_function,
                                           int argument_index,
                                           const QString &qt_name,
                                           const QString &java_name)
{
    if (argument_index < 0 || java_function == 0)
        return false;

    QString conversion_rule = java_function->conversionRule(target_language, argument_index);

    if (!conversion_rule.isEmpty()) {
        QString qt_name_var;
        QString java_name_var;

        if ((argument_index == 0 && target_language == TypeSystem::NativeCode)
             || (argument_index != 0 && target_language == TypeSystem::ShellCode)) {
            qt_name_var = "%in";
            java_name_var = "%out";
        } else {
            qt_name_var = "%out";
            java_name_var = "%in";
        }

        conversion_rule  = conversion_rule.replace(qt_name_var, qt_name)
                                          .replace(java_name_var, java_name);

        AbstractMetaArgumentList arguments = java_function->arguments();
        for (int i=0; i<arguments.size(); ++i) {
            conversion_rule = conversion_rule.replace("%" + QString::number(i+1),
                                                      arguments.at(i)->indexedName());
        }

        QStringList lines = conversion_rule.split("\n");
        foreach (QString line, lines) {
            s << INDENT << line.trimmed() << endl;
        }

        return true;
    } else {
        return false;
    }
}


void CppImplGenerator::writeJavaToQt(QTextStream &s,
                                     const AbstractMetaClass *java_class,
                                     const AbstractMetaType *function_return_type,
                                     const QString &qt_name,
                                     const QString &java_name,
                                     const AbstractMetaFunction *java_function,
                                     int argument_index)
{
    // Conversion to C++: Shell code for return values, native code for arguments
    TypeSystem::Language lang = argument_index == 0 ? TypeSystem::ShellCode : TypeSystem::NativeCode;
    if (writeConversionRule(s, lang, java_function, argument_index, qt_name, java_name))
        return;

    s << INDENT << shellClassName(java_class) << " *" << qt_name << " = ("
      << shellClassName(java_class) << " *) ";
    if (java_class->isQObject())
        s << "qtjambi_to_qobject";
    else
        s << "qtjambi_to_object";
    s << "(__jni_env, " << java_name << ");" << endl;
    if (java_class->isQObject()) {
        // ### throw exceptions when objects are null...
        s << INDENT << "if (!" << qt_name << ") "
          << default_return_statement_java(function_return_type) << ";"  << endl << endl;
    }
}


void CppImplGenerator::writeJavaToQt(QTextStream &s,
                                     const AbstractMetaType *java_type,
                                     const QString &qt_name,
                                     const QString &java_name,
                                     const AbstractMetaFunction *java_function,
                                     int argument_index,
                                     Option options)
{
    // Conversion to C++: Shell code for return values, native code for arguments
    TypeSystem::Language lang = argument_index == 0 ? TypeSystem::ShellCode : TypeSystem::NativeCode;
    if (java_function && writeConversionRule(s, lang, java_function, argument_index, qt_name, java_name))
        return;

    if (java_type == 0) {
        QString warn = QString("no conversion possible for argument '%1' in function '%2::%3' for "
                               "language '%4'")
                               .arg(argument_index)
                               .arg(java_function->implementingClass()->name())
                               .arg(java_function->name())
                               .arg(int(lang));
        ReportHandler::warning(warn);
        return;
    }
    if (java_type->name() == "QModelIndex") {
        s << INDENT << "QModelIndex " << qt_name << " = qtd_to_QModelIndex("
                << java_name << ");" << endl;
    } else if (java_type->typeEntry()->isStructInD()) {
        // empty
    } else if (java_type->typeEntry() && java_type->typeEntry()->qualifiedCppName() == "QString") {
        s << INDENT << "QString " << qt_name
          << " = " << QString("QString::fromUtf8((const char *)%1.ptr, %1.length);").arg(java_name) << endl;
    } else if (java_type->isJObjectWrapper()) {
        s << INDENT << "JObjectWrapper " << qt_name
          << " = qtjambi_to_jobjectwrapper(__jni_env, " << java_name << ");" << endl;
    } else if (java_type->isVariant()) {
        s << INDENT << "QVariant " << qt_name
          << " = " << java_name << " == NULL ? QVariant() : QVariant(*" << java_name << ");" << endl;
    } else if (java_type->isArray() && java_type->arrayElementType()->isPrimitive()) {
        AbstractMetaType *elementType = java_type->arrayElementType();

        // ### Don't assert on wrong array lengths
//        s << INDENT << "Q_ASSERT(__jni_env->GetArrayLength((jarray) " << java_name << ") == " << java_type->arrayElementCount() << ");" << endl;
        s << INDENT;
        writeTypeInfo(s, elementType);
        s << " *" << qt_name << " = (";
        writeTypeInfo(s, elementType);
        s << "*) " << java_name << ";" << endl;
/*
        s << INDENT << "__jni_env->" << getXxxArrayRegion(elementType) << "( (" << translateType(java_type, options)
          << ")" << java_name << ", 0, " << java_type->arrayElementCount() << ", "
          << "(" << translateType(elementType, options) << " *" << ")"
          << qt_name << ");" << endl;
*/
    } else if (java_type->isArray()) {
        AbstractMetaType *elementType = java_type->arrayElementType();

        s << INDENT << "Q_ASSERT(__jni_env->GetArrayLength((jarray) " << java_name << ") == " << java_type->arrayElementCount() << ");" << endl;
        writeTypeInfo(s, elementType);
        s << "[" << java_type->arrayElementCount() << "]" << qt_name << ";" << endl;

        for (int i=0; i<java_type->arrayElementCount(); ++i) {
            writeJavaToQt(s, elementType, qt_name + "[" + QString::number(i) + "]",
                "__jni_env->GetObjectArrayElement(" + java_name + ", " + QString::number(i) + ")", 0, -1, options);
        }

    } else if (java_type->isTargetLangString()) {
        s << INDENT << "QString " << qt_name
          << " = " << "QString::fromUtf8(" << java_name << ", " << java_name << "_size);" << endl;
// qtd          << " =  qtjambi_to_qstring(__jni_env, (jstring) " << java_name << ");" << endl;

    } else if (java_type->isTargetLangChar()) {
        s << INDENT << "QChar " << qt_name
          << " = (ushort)" << java_name << ";" << endl;

    } else if (java_type->isEnum() || java_type->isFlags()) {

        bool written = false;
        if (java_type->isEnum()) {
            AbstractMetaEnum *java_enum =
                m_classes.findEnum(static_cast<const EnumTypeEntry *>(java_type->typeEntry()));
            if (java_enum && !java_enum->isPublic()) {

                s << INDENT << "int " << qt_name << " = ";
                written = true;
            }
        }

        if (!written) {
            QString qualified_name = java_type->typeEntry()->qualifiedCppName();
            s << INDENT << qualified_name << " " << qt_name
              << " = (" << qualified_name << ") ";
        }

        if ((options & EnumAsInts) == 0 && (java_type->isTargetLangEnum() || java_type->isTargetLangFlags())) {
            s << java_name << ";" << endl;

        } else if (options & BoxedPrimitive) {
            const PrimitiveTypeEntry *pentry = TypeDatabase::instance()->findTargetLangPrimitiveType("int");
            Q_ASSERT(pentry);

            s << java_name << ";" << endl;

        } else {
            s << java_name << ';' << endl;
        }

    } else if (java_type->isContainer()) {
        writeJavaToQtContainer(s, java_type, qt_name, java_name, 0, -1);

    } else if (java_type->isThread()) {
        s << INDENT << "QThread *" << qt_name << " = qtjambi_to_thread(__jni_env, " << java_name
          << ");" << endl;

    } else if (java_type->typeEntry()->isCustom()) {
        const CustomTypeEntry *custom_type =
            static_cast<const CustomTypeEntry *>(java_type->typeEntry());
        s << INDENT;
        custom_type->generateCppJavaToQt(s, java_type, "__jni_env", qt_name, java_name);
        s << ";" << endl;

    } else {

        const TypeEntry *type = java_type->typeEntry();
        QString class_name = type->name();
        QString qualified_class_name = fixCppTypeName(type->qualifiedCppName());

        // Declaration and the c-cast
        s << INDENT;
        writeTypeInfo(s, java_type);
        s << ' ' << qt_name << " = (";
        writeTypeInfo(s, java_type);
        s << ") ";

        if (java_type->isPrimitive()) {
            if (options & BoxedPrimitive) {
                const PrimitiveTypeEntry *pentry = static_cast<const PrimitiveTypeEntry *>(type);
//std::cout << "---error_here " << type->targetLangName().toStdString() << " \n";
//std::cout << "----func_here " << java_function->marshalledName().toStdString() << " \n";

                if (!pentry->preferredConversion())
                    pentry = TypeDatabase::instance()->findTargetLangPrimitiveType(pentry->targetLangName());
                Q_ASSERT(pentry);

                s << java_name << ";" << endl;

            } else if ((options & GlobalRefJObject) && type->jniName() == QLatin1String("jobject")) {
                s << "__jni_env->NewGlobalRef(" << java_name << ");" << endl;
            } else {
                s << java_name << ';' << endl;
            }

#if 0
        } else if (java_type->isEnum()) {
            s << "qtjambi_to_enum(__jni_env, " << java_name << ");" << endl;
#endif

        } else if ((java_type->isQObject() || java_type->isObject())
                   && static_cast<const ObjectTypeEntry *>(type)->designatedInterface()) {
/* qtd           const InterfaceTypeEntry *ie =
                static_cast<const ObjectTypeEntry *>(type)->designatedInterface();
            s << "qtjambi_to_interface(__jni_env, ";

            // This cast is only valid if we're dealing with a native id
            if ((options & UseNativeIds) == UseNativeIds)
                s << "(QtJambiLink *)";
*/
            s << java_name << ";" << endl;
/* qtd
            s << "\"" << ie->targetLangName() << "\", \""
              << ie->javaPackage().replace(".", "/") << "/\", "
              << "\"__qt_cast_to_" << type->targetLangName() << "\");" << endl;
*/
        } else if (java_type->isObject() || java_type->isQObject() || java_type->isNativePointer()) {
            if (java_type->isReference()) {
                s << "* (" << qualified_class_name << " "
                  << QString(java_type->actualIndirections(), '*') << ") ";
            }

            if (java_type->isNativePointer()) {
/* qtd                s << "qtjambi_to_cpointer("
                << "__jni_env, "
                << java_name << ", "
                << java_type->actualIndirections() << ");" << endl; */
                s << java_name << ";" << endl; // qtd
            }/* qtd else if (java_type->isQObject()) {
                if ((options & UseNativeIds) == 0)
                    s << "qtjambi_to_qobject(__jni_env, ";
                else
                    s << "qtjambi_from_jlong(";
                s << java_name;
                s << ");" << endl;
            }*/ else {
/* qtd                if ((options & UseNativeIds) == 0)
                    s << "qtjambi_to_object(__jni_env, ";
                else
                    s << "qtjambi_from_jlong(";
*/                s << java_name;
                s << ";" << endl; // +
// qtd                s << ");" << endl;
            }

        } else {
            // Return values...
            if (argument_index == 0) {
                s << "(" << java_name << " != 0 ? *(" << qualified_class_name << " *)";
/* qtd                if ((options & UseNativeIds) == 0)
                    s << "qtjambi_to_object(__jni_env, ";
                else
                    s << "qtjambi_from_jlong(";
*/                s << java_name;
                s << " : " << qualified_class_name << "());" << endl;
            } else {
                s << "*"
                  << "(" << qualified_class_name << " *)";
                bool null_check = false;
/* qtd               if ((options & UseNativeIds) == 0) {
                    s << "qtjambi_to_object(__jni_env, ";
                } else if (hasDefaultConstructor(java_type)) {
                    null_check = true;
                    s << "(" << java_name << " != 0 ? qtjambi_from_jlong(";
                } else {
                    s << "qtjambi_from_jlong(";
                }
*/                s << java_name;
// qtd                s << ")";

                if (null_check)
                    s << " : default_" << QString(qualified_class_name).replace("::", "_") << "())";
                s << ";" << endl;
            }

        }
    }
// qtd    s << INDENT << "QTJAMBI_EXCEPTION_CHECK(__jni_env);" << endl;
}

void CppImplGenerator::writeQtToJava(QTextStream &s,
                                     const AbstractMetaType *java_type,
                                     const QString &qt_name,
                                     const QString &java_name,
                                     const AbstractMetaFunction *java_function,
                                     int argument_index,
                                     Option option)
{

    // Conversion to Java: Native code for return values, shell code for arguments
    TypeSystem::Language lang = argument_index == 0 ? TypeSystem::NativeCode : TypeSystem::ShellCode;
/* qtd    if (java_function && writeConversionRule(s, lang, java_function, argument_index, qt_name, java_name))
        return;
*/
    if (java_type == 0) {
        QString warn = QString("no conversion possible for argument '%1' in function '%2::%3' for "
                               "language '%4'")
                               .arg(argument_index)
                               .arg(java_function->implementingClass()->name())
                               .arg(java_function->name())
                               .arg(int(lang));
        ReportHandler::warning(warn);
        return;
    }

    if (java_type->name() == "QModelIndex") {
        QString prefix = "*";
        if (option & BoxedPrimitive)
            s << INDENT << "QModelIndexAccessor tmp_index = qtd_from_QModelIndex(" << qt_name << ");" << endl
                    << INDENT << "QModelIndexAccessor *" << java_name << " = &tmp_index;" << endl;
        else
            s << INDENT << "*" << java_name << " = qtd_from_QModelIndex(" << qt_name << ");" << endl;

    } else if (java_type->typeEntry()->isStructInD()) {
        if (option & BoxedPrimitive) {
            s << INDENT << java_type->typeEntry()->name() << " *" << java_name << " = ("
              << java_type->typeEntry()->name() << " *) &" << qt_name << ";" << endl;
        } else {
            s << INDENT << "*" << java_name << " = " << qt_name << ";" << endl;
        }
    } else if (java_type->isArray() && java_type->arrayElementType()->isPrimitive()) {
        AbstractMetaType *elementType = java_type->arrayElementType();
/* qtd
        s << INDENT << translateType(java_type, option) << " " << java_name << " = __jni_env->" << newXxxArray(elementType)
          << "(" << java_type->arrayElementCount() << ");" << endl;

        s << INDENT << "__jni_env->" << setXxxArrayRegion(elementType) << "("
          << "(" << translateType(java_type, option) << ")" << java_name
          << ", 0, " << java_type->arrayElementCount() << ", "
          << "(" << translateType(elementType, option) << " *" << ")"
          << qt_name << ");" << endl;
*/
        s << INDENT << translateType(java_type, option) << " " << java_name << " = " << qt_name << ";" <<endl;
    } else if (java_type->isArray()) {
        AbstractMetaType *elementType = java_type->arrayElementType();

        s << INDENT << "jobject " << java_name << " = __jni_env->NewObjectArray("
          << java_type->arrayElementCount() << ");" << endl;

        s << "jobject __qt_element = 0;";

        for (int i=0; i<java_type->arrayElementCount(); ++i) {
            writeQtToJava(s, elementType, qt_name + "[" + QString::number(i) + "]",
                "__qt_element", 0, -1, option);
            s << "__jni_env->SetObjectArrayElement((jobjectArray) " << java_name << ", "
              << i << ", __qt_element);" << endl;
        }

    } else if (java_type->isPrimitive()) {
        const PrimitiveTypeEntry *type =
                static_cast<const PrimitiveTypeEntry *>(java_type->typeEntry());

        Q_ASSERT(type);
        QString ret_val;
        if (java_function)
            ret_val = jniReturnName(java_function);
        else
            ret_val = fixCppTypeName(java_type->typeEntry()->qualifiedCppName());
        s << INDENT << ret_val <<  " " << java_name << " = " << qt_name << ";" << endl;
    } else if (java_type->isJObjectWrapper()) {
        s << INDENT << "jobject " << java_name << " = qtjambi_from_jobjectwrapper(__jni_env, "
          << qt_name << ");" << endl;
    } else if (java_type->isVariant()) {
        s << INDENT << "QVariant *" << java_name
          << " = new QVariant(" << qt_name << ");" << endl;
    } else if (java_type->isTargetLangString()) {
        if(java_type->typeEntry()->qualifiedCppName() == "QStringRef") {
            s << INDENT << "const QString *str_ref = " << qt_name << ".string();" << endl
              << INDENT << "if(str_ref)" << endl
              << INDENT << "    qtd_toUtf8(str_ref->utf16(), str_ref->size(), " << java_name << ");" << endl
              << INDENT << "else {" << endl
              << INDENT << "    QString empty_str;" << endl
              << INDENT << "    qtd_toUtf8(empty_str.utf16(), empty_str.size(), " << java_name << ");" << endl
              << INDENT << "}" << endl;
        } else {
            s << INDENT << QString("qtd_toUtf8(%1.utf16(), %1.size(), %2);").arg(qt_name, java_name) << endl;
        }
    } else if (java_type->isTargetLangChar()) {
        s << INDENT << "jchar " << java_name << " = " << qt_name << ".unicode();" << endl;

    } else if (java_type->isIntegerEnum() || java_type->isIntegerFlags()
               || ((option & EnumAsInts) && (java_type->isEnum() || java_type->isFlags()))) {
//     } else if (java_type->isEnum() || java_type->isFlags()) {

//         if (option & EnumAsInts) {
//             qDebug() << java_type->name() << "should be int...";
//         }

/*        if (option & BoxedPrimitive) {
            s << INDENT << "jobject " << java_name << " = qtjambi_from_int(__jni_env, "
            << qt_name << ");" << endl;
        } else */{
            s << INDENT << "int " << java_name << " = " << qt_name << ";" << endl;
        }

    } else if (java_type->isTargetLangEnum()) {
        Q_ASSERT((option & EnumAsInts) == 0);
        const EnumTypeEntry *et = static_cast<const EnumTypeEntry *>(java_type->typeEntry());
        s << INDENT << "int " << java_name << " = " << qt_name << ";" << endl;

    } else if (java_type->isTargetLangFlags()) {
        Q_ASSERT((option & EnumAsInts) == 0);
        const FlagsTypeEntry *ft = static_cast<const FlagsTypeEntry *>(java_type->typeEntry());
        s << INDENT << "jobject " << java_name << " = qtjambi_from_flags(__jni_env, "
          << qt_name << ", \"" << ft->javaPackage().replace('.', '/') << '/'
          << ft->originator()->javaQualifier() << '$' << ft->targetLangName() << "\");" << endl;

    } else if (java_type->isContainer()) {
        writeQtToJavaContainer(s, java_type, qt_name, java_name, 0, -1);

    } else if (java_type->isThread()) {
        s << INDENT << "jobject " << java_name << " = qtjambi_from_thread(__jni_env, " << qt_name
          << ");" << endl;

    } else if (!java_type->isNativePointer() && java_type->typeEntry()->isCustom()) {
        s << INDENT;
        static_cast<const CustomTypeEntry *>(java_type->typeEntry())
            ->generateCppQtToJava(s, java_type, "__jni_env", qt_name, java_name);
        s << ";" << endl;

    } else {
        QString return_type;
        if (java_function)
            return_type = jniReturnName(java_function);
        else {
            return_type = jniReturnType(java_type);
            return_type = fixCppTypeName(return_type);
//            return_type = fixCppTypeName(java_type->typeEntry()->qualifiedCppName());
        }
/*        if( (java_type->isValue() && !java_type->typeEntry()->isStructInD())
            || java_type->isObject() )
            s << INDENT << return_type << " *" << java_name << " = (" << return_type << "*) ";
        else*/
            s << INDENT << return_type << " " << java_name << " = (" << return_type << ") ";

        if (java_type->isQObject()) {
/* qtd            s << "qtjambi_from_qobject(__jni_env, " << "(QObject *) ";

            if (java_type->isReference() && java_type->indirections() == 0)
                s << "&";

            s << qt_name
              << ", \"" << java_type->typeEntry()->lookupName() << "\""
              << ", \"" << java_type->package().replace(".", "/") << "/\""
              << ");" << endl;
*/
            s << qt_name << ";" << endl;

#if 0
        } else if (java_type->isEnum()) {

            const EnumTypeEntry *et = static_cast<const EnumTypeEntry *>(java_type->typeEntry());
            s << "qtjambi_from_enum(__jni_env, " << qt_name << ", \""
              << et->javaQualifier() << "$" << et->targetLangName() << "\");" << endl;
#endif
        } else if (java_type->isNativePointer()) {
/* qtd            s << "qtjambi_from_cpointer(__jni_env, ";
            if (java_type->isReference())
                s << "&";
            s << qt_name << ", " << nativePointerType(java_type) << ", "
              << java_type->actualIndirections() << ");" << endl;
*/
            if (java_type->isReference())
                s << "&";
            s << qt_name << ";" << "// qtjambi_from_cpointer" << endl;
        } else if (java_type->isValue()) {
// qtd            s << fromObject(java_type->typeEntry(), "&" + qt_name) << endl;
            s << "new " << java_type->typeEntry()->qualifiedCppName() << "(" << qt_name << ");" << endl;
        } else {
// qtd            s << fromObject(java_type->typeEntry(),
// qtd                            (java_type->isReference() ? "&" : "") + qt_name) << endl;
            if (java_type->isReference())
                s << "&";
            s << qt_name << ";" << endl;
        }
    }

}

QString CppImplGenerator::getTypeName(const TypeEntry *entry, Option option)
{
    if(entry->isEnum() && (option & EnumAsInts))
        return "int";

    return entry->lookupName();
}

void CppImplGenerator::writeQtToJavaContainer(QTextStream &s,
                                              const AbstractMetaType *java_type,
                                              const QString &qt_name,
                                              const QString &java_name,
                                              const AbstractMetaFunction *java_function,
                                              int argument_index)
{
    // Language for conversion to Java: Native code for return values and Shell code for arguments
    TypeSystem::Language lang = argument_index == 0 ? TypeSystem::NativeCode : TypeSystem::ShellCode;
    if (java_function && writeConversionRule(s, lang, java_function, argument_index, qt_name, java_name))
        return;

    if (java_type == 0) {
        QString warn = QString("no conversion possible for argument '%1' in function '%2::%3' for "
                               "language '%4'")
                               .arg(argument_index)
                               .arg(java_function->implementingClass()->name())
                               .arg(java_function->name())
                               .arg(int(lang));
        ReportHandler::warning(warn);
        return;
    }

    Q_ASSERT(java_type->isContainer());
    const ContainerTypeEntry *type =
        static_cast<const ContainerTypeEntry *>(java_type->typeEntry());

    if (type->type() == ContainerTypeEntry::VectorContainer
        || type->type() == ContainerTypeEntry::LinkedListContainer
        || type->type() == ContainerTypeEntry::StackContainer
        || type->type() == ContainerTypeEntry::SetContainer
        || type->type() == ContainerTypeEntry::QueueContainer) {

        Q_ASSERT(java_type->instantiations().size() == 1);
        AbstractMetaType *targ = java_type->instantiations().first();

        QString cls_name = getTypeName(targ->typeEntry(), EnumAsInts);
        cls_name.remove("_ConcreteWrapper");

        s << endl
          << INDENT;

        switch (type->type()) {
        case ContainerTypeEntry::LinkedListContainer:
        case ContainerTypeEntry::QueueContainer:
            s << "qtjambi_linkedlist_new(__jni_env)";
            break;
        case ContainerTypeEntry::StackContainer:
            s << "qtjambi_stack_new(__jni_env)";
            break;
        case ContainerTypeEntry::SetContainer:
            s << "qtjambi_hashset_new(__jni_env)";
            break;
        default:
            s << "qtd_allocate_" << cls_name
              << "_array(" << java_name << ", " << qt_name << ".size())";
            break;
        }

        s << ";" << endl
          << INDENT;


        writeTypeInfo(s, java_type, ForceValueType);
        QString index = "i_" + qt_name;
        s << "::const_iterator " << qt_name << "_end_it = " << qt_name << ".constEnd();" << endl
          << INDENT << QString("int %0 = 0;").arg(index) << endl
          << INDENT;
        s << "for (";
        writeTypeInfo(s, java_type, ForceValueType);
        s << "::const_iterator " << qt_name << "_it = " << qt_name << ".constBegin(); "
          << qt_name << "_it != " << qt_name << "_end_it; ++" << qt_name << "_it) {" << endl;
        {
            Indentation indent(INDENT);
            s << INDENT;
            writeTypeInfo(s, targ);
            s << " __qt_tmp = *" << qt_name << "_it;" << endl;

            if(targ->isTargetLangString())
                s << INDENT << "void *__java_tmp = qtd_string_from_array(" << java_name << ", " << index << ");" << endl;

            writeQtToJava(s, targ, "__qt_tmp", "__java_tmp", 0, -1, BoxedPrimitive);

            s << INDENT << "qtd_assign_" << cls_name << "_array_element(" << java_name << ", " << index << ", __java_tmp);" << endl;
            s << INDENT << "++" << index << ";" << endl;
        }
        s << INDENT << "}" << endl;

    } else if (type->isQList()) {
//            QList<QObject*> & list2 = (*(QList<QObject*> *)nativeId);
        writeTypeInfo(s, java_type, ForceValueType);
        s << "&" << java_name << "_tmp = (*(";
        writeTypeInfo(s, java_type, ForceValueType);
        s << "*)" <<  java_name << ");" << endl
          << INDENT << java_name << "_tmp = " << qt_name << ";" << endl;

    } else if (type->type() == ContainerTypeEntry::PairContainer) {
        QList<AbstractMetaType *> args = java_type->instantiations();
        Q_ASSERT(args.size() == 2);

        s << INDENT << "jobject " << java_name << ";" << endl
          << INDENT << "{" << endl;
        {
            Indentation indent(INDENT);
            writeQtToJava(s, args.at(0), qt_name + ".first", "__java_tmp_first", 0, -1, BoxedPrimitive);
            writeQtToJava(s, args.at(1), qt_name + ".second", "__java_tmp_second", 0, -1, BoxedPrimitive);
            s << INDENT << java_name << " = qtjambi_pair_new(__jni_env, "
              << "__java_tmp_first, __java_tmp_second);" << endl;
        }

        s << INDENT << "}" << endl;

    } else if (type->type() == ContainerTypeEntry::MultiMapContainer) {

        Q_ASSERT(java_type->instantiations().size() == 2);
        AbstractMetaType *targ_key = java_type->instantiations().at(0);
        AbstractMetaType *targ_val = java_type->instantiations().at(1);

        s << endl
          << INDENT << "jobject " << java_name << " = qtjambi_treemap_new(__jni_env, " << qt_name << ".keys().size());" << endl
          << INDENT << "QList<";
        writeTypeInfo(s, targ_key);
        s << "> __qt_keys = " << qt_name << ".keys();" << endl
          << INDENT << "for (int i=0; i<__qt_keys.size(); ++i) {" << endl;
        {
            Indentation indent(INDENT);

            s << INDENT;
            writeTypeInfo(s, targ_key);
            s << " __qt_tmp_key = __qt_keys.at(i);" << endl;
            writeQtToJava(s, targ_key, "__qt_tmp_key", "__java_tmp_key", 0, -1, BoxedPrimitive);

            s << INDENT << "QList<";
            writeTypeInfo(s, targ_val);
            s << "> __qt_values = " << qt_name << ".values(__qt_tmp_key);" << endl
              << INDENT << "jobject __java_value_list = qtjambi_arraylist_new(__jni_env, __qt_values.size());" << endl
              << INDENT << "for (int j=0; j<__qt_values.size(); ++j) {" << endl;
            {
                Indentation indent(INDENT);

                s << INDENT;
                writeTypeInfo(s, targ_val);
                s << " __qt_tmp_val = __qt_values.at(j);" << endl;
                writeQtToJava(s, targ_val, "__qt_tmp_val", "__java_tmp_val", 0, -1, BoxedPrimitive);

                s << INDENT << "qtjambi_collection_add(__jni_env, __java_value_list, __java_tmp_val);" << endl;
            }
            s << INDENT << "}" << endl
              << INDENT << "qtjambi_map_put(__jni_env, " << java_name << ", __java_tmp_key, __java_value_list);" << endl;
        }
        s << INDENT << "}" << endl;

    } else if (type->type() == ContainerTypeEntry::MapContainer
               || type->type() == ContainerTypeEntry::HashContainer) {
        QString constructor = type->type() == ContainerTypeEntry::MapContainer
                              ? "qtjambi_treemap_new"
                              : "qtjambi_hashmap_new";

        Q_ASSERT(java_type->instantiations().size() == 2);
        AbstractMetaType *targ_key = java_type->instantiations().at(0);
        AbstractMetaType *targ_val = java_type->instantiations().at(1);

        s << endl
          << INDENT << "jobject " << java_name << " = " << constructor << "(__jni_env, " << qt_name
          << ".size());" << endl
          << INDENT;
        writeTypeInfo(s, java_type, Option(ExcludeReference | ExcludeConst));
        s << "::const_iterator it;" << endl
          << INDENT << "for (it=" << qt_name << ".constBegin(); it!=" << qt_name << ".constEnd(); ++it) {" << endl;
        {
            Indentation indent(INDENT);
            s << INDENT;
            writeTypeInfo(s, targ_key);
            s << " __qt_tmp_key = it.key();" << endl
              << INDENT;
            writeTypeInfo(s, targ_val);
            s << " __qt_tmp_val = it.value();" << endl;
            writeQtToJava(s, targ_key, "__qt_tmp_key", "__java_tmp_key", 0, -1, BoxedPrimitive);
            writeQtToJava(s, targ_val, "__qt_tmp_val", "__java_tmp_val", 0, -1, BoxedPrimitive);
            s << INDENT << "qtjambi_map_put(__jni_env, " << java_name
              << ", __java_tmp_key, __java_tmp_val);" << endl;
        }
        s << INDENT << "}" << endl;

    } else {
        ReportHandler::warning(QString("unable to generate container type %1, type=%2")
                               .arg(java_type->name()).arg(type->type()));
    }

// qtd    s << INDENT << "QTJAMBI_EXCEPTION_CHECK(__jni_env);" << endl;
}


void CppImplGenerator::writeJavaToQtContainer(QTextStream &s,
                                              const AbstractMetaType *java_type,
                                              const QString &qt_name,
                                              const QString &java_name,
                                              const AbstractMetaFunction *java_function,
                                              int argument_index)
{
    // Conversion to C++: Shell code for return value, native code for arguments
    TypeSystem::Language lang = argument_index == 0 ? TypeSystem::ShellCode : TypeSystem::NativeCode;
    if (java_function && writeConversionRule(s, lang, java_function, argument_index, qt_name, java_name))
        return;

    if (java_type == 0) {
        QString warn = QString("no conversion possible for argument '%1' in function '%2::%3' for "
                               "language '%4'")
                               .arg(argument_index)
                               .arg(java_function->implementingClass()->name())
                               .arg(java_function->name())
                               .arg(int(lang));
        ReportHandler::warning(warn);
        return;
    }


    Q_ASSERT(java_type->isContainer());
    const ContainerTypeEntry *type =
        static_cast<const ContainerTypeEntry *>(java_type->typeEntry());

    if (type->type() == ContainerTypeEntry::VectorContainer
        || type->type() == ContainerTypeEntry::LinkedListContainer
        || type->type() == ContainerTypeEntry::StackContainer
        || type->type() == ContainerTypeEntry::SetContainer
        || type->type() == ContainerTypeEntry::QueueContainer) {
        Q_ASSERT(java_type->instantiations().size() == 1);
        AbstractMetaType *targ = java_type->instantiations().first();
        QString elem_type = getTypeName(targ->typeEntry(), EnumAsInts);
        elem_type.remove("_ConcreteWrapper");

        s << INDENT;
        writeTypeInfo(s, java_type, ForceValueType);
        s << qt_name << ";" << endl;

        {
            if (type->type() == ContainerTypeEntry::VectorContainer
                || type->type() == ContainerTypeEntry::StackContainer)
                s << INDENT << qt_name << ".reserve(" << java_name << "->length);" << endl;

            s << INDENT << "for (int i=0; i<" << java_name << "->length; ++i) {" << endl;
            {
                Indentation indent(INDENT);
                if(targ->isTargetLangString())
                    s << INDENT << "DArray __d_element;" << endl
                      << INDENT << "qtd_get_string_from_array(" << java_name << "->ptr, i, &__d_element);" << endl;
                else {
                    s << INDENT;
                    writeTypeInfo(s, targ, Option(VirtualDispatch | ForcePointer | EnumAsInts));
                    QString cast_string = "";
                    const TypeEntry* centry = targ->typeEntry();
                    if (centry->isComplex() && (centry->isObject() || centry->isValue() || centry->isInterface()))
                        cast_string = "(void**)";
                    s << "__d_element;" << endl
                      << INDENT << "qtd_get_" << elem_type << "_from_array(" << java_name << ", i, &__d_element);" << endl;
                }
                writeJavaToQt(s, targ, "__qt_element", "__d_element", 0, -1, BoxedPrimitive);
                QString cont_element = "__qt_element";
                if(targ->typeEntry()->isStructInD() && targ->name() != "QModelIndex")
                    cont_element = "__d_element";
                s << INDENT << qt_name << " << " << cont_element << ";" << endl;
            }
// qtd            s << INDENT << "}" << endl;
        }
        s << INDENT << "}" << endl;
    } else if (type->isQList()) {
        writeTypeInfo(s, java_type, ForceValueType);
        s << qt_name << " = (*(";
        writeTypeInfo(s, java_type, ForceValueType);
        s << "*)" <<  java_name << ");" << endl;
    } else if (type->type() == ContainerTypeEntry::PairContainer) {
        QList<AbstractMetaType *> targs = java_type->instantiations();
        Q_ASSERT(targs.size() == 2);

        s << INDENT;
        writeTypeInfo(s, java_type, ForceValueType);
        s << " " << qt_name << ";" << endl
          << INDENT << "if (" << java_name << " != 0) {" << endl;
        {
            // separate scope required just in case function takes two QPair's.
            Indentation indent(INDENT);
            s << INDENT << "jobject __java_first = qtjambi_pair_get(__jni_env, "
              << java_name << ", 0);" << endl;
            writeJavaToQt(s, targs.at(0), "__qt_first", "__java_first", 0, -1, BoxedPrimitive);

            s << INDENT << "jobject __java_second = qtjambi_pair_get(__jni_env, "
              << java_name << ", 1);" << endl;
            writeJavaToQt(s, targs.at(1), "__qt_second", "__java_second", 0, -1, BoxedPrimitive);

            s << INDENT << qt_name << ".first = __qt_first;" << endl
              << INDENT << qt_name << ".second = __qt_second;" << endl;
        }
        s << INDENT << "}" << endl;
    } else if (type->type() == ContainerTypeEntry::MapContainer
               || type->type() == ContainerTypeEntry::HashContainer) {
        Q_ASSERT(java_type->instantiations().size() == 2);
        AbstractMetaType *targ_key = java_type->instantiations().at(0);
        AbstractMetaType *targ_val = java_type->instantiations().at(1);

        s << INDENT;
        writeTypeInfo(s, java_type, ForceValueType);
        s << qt_name << ";" << endl;
        s << INDENT << "if (" << java_name << " != 0) {" << endl;
        {
            Indentation indent(INDENT);
            s << INDENT << "int __qt_list_size = qtjambi_map_size(__jni_env, " << java_name
              << ");" << endl
              << INDENT
              << "jobjectArray __java_entry_set = qtjambi_map_entryset_array(__jni_env, " << java_name
              << ");" << endl;

            s << INDENT << "for (int i=0; i<__qt_list_size; ++i) {" << endl;
            {
                Indentation indent(INDENT);
                s << INDENT
                  << "QPair<jobject, jobject> __java_entry = "
                  << "qtjambi_entryset_array_get(__jni_env, __java_entry_set, i);"
                  << endl
                  << INDENT << "jobject __java_key = __java_entry.first;" << endl
                  << INDENT << "jobject __java_val = __java_entry.second;" << endl;
                writeJavaToQt(s, targ_key, "__qt_key", "__java_key", 0, -1, BoxedPrimitive);
                writeJavaToQt(s, targ_val, "__qt_val", "__java_val", 0, -1, BoxedPrimitive);
                s << INDENT << qt_name << ".insert(__qt_key, __qt_val);" << endl;
            }
            s << INDENT << "}" << endl;
        }
        s << INDENT << "}" << endl;

    } else {
        ReportHandler::warning(QString("unable to generate container type %1, %2")
                               .arg(java_type->name()).arg(type->type()));
    }

}


void CppImplGenerator::writeFunctionCall(QTextStream &s, const QString &object_name,
                                         const AbstractMetaFunction *java_function,
                                         const QString &prefix,
                                         Option option,
                                         const QStringList &extra_arguments)
{
    QString function_name = option & OriginalName ? java_function->originalName() : java_function->name();

    AbstractMetaClassList interfaces = java_function->implementingClass()->interfaces();

    QString classPrefix;
    if (prefix.isEmpty()
        && !java_function->implementingClass()->interfaces().isEmpty()
        && !java_function->implementingClass()->inheritsFrom(java_function->declaringClass())) {
        classPrefix = java_function->declaringClass()->qualifiedCppName() + "::";
    }

    if (java_function->isInGlobalScope()) {

        // Global scope stream operators need the arguments to be reordered (this ref at end)
        // so we special case them in order to simplify this code
        bool stream_operator = java_function->originalName() == "operator<<"
                               || java_function->originalName() == "operator>>";

        if (java_function->type() == 0)
            s << "if (" << object_name << " != 0) ";
        else
            s << "(" << object_name << " != 0) ? ";
        s << "::" << prefix << function_name << "(";
        if (!stream_operator)
            s << "*" << object_name << ", ";
        writeFunctionCallArguments(s, java_function, "__qt_");
        if (stream_operator)
            s << ", *" << object_name;
        s << ")";
        if (java_function->type() != 0)
            s << " : " << default_return_statement_qt(java_function->type(), Generator::Option(option | Generator::NoReturnStatement));
        s << ";";
    } else {
        s << object_name << (java_function->isStatic() ? QLatin1String("::") : QLatin1String("->") + classPrefix)
          << prefix << function_name << "(";
        writeFunctionCallArguments(s, java_function, "__qt_");

        // The extra arguments...
        for (int i=0; i<extra_arguments.size(); ++i) {
            if (i > 0 || java_function->arguments().size() != 0)
                s << ", ";
            s << extra_arguments.at(i);
        }

        s << ");";
    }

    s << endl;

}


void CppImplGenerator::writeFunctionCallArguments(QTextStream &s,
                                                  const AbstractMetaFunction *java_function,
                                                  const QString &prefix,
                                                  Option options)
{
    AbstractMetaArgumentList arguments = java_function->arguments();

    int written_arguments = 0;
    const AbstractMetaClass *cls = java_function->ownerClass();
    if (java_function->isConstructor() && cls->isPolymorphic()) {
        s << "d_ptr";
        written_arguments++;
    }
    for (int i=0; i<arguments.size(); ++i) {
        const AbstractMetaArgument *argument = arguments.at(i);
        AbstractMetaType *a_type = argument->type();

        if ((options & SkipRemovedArguments) == SkipRemovedArguments
            && java_function->argumentRemoved(i+1)) {
            continue;
        }

        if (written_arguments++ > 0) {
            s << ", ";
        }

        bool enum_as_int = (options & EnumAsInts) && (argument->type()->typeEntry()->isEnum()
                                                      || argument->type()->typeEntry()->isFlags());
        if (a_type->isEnum()) {
            AbstractMetaEnum *java_enum =
                m_classes.findEnum(static_cast<const EnumTypeEntry *>(argument->type()->typeEntry()));
            if (java_enum == 0) {
                ReportHandler::warning(QString("enum not found: '%1'")
                    .arg(argument->type()->typeEntry()->qualifiedCppName()));
            } else {
                enum_as_int |= !java_enum->isPublic();
            }
        }

        if ( (options & VirtualDispatch)
             && a_type->isContainer()) {
            if ( ((const ContainerTypeEntry *)a_type->typeEntry())->isQList() )
                s << "(void*)&" <<  argument->indexedName();
            else
                s << "__d_" << argument->indexedName();
            continue;
        }

        if ((!(options & NoCasts) && !enum_as_int) || ((options & ForceEnumCast) && a_type->isEnum())) {

            // If the type in the signature is specified without template instantiation, but the
            // class is actually a template class, then we have troubles.
            AbstractMetaClass *cls = classes().findClass(argument->type()->typeEntry()->qualifiedCppName());

            if ( (options & VirtualDispatch) && !a_type->typeEntry()->isStructInD()
                  && ( a_type->isValue()
                       || (a_type->isReference() && (a_type->typeEntry()->isValue() || a_type->typeEntry()->isObject() || a_type->typeEntry()->isPrimitive()) && !a_type->isTargetLangString())
                       ) )
                s << "&";

            if( (options & VirtualDispatch) && a_type->typeEntry()->isStructInD() && a_type->isReference())
                s << "&";

            if ( (options & VirtualDispatch)
                 && ( a_type->isTargetLangString() || a_type->name() == "QModelIndex" ) )
                ;
            else if (cls == 0 || cls->templateArguments().size() == a_type->instantiations().size()) {
                s << "(";
                writeTypeInfo(s, a_type, options);
                s << ")";
            }
        }

        if (a_type->isNativePointer() && a_type->typeEntry()->name() == "QString" && !a_type->isReference())
            s << "&";

        if ( ( !a_type->isPrimitive()
            || !java_function->conversionRule(TypeSystem::NativeCode, argument->argumentIndex()+1).isEmpty() )
             && (!a_type->typeEntry()->isStructInD() || a_type->name() == "QModelIndex") ) {
            s << prefix;
        }

        if (options & VirtualDispatch) {
            if( argument->type()->isTargetLangString())
                s << argument->indexedName() << ".utf16(), " << argument->indexedName() << ".size()";
            else if (argument->type()->name() == "QModelIndex")
                s << "qtd_from_QModelIndex(" << argument->indexedName() << ")";
            else
                s << argument->indexedName();
        } else
            s << argument->indexedName();
    }
}


QString CppImplGenerator::translateType(const AbstractMetaType *java_type, Option option, bool d_export)
{
    if (!java_type)
        return "void";

    const TypeEntry *type = java_type->typeEntry();
    QString class_name = type->name();
    QString qualified_class_name = fixCppTypeName(type->qualifiedCppName());
    QString d_name = qualified_class_name;
    if (d_export)
        d_name = type->lookupName();

    if (java_type->isPrimitive()
        || java_type->isTargetLangString()
        || java_type->isVariant()
        || java_type->isJObjectWrapper()
        || java_type->isTargetLangChar()) {
        return d_name;
    } else if (java_type->isArray()) {
        if (d_export)
            return java_type->arrayElementType()->name() + "*";
        else
            return java_type->arrayElementType()->typeEntry()->qualifiedCppName() + "*";
    } else if (java_type->isIntegerEnum() || java_type->isIntegerFlags()
        || ((option & EnumAsInts) && (java_type->isEnum() || java_type->isFlags()))) {
        return "int";
    } else if (java_type->isReference()) {
        if (java_type->typeEntry()->isValue())
            return "void*";
        else
            return d_name + " "+ QString(java_type->actualIndirections(), '*');
    } else if (java_type->isNativePointer()) {
        if (java_type->typeEntry()->isStructInD() && global.dVersion == 2 && java_type->isConstant() && d_export)
            return "const(" + d_name + QString(java_type->indirections()-1, '*') + ")*";
        else if (java_type->typeEntry()->isValue())
            return "void*";
        else if (java_type->typeEntry()->isEnum() && d_export)
            return "int" + QString(java_type->indirections(), '*');
        else {
            if (java_type->isConstant() && global.dVersion == 2 && d_export)
                return "const (" + d_name + QString(java_type->indirections(), '*') + ")";
            else
                return d_name + QString(java_type->indirections(), '*');
        }
    } else {
        return d_name + QString(java_type->indirections(), '*');
    }
}

void CppImplGenerator::writeExtraIncludes(QTextStream &s, const AbstractMetaClass *java_class)
{
    IncludeList includes = java_class->typeEntry()->extraIncludes();
    qSort(includes.begin(), includes.end());

    int used = 0;
    foreach (const Include &i, includes) {
        if (i.type != Include::TargetLangImport) {
            s << i.toString() << endl;
            ++used;
        }
    }


    if (used)
        s << endl;

}


void CppImplGenerator::writeDefaultConstructedValues_helper(QSet<QString> &values,
                                                            const AbstractMetaFunction *func)
{
    foreach (AbstractMetaArgument *arg, func->arguments()) {
        AbstractMetaType *type = arg->type();
        if (func->typeReplaced(arg->argumentIndex()+1).isEmpty() && type->isValue() && hasDefaultConstructor(type))
            values << type->typeEntry()->qualifiedCppName();
    }
}


void CppImplGenerator::writeDefaultConstructedValues(QTextStream &s, const AbstractMetaClass *java_class) {

    QSet<QString> values;

    // Class functions, more or less copied from the logic in write(Class) above...
    AbstractMetaFunctionList class_funcs;

    // Add normal final functions
    foreach (AbstractMetaFunction *function, java_class->functionsInTargetLang()) {
        if (!function->isEmptyFunction())
            class_funcs << function;
    }

    // Add abstract functions, I think...
    foreach (AbstractMetaFunction *function, java_class->queryFunctions(AbstractMetaClass::NormalFunctions
                                                                        | AbstractMetaClass::AbstractFunctions
                                                                        | AbstractMetaClass::NotRemovedFromTargetLang)) {
        if (function->implementingClass() != java_class)
            class_funcs << function;
    }

    // Signals (their c++ wrapper calls actually...)
    class_funcs += java_class->queryFunctions(AbstractMetaClass::Signals);

    //
    foreach (AbstractMetaFunction *f, class_funcs) {
        writeDefaultConstructedValues_helper(values, f);
    }

    foreach (AbstractMetaField *field, java_class->fields()) {
        writeDefaultConstructedValues_helper(values, field->setter());
    }

    if (!values.isEmpty()) {
        s << endl << endl
          << "// Default constructed values used throughout final functions..." << endl;
        for (QSet<QString>::const_iterator it = values.constBegin(); it != values.constEnd(); ++it) {
            s << "Q_GLOBAL_STATIC(" << *it << ", default_" << QString(*it).replace("::", "_")
              << ");" << endl;
        }
        s << endl << endl;
    }
}

