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
#include "dgenerator.h"
#include "reporthandler.h"
#include "docparser.h"
#include "jumptable.h"
#include "fileout.h"

#include <QtCore/QDir>
#include <QtCore/QTextStream>
#include <QtCore/QVariant>
#include <QtCore/QRegExp>
#include <QDebug>

#include <iostream>


static Indentor INDENT;

DGenerator::DGenerator()
    : m_doc_parser(0),
      m_docs_enabled(false),
      m_native_jump_table(false),
      m_recursive(0),
      m_isRecursive(false)
{
    excludedTypes << "qint64" << "bool" << "int" << "QString" << "char" << "WId"
                  << "unsigned char" << "uint" << "double" << "short" << "float"
                  << "signed char" << "unsigned short" << "QBool" << "unsigned int"
                  << "Qt::HANDLE" << "QChar" << "java.lang.JObjectWrapper" << "void"
                  << "QLatin1String" << "unsigned long long" << "signed int"
                  << "signed short" << "Array" << "GLuint" << "GLenum" << "GLint"
                  << "unsigned long" << "ulong" << "long" << "QByteRef"
                  << "QStringList" << "QVector" << "QPair"
                  << "QSet" << "QStringRef" << "quintptr" << "size_t";
}

QString DGenerator::fileNameForClass(const AbstractMetaClass *d_class) const
{
    return QString("%1.d").arg(d_class->name());
}

void DGenerator::writeFieldAccessors(QTextStream &s, const AbstractMetaField *field)
{
    Q_ASSERT(field->isPublic() || field->isProtected());

    const AbstractMetaClass *declaringClass = field->enclosingClass();

    FieldModification mod = declaringClass->typeEntry()->fieldModification(field->name());

    // Set function
    if (mod.isWritable() && !field->type()->isConstant()) {
        const AbstractMetaFunction *setter = field->setter();
        if (declaringClass->hasFunction(setter)) {
            QString warning =
                QString("class '%1' already has setter '%2' for public field '%3'")
                .arg(declaringClass->name()).arg(setter->name()).arg(field->name());
            ReportHandler::warning(warning);
        } else {
            if (!notWrappedYet(setter)) // qtd2
                writeFunction(s, setter);
        }
    }

    // Get function
    const AbstractMetaFunction *getter = field->getter();
    if (mod.isReadable()) {
        if (declaringClass->hasFunction(getter)) {
            QString warning =
                QString("class '%1' already has getter '%2' for public field '%3'")
                .arg(declaringClass->name()).arg(getter->name()).arg(field->name());
            ReportHandler::warning(warning);
        } else {
            if (!notWrappedYet(getter)) // qtd2
                writeFunction(s, getter);
        }
    }
}

QString DGenerator::translateType(const AbstractMetaType *d_type, const AbstractMetaClass *context, Option option)
{
    QString s;

    if (context != 0 && d_type != 0 && context->typeEntry()->isGenericClass() && d_type->originalTemplateType() != 0)
        d_type = d_type->originalTemplateType();

    QString constPrefix, constPostfix;
    if (d_type && d_type->isConstant() && global.dVersion == 2) {
        constPrefix = "const(";
        constPostfix = ")";
    }

    if (!d_type) {
        s = "void";
    } else if (d_type->typeEntry()->qualifiedCppName() == "QChar") {
        s = "wchar" + QString(d_type->actualIndirections(), '*');
    } else if (d_type->typeEntry() && d_type->typeEntry()->qualifiedCppName() == "QString") {
        s = "string";
    } else if (d_type->isArray()) {
        s = translateType(d_type->arrayElementType(), context) + "[]";
    } else if (d_type->isEnum() /* qtd2 || d_type->isFlags() */) {
        if (( d_type->isEnum() && ((EnumTypeEntry *)d_type->typeEntry())->forceInteger() )
            || ( d_type->isFlags() && ((FlagsTypeEntry *)d_type->typeEntry())->forceInteger() ) ) {
            if (option & BoxedPrimitive)
                s = "java.lang.Integer";
            else
                s = "int";
        } else {
            if (option & EnumAsInts)
                s = "int";
            else
            {
                // Hack around forward-referencing the implementing class in an interface.
                if (context->typeEntry()->designatedInterface() && d_type->typeEntry()->javaQualifier() == context->name())
                    s = d_type->name();
                else
                    s = d_type->typeEntry()->qualifiedTargetLangName();
            }

        }
    } else if (d_type->isFlags()) { // qtd2 begin
        if (d_type->isFlags() && ((FlagsTypeEntry *)d_type->typeEntry())->forceInteger()) {
            if (option & BoxedPrimitive)
                s = "java.lang.Integer";
            else
                s = "int";
        } else
            s = "int";
    } else {
/* qtd        if (d_type->isPrimitive() && (option & BoxedPrimitive)) {
            s = static_cast<const PrimitiveTypeEntry *>(d_type->typeEntry())->javaObjectName();
        } else */ if (d_type->isVariant()) {
            s = "QVariant";
        } else if (d_type->isNativePointer()) {
            if (d_type->typeEntry()->isValue() && !d_type->typeEntry()->isStructInD())
                s = d_type->typeEntry()->lookupName();
            else if (d_type->typeEntry()->isEnum())
                s = "int" + QString(d_type->actualIndirections(), '*');
            else
                s = constPrefix + d_type->typeEntry()->lookupName() + QString(d_type->actualIndirections(), '*') + constPostfix;
        } else if (d_type->isContainer()) {
            const ContainerTypeEntry* c_entry = static_cast<const ContainerTypeEntry*>(d_type->typeEntry());
            Q_ASSERT(c_entry);

            if ((option & SkipTemplateParameters) == 0) {
                QList<AbstractMetaType *> args = d_type->instantiations();
                const ContainerTypeEntry *cte =
                        static_cast<const ContainerTypeEntry *>(d_type->typeEntry());
                if (args.size() == 1) { // QVector or QList
                    if(cte->isQList())
                        s = "QList!(" + translateType(args.at(0), context, BoxedPrimitive) + ")";
                    else
                        s = translateType(args.at(0), context, BoxedPrimitive) + "[]";
                }
                else if(args.size() == 2) { // all sorts of maps
                    s = translateType(args.at(1), context, BoxedPrimitive); // value
                    bool isMultiMap = static_cast<const ContainerTypeEntry *>(d_type->typeEntry())->type() == ContainerTypeEntry::MultiMapContainer;
                    if (isMultiMap)
                        s += "[]";
                    s += "[" + translateType(args.at(0), context, BoxedPrimitive) + "]";
                } else {
                    s = d_type->typeEntry()->qualifiedTargetLangName();

                    for (int i=0; i<args.size(); ++i) {
                        if (i != 0)
                            s += ", ";
                        bool isMultiMap = static_cast<const ContainerTypeEntry *>(d_type->typeEntry())->type() == ContainerTypeEntry::MultiMapContainer
                                          && i == 1;
                        if (isMultiMap)
                            s += "java.util.List<";
                        s += translateType(args.at(i), context, BoxedPrimitive);
                        if (isMultiMap)
                            s += ">";
                    }
                    s += '>';
                }
            }

        } else {
            const TypeEntry *type = d_type->typeEntry();
            if (type->designatedInterface())
                type = type->designatedInterface();
            if (type->isString())
                s = "string";
            else if (type->isObject()) {
                s = type->name();
            } else if (type->isValue()){
                s = constPrefix + type->lookupName() + constPostfix;
            } else {
                s = type->lookupName();
            }
        }
    }

    return s;
}

QString DGenerator::argumentString(const AbstractMetaFunction *d_function,
                                      const AbstractMetaArgument *d_argument,
                                      uint options)
{
    QString modified_type = d_function->typeReplaced(d_argument->argumentIndex() + 1);
    QString arg;

    AbstractMetaType *type = d_argument->type();
    // qtd2 if argument is "QString &" ref attribute needed FIXME maybe we need this not only for QString, but for other Value types??
    if (type->typeEntry()->isValue() && type->isNativePointer() && type->typeEntry()->name() == "QString")
        arg = "ref ";

    if (modified_type.isEmpty())
        arg += translateType(d_argument->type(), d_function->implementingClass(), (Option) options);
    else
        arg += modified_type.replace('$', '.');

    if ((options & SkipName) == 0) {
        arg += " ";
        arg += d_argument->argumentName();
    }

    if (!d_argument->defaultValueExpression().isEmpty()) // qtd
        arg += " = " + d_argument->defaultValueExpression();

    return arg;
}

void DGenerator::writeArgument(QTextStream &s,
                                  const AbstractMetaFunction *d_function,
                                  const AbstractMetaArgument *d_argument,
                                  uint options)
{
    s << argumentString(d_function, d_argument, options);
}


void DGenerator::writeIntegerEnum(QTextStream &s, const AbstractMetaEnum *d_enum)
{
    const AbstractMetaEnumValueList &values = d_enum->values();

    s << "    public static class " << d_enum->name() << "{" << endl;
    for (int i=0; i<values.size(); ++i) {
        AbstractMetaEnumValue *value = values.at(i);

        if (d_enum->typeEntry()->isEnumValueRejected(value->name()))
            continue;

        if (m_doc_parser)
            s << m_doc_parser->documentation(value);

        s << "        public static final int " << value->name() << " = " << value->value();
        s << ";";
        s << endl;
    }

    s << "    } // end of enum " << d_enum->name() << endl << endl;
}

void DGenerator::writeEnumAliases(QTextStream &s, const AbstractMetaEnum *d_enum)
{
    const AbstractMetaEnumValueList &values = d_enum->values();
    for (int i=0; i<values.size(); ++i) {
        AbstractMetaEnumValue *enum_value = values.at(i);

        if (!d_enum->typeEntry()->isEnumValueRejected(enum_value->name()))
            s << INDENT << QString("alias %1.%2 %2;").arg(d_enum->name()).arg(enum_value->name()) << endl;
    }
    s << endl;
}

void DGenerator::writeEnum(QTextStream &s, const AbstractMetaEnum *d_enum, bool withAliases)
{
    if (m_doc_parser) {
        s << m_doc_parser->documentation(d_enum);
    }

    /* qtd

    if (d_enum->typeEntry()->forceInteger()) {
        writeIntegerEnum(s, d_enum);
        return;
    }

    // Check if enums in QObjects are declared in the meta object. If not
    if (  (d_enum->enclosingClass()->isQObject() || d_enum->enclosingClass()->isQtNamespace())
        && !d_enum->hasQEnumsDeclaration()) {
        s << "    @QtBlockedEnum" << endl;
    }
*/
    // Generates Java 1.5 type enums
    s << INDENT << "public enum " << d_enum->name() << " {" << endl;
    const AbstractMetaEnumValueList &values = d_enum->values();
    EnumTypeEntry *entry = d_enum->typeEntry();


    for (int i=0; i<values.size(); ++i) {
        Indentation indent(INDENT);
        AbstractMetaEnumValue *enum_value = values.at(i);

        if (d_enum->typeEntry()->isEnumValueRejected(enum_value->name()))
            continue;

        if (m_doc_parser)
            s << m_doc_parser->documentation(enum_value);

        s << INDENT << enum_value->name() << " = " << enum_value->value();

        if (i != values.size() - 1) {
            AbstractMetaEnumValue *next_value = values.at(i+1); // qtd
            if (!(d_enum->typeEntry()->isEnumValueRejected(next_value->name()) && i == values.size() - 2)) // qtd
                s << "," << endl;
        }
    }
/* qtd
    if (entry->isExtensible())
        s << "        CustomEnum = 0";
*/
    s << endl << INDENT << "}" << endl << endl; // qtd


/* qtd    s << ";" << endl << endl;

    s << "        " << d_enum->name() << "(int value) { this.value = value; }" << endl
      << "        public int value() { return value; }" << endl
      << endl;

    // Write out the createQFlags() function if its a QFlags enum
    if (entry->flags()) {
        FlagsTypeEntry *flags_entry = entry->flags();
        s << "        public static " << flags_entry->targetLangName() << " createQFlags("
          << entry->targetLangName() << " ... values) {" << endl
          << "            return new " << flags_entry->targetLangName() << "(values);" << endl
          << "        }" << endl;
    }

    // The resolve functions. The public one that returns the right
    // type and an internal one that has a generic signature. Makes it
    // easier to find the right one from JNI.
    s << "        public static " << d_enum->name() << " resolve(int value) {" << endl
      << "            return (" << d_enum->name() << ") resolve_internal(value);" << endl
      << "        }" << endl
      << "        private static Object resolve_internal(int value) {" << endl
      << "            switch (value) {" << endl;

    for (int i=0; i<values.size(); ++i) {
        AbstractMetaEnumValue *e = values.at(i);

        if (d_enum->typeEntry()->isEnumValueRejected(e->name()))
            continue;

        s << "            case " << e->value() << ": return " << e->name() << ";" << endl;
    }

    s << "            }" << endl;

    if (entry->isExtensible()) {
        s << "            if (enumCache == null)" << endl
          << "                enumCache = new java.util.HashMap<Integer, " << d_enum->name()
          << ">();" << endl
          << "            " << d_enum->name() << " e = enumCache.get(value);" << endl
          << "            if (e == null) {" << endl
          << "                e = (" << d_enum->name() << ") qt.GeneratorUtilities.createExtendedEnum("
          << "value, CustomEnum.ordinal(), " << d_enum->name() << ".class, CustomEnum.name());"
          << endl
          << "                enumCache.put(value, e);" << endl
          << "            }" << endl
          << "            return e;" << endl;
    } else {
        s << "            throw new qt.QNoSuchEnumValueException(value);" << endl;
    }


    s << "        }" << endl;

    s << "        private final int value;" << endl
      << endl;
    if (entry->isExtensible()) {
        s << "        private static java.util.HashMap<Integer, " << d_enum->name()
          << "> enumCache;";
    }
    s << "    }" << endl;
*/
    // Write out the QFlags if present...
/*    FlagsTypeEntry *flags_entry = entry->flags();
    if (flags_entry) {
        QString flagsName = flags_entry->targetLangName();
        s << INDENT << "alias QFlags!(" << d_enum->name() << ") " << flagsName << ";" << endl << endl;
    }*/

    if (withAliases)
        writeEnumAliases(s, d_enum);
}

void DGenerator::writePrivateNativeFunction(QTextStream &s, const AbstractMetaFunction *d_function)
{
    int exclude_attributes = AbstractMetaAttributes::Public | AbstractMetaAttributes::Protected;
    int include_attributes = 0;

    if (d_function->isEmptyFunction())
        exclude_attributes |= AbstractMetaAttributes::Native;
    else
        include_attributes |= AbstractMetaAttributes::Native;

//     if (!d_function->isConstructor())
//         include_attributes |= AbstractMetaAttributes::Static;

    writeFunctionAttributes(s, d_function, include_attributes, exclude_attributes,
                            EnumAsInts | ExternC
                            | (d_function->isEmptyFunction()
                               || d_function->isNormal()
                               || d_function->isSignal() ? 0 : SkipReturnType));

    if (d_function->isConstructor())
        s << "void* ";


    s << d_function->marshalledName();
/* qtd
    s << "(";

    AbstractMetaArgumentList arguments = d_function->arguments();

    if (!d_function->isStatic() && !d_function->isConstructor())
        s << "void *__this__nativeId";
    for (int i=0; i<arguments.count(); ++i) {
        const AbstractMetaArgument *arg = arguments.at(i);

        if (!d_function->argumentRemoved(i+1)) {
            if (i > 0 || (!d_function->isStatic() && !d_function->isConstructor()))
                s << ", ";

            if (!arg->type()->hasNativeId())
                writeArgument(s, d_function, arg, EnumAsInts);
            else
                s << "void *" << arg->argumentName();
        }
    }
    s << ")";
*/

    CppImplGenerator::writeFinalFunctionArguments(s, d_function, true); // qtd

    // Make sure people don't call the private functions
    // qtd remember name QNoImplementationException
    if (d_function->isEmptyFunction()) {
        s << endl
          << INDENT << "{" << endl
          << INDENT << "    throw new Exception(\"No Implementation Exception\");" << endl
          << INDENT << "}" << endl << endl;
    } else {
        s << ";" << endl;
    }
}

static QString function_call_for_ownership(TypeSystem::Ownership owner)
{
    if (owner == TypeSystem::CppOwnership) {
        return "qtdSetOwnership(QtdObjectOwnership.native)";
    } else /* qtd 2 if (owner == TypeSystem::TargetLangOwnership) */ {
        return "qtdSetOwnership(QtdObjectOwnership.d)";
    }/* else if (owner == TypeSystem::DefaultOwnership) {
        return "__no_real_delete = false";

    } else {
        Q_ASSERT(false);
        return "bogus()";
    }*/
}

void DGenerator::writeOwnershipForContainer(QTextStream &s, TypeSystem::Ownership owner,
                                               AbstractMetaType *type, const QString &arg_name)
{
    Q_ASSERT(type->isContainer());

    s << INDENT << "for (" << type->instantiations().at(0)->fullName() << " i : "
                << arg_name << ")" << endl
      << INDENT << "    if (i != null) i." << function_call_for_ownership(owner) << ";" << endl;

}

void DGenerator::writeOwnershipForContainer(QTextStream &s, TypeSystem::Ownership owner,
                                               AbstractMetaArgument *arg)
{
    writeOwnershipForContainer(s, owner, arg->type(), arg->argumentName());
}

static FunctionModificationList get_function_modifications_for_class_hierarchy(const AbstractMetaFunction *d_function)
{
    FunctionModificationList mods;
    const AbstractMetaClass *cls = d_function->implementingClass();
    while (cls != 0) {
        mods += d_function->modifications(cls);

        if (cls == cls->baseClass())
            break;
        cls = cls->baseClass();
    }
    return mods;
}

void DGenerator::writeInjectedCode(QTextStream &s, const AbstractMetaFunction *d_function,
                                      CodeSnip::Position position)
{
    FunctionModificationList mods = get_function_modifications_for_class_hierarchy(d_function);
    foreach (FunctionModification mod, mods) {
        if (mod.snips.count() <= 0)
            continue ;

        foreach (CodeSnip snip, mod.snips) {
            if (snip.position != position)
                continue ;

            if (snip.language != TypeSystem::TargetLangCode)
                continue ;

            QString code;
            QTextStream tmpStream(&code);
            snip.formattedCode(tmpStream, INDENT);
            ArgumentMap map = snip.argumentMap;
            ArgumentMap::iterator it = map.begin();
            for (;it!=map.end();++it) {
                int pos = it.key() - 1;
                QString meta_name = it.value();

                if (pos >= 0 && pos < d_function->arguments().count()) {
                    code = code.replace(meta_name, d_function->arguments().at(pos)->argumentName());
                } else {
                    QString debug = QString("argument map specifies invalid argument index %1"
                                            "for function '%2'")
                                            .arg(pos + 1).arg(d_function->name());
                    ReportHandler::warning(debug);
                }

            }
            s << code << endl;
        }
    }
}

void DGenerator::writeJavaCallThroughContents(QTextStream &s, const AbstractMetaFunction *d_function, uint attributes)
{
    Q_UNUSED(attributes);
    writeInjectedCode(s, d_function, CodeSnip::Beginning);
/* qtd
    if (d_function->implementingClass()->isQObject()
        && !d_function->isStatic()
        && !d_function->isConstructor()
        && d_function->name() != QLatin1String("thread")
        && d_function->name() != QLatin1String("disposeLater")) {
        s << INDENT << "qt.GeneratorUtilities.threadCheck(this);" << endl;
    }
*/
    AbstractMetaArgumentList arguments = d_function->arguments();

    if (!d_function->isConstructor()) {
        TypeSystem::Ownership owner = d_function->ownership(d_function->implementingClass(), TypeSystem::TargetLangCode, -1);
        if (owner != TypeSystem::InvalidOwnership)
            s << INDENT << "this." << function_call_for_ownership(owner) << ";" << endl;
    }

    for (int i=0; i<arguments.count(); ++i) {
        AbstractMetaArgument *arg = arguments.at(i);

        if (!d_function->argumentRemoved(i+1)) {
            TypeSystem::Ownership owner = d_function->ownership(d_function->implementingClass(), TypeSystem::TargetLangCode, i+1);
            if (owner != TypeSystem::InvalidOwnership) {
                QString empty_condition = " !is null";
                if (arg->type()->isContainer())
                    empty_condition = ".length != 0";
                s << INDENT << "if (" << arg->argumentName() << empty_condition << ") {" << endl;
                {
                    Indentation indent(INDENT);
                    if (arg->type()->isContainer())
                        ;// qtd2 writeOwnershipForContainer(s, owner, arg);
                    else
                        s << INDENT << arg->argumentName() << "." << function_call_for_ownership(owner) << ";" << endl;
                }
                s << INDENT << "}" << endl;
            }
/*
            if (type->isArray()) {
                s << INDENT << "if (" << arg->argumentName() << ".length != " << type->arrayElementCount() << ")" << endl
                  << INDENT << "    " << "throw new IllegalArgumentException(\"Wrong number of elements in array. Found: \" + "
                  << arg->argumentName() << ".length + \", expected: " << type->arrayElementCount() << "\");"
                  << endl << endl;
            }

            if (type->isEnum()) {
                EnumTypeEntry *et = (EnumTypeEntry *) type->typeEntry();
                if (et->forceInteger()) {
                    if (!et->lowerBound().isEmpty()) {
                        s << INDENT << "if (" << arg->argumentName() << " < " << et->lowerBound() << ")" << endl
                          << INDENT << "    throw new IllegalArgumentException(\"Argument " << arg->argumentName()
                          << " is less than lowerbound " << et->lowerBound() << "\");" << endl;
                    }
                    if (!et->upperBound().isEmpty()) {
                        s << INDENT << "if (" << arg->argumentName() << " > " << et->upperBound() << ")" << endl
                          << INDENT << "    throw new IllegalArgumentException(\"Argument " << arg->argumentName()
                          << " is greated than upperbound " << et->upperBound() << "\");" << endl;
                    }
                }
            }
            */
        }
    }

/* qtd2
    if (!d_function->isConstructor() && !d_function->isStatic()) {
        s << INDENT << "if (nativeId() == 0)" << endl
          << INDENT << "    throw new QNoNativeResourcesException(\"Function call on incomplete object of type: \" +getClass().getName());" << endl;
    }
*/
    for (int i=0; i<arguments.size(); ++i) {
        if (d_function->nullPointersDisabled(d_function->implementingClass(), i + 1)) {
            s << INDENT << "/*if (" << arguments.at(i)->argumentName() << " is null)" << endl
              << INDENT << "    throw new NullPointerException(\"Argument '" << arguments.at(i)->argumentName() << "': null not expected.\"); */" << endl;
        }
    }

    QList<ReferenceCount> referenceCounts;
    for (int i=0; i<arguments.size() + 1; ++i) {
        referenceCounts = d_function->referenceCounts(d_function->implementingClass(),
                                                         i == 0 ? -1 : i);

        foreach (ReferenceCount refCount, referenceCounts) {
			// TODO: What is the correct value to pass as last parameter if (i == 0)?
            writeReferenceCount(s, refCount, i == 0 ? "this" : arguments.at(i-1)->argumentName(), i == 0 ? 0 : arguments.at(i-1)->type());
		}
    }

    referenceCounts = d_function->referenceCounts(d_function->implementingClass(), 0);
    AbstractMetaType *return_type = d_function->type();
    QString new_return_type = QString(d_function->typeReplaced(0)).replace('$', '.');
    bool has_return_type = new_return_type != "void"
        && (!new_return_type.isEmpty() || return_type != 0);
// qtd    TypeSystem::Ownership owner = d_function->ownership(d_function->implementingClass(), TypeSystem::TargetLangCode, 0);

    bool has_code_injections_at_the_end = false;
    FunctionModificationList mods = get_function_modifications_for_class_hierarchy(d_function);
    foreach (FunctionModification mod, mods) {
        foreach (CodeSnip snip, mod.snips) {
            if (snip.position == CodeSnip::End && snip.language == TypeSystem::TargetLangCode) {
                has_code_injections_at_the_end = true;
                break;
            }
        }
    }

//    bool needs_return_variable = has_return_type
//        && (owner != TypeSystem::InvalidOwnership || referenceCounts.size() > 0 || has_code_injections_at_the_end);

    if(return_type) { // qtd
        if (return_type->isTargetLangString())
            s << INDENT << "string res;" << endl;

        if(return_type->name() == "QModelIndex")
            s << INDENT << "QModelIndex res;" << endl;
        else if (return_type->typeEntry()->isStructInD())
            s << INDENT << return_type->name() << " res;" << endl;

        if(return_type->isContainer())
        {
            const ContainerTypeEntry *type =
                    static_cast<const ContainerTypeEntry *>(return_type->typeEntry());
            if(type->isQList()) // QList is a native type now
                s << INDENT << "auto res = " << this->translateType(d_function->type(), d_function->ownerClass(), NoOption) << ".opCall();" << endl;
            else
                s << INDENT << this->translateType(d_function->type(), d_function->ownerClass(), NoOption) << " res;" << endl;
        }
    }

    // returning string or a struct
    bool return_in_arg = return_type && (return_type->isTargetLangString() ||
                                         return_type->name() == "QModelIndex" ||
                                         return_type->isContainer() ||
                                         return_type->typeEntry()->isStructInD());

    // bool flag showing if we return value immediately, without any conversions
    // which is commpon for primitive types, initially set up to return_in_arg, because in that case
    // we don't need type conversions
    bool returnImmediately = return_in_arg;

    s << INDENT;
    if ( (has_return_type && d_function->argumentReplaced(0).isEmpty() ) || d_function->isConstructor()) { //qtd
        if(d_function->type() && d_function->type()->isQObject()) { // qtd
            s << "void *ret = ";
        } else if(return_in_arg) // qtd
            ;
        else if (d_function->isConstructor()) { // qtd
            s << "void* ret = ";
        } else if (return_type && return_type->isValue() && !return_type->typeEntry()->isStructInD()) {
            s << "void* ret = ";
        } else if (return_type && return_type->isVariant()) {
            s << "void* ret = ";
        } else if (return_type && ( return_type->isObject() ||
                  (return_type->isNativePointer() && return_type->typeEntry()->isValue()) ||
                   return_type->typeEntry()->isInterface()) ) {
            s << "void* ret = ";
        } else if (return_type && return_type->isArray()) {
            s << return_type->arrayElementType()->name() + "* ret = ";
        } else {
            returnImmediately = true;
            s << "return ";
        }

        if (return_type && return_type->isTargetLangEnum()) {
            s << "cast(" << return_type->typeEntry()->qualifiedTargetLangName() << ") ";
        }/* qtd2 flags else if (return_type && return_type->isTargetLangFlags()) {
            s << "new " << return_type->typeEntry()->qualifiedTargetLangName() << "(";
        }*/
    }

    bool useJumpTable = d_function->jumpTableId() != -1;
    if (useJumpTable) {
        // The native function returns the correct type, we only have
        // java.lang.Object so we may have to cast...
        QString signature = JumpTablePreprocessor::signature(d_function);

//         printf("return: %s::%s return=%p, replace-value=%s, replace-type=%s signature: %s\n",
//                qPrintable(d_function->ownerClass()->name()),
//                qPrintable(d_function->signature()),
//                return_type,
//                qPrintable(d_function->argumentReplaced(0)),
//                qPrintable(new_return_type),
//                qPrintable(signature));

        if (has_return_type && signature.at(0) == 'L') {
            if (new_return_type.length() > 0) {
//                 printf(" ---> replace-type: %s\n", qPrintable(new_return_type));
                s << "(" << new_return_type << ") ";
            } else if (d_function->argumentReplaced(0).isEmpty()) {
//                 printf(" ---> replace-value\n");
                s << "(" << translateType(return_type, d_function->implementingClass()) << ") ";
            }
        }

            s << "JTbl." << JumpTablePreprocessor::signature(d_function) << "("
          << d_function->jumpTableId() << ", ";

        // Constructors and static functions don't have native id, but
        // the functions expect them anyway, hence add '0'. Normal
        // functions get their native ids added just below...
        if (d_function->isConstructor() || d_function->isStatic())
            s << "0, ";

    } else {
/* qtd       if (attributes & SuperCall) {
            s << "super.";
        }*/
        s << d_function->marshalledName() << "(";
    }

    bool arg_written = false;

    if (!d_function->isConstructor() && !d_function->isStatic()) {
        s << "qtdNativeId";
        arg_written = true;
    }

    if (d_function->isConstructor() &&
        ( d_function->ownerClass()->isPolymorphic()
        || d_function->implementingClass()->typeEntry()->isObject() ) ) { // qtd
        if (arg_written)
            s << ", ";
        s << "cast(void*) this";
        arg_written = true;
    }

    if(return_in_arg) {
        if (arg_written)
            s << ", ";
        s << "&res";
        arg_written = true;
    }

    for (int i=0; i<arguments.count(); ++i) {
        const AbstractMetaArgument *arg = arguments.at(i);
        const AbstractMetaType *type = arg->type();
        const TypeEntry *te = type->typeEntry();

        if (!d_function->argumentRemoved(i+1)) {
            if (arg_written)
                s << ", ";
            arg_written = true;

            // qtd
            QString modified_type = d_function->typeReplaced(arg->argumentIndex() + 1);
            if (!modified_type.isEmpty())
                modified_type = modified_type.replace('$', '.');

            QString arg_name = arg->argumentName();

            if (type->isVariant())
                s << arg_name << " is null ? null : " << arg_name << ".qtdNativeId";
            else if (te->designatedInterface())
                s << arg_name << " is null ? null : " << arg_name << ".__ptr_" << te->designatedInterface()->name();
            else if (modified_type == "string" /* && type->fullName() == "char" */) {
                s << "toStringz(" << arg_name << ")";
            } else if (type->isArray()) {
                s << arg_name << ".ptr";
            } else if(type->isContainer()) {
                const ContainerTypeEntry *cte =
                        static_cast<const ContainerTypeEntry *>(te);
                if(isLinearContainer(cte))
                    s << QString("&%1").arg(arg_name);
            } else if (type->typeEntry()->qualifiedCppName() == "QChar") {
                s << arg_name;
            } else if (type->isTargetLangString() || (te && te->qualifiedCppName() == "QString")) {
                s << arg_name;
            } else if (type->isTargetLangEnum() || type->isTargetLangFlags()) {
                s << arg_name;
// qtd                s << arg->argumentName() << ".value()";
            } else if (!type->hasNativeId() && !(te->isValue() && type->isNativePointer())) { // qtd2 hack for QStyleOption not being a nativeId based for some reason
                s << arg_name;
            } else if (te->isStructInD()) {
                s << arg_name;
            } else {
                bool force_abstract = te->isComplex() && (((static_cast<const ComplexTypeEntry *>(te))->typeFlags() & ComplexTypeEntry::ForceAbstract) != 0);
                if (!force_abstract) {
                    s << arg_name << " is null ? null : ";
                } // else if (value type is abstract) then we will get a null pointer exception, which is all right

                if(global.dVersion == 2 && type->isConstant())
                    s << "(cast(" << type->name() << ")" << arg_name << ").qtdNativeId";
                else
                    s << arg_name << ".qtdNativeId";
            }
        }
    }

    if (useJumpTable) {
        if (arg_written)
            s << ", ";

        if (d_function->isStatic())
            s << "null";
        else
            s << "this";
        arg_written = true;
    }

    s << ")";

    if ( !d_function->argumentReplaced(0).isEmpty() ) {
        s << ";" << endl;
        s << INDENT << "return " << d_function->argumentReplaced(0) << ";" << endl;
        return;
    }

// qtd2    if (return_type && (/* qtdreturn_type->isTargetLangEnum() ||*/ return_type->isTargetLangFlags()))
//        s << ")";

    s << ";" << endl;

/* qtd2
    if (needs_return_variable) {
        if (owner != TypeSystem::InvalidOwnership) {
            s << INDENT << "if (ret != null) {" << endl;
            if (return_type->isContainer())
                writeOwnershipForContainer(s, owner, return_type, "ret");
            else
                s << INDENT << "    ret." << function_call_for_ownership(owner) << ";" << endl;
            s << INDENT << "}" << endl;
        }
        s << INDENT << "return ret;" << endl;
    }
*/
    if (d_function->isConstructor()) {
        TypeSystem::Ownership owner = d_function->ownership(d_function->implementingClass(), TypeSystem::TargetLangCode, -1);
        if (owner != TypeSystem::InvalidOwnership && d_function->isConstructor())
            s << INDENT << "this." << function_call_for_ownership(owner) << ";" << endl;
    }

    // return value marshalling
    if(return_type) {
        if (!returnImmediately) {
            s << INDENT;
            QString modified_type = d_function->typeReplaced(0);
            if (modified_type.isEmpty())
                s << translateType(d_function->type(), d_function->implementingClass());
            else
                s << modified_type.replace('$', '.');
            s << " __d_return_value = ";
        }

        if ( ( has_return_type && d_function->argumentReplaced(0).isEmpty() )) // qtd
        {
            if(return_type->isQObject())
                s << return_type->name() << ".__getObject(ret);" << endl;
        }

        if (return_type->isValue() && !return_type->typeEntry()->isStructInD())
            s << "new " << return_type->name() << "(ret);" << endl;

        if (return_type->isVariant())
            s << "new QVariant(ret);" << endl;

        if (return_type->isNativePointer() && return_type->typeEntry()->isValue())
            s << "new " << return_type->name() << "(ret, QtdObjectInitFlags.nativeOwnership);" << endl;

        if (return_type->isObject()) {
            s << "qtd_" << return_type->name() << "_from_ptr(ret);" << endl << endl;
        }

        if (return_type->isArray()) {
            s << "ret[0 .. " << return_type->arrayElementCount() << "];" << endl;
        }

        foreach (ReferenceCount referenceCount, referenceCounts) {
            writeReferenceCount(s, referenceCount, "__d_return_value", return_type);
        }

        if (!returnImmediately)
            s << INDENT << "return __d_return_value;" << endl;
    }
    writeInjectedCode(s, d_function, CodeSnip::End);

    if(return_in_arg) // qtd
        s << INDENT << "return res;" << endl;
}

void DGenerator::retrieveModifications(const AbstractMetaFunction *d_function,
                                          const AbstractMetaClass *d_class,
                                          uint *exclude_attributes,
                                          uint *include_attributes) const
{
    FunctionModificationList mods = d_function->modifications(d_class);
//     printf("name: %s has %d mods\n", qPrintable(d_function->signature()), mods.size());
    foreach (FunctionModification mod, mods) {
        if (mod.isAccessModifier()) {
//             printf(" -> access mod to %x\n", mod.modifiers);
            *exclude_attributes |= AbstractMetaAttributes::Public
                                | AbstractMetaAttributes::Protected
                                | AbstractMetaAttributes::Private
                                | AbstractMetaAttributes::Friendly;

            if (mod.isPublic())
                *include_attributes |= AbstractMetaAttributes::Public;
            else if (mod.isProtected())
                *include_attributes |= AbstractMetaAttributes::Protected;
            else if (mod.isPrivate())
                *include_attributes |= AbstractMetaAttributes::Private;
            else if (mod.isFriendly())
                *include_attributes |= AbstractMetaAttributes::Friendly;
        }

        if (mod.isFinal()) {
            *include_attributes |= AbstractMetaAttributes::FinalInTargetLang;
        } else if (mod.isNonFinal()) {
            *exclude_attributes |= AbstractMetaAttributes::FinalInTargetLang;
        }
    }

    *exclude_attributes &= ~(*include_attributes);
}

QString DGenerator::functionSignature(const AbstractMetaFunction *d_function,
                                         uint included_attributes, uint excluded_attributes,
                                         Option option,
                                         int arg_count)
{
    AbstractMetaArgumentList arguments = d_function->arguments();
    int argument_count = arg_count < 0 ? arguments.size() : arg_count;

    QString result;
    QTextStream s(&result);
    QString functionName = d_function->isConstructor() ? "this" : d_function->name(); // qtd
    // The actual function
    if (!(d_function->isEmptyFunction() || d_function->isNormal() || d_function->isSignal()))
        option = Option(option | SkipReturnType);
    writeFunctionAttributes(s, d_function, included_attributes, excluded_attributes, option);

    s << functionName << "(";
    writeFunctionArguments(s, d_function, argument_count, option);
    s << ")";

    if(d_function->isConstant())
        s << " const";

    return result;
}

void DGenerator::setupForFunction(const AbstractMetaFunction *d_function,
                                     uint *included_attributes,
                                     uint *excluded_attributes) const
{
    *excluded_attributes |= d_function->ownerClass()->isInterface() || d_function->isConstructor()
                            ? AbstractMetaAttributes::Native | AbstractMetaAttributes::Final
                            : 0;
    if (d_function->ownerClass()->isInterface())
        *excluded_attributes |= AbstractMetaAttributes::Abstract;
    if (d_function->needsCallThrough())
        *excluded_attributes |= AbstractMetaAttributes::Native;

    const AbstractMetaClass *d_class = d_function->ownerClass();
    retrieveModifications(d_function, d_class, excluded_attributes, included_attributes);
}

void DGenerator::writeReferenceCount(QTextStream &s, const ReferenceCount &refCount,
                                        const QString &argumentName, AbstractMetaType *argumentType)
{
    if (refCount.action == ReferenceCount::Ignore)
        return;

    QString refCountVariableName = refCount.variableName;
    if (!refCount.declareVariable.isEmpty() && refCount.action != ReferenceCount::Set) {
        s << INDENT << "auto __rcTmp = " << refCountVariableName << ";" << endl;
        refCountVariableName = "__rcTmp";
    }
    QString empty_condition = " !is null";
    if (argumentType && argumentType->isContainer())
//        if (((const ContainerTypeEntry *)argumentType->typeEntry())->isQList())
            empty_condition = ".length != 0";

    if (refCount.action != ReferenceCount::Set) {
        s << INDENT << "if (" << argumentName << empty_condition;

        if (!refCount.conditional.isEmpty())
            s << " && " << refCount.conditional;

        s << ") {" << endl;
    } else {
         if (!refCount.conditional.isEmpty())
             s << INDENT << "if (" << refCount.conditional << ") ";
         s << INDENT << "{" << endl;
    }

    {
        Indentation indent(INDENT);
        QString summand = argumentName;
        switch (refCount.action) {
        case ReferenceCount::Add:
            s << INDENT << refCountVariableName << " ~= cast(Object) " << argumentName << ";" << endl;
            break;
        case ReferenceCount::AddAll:
            if(isNativeContainer(argumentType))
                summand = argumentName + ".toArray()";
            s << INDENT << refCountVariableName << " ~= " << summand << ";" << endl;
            break;
        case ReferenceCount::Remove:
            s << INDENT << "remove(" << refCountVariableName
              << ", cast(Object) " << argumentName << ");" << endl;
            break;
        case ReferenceCount::Set:
            {
                if (refCount.declareVariable.isEmpty())
                    s << INDENT << refCount.variableName << " = cast(Object) " << argumentName << ";" << endl;
                else
                    s << INDENT << refCountVariableName << " = cast(Object) " << argumentName << ";" << endl;
            }
        default:
            break;
        };
    }
    s << INDENT << "}" << endl;
}

void DGenerator::writeFunction(QTextStream &s, const AbstractMetaFunction *d_function,
                                  uint included_attributes, uint excluded_attributes)
{
    s << endl;

    if (d_function->isModifiedRemoved(TypeSystem::TargetLangCode))
        return ;
    QString functionName = d_function->name();
    setupForFunction(d_function, &included_attributes, &excluded_attributes);

    if (!d_function->ownerClass()->isInterface()) {
// qtd2        writeEnumOverload(s, d_function, included_attributes, excluded_attributes);
// qtd        writeFunctionOverloads(s, d_function, included_attributes, excluded_attributes);
    }
/* qtd
    static QRegExp regExp("^(insert|set|take|add|remove|install).*");

    if (regExp.exactMatch(d_function->name())) {
        AbstractMetaArgumentList arguments = d_function->arguments();

        const AbstractMetaClass *c = d_function->implementingClass();
        bool hasObjectTypeArgument = false;
        foreach (AbstractMetaArgument *argument, arguments) {
            TypeSystem::Ownership d_ownership = d_function->ownership(c, TypeSystem::TargetLangCode, argument->argumentIndex()+1);
            TypeSystem::Ownership shell_ownership = d_function->ownership(c, TypeSystem::ShellCode, argument->argumentIndex()+1);

            if (argument->type()->typeEntry()->isObject()
                && d_ownership == TypeSystem::InvalidOwnership
                && shell_ownership == TypeSystem::InvalidOwnership) {
                hasObjectTypeArgument = true;
                break;
            }
        }

        if (hasObjectTypeArgument
            && !d_function->isAbstract()
            && d_function->referenceCounts(d_function->implementingClass()).size() == 0) {
            m_reference_count_candidate_functions.append(d_function);
        }
    }


    if (m_doc_parser) {
        QString signature = functionSignature(d_function,
                                              included_attributes | NoBlockedSlot,
                                              excluded_attributes);
        s << m_doc_parser->documentationForFunction(signature) << endl;
    }

    const QPropertySpec *spec = d_function->propertySpec();
    if (spec && d_function->modifiedName() == d_function->originalName()) {
        if (d_function->isPropertyReader()) {
            s << "    @qt.QtPropertyReader(name=\"" << spec->name() << "\")" << endl;
            if (!spec->designable().isEmpty())
                s << "    @qt.QtPropertyDesignable(\"" << spec->designable() << "\")" << endl;
        } else if (d_function->isPropertyWriter()) {
            s << "    @qt.QtPropertyWriter(name=\"" << spec->name() << "\")" << endl;
        } else if (d_function->isPropertyResetter()) {
            s << "    @qt.QtPropertyResetter(name=\"" << spec->name() << "\")"
              << endl;
        }
    }
*/
    s << functionSignature(d_function, included_attributes, excluded_attributes);

    if (d_function->isConstructor()) {
        writeConstructorContents(s, d_function);
    } else if (d_function->needsCallThrough() || d_function->isStatic()) { // qtd
        if (d_function->isAbstract()) {
            s << ";" << endl;
        } else {
            s << " {" << endl;
            {
                Indentation indent(INDENT);
                writeJavaCallThroughContents(s, d_function);
            }
            s << INDENT << "}" << endl;
        }

/* qtd
        if (d_function->jumpTableId() == -1) {
            writePrivateNativeFunction(s, d_function);
        }
*/
    } else {
        s << ";" << endl;
    }
}

static void write_equals_parts(QTextStream &s, const AbstractMetaFunctionList &lst, char prefix, bool *first) {
    foreach (AbstractMetaFunction *f, lst) {
        AbstractMetaArgument *arg = f->arguments().at(0);
        QString type = f->typeReplaced(1);
        if (type.isEmpty())
            type = arg->type()->typeEntry()->qualifiedTargetLangName();
        s << INDENT << (*first ? "if" : "else if") << " (other instanceof " << type << ")" << endl
          << INDENT << "    return ";
        if (prefix != 0) s << prefix;
        s << f->name() << "((" << type << ") other);" << endl;
        *first = false;
    }
}

static void write_compareto_parts(QTextStream &s, const AbstractMetaFunctionList &lst, int value, bool *first) {
    foreach (AbstractMetaFunction *f, lst) {
        AbstractMetaArgument *arg = f->arguments().at(0);
        QString type = f->typeReplaced(1);
        if (type.isEmpty())
            type = arg->type()->typeEntry()->qualifiedTargetLangName();
        s << INDENT << (*first ? "if" : "else if") << " (other instanceof " << type << ") {" << endl
          << INDENT << "    if (" << f->name() << "((" << type << ") other)) return " << value << ";" << endl
          << INDENT << "    else return " << -value << ";" << endl
          << INDENT << "}" << endl;
        *first = false;
    }
    s << INDENT << "throw new ClassCastException();" << endl;
}

bool DGenerator::isComparable(const AbstractMetaClass *cls) const
{
    AbstractMetaFunctionList eq_functions = cls->equalsFunctions();
    AbstractMetaFunctionList neq_functions = cls->notEqualsFunctions();

    // Write the comparable functions
    AbstractMetaFunctionList ge_functions = cls->greaterThanFunctions();
    AbstractMetaFunctionList geq_functions = cls->greaterThanEqFunctions();
    AbstractMetaFunctionList le_functions = cls->lessThanFunctions();
    AbstractMetaFunctionList leq_functions = cls->lessThanEqFunctions();

    bool hasEquals = eq_functions.size() || neq_functions.size();
    bool isComparable = hasEquals
                        ? ge_functions.size() || geq_functions.size() || le_functions.size() || leq_functions.size()
                        : geq_functions.size() == 1 && leq_functions.size() == 1;

    return isComparable;
}


void DGenerator::writeJavaLangObjectOverrideFunctions(QTextStream &s,
                                                         const AbstractMetaClass *cls)
{
    AbstractMetaFunctionList eq_functions = cls->equalsFunctions();
    AbstractMetaFunctionList neq_functions = cls->notEqualsFunctions();

    if (eq_functions.size() || neq_functions.size()) {
        s << endl
          << INDENT << "@SuppressWarnings(\"unchecked\")" << endl
          << INDENT << "@Override" << endl
          << INDENT << "public boolean equals(Object other) {" << endl;
        bool first = true;
        write_equals_parts(s, eq_functions, (char) 0, &first);
        write_equals_parts(s, neq_functions, '!', &first);
        s << INDENT << "    return false;" << endl
          << INDENT << "}" << endl << endl;
    }

    // Write the comparable functions
    AbstractMetaFunctionList ge_functions = cls->greaterThanFunctions();
    AbstractMetaFunctionList geq_functions = cls->greaterThanEqFunctions();
    AbstractMetaFunctionList le_functions = cls->lessThanFunctions();
    AbstractMetaFunctionList leq_functions = cls->lessThanEqFunctions();

    bool hasEquals = eq_functions.size() || neq_functions.size();
    bool comparable = isComparable(cls);
    if (comparable) {
        s << INDENT << "public int compareTo(Object other) {" << endl;
        {
            Indentation indent(INDENT);
            if (hasEquals) {
                s << INDENT << "if (equals(other)) return 0;" << endl;
                bool first = false;
                if (le_functions.size()) {
                    write_compareto_parts(s, le_functions, -1, &first);
                } else if (ge_functions.size()) {
                    write_compareto_parts(s, ge_functions, 1, &first);
                } else if (leq_functions.size()) {
                    write_compareto_parts(s, leq_functions, -1, &first);
                } else if (geq_functions.size()) {
                    write_compareto_parts(s, geq_functions, 1, &first);
                }

            } else if (le_functions.size() == 1) {
                QString className = cls->typeEntry()->qualifiedTargetLangName();
                s << INDENT << "if (operator_less((" << className << ") other)) return -1;" << endl
                  << INDENT << "else if (((" << className << ") other).operator_less(this)) return 1;" << endl
                  << INDENT << "else return 0;" << endl;

            } else if (geq_functions.size() == 1 && leq_functions.size()) {
                QString className = cls->typeEntry()->qualifiedTargetLangName();
                s << INDENT << "boolean less = operator_less_or_equal((" << className << ") other);" << endl
                  << INDENT << "boolean greater = operator_greater_or_equal((" << className << ") other);" << endl
                  << INDENT << "if (less && greater) return 0;" << endl
                  << INDENT << "else if (less) return -1;" << endl
                  << INDENT << "else return 1;" << endl;
            }
        }

        s << INDENT << "}" << endl;
    }


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
              << INDENT << "@Override" << endl
              << INDENT << "public int hashCode() {" << endl
              << INDENT << "    if (nativeId() == 0)" << endl
              << INDENT << "        throw new QNoNativeResourcesException(\"Function call on incomplete object of type: \" +getClass().getName());" << endl
              << INDENT << "    return __qt_hashCode(nativeId());" << endl
              << INDENT << "}" << endl
              << INDENT << "native int __qt_hashCode(long __this_nativeId);" << endl;
        }
    }

    // Qt has a standard toString() conversion in QVariant?
    QVariant::Type type = QVariant::nameToType(cls->qualifiedCppName().toLatin1());
    if (QVariant(type).canConvert(QVariant::String) &&  !cls->hasToStringCapability()) {
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
              << INDENT << "@Override" << endl
              << INDENT << "public String toString() {" << endl
              << INDENT << "    if (nativeId() == 0)" << endl
              << INDENT << "        throw new QNoNativeResourcesException(\"Function call on incomplete object of type: \" +getClass().getName());" << endl
              << INDENT << "    return __qt_toString(nativeId());" << endl
              << INDENT << "}" << endl
              << INDENT << "native String __qt_toString(long __this_nativeId);" << endl;
        }
    }
}

void DGenerator::writeEnumOverload(QTextStream &s, const AbstractMetaFunction *d_function,
                                      uint include_attributes, uint exclude_attributes)
{
    AbstractMetaArgumentList arguments = d_function->arguments();

    if ((d_function->implementingClass() != d_function->declaringClass())
        || ((!d_function->isNormal() && !d_function->isConstructor()) || d_function->isEmptyFunction() || d_function->isAbstract())) {
        return ;
    }


    int option = 0;
    if (d_function->isConstructor())
        option = Option(option | SkipReturnType);
    else
        include_attributes |= AbstractMetaAttributes::FinalInTargetLang;

    int generate_enum_overload = -1;
    for (int i=0; i<arguments.size(); ++i)
        generate_enum_overload = arguments.at(i)->type()->isTargetLangFlags() ? i : -1;

    if (generate_enum_overload >= 0) {
        if (m_doc_parser) {
            // steal documentation from main function
            QString signature = functionSignature(d_function,
                                                  include_attributes | NoBlockedSlot,
                                                  exclude_attributes);
            s << m_doc_parser->documentationForFunction(signature) << endl;
        }

        s << endl;

        writeFunctionAttributes(s, d_function, include_attributes, exclude_attributes, option);
        s << d_function->name() << "(";
        if (generate_enum_overload > 0) {
            writeFunctionArguments(s, d_function, generate_enum_overload);
            s << ", ";
        }

        // Write the ellipsis convenience argument
        AbstractMetaArgument *affected_arg = arguments.at(generate_enum_overload);
        EnumTypeEntry *originator = ((FlagsTypeEntry *)affected_arg->type()->typeEntry())->originator();

        s << originator->javaPackage() << "." << originator->javaQualifier() << "." << originator->targetLangName()
          << " ... " << affected_arg->argumentName() << ") {" << endl;

        s << "        ";
        QString new_return_type = d_function->typeReplaced(0);
        if (new_return_type != "void" && (!new_return_type.isEmpty() || d_function->type() != 0))
            s << "return ";

        if (d_function->isConstructor()) {
            s << "this";
        } else {
            if (d_function->isStatic())
                s << d_function->implementingClass()->fullName() << ".";
            else
                s << "this.";
            s << d_function->name();
        }

        s << "(";
        for (int i=0; i<generate_enum_overload; ++i) {
            s << arguments.at(i)->argumentName() << ", ";
        }
        s << "new " << affected_arg->type()->fullName() << "(" << affected_arg->argumentName() << "));" << endl
          << "    }" << endl;
    }
}

void DGenerator::writeInstantiatedType(QTextStream &s, const AbstractMetaType *abstractMetaType) const
{
    Q_ASSERT(abstractMetaType != 0);

    const TypeEntry *type = abstractMetaType->typeEntry();
    s << type->qualifiedTargetLangName();

    if (abstractMetaType->hasInstantiations()) {
        s << "<";
        QList<AbstractMetaType *> instantiations = abstractMetaType->instantiations();
        for(int i=0; i<instantiations.size(); ++i) {
            if (i > 0)
                s << ", ";

            writeInstantiatedType(s, instantiations.at(i));
        }
        s << ">";
    }
}

void DGenerator::writeFunctionOverloads(QTextStream &s, const AbstractMetaFunction *d_function,
                                           uint include_attributes, uint exclude_attributes)
{
    AbstractMetaArgumentList arguments = d_function->arguments();
    int argument_count = arguments.size();

    // We only create the overloads for the class that actually declares the function
    // unless this is an interface, in which case we create the overloads for all
    // classes that directly implement the interface.
    const AbstractMetaClass *decl_class = d_function->declaringClass();
    if (decl_class->isInterface()) {
        AbstractMetaClassList interfaces = d_function->implementingClass()->interfaces();
        foreach (AbstractMetaClass *iface, interfaces) {
            if (iface == decl_class) {
                decl_class = d_function->implementingClass();
                break;
            }
        }
    }
    if (decl_class != d_function->implementingClass())
        return;

    // Figure out how many functions we need to write out,
    // One extra for each default argument.
    int overload_count = 0;
    uint excluded_attributes = AbstractMetaAttributes::Abstract
                            | AbstractMetaAttributes::Native
                            | exclude_attributes;
    uint included_attributes = (d_function->isConstructor() ? 0 : AbstractMetaAttributes::Final) | include_attributes;

    for (int i=0; i<argument_count; ++i) {
        if (!arguments.at(i)->defaultValueExpression().isEmpty() && !d_function->argumentRemoved(i+1))
            ++overload_count;
    }
    Q_ASSERT(overload_count <= argument_count);
    for (int i=0; i<overload_count; ++i) {
        int used_arguments = argument_count - i - 1;

        QString signature = functionSignature(d_function, included_attributes,
                                              excluded_attributes,
                                              d_function->isEmptyFunction()
                                              || d_function->isNormal()
                                              || d_function->isSignal() ? NoOption
                                                                           : SkipReturnType,
                                              used_arguments);

        s << endl;
        if (m_doc_parser) {
            s << m_doc_parser->documentationForFunction(signature) << endl;
        }

        s << signature << " {\n        ";
        QString new_return_type = d_function->typeReplaced(0);
        if (new_return_type != "void" && (!new_return_type.isEmpty() || d_function->type()))
            s << "return ";
        if (d_function->isConstructor())
            s << "this";
        else
            s << d_function->name();
        s << "(";

        int written_arguments = 0;
        for (int j=0; j<argument_count; ++j) {
            if (!d_function->argumentRemoved(j+1)) {
                if (written_arguments++ > 0)
                    s << ", ";

                if (j < used_arguments) {
                    s << arguments.at(j)->argumentName();
                } else {
                    AbstractMetaType *arg_type = 0;
                    QString modified_type = d_function->typeReplaced(j+1);
                    if (modified_type.isEmpty()) {
                        arg_type = arguments.at(j)->type();
                        if (arg_type->isNativePointer()) {
                            s << "(qt.QNativePointer)";
                        } else {
                            const AbstractMetaType *abstractMetaType = arguments.at(j)->type();
                            const TypeEntry *type = abstractMetaType->typeEntry();
                            if (type->designatedInterface())
                                type = type->designatedInterface();
                            if (!type->isEnum() && !type->isFlags()) {
                                s << "(";
                                writeInstantiatedType(s, abstractMetaType);
                                s << ")";
                            }
                        }
                    } else {
                        s << "(" << modified_type.replace('$', '.') << ")";
                    }

                    QString defaultExpr = arguments.at(j)->defaultValueExpression();

                    int pos = defaultExpr.indexOf(".");
                    if (pos > 0) {
                        QString someName = defaultExpr.left(pos);
                        ComplexTypeEntry *ctype =
                            TypeDatabase::instance()->findComplexType(someName);
                        QString replacement;
                        if (ctype != 0 && ctype->isVariant())
                            replacement = "qt.QVariant.";
                        else if (ctype != 0)
                            replacement = ctype->javaPackage() + "." + ctype->targetLangName() + ".";
                        else
                            replacement = someName + ".";
                        defaultExpr = defaultExpr.replace(someName + ".", replacement);
                    }

                    if (arg_type != 0 && arg_type->isFlags()) {
                        s << "new " << arg_type->fullName() << "(" << defaultExpr << ")";
                    } else {
                        s << defaultExpr;
                    }
                }
            }
        }
        s << ");\n    }" << endl;
    }
}

const TypeEntry* DGenerator::fixedTypeEntry(const TypeEntry *type)
{
    if (!type)
        return NULL;
    if (type->designatedInterface())
        return type;
    else if (type->isEnum()) {
        const EnumTypeEntry *te = static_cast<const EnumTypeEntry *>(type);
        TypeEntry *ownerTe = TypeDatabase::instance()->findType(te->qualifier());
        if(ownerTe)
            typeEntriesEnums << ownerTe;
        return NULL;
//        return ownerTe;
    } else if (type->isFlags()) {
        const FlagsTypeEntry *te = static_cast<const FlagsTypeEntry *>(type);
        TypeEntry *ownerTe = TypeDatabase::instance()->findType(te->qualifier());
        return NULL;
//        return ownerTe;
    } else //if (type->isObject())
        return type;
//    else return NULL;
}

void DGenerator::addInstantiations(const AbstractMetaType* d_type)
{
    if (d_type->isContainer()) {
        QList<AbstractMetaType *> args = d_type->instantiations();
        for (int i=0; i<args.size(); ++i) {
            const TypeEntry *type = fixedTypeEntry(args.at(i)->typeEntry());
            if (type)
                typeEntries.insert(type);
        }
    }
}

void DGenerator::addTypeEntry(const AbstractMetaClass *d_class, const AbstractMetaFunction *function, QSet<const TypeEntry*> &typeEntries)
{
        // If a method in an interface class is modified to be private, this should
        // not be present in the interface at all, only in the implementation.
        if (d_class->isInterface()) {
            uint includedAttributes = 0;
            uint excludedAttributes = 0;
            retrieveModifications(function, d_class, &excludedAttributes, &includedAttributes);
            if (includedAttributes & AbstractMetaAttributes::Private)
                return;
        }

        if (notWrappedYet(function)) // qtd2
            return;

        // return type for function
        if (function->type()) {
            addInstantiations(function->type());
            const TypeEntry *type = fixedTypeEntry(function->type()->typeEntry());
            if (type)
                typeEntries.insert(type);
        }

        AbstractMetaArgumentList arguments = function->arguments();
        for (int i=0; i<arguments.count(); ++i) {
            const AbstractMetaArgument *arg = arguments.at(i);
            addInstantiations(arg->type());
            const TypeEntry *type = fixedTypeEntry(arg->type()->typeEntry());
            if (type)
                typeEntries.insert(type);
        }
}

void DGenerator::fillRequiredImports(const AbstractMetaClass *d_class)
{
    if (m_recursive < 2) {
        typeEntries.clear();
        typeEntriesEnums.clear();
    }

    // import for base class
    if(d_class->baseClass())
        typeEntries << d_class->baseClass()->typeEntry();

    //interfaces
    AbstractMetaClassList interfaces = d_class->interfaces();
    if (!interfaces.isEmpty()) {
        for (int i=0; i<interfaces.size(); ++i) {
            AbstractMetaClass *iface = interfaces.at(i);
            InterfaceTypeEntry *te = (InterfaceTypeEntry*) iface->typeEntry();
            typeEntries << te->origin();
        }
    }

    AbstractMetaFunctionList d_funcs = d_class->functionsInTargetLang();

    // in case of ConcreteWrapper - adding extra functions
    if (!d_class->isInterface() && d_class->isAbstract()) {
        AbstractMetaFunctionList functions_add = d_class->queryFunctions(AbstractMetaClass::NormalFunctions | AbstractMetaClass::AbstractFunctions | AbstractMetaClass::NonEmptyFunctions | AbstractMetaClass::NotRemovedFromTargetLang);
        d_funcs << functions_add;
    }

    for (int i=0; i<d_funcs.size(); ++i) {
        AbstractMetaFunction *function = d_funcs.at(i);
        addTypeEntry(d_class, function, typeEntries);
    }

    // virtual dispatch
    AbstractMetaFunctionList virtualFunctions = d_class->virtualFunctions();
    for (int i=0; i<virtualFunctions.size(); ++i) {
        AbstractMetaFunction *function = virtualFunctions.at(i);
        addTypeEntry(d_class, function, typeEntries);
    }

    AbstractMetaFieldList fields = d_class->fields();
    foreach (const AbstractMetaField *field, fields) {
        if (field->wasPublic() || (field->wasProtected() && !d_class->isFinal())) {
            addTypeEntry(d_class, field->setter(), typeEntries);
            addTypeEntry(d_class, field->getter(), typeEntries);
        }
    }

    // signals
    AbstractMetaFunctionList signal_funcs = d_class->queryFunctions(AbstractMetaClass::Signals
                                                                   | AbstractMetaClass::Visible
                                                                   | AbstractMetaClass::NotRemovedFromTargetLang);
    for (int i=0; i<signal_funcs.size(); ++i)
        addTypeEntry(d_class, signal_funcs.at(i), typeEntries);

    if(d_class->isQObject() && d_class->name() != "QObject")
        typeEntries << TypeDatabase::instance()->findType("QObject");

    if(m_recursive == 1)
        m_recursive++;
}

void DGenerator::writeImportString(QTextStream &s, const TypeEntry* typeEntry)
{
/*    QString visibility = "private";
    if (typeEntry->isNamespace() || typeEntry->name() == "QObject")
        visibility = "public";
    if(d_class->baseClass() && d_class->baseClass()->typeEntry() == typeEntry)
        visibility = "public";*/
    QString visibility = "public";
    s << QString("%1 import ").arg(visibility) << typeEntry->javaPackage() << "." << typeEntry->targetLangName() << ";" << endl;
}

void DGenerator::writeRequiredImports(QTextStream &s, const AbstractMetaClass *d_class)
{
    foreach (const TypeEntry *typeEntry, typeEntriesEnums) {
        if (!excludedTypes.contains(typeEntry->name()) && d_class->typeEntry() != typeEntry
            && typeEntry->javaQualifier() != typeEntry->name()
/*also*/            && !excludedTypes2.contains(typeEntry->name()))
            writeImportString(s, typeEntry);
    }

    foreach (const TypeEntry *typeEntry, typeEntries) {
        if (!excludedTypes.contains(typeEntry->name()) && d_class->typeEntry() != typeEntry
            && typeEntry->javaQualifier() != typeEntry->name()
/*also*/            && !excludedTypes2.contains(typeEntry->name()))
            writeImportString(s, typeEntry);
    }
    excludedTypes2.clear();
}

void DGenerator::writeDestructor(QTextStream &s, const AbstractMetaClass *d_class)
{
    if (!d_class->hasConstructors())
        return;

    if (d_class->isDestructorBase())
    {
        s << INDENT << "protected override void qtdDeleteNative() {" << endl;
        {
            s << INDENT << "    qtd_" << d_class->name() << "_delete(qtdNativeId);" << endl;
        }
        s << INDENT << "}" << endl << endl;

        s << INDENT << "static void __deleteNativeObject(void* ptr) {" << endl
          << INDENT << "    qtd_" << d_class->name() << "_delete(ptr);" << endl
          << INDENT << "}" << endl << endl;

        s << INDENT << "static void __callNativeDestructor(void* nativeId) {" << endl
          << INDENT << "    qtd_" << d_class->name() << "_destroy(nativeId);" << endl
          << INDENT << "}" << endl << endl;
    }
}

void DGenerator::writeOwnershipSetter(QTextStream &s, const AbstractMetaClass *d_class)
{
    if (d_class->isInterface())
        s << INDENT << "void qtdSetOwnership(QtdObjectOwnership own) const;";
    else if (!d_class->isNamespace()) // COMPILER BUG:
        s << INDENT << "void qtdSetOwnership(QtdObjectOwnership own) const { super.qtdSetOwnership(own); }";
}

void DGenerator::writeSignalHandlers(QTextStream &s, const AbstractMetaClass *d_class)
{
    AbstractMetaFunctionList signal_funcs = signalFunctions(d_class);

    QString attr;

//    return; // #TODO Don't need handlers for now. Restore in conversion functions later

    s << "// signal handlers" << endl;
    foreach(AbstractMetaFunction *signal, signal_funcs) {
        QString sigExternName = signalExternName(d_class, signal);

/*
        QString extra_args;

        foreach (AbstractMetaArgument *argument, arguments) {
            if(argument->type()->isContainer()) {
                QString arg_name = argument->indexedName();
                const AbstractMetaType *arg_type = argument->type();
                QString type_string = translateType(argument->type(), signal->implementingClass(), BoxedPrimitive);
                extra_args += ", " + type_string + " " + arg_name;
            }
        }
*/
        AbstractMetaArgumentList arguments = signal->arguments();

        s << "/*private extern(C) void " << sigExternName << "_handle(void* dId, void** args) {" << endl;
        {
            Indentation indent(INDENT);
            s << INDENT << "auto d_object = cast(" << d_class->name() << ") dId;" << endl;
            int sz = arguments.count();

            for (int j=0; j<sz; ++j) {
                AbstractMetaArgument *argument = arguments.at(j);
                QString arg_name = argument->indexedName();
                AbstractMetaType *type = argument->type();
                // if has QString argument we have to pass char* and str.length to QString constructor

                QString arg_ptr = QString("args[%1]").arg(argument->argumentIndex() + 1);

                if (type->isContainer()) {
                    s << INDENT << translateType(type, signal->implementingClass(), BoxedPrimitive) << " " << arg_name << ";" << endl
                      << INDENT << cppContainerConversionName(d_class, type, FromCpp) << "(" << arg_ptr << ", &" << arg_name << ");" << endl;
                } else if (type->isTargetLangString()) {
                    s << INDENT << "auto " << arg_name << "_ptr = " << arg_ptr << ";" << endl
                      << INDENT << "string " << arg_name << " = QStringUtil.toNativeString(" << arg_name << "_ptr);";
                } else if(type->isPrimitive() || type->isEnum() || type->isFlags() || type->typeEntry()->isStructInD()) {
                    QString type_name = argument->type()->typeEntry()->qualifiedTargetLangName();
                    s << INDENT << "auto " << arg_name << " = *(cast(" << type_name << "*)" << arg_ptr << ");";
                } else if(type->isObject() || type->isQObject()
                        || (type->typeEntry()->isValue() && type->isNativePointer())
                        || type->isValue()) {
                    QString type_name = type->name();
                    const ComplexTypeEntry *ctype = static_cast<const ComplexTypeEntry *>(type->typeEntry());
                    if(ctype->isAbstract())
                        type_name = type_name + "_ConcreteWrapper";
                    s << INDENT << "scope " << arg_name << " = new " << type_name
                                << "(cast(void*)(" << arg_ptr << "), QtdObjectInitFlags.onStack);" << endl;
                }
                s << endl;
            }
//            s << INDENT << "Stdout(\"" << d_class->name() << "\", \"" << signal->name() << "\").newline;" << endl;
            s << INDENT << "//d_object." << signal->name() << "_emit(";
            for (int j = 0; j<sz; ++j) {
                AbstractMetaArgument *argument = arguments.at(j);
                QString arg_name = argument->indexedName();
                if (j != 0)
                    s << ", ";
                s << arg_name;
            }

            s << ");" << endl;
        }
        s << "}*/" << endl;
    }
}

AbstractMetaFunctionList DGenerator::generatedClassFunctions(const AbstractMetaClass *d_class)
{
    AbstractMetaFunctionList r;
    AbstractMetaFunctionList d_funcs = d_class->functionsInTargetLang();
    for (int i=0; i<d_funcs.size(); ++i) {
        AbstractMetaFunction *function = d_funcs.at(i);

        // If a method in an interface class is modified to be private, this should
        // not be present in the interface at all, only in the implementation.
        if (d_class->isInterface()) {
            uint includedAttributes = 0;
            uint excludedAttributes = 0;
            retrieveModifications(function, d_class, &excludedAttributes, &includedAttributes);
            if (includedAttributes & AbstractMetaAttributes::Private)
                continue;
        }

        if (!notWrappedYet(function)) // qtd2
            r += function;
    }
    return r;
}

void DGenerator::write(QTextStream &s, const AbstractMetaClass *d_class)
{
    ReportHandler::debugSparse("Generating class: " + d_class->fullName());

    bool fakeClass = d_class->attributes() & AbstractMetaAttributes::Fake;


    QString auxModName = d_class->package() + "." + d_class->name() + "_aux";
    FileOut auxFile(outputDirectory() + "/" + subDirectoryForClass(d_class) + "/" + d_class->name() + "_aux.d");
    auxFile.isDone = true;
    auxFile.stream << "module " << auxModName << ";" << endl << endl;

    bool staticInit = d_class->isQObject() || d_class->typeEntry()->isValue()
                      || (global.cppShared && d_class->generateShellClass() && !d_class->isInterface() && !d_class->isNamespace());
    if (staticInit)
    {
        auxFile.isDone = false;
        auxFile.stream << "extern(C) void static_init_" << d_class->name() << "();" << endl;
        auxFile.stream << "shared static this() { static_init_" << d_class->name() << "; }" << endl << endl;
    }

    if (m_docs_enabled) {
        m_doc_parser = new DocParser(m_doc_directory + "/" + d_class->name().toLower() + ".jdoc");
    }
    if (!m_isRecursive)
        s << "module " << d_class->package() << "." << d_class->name() <<";" << endl << endl;

/*
    s << "// some type info" << endl;
    QString hasVirtuals = d_class->hasVirtualFunctions() ? "has" : "doesn't have";
    QString isFinal = d_class->isFinal() ? "is" : "is not";
    QString isNativeId = d_class->typeEntry()->isNativeIdBased() ? "is" : "is not";
    s << "// " << hasVirtuals << " virtual functions" << endl
      << "// " << isFinal << " final" << endl
      << "// " << isNativeId << " native id based" << endl << endl
      << "// " << d_class->generateShellClass() << " shell class" << endl
      << "// " << d_class->hasVirtualFunctions() << endl
      << "// " << d_class->hasProtectedFunctions() << endl
      << "// " << d_class->hasFieldAccessors() << endl
      << "// " << d_class->typeEntry()->isObject() << endl;
*/

    const ComplexTypeEntry *ctype = d_class->typeEntry();
    if (!ctype->addedTo.isEmpty() && !m_isRecursive) {
        ComplexTypeEntry *ctype_parent = TypeDatabase::instance()->findComplexType(ctype->addedTo);
        s << "public import " << ctype_parent->javaPackage() << "." << ctype_parent->name() << ";" << endl;
        return;
    }

    if(d_class->isInterface() && !m_isRecursive) {
        s << "public import " << ctype->javaPackage() << "." << ctype->qualifiedCppName() << ";" << endl;
        return;
    }
    AbstractMetaClassList includedClassesList;

    /* m_recursive is increasing by 1 each time we fill the import for a class
       if it equals to 0 or 1 imports Set is cleared before a filling cycle - if there
       is only one class as usual or if there are many classes in module, but before
       filling for first class we need to clear Set. Wow :)
       */
    if(ctype->includedClasses.size() > 0)
        m_recursive = 1;
    else
        m_recursive = 0;

    foreach(QString child, ctype->includedClasses) {
        ComplexTypeEntry *ctype_child = TypeDatabase::instance()->findComplexType(child);
        foreach (AbstractMetaClass *cls, m_classes) {
            if ( cls->name() == ctype_child->name() ) {
                includedClassesList << cls;
                fillRequiredImports(cls);
                excludedTypes2 << cls->name();
            }
        }
    }

    QString interface;
    if(d_class->typeEntry()->designatedInterface())
        interface = d_class->typeEntry()->designatedInterface()->name();

    if(d_class->typeEntry()->designatedInterface()) {
        foreach (AbstractMetaClass *cls, m_classes) {
            if ( cls->name() == interface ) {
                includedClassesList << cls;
                fillRequiredImports(cls);
                excludedTypes2 << cls->name();
            }
        }
    }

    fillRequiredImports(d_class);
    excludedTypes2 << d_class->name();
    if(ctype->includedClasses.size() > 0)
        m_recursive = 0;

    QList<Include> includes = d_class->typeEntry()->extraIncludes();
    foreach (const Include &inc, includes) {
        if (inc.type == Include::TargetLangImport) {
            s << inc.toString() << endl;
        }
    }

    // Auxiliary file contents should have been written at this point
    if (!auxFile.isDone)
    {
        s << "public import " << auxModName << ";" << endl;
        auxFile.done();
    }

    if (!m_isRecursive) {
        s << "public import qt.QGlobal;" << endl
          << "public import qt.core.Qt;" << endl
          << "import qtd.QtdObject;" << endl
          << "import qt.core.QString;" << endl
          << "import qtd.Array;" << endl
          << "import qt.core.QList;" << endl;
        if (d_class->isQObject()) {
            // TODO: just move those to a separate module publicly imported by QObject
            // or to QObject itself
            s << "public import qtd.MOC : Q_OBJECT;" << endl

              << "import qtd.Signal;" << endl
              << "import qt.core.QMetaObject;" << endl
              << "import qtd.meta.Runtime;" << endl;

            if (d_class->name() != "QObject")
                s << "import qt.core.QObject;" << endl;
        }

        // qtd2 hack!
        if (d_class->name() == "QCoreApplication")
            s << "private import qt.core.ArrayOps;" << endl;
        else if (d_class->name() == "QApplication")
            s << "private import qt.gui.ArrayOps;" << endl;

        /*
           we don't need to import ArrayOps2 for anything else than QObjects,
           for example if it is done in the namespaces, it may cause circular
           imports forward references and shit. If ArrayOps2 is expanded later
           for other usages - then restrict it just for namespaces/interfaces
        */
        if(d_class->isQObject())
            s << "private import " << d_class->package() << ".ArrayOps2;" << endl;

        s << "// automatic imports-------------" << endl;
        writeRequiredImports(s, d_class);
        s << endl;
        if (global.dPhobos)
        {
            s << "import std.stdio;" << endl
              << "import std.string : toStringz;" << endl
              << "import std.utf;" << endl
              << "import core.memory;" << endl;
        }
        else
        {
            s << "import tango.io.Stdout;" << endl
              << "import tango.stdc.stringz;" << endl
              << "import tango.text.convert.Utf;" << endl
              << "import tango.core.Memory;" << endl;
        }

        s << endl << endl;
    }

    if (m_doc_parser) {
        s << m_doc_parser->documentation(d_class) << endl << endl;
    }

/* qtd    s << "@QtJambiGeneratedClass" << endl;

    if ((d_class->typeEntry()->typeFlags() & ComplexTypeEntry::Deprecated) != 0) {
        s << "@Deprecated" << endl;
    }
*/


    if (d_class->isInterface()) {
        s << "public interface ";
    } else {
        if (d_class->isPublic())
            s << "public ";
        // else friendly

        bool force_abstract = (d_class->typeEntry()->typeFlags() & ComplexTypeEntry::ForceAbstract) != 0;
        if (d_class->isFinal() && !force_abstract)
            s << "final ";
        if ((d_class->isAbstract() && !d_class->isNamespace()) || force_abstract)
            s << "abstract ";

        if (!d_class->typeEntry()->targetType().isEmpty()) {
            s << d_class->typeEntry()->targetType() << " ";
        } else if (d_class->isNamespace() && d_class->functionsInTargetLang().size() == 0) {
            s << "interface ";
        } else if (d_class->isNamespace()) {
            s << "class ";
        } else {
            s << "class ";
        }

    }

    const ComplexTypeEntry *type = d_class->typeEntry();

    s << d_class->name();

    if (type->isGenericClass()) {
        s << "<";
        QList<TypeEntry *> templateArguments = d_class->templateBaseClass()->templateArguments();
        for (int i=0; i<templateArguments.size(); ++i) {
            TypeEntry *templateArgument = templateArguments.at(i);
            if (i > 0)
                s << ", ";
            s << templateArgument->name();
        }
        s << ">";
    }

    AbstractMetaClassList interfaces = d_class->interfaces();
    bool implements = false;
    if (!d_class->isNamespace() && !d_class->isInterface()) {
        if (!d_class->baseClassName().isEmpty()) {
            s << " : " << d_class->baseClass()->name();
            implements = true;
        } else {

            /*
            QString sc = type->defaultSuperclass();
            if ((sc != d_class->name()) && !sc.isEmpty()) {
                s << " : " << sc;
                implements = true;
            }
            */
            // only QObjects are handled polymorphically for now
            if (d_class->isQObject())
                s << " : PolymorphicObject";
            else
                s << " : QtdObject";
            implements = true;
        }
    }/* qtd else if (d_class->isInterface()) {
        s << " extends QtJambiInterface";
    }*/

    // implementing interfaces...
    for (int i=0; i<interfaces.size(); ++i) {
        if (implements)
            s << ", ";
        else {
            s << " : ";
            implements = true;
        }
        AbstractMetaClass *iface = interfaces.at(i);
        s << iface->name();
    }

/* qtd
    if (isComparable(d_class)) {
        if (!implements) {
            implements = true;
            s << endl << "    implements ";
        }
        else
            s << "," << endl << "            ";
        s << "java.lang.Comparable<Object>";
    }

    if (d_class->hasCloneOperator()) {
        if (!implements) {
            implements = true;
            s << endl << "    implements ";
        }
        else
            s << "," << endl << "            ";
        s << "java.lang.Cloneable";
    }
*/
    s << endl << "{" << endl;

    Indentation indent(INDENT);

    // Enums
    if (!d_class->typeEntry()->designatedInterface() && !d_class->enums().isEmpty()) {
        foreach (AbstractMetaEnum *d_enum, d_class->enums())
            writeEnum(s, d_enum, true);
    }

    // Enums in designated interfaces
    if (d_class->isInterface() && d_class->primaryInterfaceImplementor()) {
        foreach (AbstractMetaEnum *d_enum, d_class->primaryInterfaceImplementor()->enums())
            writeEnum(s, d_enum, true);
    }

    // Define variables for reference count mechanism
    if (!d_class->isInterface() && !d_class->isNamespace()) {
        QHash<QString, int> variables;
        foreach (AbstractMetaFunction *function, d_class->functions()) {
            QList<ReferenceCount> referenceCounts = function->referenceCounts(d_class);
            foreach (ReferenceCount refCount, referenceCounts) {
                variables[refCount.variableName] |= refCount.action
                                                    | refCount.access
                                                    | (refCount.threadSafe ? ReferenceCount::ThreadSafe : 0)
                                                    | (function->isStatic() ? ReferenceCount::Static : 0)
                                                    | (refCount.declareVariable.isEmpty() ? ReferenceCount::DeclareVariable : 0);
            }
        }

        foreach (QString variableName, variables.keys()) {
            int actions = variables.value(variableName) & ReferenceCount::ActionsMask;
//            bool threadSafe = variables.value(variableName) & ReferenceCount::ThreadSafe;
            bool isStatic = variables.value(variableName) & ReferenceCount::Static;
            bool declareVariable = variables.value(variableName) & ReferenceCount::DeclareVariable;
            int access = variables.value(variableName) & ReferenceCount::AccessMask;

            if (actions == ReferenceCount::Ignore || !declareVariable)
                continue;

            if (((actions & ReferenceCount::Add) == 0) != ((actions & ReferenceCount::Remove) == 0)) {
                QString warn = QString("either add or remove specified for reference count variable '%1' in '%2' but not both")
                    .arg(variableName).arg(d_class->fullName());
                ReportHandler::warning(warn);
            }
            s << endl;
/* qtd
            if (TypeDatabase::instance()->includeEclipseWarnings())
                s << INDENT << "@SuppressWarnings(\"unused\")" << endl;
*/
            if (actions != ReferenceCount::Set && actions != ReferenceCount::Ignore) { // qtd2

            s << INDENT;
            switch (access) {
            case ReferenceCount::Private:
                s << "package "; break; // qtd
            case ReferenceCount::Protected:
                s << "protected "; break;
            case ReferenceCount::Public:
                s << "public "; break;
            default:
                s << "protected"; // friendly
            }

            } // qtd2

            if (isStatic)
                s << "static ";

            if (actions != ReferenceCount::Set && actions != ReferenceCount::Ignore) {
                s << "Object[] " << variableName << ";" << endl;
/*
                if (threadSafe)
                    s << "java.util.Collections.synchronizedCollection(";
                s << "new java.util.ArrayList<Object>()";
                if (threadSafe)
                    s << ")";
                s << ";" << endl;*/
            } else if (actions != ReferenceCount::Ignore) {
/* qtd2               if (threadSafe)
                    s << "synchronized ";*/
                s << "Object " << variableName << " = null;" << endl;
            }
        }
        s << endl;
    }

/* qtd2
    if (!d_class->isInterface() && (!d_class->isNamespace() || d_class->functionsInTargetLang().size() > 0)
        && (d_class->baseClass() == 0 || d_class->package() != d_class->baseClass()->package())) {
        s << endl
          << INDENT << "static {" << endl;

        if (d_class->isNamespace()) {
            s << INDENT << "    qt.QtJambi_LibraryInitializer.init();" << endl;
        }

        s << INDENT << "    " << d_class->package() << ".QtJambi_LibraryInitializer.init();" << endl
          << INDENT << "}" << endl;
    }
*/

    // Signals
    if (d_class->isQObject())
    {
        AbstractMetaFunctionList signal_funcs = signalFunctions(d_class, false);
        writeSignalSignatures(s, d_class, signal_funcs);

        foreach (AbstractMetaFunction *signal, signal_funcs)
        {
            writeSignal(s, signal);
            if(!signal->isPrivate())
                writeFunction(s, signal);
        }
    }

    // Class has subclasses but also only private constructors
    if (!d_class->isFinalInTargetLang() && d_class->isFinalInCpp()) {
        s << endl << INDENT << "/**" << endl
          << INDENT << " * This constructor is a place holder intended to prevent" << endl
          << INDENT << " * users from subclassing the class. Certain classes can" << endl
          << INDENT << " * unfortunately only be subclasses internally. The constructor" << endl
          << INDENT << " * will indiscriminately throw an exception if called. If the" << endl
          << INDENT << " * exception is ignored, any use of the constructed object will" << endl
          << INDENT << " * cause an exception to occur." << endl << endl
          << INDENT << " * @throws QClassCannotBeSubclassedException" << endl
          << INDENT << " **/" << endl
          << INDENT << "protected " << d_class->name() << "() throws QClassCannotBeSubclassedException {" << endl
          << INDENT << "    throw new QClassCannotBeSubclassedException(" << d_class->name() << ".class);" << endl
          << INDENT << "}" << endl << endl;
    }
    s << "// Functions" << endl;

    // Functions
    AbstractMetaFunctionList d_funcs = d_class->functionsInTargetLang();
    AbstractMetaFunctionList d_funcs_gen = generatedClassFunctions(d_class);
    for (int i=0; i<d_funcs_gen.size(); ++i) {
        AbstractMetaFunction *function = d_funcs_gen.at(i);
//        if(function->isSlot())
//            writeSlot(s, function);
          writeFunction(s, function);
// qtd       s << function->minimalSignature() << endl;
    }
    if(d_class->isInterface())
        s << endl << INDENT << "public void* __ptr_" << d_class->name() << "();" << endl << endl;


    s << "// Field accessors" << endl;
    // Field accessors
    AbstractMetaFieldList fields = d_class->fields();
    foreach (const AbstractMetaField *field, fields) {
        if (field->wasPublic() || (field->wasProtected() && !d_class->isFinal()))
            writeFieldAccessors(s, field);
    }

    if (d_class->isQObject())
        writeQObjectFunctions(s, d_class);

    if (ctype->isObject() && !ctype->isQObject()) // conversion function wrapper to be consistent with QObject
    { // some code duplication, remove when there is a better mechanism for Object type conversions
        QString class_name = ctype->name();
        QString return_type_name = class_name;
        if(ctype->designatedInterface())
            return_type_name = ctype->designatedInterface()->name();
        s << "    static " << return_type_name << " __getObject(void* nativeId) {" << endl
          << "        return qtd_" << class_name << "_from_ptr(nativeId);" << endl
          << "    }" << endl << endl;
    }

    // flag to mark the type of class (to use in templates to convert arguments)
    if (d_class->baseClassName().isEmpty())
    {
        if (d_class->typeEntry()->isQObject())
            s << INDENT << "public alias void __isQObjectType;" << endl << endl;
        else if (d_class->typeEntry()->isObject())
            s << INDENT << "public alias void __isObjectType;" << endl << endl;
        else if (d_class->typeEntry()->isValue())
            s << INDENT << "public alias void __isValueType;" << endl << endl;
    }

    s << INDENT << "public alias void __isQtType_" << d_class->name() << ";" << endl << endl;

    // construction of a native copy of a Value
    if (d_class->typeEntry()->isValue())
    {
        AbstractMetaFunction *copy_ctor = d_class->copyConstructor();
        if (!d_class->typeEntry()->hasPrivateCopyConstructor()) // can do a copy if we have a public ctor or don't have any
            s << INDENT << "static void* __constructNativeCopy(const void* orig) {" << endl
              << INDENT << "    return qtd_" << d_class->name() << "_native_copy(orig);" << endl
              << INDENT << "}" << endl << endl

              << INDENT << "static void __constructPlacedNativeCopy(const void* orig, void* place) {" << endl
              << INDENT << "    qtd_" << d_class->name() << "_placed_copy(orig, place);" << endl
              << INDENT << "}" << endl << endl;
    }

    // Add dummy constructor for use when constructing subclasses
    if (!d_class->isNamespace() && !d_class->isInterface() && !fakeClass) {
        s << endl
          << INDENT << "public "
          << "this";

        s << "(void* nativeId, QtdObjectInitFlags initFlags = QtdObjectInitFlags.none) {" << endl;

        {
            Indentation indent(INDENT);

            if (d_class->name() == "QObject") {
                s << INDENT << "//assert (!(initFlags & QtdObjectInitFlags.onStack));" << endl
                  << INDENT << "qtdPin();" << endl
                  << INDENT << "_flags.isQObject = true;" << endl;
            }

            s << INDENT << "super(nativeId, initFlags);" << endl;

            // pointers to native interface objects for classes that implement interfaces
            // initializing
            interfaces = d_class->interfaces();
            if (!interfaces.isEmpty()) {
                for (int i=0; i<interfaces.size(); ++i) {
                    AbstractMetaClass *iface = interfaces.at(i);

                    s << INDENT << "    __m_ptr_" << iface->name() << " = qtd_" << d_class->name() << "_cast_to_" << iface->qualifiedCppName()
                      << "(nativeId);" << endl;
                }
            }
        }

        s << INDENT << "}" << endl << endl;

        // pointers to native interface objects for classes that implement interfaces
        // initializing
        interfaces = d_class->interfaces();
        if (!interfaces.isEmpty()) {
            for (int i=0; i<interfaces.size(); ++i) {
                AbstractMetaClass *iface = interfaces.at(i);

                s << INDENT << "private void* __m_ptr_" << iface->name() << ";" << endl
                  << INDENT << "public void* __ptr_" << iface->name() << "() { return __m_ptr_" << iface->name() << "; }" << endl << endl;
            }
        }

        writeDestructor(s, d_class);
    }

    if (d_class->typeEntry()->isValue())
        writeValueFunctions(s, d_class);
/* qtd
    // Add a function that converts an array of the value type to a QNativePointer
    if (d_class->typeEntry()->isValue() && !fakeClass) {
        s << endl
          << INDENT << "public static native QNativePointer nativePointerArray(" << d_class->name()
          << " array[]);" << endl;
    }

    // write the cast to this function....
    if (d_class->isInterface()) {
        s << endl
          << "    public long __qt_cast_to_"
          << static_cast<const InterfaceTypeEntry *>(type)->origin()->targetLangName()
          << "(long ptr);" << endl;
    } else {
        foreach (AbstractMetaClass *cls, interfaces) {
            s << endl
              << "    @QtBlockedSlot public native long __qt_cast_to_"
              << static_cast<const InterfaceTypeEntry *>(cls->typeEntry())->origin()->targetLangName()
              << "(long ptr);" << endl;
        }
    }
*/

/* qtd    writeJavaLangObjectOverrideFunctions(s, d_class);
*/
    writeOwnershipSetter(s, d_class);
    s << "// Injected code in class" << endl;
    writeExtraFunctions(s, d_class);
// qtd2    writeToStringFunction(s, d_class);
/* qtd
    if (d_class->hasCloneOperator()) {
        writeCloneFunction(s, d_class);
    }
*/
    s << "}" << endl; // end of class scope

    /* ---------------- injected free code ----------------*/
    const ComplexTypeEntry *class_type = d_class->typeEntry();
    Q_ASSERT(class_type);

    CodeSnipList code_snips = class_type->codeSnips();
    foreach (const CodeSnip &snip, code_snips) {
        if (!d_class->isInterface() && snip.language == TypeSystem::TargetLangFreeCode) {
            s << endl;
            snip.formattedCode(s, INDENT);
        }
    }
    /* --------------------------------------------------- */

    interfaces = d_class->interfaces();
    if (!interfaces.isEmpty()) {
        for (int i=0; i<interfaces.size(); ++i) {
            AbstractMetaClass *iface = interfaces.at(i);

            s << INDENT << "private static extern (C) void*" << "qtd_" << d_class->name() << "_cast_to_" << iface->qualifiedCppName()
                    << "(void* nativeId);" << endl;
        }
    }

    if (!d_class->isInterface() && d_class->isAbstract()) {
        s << endl;

        s << INDENT << "public class " << d_class->name() << "_ConcreteWrapper : " << d_class->name() << " {" << endl;

        {
            Indentation indent(INDENT);

            s << INDENT << "public this(void* native_id, QtdObjectInitFlags initFlags = QtdObjectInitFlags.nativeOwnership) {" << endl
              << INDENT << "    super(native_id, initFlags);" << endl << endl;

            s << INDENT << "}" << endl << endl;

            uint exclude_attributes = AbstractMetaAttributes::Native | AbstractMetaAttributes::Abstract;
            uint include_attributes = 0;
            AbstractMetaFunctionList functions = d_class->queryFunctions(AbstractMetaClass::NormalFunctions | AbstractMetaClass::AbstractFunctions | AbstractMetaClass::NonEmptyFunctions | AbstractMetaClass::NotRemovedFromTargetLang);
            foreach (const AbstractMetaFunction *d_function, functions) {
                retrieveModifications(d_function, d_class, &exclude_attributes, &include_attributes);
                if (notWrappedYet(d_function))
                    continue;
                s << endl
                  << INDENT << "override ";
                writeFunctionAttributes(s, d_function, include_attributes, exclude_attributes,
                                        d_function->isNormal() || d_function->isSignal() ? 0 : SkipReturnType);

                s << d_function->name() << "(";
                writeFunctionArguments(s, d_function, d_function->arguments().count());
                s << ")";

                if(d_function->isConstant())
                    s << " const";

                s << " {" << endl;
                {
                    Indentation indent(INDENT);
                    writeJavaCallThroughContents(s, d_function, SuperCall);
                }
                s << INDENT << "}" << endl;
            }
        }
        s  << INDENT << "}" << endl << endl;
    }

    if (d_class->generateShellClass()) { // qtd2
        if (d_class->isPolymorphic()
            && (d_class->typeEntry()->isObject() && !d_class->typeEntry()->isQObject()) )
        s << endl << "extern (C) void *__" << d_class->name() << "_entity(void *q_ptr);" << endl << endl;
    }

    if (d_class->typeEntry()->isValue())
    {
        AbstractMetaFunction *copy_ctor = d_class->copyConstructor();
        if (!d_class->typeEntry()->hasPrivateCopyConstructor())  // can do a copy if we have a public ctor or don't have any
        {
            s << "private extern(C) void qtd_" << d_class->name() << "_placed_copy(const void* orig, void* place);" << endl
              << "private extern(C) void* qtd_" << d_class->name() << "_native_copy(const void* orig);" << endl;
        }
    }

//    if (d_class->needsConversionFunc)
        writeConversionFunction(s, d_class);

    if (d_class->hasConstructors() && d_class->isDestructorBase())
        s << "extern (C) void qtd_" << d_class->name() << "_delete(void *ptr);" << endl
          << "extern (C) void qtd_" << d_class->name() << "_destroy(void *ptr);" << endl << endl;

    // qtd

    s << endl << "// C wrappers for signal emitters" << endl;

    if (d_class->isQObject())
    {
        AbstractMetaFunctionList signal_funcs = signalFunctions(d_class, false);

        foreach (AbstractMetaFunction *signal, signal_funcs)
            if(!signal->isPrivate())
                writePrivateNativeFunction(s, signal);
    }

    s << endl << "// C wrappers" << endl;
    d_funcs = d_class->functionsInTargetLang();
    if (!d_class->isInterface())
        for (int i=0; i<d_funcs.size(); ++i) {
            AbstractMetaFunction *function = d_funcs.at(i);

            if (!notWrappedYet(function)) // qtd2
                if (function->jumpTableId() == -1)
                    writePrivateNativeFunction(s, function);
        }


    s << "// Just the private functions for abstract functions implemeneted in superclasses" << endl;
    // Just the private functions for abstract functions implemeneted in superclasses
    if (!d_class->isInterface() && d_class->isAbstract()) {
        d_funcs = d_class->queryFunctions(AbstractMetaClass::NormalFunctions | AbstractMetaClass::AbstractFunctions | AbstractMetaClass::NotRemovedFromTargetLang);
        foreach (AbstractMetaFunction *d_function, d_funcs) {
            if (d_function->implementingClass() != d_class) {
                s << endl;
                writePrivateNativeFunction(s, d_function);
            }
        }
    }


    foreach (const AbstractMetaField *field, fields) {
        if (field->wasPublic() || (field->wasProtected() && !d_class->isFinal()))
            writeNativeField(s, field);
    }
    s << endl << endl;

    // qtd
    s << endl << "// Virtual Dispatch functions" << endl;
    AbstractMetaFunctionList virtualFunctions = d_class->virtualFunctions();
    for (int pos = 0; pos<virtualFunctions.size(); ++pos) {
        const AbstractMetaFunction *function = virtualFunctions.at(pos);
        if (!notWrappedYet(function)) // qtd2
            writeShellVirtualFunction(s, function, d_class, pos);
    }

    // write static constructor
    if (staticInit) {
        QString initArgs;
        if (global.cppShared && d_class->generateShellClass())
        {
            initArgs = "void* virtuals";
            if (d_class->name() == "QObject")
                initArgs += ", void* signals";

            s << "private extern (C) void qtd_" << d_class->name()
              << QString("_initCallBacks(%1);").arg(initArgs) << endl << endl;
        }

        s << "extern(C) void static_init_" << d_class->name() << "() {" << endl;

        if (d_class->typeEntry()->isValue())
            s << INDENT << d_class->name() << ".QTypeInfo.init();" << endl;

        if (global.cppShared && d_class->generateShellClass()) {

            AbstractMetaFunction::Options opts(AbstractMetaFunction::DeclaringClass | AbstractMetaFunction::NoExternNamespace);

            // virtual functions
            int virtuals_index = 0;
            QString virtuals_init;

            foreach (const AbstractMetaFunction *function, virtualFunctions) {
                if (!notWrappedYet(function) && d_class == function->declaringClass()) {
                    QString mName = function->marshalledName(opts);
                    virtuals_init += QString("    virt_arr[%1] = &qtd_export_%2_dispatch;\n").arg(virtuals_index).arg(mName);
                    virtuals_index++;
                }
            }

            if (virtuals_index == 0)
                initArgs = "null";
            else {
                s << "    void*[" << virtuals_index << "] virt_arr;" << endl;
                s << virtuals_init;
                initArgs = "virt_arr.ptr";
            }

            if (d_class->name() == "QObject") {
                // qt_metacall, metaObject
                s << endl << INDENT << "void*[2] sign_arr;" << endl;
                s << INDENT << "sign_arr[0] = &qtd_export_QObject_qt_metacall_dispatch;" << endl;
                s << INDENT << "sign_arr[1] = &qtd_export_QObject_metaObject_dispatch;" << endl;
                initArgs += ", sign_arr.ptr";
            }

            s << INDENT << "qtd_" << d_class->name() << QString("_initCallBacks(%1);").arg(initArgs) << endl;
        }

        s << "}" << endl << endl;
    }

    writeSignalHandlers(s, d_class);
    s << endl;

    if (m_docs_enabled) {
        delete m_doc_parser;
        m_doc_parser = 0;
    }

    // qtd multiple classes
    foreach (AbstractMetaClass *cls, includedClassesList) {
        m_isRecursive = true;
        write(s, cls);
        m_isRecursive = false;
    }

    if (d_class->isQObject())
        writeQObjectFreeFunctions(s, d_class);

    if (d_class->typeEntry()->isValue())
        writeValueFreeFunctions(s, d_class);
}

void DGenerator::writeValueFunctions(QTextStream &s, const AbstractMetaClass *d_class)
{
    s << INDENT << "struct QTypeInfo {" << endl;
    s << INDENT << "    static __gshared bool isComplex;" << endl;
    s << INDENT << "    static __gshared bool isStatic;" << endl;
    s << INDENT << "    static __gshared bool isLarge;" << endl;
    s << INDENT << "    static __gshared bool isPointer;" << endl;
    s << INDENT << "    static __gshared bool isDummy;" << endl << endl;

    s << INDENT << "    static init() {" << endl;

    s <<   QString("        isComplex = qtd_%1_QTypeInfo_isComplex();\n"
                   "        isStatic = qtd_%1_QTypeInfo_isStatic();\n"
                   "        isLarge = qtd_%1_QTypeInfo_isLarge();\n"
                   "        isPointer = qtd_%1_QTypeInfo_isPointer();\n"
                   "        isDummy = qtd_%1_QTypeInfo_isDummy();\n").arg(d_class->name())
                << "        }" << endl
                << "    }" << endl << endl;
}

void DGenerator::writeValueFreeFunctions(QTextStream &s, const AbstractMetaClass *d_class)
{
    s << QString("private extern (C) bool qtd_%1_QTypeInfo_isComplex();\n").arg(d_class->name());
    s << QString("private extern (C) bool qtd_%1_QTypeInfo_isStatic();\n").arg(d_class->name());
    s << QString("private extern (C) bool qtd_%1_QTypeInfo_isLarge();\n").arg(d_class->name());
    s << QString("private extern (C) bool qtd_%1_QTypeInfo_isPointer();\n").arg(d_class->name());
    s << QString("private extern (C) bool qtd_%1_QTypeInfo_isDummy();\n").arg(d_class->name());
}

void DGenerator::writeConversionFunction(QTextStream &s, const AbstractMetaClass *d_class)
{
    const ComplexTypeEntry *ctype = d_class->typeEntry();
    if(ctype->isQObject() || !ctype->isObject())
        return;
    QString class_name = ctype->name();
    QString return_type_name = class_name;
    if(ctype->designatedInterface())
        return_type_name = ctype->designatedInterface()->name();

    s << return_type_name << " qtd_" << class_name << "_from_ptr(void* ret) {" << endl;


    QString type_name = class_name;
    if(ctype->isAbstract())
        type_name = ctype->targetLangName() + "_ConcreteWrapper";

    // if class has virtual functions then it has classname_entity function so
    // we can look for D Object pointer. otherwise create new wrapper
    if (d_class->hasVirtualFunctions()) {
        s << INDENT << "void* d_obj = __" << ctype->targetLangName() << "_entity(ret);" << endl
          << INDENT << "if (d_obj !is null) {" << endl
          << INDENT << "    auto d_obj_ref = cast (Object) d_obj;" << endl
          << INDENT << "    return cast(" << return_type_name << ") d_obj_ref;" << endl
          << INDENT << "} else {" << endl
          << INDENT << "    auto return_value = new " << type_name << "(ret, QtdObjectInitFlags.nativeOwnership);" << endl
          << INDENT << "    return return_value;" << endl
          << INDENT << "}" << endl;
    } else {
        s << INDENT << "auto return_value = new " << type_name << "(ret, QtdObjectInitFlags.nativeOwnership);" << endl
          << INDENT << "return return_value;" << endl;
    }
    s << "}" << endl << endl;
}

void DGenerator::writeQObjectFreeFunctions(QTextStream &s, const AbstractMetaClass *d_class)
{
    s << "extern(C) QMetaObjectNative* qtd_" << d_class->name() << "_staticMetaObject();" << endl << endl
      << "extern(C) void qtd_" << d_class->name() << "_createEntity(void* nativeId, void* dId);" <<  endl << endl
      << "extern(C) int qtd_" << d_class->name() << "_qt_metacall(void *nativeId, MetaCall _c, int _id, void **_a);" << endl;

    QString prefix = global.cppShared ? "qtd_export_" : "qtd_";

    if (d_class->name() == "QObject") {
        s << "extern(C) int " << prefix << "QObject_qt_metacall_dispatch(void *d_entity, MetaCall _c, int _id, void **_a) {" << endl
          << "    auto d_object = cast(QObject) d_entity;" << endl
          << "    return d_object.qt_metacall(_c, _id, _a);" << endl
          << "};" << endl << endl;

        s << "extern(C) void* " << prefix << "QObject_metaObject_dispatch(void *d_entity) {" << endl
          << "    auto d_object = cast(QObject) d_entity;" << endl
          << "    return d_object.metaObject().nativeId();" << endl
          << "};" << endl << endl;
    }
}

void writeMetaMethodSignatures(QTextStream &s, const QString &var_name, AbstractMetaFunctionList meta_funcs)
{
    s << INDENT << "private static const string[] " << var_name << " = [";
    {
        Indentation indent(INDENT);
        for (int i = 0; i < meta_funcs.size(); ++i)
        {
            if (i)
                s << ", ";
            int j = 0;
            bool hasDefault = false;
            do // need this to look for default arguments and generate extra signatures
            {
                if (j)
                    s << ", ";
                s << endl << INDENT << "    \"" << meta_funcs.at(i)->minimalSignature(j) << "\"";
                AbstractMetaArgumentList args = meta_funcs.at(i)->arguments();
                if(args.size() && j<args.size())
                    hasDefault = !args.at(args.size() - 1 - j)->defaultValueExpression().isEmpty();
                else
                    hasDefault = false;
                j++;
            } while (hasDefault);
        }
    }
    s << INDENT << "];" << endl << endl;
}

void DGenerator::writeQObjectFunctions(QTextStream &s, const AbstractMetaClass *d_class)
{
    AbstractMetaFunctionList d_funcs_gen = generatedClassFunctions(d_class);
    AbstractMetaFunctionList slot_funcs;
    for (int i=0; i<d_funcs_gen.size(); ++i) {
      AbstractMetaFunction *function = d_funcs_gen.at(i);
      if(function->isSlot())
          slot_funcs += function;
    }
    writeMetaMethodSignatures(s, "__slotSignatures", slot_funcs);

    QString concrete_name = d_class->isAbstract() ? d_class->name() + "_ConcreteWrapper" : d_class->name();

    if (!d_class->isFinal()) {
        s << "    int qt_metacall(MetaCall _c, int _id, void **_a) {" << endl
          << "        return qtd_" << d_class->name() << "_qt_metacall(qtdNativeId, _c, _id, _a);" << endl
          << "    }" << endl << endl;
    }

    s << "    @property QMetaObject metaObject() {" << endl
      << "        return staticMetaObject;" << endl
      << "    }" << endl << endl

      << "    @property static QMetaObject staticMetaObject() {" << endl
      << "        return meta!(" << d_class->name() << ");" << endl
      << "    }" << endl << endl

      << "    static " << d_class->name() << " __getObject(void* nativeId) {" << endl
      << "        return static_cast!(" << d_class->name() << ")(staticMetaObject.getWrapper(nativeId));" << endl
      << "    }" << endl << endl

      << "    static void __createEntity(void* nativeId, void* dId) {" << endl
      << "        return qtd_" << d_class->name() << "_createEntity(nativeId, dId);" << endl
      << "    }" << endl << endl

      << "    static void* qtdNativeStaticMetaObject() {" << endl
      << "        return qtd_" << d_class->name() << "_staticMetaObject();" << endl
      << "    }" << endl

      << "    static QtdObject qtdCreateWrapper(void* nativeId, QtdObjectInitFlags initFlags) {" << endl
      << "        auto obj = new " << concrete_name << "(nativeId, initFlags);" << endl
      << "        " << d_class->name() << ".__createEntity(nativeId, cast(void*)obj);" << endl
      << "        return obj;" << endl
      << "    }" << endl << endl

      << "    static void _populateMetaInfo(QMetaObject mo) {" << endl
      << "        int index;" << endl << endl;

    AbstractMetaFunctionList signal_funcs = signalFunctions(d_class, false);

    int staticId = 0;
    for (int i = 0; i < signal_funcs.size(); ++i)
    {
      int j = 0;
      bool hasDefault = false;
      do // need this to look for default arguments and generate extra signatures
      {
          AbstractMetaFunction *fn = signal_funcs.at(i);
    s << "        index = mo.indexOfMethod_Cpp(__signalSignatures[" << staticId << "]);" << endl
      << "        mo.addMethod(new QMetaSignal(signature!(";
          writeMetaMethodArguments(s, fn, j);
    s << ")(\"" << fn->name() << "\"), index));" << endl << endl;
          AbstractMetaArgumentList args = fn->arguments();
          if(args.size() && j<args.size())
              hasDefault = !args.at(args.size() - 1 - j)->defaultValueExpression().isEmpty();
          else
              hasDefault = false;
          j++;
          staticId++;
      } while (hasDefault);
    }

    staticId = 0;
    for (int i = 0; i < slot_funcs.size(); ++i)
    {
      int j = 0;
      bool hasDefault = false;
      do // need this to look for default arguments and generate extra signatures
      {
          AbstractMetaFunction *fn = slot_funcs.at(i);
    s << "        index = mo.indexOfMethod_Cpp(__slotSignatures[" << staticId << "]);" << endl
      << "        mo.addMethod(new QMetaSlot(signature!(";
          writeMetaMethodArguments(s, fn, j);
    s << ")(\"" << fn->name() << "\"), index));" << endl << endl;
          AbstractMetaArgumentList args = fn->arguments();
          if(args.size() && j<args.size())
              hasDefault = !args.at(args.size() - 1 - j)->defaultValueExpression().isEmpty();
          else
              hasDefault = false;
          j++;
          staticId++;
      } while (hasDefault);
    }

    s  << "    }" << endl << endl;
}

void DGenerator::marshalFromCppToD(QTextStream &s, const ComplexTypeEntry* ctype)
{
    if(ctype->isQObject()) {
        QString type_name = ctype->name();
        if (ctype->isAbstract())
            type_name += "_ConcreteWrapper";
        s << "return " << type_name << ".__getObject(ret);" << endl;
    } else if (ctype->isValue() && !ctype->isStructInD()) {
        s << INDENT << "return new " << ctype->name() << "(ret);" << endl;
    } else if (ctype->isVariant()) {
        s << INDENT << "return new QVariant(ret);" << endl;
    } else if (ctype->name() == "QModelIndex" || ctype->isStructInD()) {
        s << INDENT << "return ret;" << endl;
    } else if (ctype->isObject()) {
        QString type_name = ctype->name();
        s << "return qtd_" << type_name << "_from_ptr(ret);" << endl;
    }
}

void DGenerator::writeNativeField(QTextStream &s, const AbstractMetaField *field)
{
    Q_ASSERT(field->isPublic() || field->isProtected());

    const AbstractMetaClass *declaringClass = field->enclosingClass();

    FieldModification mod = declaringClass->typeEntry()->fieldModification(field->name());

    // Set function
    if (mod.isWritable() && !field->type()->isConstant()) {
        const AbstractMetaFunction *setter = field->setter();
        if (declaringClass->hasFunction(setter)) {
            QString warning =
                QString("class '%1' already has setter '%2' for public field '%3'")
                .arg(declaringClass->name()).arg(setter->name()).arg(field->name());
            ReportHandler::warning(warning);
        } else {
            if (!notWrappedYet(setter))
                writePrivateNativeFunction(s, setter);
        }
    }

    // Get function
    const AbstractMetaFunction *getter = field->getter();
    if (mod.isReadable()) {
        if (declaringClass->hasFunction(getter)) {
            QString warning =
                QString("class '%1' already has getter '%2' for public field '%3'")
                .arg(declaringClass->name()).arg(getter->name()).arg(field->name());
            ReportHandler::warning(warning);
        } else {
            if (!notWrappedYet(getter))
                writePrivateNativeFunction(s, getter);
        }
    }
}

void DGenerator::writeSignalSignatures(QTextStream &s, const AbstractMetaClass *d_class, AbstractMetaFunctionList signal_funcs)
{
    writeMetaMethodSignatures(s, "__signalSignatures", signal_funcs);

    s << INDENT << "int signalSignature(int signalId, ref stringz signature) {" << endl;
    {
        Indentation indent(INDENT);

        if (d_class->name() != "QObject")
        {
            s << INDENT << "signalId = super.signalSignature(signalId, signature);" << endl
              << INDENT << "if (signature)" << endl
              << INDENT << "    return signalId;" << endl;
        }

        s << INDENT << "if (signalId < __signalSignatures.length)" << endl
          << INDENT << "    signature = __signalSignatures[signalId].ptr;" << endl
          << INDENT << "else" << endl
          << INDENT << "    signalId -= __signalSignatures.length;" << endl
          << INDENT << "return signalId;" << endl;
    }
    s << INDENT << "}" << endl;
}

void DGenerator::writeMetaMethodArguments(QTextStream &s, const AbstractMetaFunction *d_function, int reduce)
{
    bool withDefArgs = false;
    if(reduce == -1) {
        reduce = 0;
        withDefArgs = true;
    }

    AbstractMetaArgumentList arguments = d_function->arguments();
    int sz = arguments.count() - reduce;

    for (int i=0; i<sz; ++i) {
        if(i != 0)
            s << ",";

        QString modifiedType = d_function->typeReplaced(i+1);

        if (modifiedType.isEmpty())
            s << translateType(arguments.at(i)->type(), d_function->implementingClass(), BoxedPrimitive);
        else
            s << modifiedType;

        if (!arguments.at(i)->defaultValueExpression().isEmpty() && withDefArgs) // qtd
            s << " = " + arguments.at(i)->defaultValueExpression();
    }
}

void DGenerator::writeSignal(QTextStream &s, const AbstractMetaFunction *d_function)
{
    Q_ASSERT(d_function->isSignal());
/*
    s << INDENT << "mixin BindQtSignal!(\"" << d_function->name() << "(";

    writeMetaMethodArguments(s, d_function);

    s << ")\");" << endl;
    */
}

void DGenerator::writeShellVirtualFunction(QTextStream &s, const AbstractMetaFunction *d_function,
                                          const AbstractMetaClass *implementor, int id)
{
    Q_UNUSED(id);
    Q_UNUSED(implementor);

    if (implementor != d_function->declaringClass())
        return;

    CppImplGenerator::writeVirtualDispatchFunction(s, d_function, implementor, true);
    s << "{" << endl;

    const AbstractMetaClass *own_class = d_function->ownerClass();

    InterfaceTypeEntry *ite = own_class->typeEntry()->designatedInterface();
    if (ite)
        s << INDENT << "auto d_object = cast(" << ite->name() << ")cast(Object) dId;" << endl;
    else
        s << INDENT << "auto d_object = cast(" << own_class->name() << ") dId;" << endl;

    // the function arguments
    AbstractMetaArgumentList arguments = d_function->arguments();
    foreach (const AbstractMetaArgument *argument, arguments)
        if (!d_function->argumentRemoved(argument->argumentIndex() + 1)) {
            QString arg_name = argument->indexedName();
            AbstractMetaType *type = argument->type();
            // if has QString argument we have to pass char* and str.length to QString constructor
            {
                if (type->isContainer())
                {
                    if ( ((const ContainerTypeEntry *)type->typeEntry())->isQList() ) {
                        s << INDENT;
                        s << "auto " << arg_name << "_d_ref = cast(" << translateType(type, implementor) << "*)" << arg_name << ";" << endl;
                    }
                } else if(type->isEnum())
                    s << INDENT << "auto " << arg_name << "_enum = cast("
                                << type->typeEntry()->qualifiedTargetLangName() << ") " << arg_name << ";";
                else if (type->typeEntry()->qualifiedCppName() == "QChar")
                    s << INDENT << "auto " << arg_name << "_d_ref = cast(wchar" << QString(type->actualIndirections(), '*')
                                << ") " << arg_name << ";";
                else if (type->isTargetLangString())
                    s << INDENT << "string " << arg_name << "_d_ref = toUTF8("
                                << arg_name << "[0.." << arg_name << "_size]);";
                else if (type->typeEntry()->isValue() && type->isNativePointer() && type->typeEntry()->name() == "QString") {
                    s << INDENT << "auto " << arg_name << "_d_qstr = QStringUtil(" << arg_name << ", true);" << endl
                      << INDENT << "string " << arg_name << "_d_ref = " << arg_name << "_d_qstr.toNativeString();";
                } else if(type->isVariant())
                    s << INDENT << "scope " << arg_name << "_d_ref = new QVariant(" << arg_name << ", QtdObjectInitFlags.onStack);";
                else if (type->typeEntry()->isStructInD())
                    continue;
                else if (!type->hasNativeId() && !(type->typeEntry()->isValue() && type->isNativePointer()))
                    continue;
                else if(type->isObject()
                    || (type->typeEntry()->isValue() && type->isNativePointer())
                    || type->isValue() || type->isVariant()) {
                    QString type_name = type->typeEntry()->name();
                    const ComplexTypeEntry *ctype = static_cast<const ComplexTypeEntry *>(type->typeEntry());
                    if(ctype->isAbstract())
                        type_name = type_name + "_ConcreteWrapper";
                    s << INDENT << "scope " << arg_name << "_d_ref = new " << type_name << "(" << arg_name << ", QtdObjectInitFlags.onStack);";
                }
                else if (type->isQObject()) {
                    QString type_name = type->name();
                    const ComplexTypeEntry *ctype = static_cast<const ComplexTypeEntry *>(type->typeEntry());
                    if(ctype->isAbstract())
                        type_name = type_name + "_ConcreteWrapper";

                    s << INDENT << "scope " << arg_name << "_d_ref = new " << type_name << "(" << arg_name << ", QtdObjectInitFlags.onStack);" << endl;
                }
                s << endl;
            }
    }

    s << INDENT;
    AbstractMetaType *return_type = d_function->type();
    QString new_return_type = QString(d_function->typeReplaced(0)).replace('$', '.');
    bool has_return_type = new_return_type != "void"
        && (!new_return_type.isEmpty() || return_type != 0);
    if(has_return_type) {
        AbstractMetaType *f_type = d_function->type();
        if(f_type && (f_type->isObject() || f_type->isQObject() || f_type->isVariant() ||
                      (f_type->isValue() && !f_type->typeEntry()->isStructInD())))
        {
            QString f_type_name = f_type->name();
            if(f_type->typeEntry()->designatedInterface())
                f_type_name = f_type->typeEntry()->designatedInterface()->name();
            s << f_type_name << " ret_value = ";
        }
        else if (f_type && f_type->isTargetLangString())
            s << "string _d_str = ";
        else if (f_type && (f_type->name() == "QModelIndex" || f_type->typeEntry()->isStructInD()))
            s << "*__d_return_value = ";
        else
            s << "auto return_value = ";
    }
    s << "d_object." << d_function->name() << "(";

    uint nativeArgCount = 0;
    foreach (const AbstractMetaArgument *argument, arguments)
        if (!d_function->argumentRemoved(argument->argumentIndex() + 1)) {
            QString arg_name = argument->indexedName();
            const AbstractMetaType *type = argument->type();

            if (nativeArgCount > 0)
                s << "," << " ";

            QString modified_type = d_function->typeReplaced(argument->argumentIndex() + 1);
            if (!modified_type.isEmpty())
                modified_type = modified_type.replace('$', '.');

            if (modified_type == "string" /* && type->fullName() == "char" */)
                s << "fromStringz(" << arg_name << ")";
            else
            {
                if(type->isContainer()
                   || (type->isReference() && type->typeEntry()->isStructInD()))
                    s << "*";
                s << arg_name;
                if (type->isContainer() && ((const ContainerTypeEntry *)type->typeEntry())->isQList() )
                    s << "_d_ref";
            }
            if (type->typeEntry()->isStructInD()) ;
            else if (type->isQObject() || type->isObject()
                || (type->typeEntry()->isValue() && type->isNativePointer())
                || type->isValue()
                || type->isTargetLangString() || type->isVariant())
                s << "_d_ref";
            else if(type->isEnum())
                s << "_enum";

            nativeArgCount++;
        }
    s << ");" << endl;

    // check for arguments that may return value
    foreach (const AbstractMetaArgument *argument, arguments)
        if (!d_function->argumentRemoved(argument->argumentIndex() + 1)) {
            QString arg_name = argument->indexedName();
            AbstractMetaType *type = argument->type();

            if (type->typeEntry()->isValue() && type->isNativePointer() && type->typeEntry()->name() == "QString")
                s << INDENT << arg_name << "_d_qstr.assign(" << arg_name << "_d_ref);" << endl;
        }

    if(has_return_type) {
        AbstractMetaType *f_type = d_function->type();
        if(f_type) {
            if(f_type->isObject() || f_type->isQObject() || f_type->isVariant() ||
               (f_type->isValue() && !f_type->typeEntry()->isStructInD())) {
                QString native_id = "qtdNativeId";
                if (f_type->typeEntry()->designatedInterface())
                    native_id =  "__ptr_" + f_type->typeEntry()->designatedInterface()->name();
                s << INDENT << "return ret_value is null? null : ret_value." << native_id << ";" << endl;
            } else if (f_type->isTargetLangString())
                s << INDENT << "*ret_str = _d_str;" << endl;
            else if (f_type->isContainer()) {
                if (isNativeContainer(f_type))
                    s << INDENT << "*__d_arr = return_value;" << endl;
                else
                    s << INDENT << "*__d_arr_ptr = return_value.ptr;" << endl
                      << INDENT << "*__d_arr_size = return_value.length;" << endl;
            } else if (f_type->name() == "QModelIndex" || f_type->typeEntry()->isStructInD())
                ;
            else
                s << INDENT << "return return_value;" << endl;
        } else
            s << INDENT << "return return_value;" << endl;

    }

    s << "}" << endl << endl;
}

void DGenerator::generate()
{
    // qtd
    // code for including classses in 1 module for avoiding circular imports
    foreach (AbstractMetaClass *cls, m_classes) {
        const ComplexTypeEntry *ctype = cls->typeEntry();

        if (!cls->isInterface() && cls->isAbstract()) {
            ComplexTypeEntry *ctype_m = (ComplexTypeEntry *)ctype;
            ctype_m->setAbstract(true);
        }

        foreach(QString child, ctype->includedClasses) {
            ComplexTypeEntry *ctype_child = TypeDatabase::instance()->findComplexType(child);
            ctype_child->addedTo = cls->name();
        }

/* we don't need this anymore
        // generate QObject conversion functions only those that are required
        AbstractMetaFunctionList d_funcs = cls->functionsInTargetLang();
        for (int i=0; i<d_funcs.size(); ++i) {
            AbstractMetaType *f_type = d_funcs.at(i)->type();
            if (!f_type)
                continue;
            if (f_type->isQObject() || f_type->isObject()) {
                const ComplexTypeEntry* cte = static_cast<const ComplexTypeEntry *>(f_type->typeEntry());
                AbstractMetaClass* d_class = ClassFromEntry::get(cte);
                if (d_class)
                    d_class->needsConversionFunc = true;
            }
        }*/
    }

    Generator::generate();

    {
        const AbstractMetaClass *last_class = 0;
        QFile file("mjb_nativepointer_api.log");
        if (file.open(QFile::WriteOnly)) {
            QTextStream s(&file);

            AbstractMetaFunctionList nativepointer_functions;
            for (int i=0; i<m_nativepointer_functions.size(); ++i) {
                AbstractMetaFunction *f = const_cast<AbstractMetaFunction *>(m_nativepointer_functions[i]);
                if (f->ownerClass() == f->declaringClass() || f->isFinal())
                    nativepointer_functions.append(f);
            }

            s << "Number of public or protected functions with QNativePointer API: " << nativepointer_functions.size() << endl;
            foreach (const AbstractMetaFunction *f, nativepointer_functions) {
                if (last_class != f->ownerClass()) {
                    last_class = f->ownerClass();
                    s << endl << endl<< "Class " << last_class->name() << ":" << endl;
                    s << "---------------------------------------------------------------------------------"
                    << endl;
                }

                s << f->minimalSignature() << endl;
            }

            m_nativepointer_functions.clear();        }
    }

    {
        const AbstractMetaClass *last_class = 0;
        QFile file("mjb_object_type_usage.log");
        if (file.open(QFile::WriteOnly)) {
            QTextStream s(&file);

            AbstractMetaFunctionList resettable_object_functions;
            for (int i=0; i<m_resettable_object_functions.size(); ++i) {
                AbstractMetaFunction *f = const_cast<AbstractMetaFunction *>(m_resettable_object_functions[i]);
                if (f->ownerClass() == f->declaringClass() || f->isFinal())
                    resettable_object_functions.append(f);
            }

            s << "Number of public or protected functions that return a non-QObject object type, or that are virtual and take a non-QObject object type argument: " << resettable_object_functions.size() << endl;
            foreach (const AbstractMetaFunction *f, resettable_object_functions) {
                if (last_class != f->ownerClass()) {
                    last_class = f->ownerClass();
                    s << endl << endl<< "Class " << last_class->name() << ":" << endl;
                    s << "---------------------------------------------------------------------------------"
                    << endl;
                }

                s << f->minimalSignature() << endl;
            }

            m_resettable_object_functions.clear();        }
    }

    {
        QFile file("mjb_reference_count_candidates.log");
        if (file.open(QFile::WriteOnly)) {
            QTextStream s(&file);

            s << "The following functions have a signature pattern which may imply that" << endl
              << "they need to apply reference counting to their arguments ("
              << m_reference_count_candidate_functions.size() << " functions) : " << endl;

              foreach (const AbstractMetaFunction *f, m_reference_count_candidate_functions) {
                  s << f->implementingClass()->fullName() << " : " << f->minimalSignature() << endl;
              }
        }
        file.close();
    }
}

void DGenerator::writeFunctionAttributes(QTextStream &s, const AbstractMetaFunction *d_function,
                                            uint included_attributes, uint excluded_attributes,
                                            uint options)
{
    uint attr = (d_function->attributes() & (~excluded_attributes)) | included_attributes;

    if ((attr & AbstractMetaAttributes::Public) || (attr & AbstractMetaAttributes::Protected)) {

        // Does the function use native pointer API?
        bool nativePointer = d_function->type() && d_function->type()->isNativePointer()
                             && d_function->typeReplaced(0).isEmpty();

        // Does the function need to be considered for resetting the Java objects after use?
        bool resettableObject = false;

        if (!nativePointer
            && d_function->type()
            && d_function->type()->hasInstantiations()
            && d_function->typeReplaced(0).isEmpty()) {

            QList<AbstractMetaType *> instantiations = d_function->type()->instantiations();

            foreach (const AbstractMetaType *type, instantiations) {
                if (type && type->isNativePointer()) {
                    nativePointer = true;
                    break;
                }
            }

        }

        AbstractMetaArgumentList arguments = d_function->arguments();
        if (!nativePointer || (!resettableObject && !d_function->isFinal())) {
            foreach (const AbstractMetaArgument *argument, arguments) {
                if (!d_function->argumentRemoved(argument->argumentIndex()+1)
                    && d_function->typeReplaced(argument->argumentIndex()+1).isEmpty()) {

                    if (argument->type()->isNativePointer()) {

                        nativePointer = true;
                        if (resettableObject) break ;

                    } else if (!d_function->isFinalInTargetLang()
                                && argument->type()->isObject()
                                && !argument->type()->isQObject()
                                && !d_function->resetObjectAfterUse(argument->argumentIndex()+1)
                                && d_function->ownership(d_function->declaringClass(), TypeSystem::ShellCode, argument->argumentIndex()+1) == TypeSystem::InvalidOwnership) {

                        resettableObject = true;
                        if (nativePointer) break ;

                    } else if (argument->type()->hasInstantiations()) {

                        QList<AbstractMetaType *> instantiations = argument->type()->instantiations();
                        foreach (AbstractMetaType *type, instantiations) {
                            if (type && type->isNativePointer()) {
                                nativePointer = true;
                                if (resettableObject) break;
                            } else if (!d_function->isFinal()
                                       && type
                                       && type->isObject()
                                       && !type->isQObject()
                                       && !d_function->resetObjectAfterUse(argument->argumentIndex()+1)) {
                                resettableObject = true;
                                if (nativePointer) break ;
                            }
                        }

                        if (nativePointer && resettableObject)
                            break;

                    }
                }
            }
        }

        if (nativePointer && !m_nativepointer_functions.contains(d_function))
            m_nativepointer_functions.append(d_function);
        if (resettableObject && !m_resettable_object_functions.contains(d_function))
            m_resettable_object_functions.append(d_function);
    }

    if ((options & SkipAttributes) == 0) {
        if (d_function->isEmptyFunction()
            || d_function->isDeprecated()) s << INDENT << "deprecated ";
/*
        bool needsSuppressUnusedWarning = TypeDatabase::instance()->includeEclipseWarnings()
                                          && d_function->isSignal()
                                          && (((excluded_attributes & AbstractMetaAttributes::Private) == 0)
                                               && (d_function->isPrivate()
                                                   || ((included_attributes & AbstractMetaAttributes::Private) != 0)));

        if (needsSuppressUnusedWarning && d_function->needsSuppressUncheckedWarning()) {
            s << INDENT<< "@SuppressWarnings({\"unchecked\", \"unused\"})" << endl;
        } else if (d_function->needsSuppressUncheckedWarning()) {
            s << INDENT<< "@SuppressWarnings(\"unchecked\")" << endl;
        } else if (needsSuppressUnusedWarning) {
            s << INDENT<< "@SuppressWarnings(\"unused\")" << endl;
        }

        if (!(attr & NoBlockedSlot)
            && !d_function->isConstructor()
            && !d_function->isSlot()
            && !d_function->isSignal()
            && !d_function->isStatic()
            && !(included_attributes & AbstractMetaAttributes::Static))
            s << INDENT << "@QtBlockedSlot" << endl;
*/
        if (!(options & ExternC))
            s << INDENT;

        if (attr & AbstractMetaAttributes::Public) s << "public ";
        else if (attr & AbstractMetaAttributes::Protected) s << "protected ";
        else if (attr & AbstractMetaAttributes::Private) s << "private ";
        else if (attr & AbstractMetaAttributes::Native) s << "private extern(C) ";
        bool isStatic = (attr & AbstractMetaAttributes::Static);

        if (attr & AbstractMetaAttributes::Native) ;
        else if (!isStatic && (attr & AbstractMetaAttributes::FinalInTargetLang)) s << "final ";
        else if (!isStatic && (attr & AbstractMetaAttributes::Abstract)) s << "abstract ";

        if (isStatic && !(options & ExternC)) s << "static ";
    }

    if ((options & SkipReturnType) == 0) {
        QString modified_type = d_function->typeReplaced(0);
        if (options & ExternC) {
            uint options = 0x0004; // qtd externC
            s << CppImplGenerator::jniReturnName(d_function, options, true) << " ";
        }
        else if (modified_type.isEmpty())
            s << translateType(d_function->type(), d_function->implementingClass(), (Option) options);
        else
            s << modified_type.replace('$', '.');
        s << " ";
    }

}

void DGenerator::writeConstructorContents(QTextStream &s, const AbstractMetaFunction *d_function)
{
    // Write constructor
    s << " {" << endl;
    {
        Indentation indent(INDENT);
        writeJavaCallThroughContents(s, d_function);

        // Write out expense checks if present...
        const AbstractMetaClass *d_class = d_function->implementingClass();
        const ComplexTypeEntry *te = d_class->typeEntry();
        if (te->expensePolicy().isValid()) {
            s << endl;
            const ExpensePolicy &ep = te->expensePolicy();
            s << INDENT << "qt.GeneratorUtilities.countExpense(" << d_class->fullName()
              << ".class, " << ep.cost << ", " << ep.limit << ");" << endl;
        }

        foreach (CodeSnip snip, te->codeSnips()) {
            if (snip.language == TypeSystem::Constructors) {
                snip.formattedCode(s, INDENT);
            }
        }

        s << INDENT << "this(ret, QtdObjectInitFlags.createdByD);" << endl;
    }
    s << INDENT << "}" << endl << endl;

/* qtd    // Write native constructor
    if (d_function->jumpTableId() == -1)
        writePrivateNativeFunction(s, d_function);
*/
}

void DGenerator::writeFunctionArguments(QTextStream &s, const AbstractMetaFunction *d_function,
                                           int argument_count, uint options)
{
    AbstractMetaArgumentList arguments = d_function->arguments();

    if (argument_count == -1)
        argument_count = arguments.size();

    for (int i=0; i<argument_count; ++i) {
        if (!d_function->argumentRemoved(i+1)) {
            if (i != 0)
                s << ", ";
            writeArgument(s, d_function, arguments.at(i), options);
        }
    }
}


void DGenerator::writeExtraFunctions(QTextStream &s, const AbstractMetaClass *d_class)
{
    const ComplexTypeEntry *class_type = d_class->typeEntry();
    Q_ASSERT(class_type);

    CodeSnipList code_snips = class_type->codeSnips();
    foreach (const CodeSnip &snip, code_snips) {
        if ((!d_class->isInterface() && snip.language == TypeSystem::TargetLangCode)
            || (d_class->isInterface() && snip.language == TypeSystem::Interface)) {
            s << endl;
            snip.formattedCode(s, INDENT);
        }
    }
}


void DGenerator::writeToStringFunction(QTextStream &s, const AbstractMetaClass *d_class)
{
    bool generate = d_class->hasToStringCapability() && !d_class->hasDefaultToStringFunction();
    bool core = d_class->package() == QLatin1String("qt.core");
    bool qevent = false;

    const AbstractMetaClass *cls = d_class;
    while (cls) {
        if (cls->name() == "QEvent") {
            qevent = true;
            break;
        }
        cls = cls->baseClass();
    }

    if (generate || qevent) {

        if (qevent && core) {
            s << endl
              << "    @Override" << endl
              << "    public String toString() {" << endl
              << "        return getClass().getSimpleName() + \"(type=\" + type().name() + \")\";" << endl
              << "    }" << endl;
        } else {
            s << endl
              << "    @Override" << endl
              << "    public String toString() {" << endl
              << "        if (qtdNativeId == 0)" << endl
              << "            throw new QNoNativeResourcesException(\"Function call on incomplete object of type: \" +getClass().getName());" << endl
              << "        return __qt_toString(nativeId());" << endl
              << "    }" << endl
              << "    native String __qt_toString(long __this_nativeId);" << endl;
        }
    }
}

void DGenerator::writeCloneFunction(QTextStream &s, const AbstractMetaClass *d_class)
{
    s << endl
      << "    @Override" << endl
      << "    public " << d_class->name() << " clone() {" << endl
      << "        if (nativeId() == 0)" << endl
      << "            throw new QNoNativeResourcesException(\"Function call on incomplete object of type: \" +getClass().getName());" << endl
      << "        return __qt_clone(nativeId());" << endl
      << "    }" << endl
      << "    native " << d_class->name() << " __qt_clone(long __this_nativeId);" << endl;
}

void DGenerator::writeDExport(QTextStream &s, QString retType, QString name, QString args, QString funcBody)
{
    QString ext = "extern (C)";

    if (global.cppShared) {
        QString exp;
        if (global.targetPlatform == Global::Win32Target)
            exp = "export";

        s << QString(
            "    %5 %1 qtd_export_%2(%3) { %4 }\n"
            "    %5 %6 void qtd_set_%2(VoidFunc func);\n"
            "    static this() { qtd_set_%2(cast(VoidFunc)&qtd_export_%2); }\n")
            .arg(retType, name, args, funcBody, ext, exp);
    } else {
        s << QString("%5 %1 qtd_%2(%3) { %4 }\n")
                .arg(retType, name, args, funcBody, ext);
    }
}

ClassFromEntry* ClassFromEntry::m_instance = NULL;

ClassFromEntry::ClassFromEntry()
{
}

AbstractMetaClass* ClassFromEntry::get(const TypeEntry *ctype)
{
    if(!m_instance)
        return NULL;

    return m_instance->classFromEntry[ctype];
}

void ClassFromEntry::construct(const AbstractMetaClassList &classes)
{
    if(!m_instance) {
        m_instance = new ClassFromEntry;
        m_instance->setClasses(classes);
        m_instance->buildHash();
    }
}

void ClassFromEntry::buildHash()
{
    foreach (AbstractMetaClass *cls, m_classes) {
        const ComplexTypeEntry *ctype = cls->typeEntry();
        classFromEntry[ctype] = cls;
    }
}

void ClassFromEntry::print(QTextStream &s)
{
    s << m_instance->m_classes.size();
    foreach (AbstractMetaClass *cls, m_instance->m_classes) {
        s << cls->name() << endl;
    }
}

