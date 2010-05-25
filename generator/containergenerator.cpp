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

#include "containergenerator.h"
#include "cppimplgenerator.h"
#include "fileout.h"

static Indentor INDENT;

ContainerGenerator::ContainerGenerator(CppImplGenerator *cpp_impl_generator):
        DGenerator(), m_cpp_impl_generator(cpp_impl_generator)

{
    setFilenameStub("ArrayOps");
    excludedTypes.clear();

    // qtd2
    excludedTypes << "QFuture";
}

QString ContainerGenerator::subDirectoryForPackage(const QString &package, OutputDirectoryType type) const
{
    switch (type) {
    case CppDirectory:
        return "cpp/" + QString(package).replace(".", "_") + "/";
    case DDirectory:
        return QString(package).replace(".", "/");
    case HDirectory:
        return "include/";
    default:
        return QString(); // kill nonsense warnings
    }
}

void ContainerGenerator::write(QTextStream &, const AbstractMetaClass *)
{
    // not used
}

void ContainerGenerator::addTypeEntry(const TypeEntry* te)
{
    if (!excludedTypes.contains(te->name()))
        containerTypes << te;
}

void ContainerGenerator::processType(AbstractMetaType *d_type)
{
    if (d_type->isContainer()) {
        QList<AbstractMetaType *> args = d_type->instantiations();

        if (args.size() == 1) // QVector or QList
            if (args.at(0)->typeEntry()->isComplex()
                && !args.at(0)->isContainer()
                && !args.at(0)->isTargetLangString())
                addTypeEntry(args.at(0)->typeEntry()); // qMakePair(args.at(0)->typeEntry(), m_class);
    }
}

void ContainerGenerator::processFunction(const AbstractMetaFunction *d_function)
{
    if (notWrappedYet(d_function)) // qtd2
        return;

    if (d_function->type()) {
        AbstractMetaType *d_type = d_function->type();
        if (d_type->isContainer()) {
            processType(d_type);
        }
    }

    AbstractMetaArgumentList arguments = d_function->arguments();
    for (int i=0; i<arguments.count(); ++i) {
        const AbstractMetaArgument *arg = arguments.at(i);
        processType(arg->type());
    }
}

void ContainerGenerator::buildTypeList()
{
    foreach (AbstractMetaClass *d_class, classes()) {
m_class = d_class;
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

            processFunction(function);
        }

        AbstractMetaFieldList fields = d_class->fields();
        foreach (const AbstractMetaField *field, fields) {
            if (field->wasPublic() || (field->wasProtected() && !d_class->isFinal())) {
                processFunction(field->setter());
                processFunction(field->getter());
            }
        }

        AbstractMetaFunctionList signal_funcs = signalFunctions(d_class);
        for(int i = 0; i < signal_funcs.size(); i++) {
            AbstractMetaFunction *signal = signal_funcs.at(i);

            AbstractMetaArgumentList arguments = signal->arguments();
            foreach (AbstractMetaArgument *argument, arguments) {
                if(argument->type()->isContainer()) {
                    bool inList = false;
                    foreach(AbstractMetaType* type, signalEntries[d_class->package()]) {
                        const TypeEntry *teInList = type->instantiations().first()->typeEntry();
                        const TypeEntry *te = argument->type()->instantiations().first()->typeEntry();

                        if ((te == teInList) && (argument->type()->typeEntry() == type->typeEntry()))
                            inList = true;
                    }
                    if (!inList)
                        (signalEntries[d_class->package()]) << argument->type();
//                    (signalEntries[d_class->package()])[argument->type()->instantiations().first()->typeEntry()] = argument->type();
                }
            }
        }
    }
}

void ContainerGenerator::generate()
{
    buildTypeList();

    writeFile(cppFilename(), CppDirectory, &ContainerGenerator::writeCppContent); // cpp file
    writeFile("ArrayOps_%1.h", HDirectory, &ContainerGenerator::writeHeaderContent); // header file
    writeFile(dFilename(), DDirectory, &ContainerGenerator::writeDContent); // d file
    writeFile("ArrayOps2.d", DDirectory, &ContainerGenerator::writeDContent2); // d file
}

void ContainerGenerator::writeFile(const QString& fileName, OutputDirectoryType dirType, WriteOut writeOut)
{
    AbstractMetaClassList classList = classes();
    QHash<QString, FileOut *> fileHash;

    // Seems continue is not supported by our foreach loop, so
    foreach (AbstractMetaClass *cls, classList) {

        FileOut *f = fileHash.value(cls->package(), 0);
        if (f == 0) {
            f = new FileOut(outputDirectory() + "/" + subDirectoryForPackage(cls->package(), dirType) + "/" +
                    fileName.arg(cls->package().replace(".", "_")));
            writeNotice(f->stream);

            (this->*writeOut)(f->stream, cls);

            fileHash.insert(cls->package(), f);

//            QString pro_file_name = cls->package().replace(".", "_") + "/" + cls->package().replace(".", "_") + ".pri";
//            priGenerator->addSource(pro_file_name, cppFilename());
        }
    }

    foreach (QString package, fileHash.keys()) {
        FileOut *f = fileHash.value(package, 0);
        if (f != 0) {
            if( f->done() )
                ++m_num_generated_written;
            ++m_num_generated;

            delete f;
        }
    }
}

void ContainerGenerator::writeCppContent(QTextStream &s, AbstractMetaClass *cls)
{
    QString package = cls->package().replace(".", "_");

    s << "// stuff for passing D function pointers" << endl << endl
      << "#include \"qtd_masterinclude.h\"" << endl << endl
      << "#include \"qtd_core.h\"" << endl
      << "#include \"ArrayOps_" << package << ".h\"" << endl
      << "#include \"ArrayOps_qt_core.h\"" << endl
      << "#include \"ArrayOpsPrimitive.h\"" << endl << endl
      << "#ifdef CPP_SHARED" << endl << endl;


    foreach (const TypeEntry *te, containerTypes) {
        if (te->javaPackage() == cls->package()) {
            const ComplexTypeEntry *centry = static_cast<const ComplexTypeEntry *>(te);
            QString cls_name = centry->name();

            setFuncNames(cls_name);
            s << "QTD_EXPORT_VAR(" << all_name << ")" << endl
              << "QTD_EXPORT_VAR(" << ass_name << ")" << endl
              << "QTD_EXPORT_VAR(" << get_name << ")" << endl << endl;
        }
    }

    s << endl
      << "extern \"C\" DLL_PUBLIC void qtd_" << cls->package().replace(".", "_") << "_ArrayOps_initCallBacks(pfunc_abstr *callbacks)" << endl
      << "{" << endl;

    int num_funcs = 0;
    foreach (const TypeEntry *te, containerTypes) {
        if (te->javaPackage() == cls->package()) {
            const ComplexTypeEntry *centry = static_cast<const ComplexTypeEntry *>(te);
            QString cls_name = centry->name();

            setFuncNames(cls_name);
            s << "    QTD_EXPORT_VAR_SET(" << all_name << ", callbacks[" << num_funcs + 0 << "]);" << endl
              << "    QTD_EXPORT_VAR_SET(" << ass_name << ", callbacks[" << num_funcs + 1 << "]);" << endl
              << "    QTD_EXPORT_VAR_SET(" << get_name << ", callbacks[" << num_funcs + 2 << "]);" << endl << endl;

            num_funcs += NUM_ARRAY_FUNCS;
        }
    }
    s << "}" << endl
      << "#endif" << endl;
/*
    QMap<const TypeEntry*, AbstractMetaType*> typeList = signalEntries[cls->package()];

    QMapIterator<const TypeEntry*, AbstractMetaType*> i(typeList);
    while (i.hasNext()) {
        i.next();
        s << "// " << i.key()->targetLangName() << endl
          << "extern \"C\" DLL_PUBLIC void qtd_" << package << "_" << i.key()->targetLangName() << "_to_d_array(void *cpp_ptr, DArray* __d_container) {" << endl;

        AbstractMetaType *arg_type = i.value();
        m_cpp_impl_generator->writeTypeInfo(s, arg_type, NoOption);
        s << "container = (*reinterpret_cast< ";
        m_cpp_impl_generator->writeTypeInfo(s, arg_type, ExcludeReference);
        s << "(*)>(cpp_ptr));" << endl;

        m_cpp_impl_generator->writeQtToJavaContainer(s, arg_type, "container", "__d_container", 0, -1);
        s << "}" << endl;
    }*/

    s << "// signal conversion functions" << endl;

    foreach(AbstractMetaType* arg_type, signalEntries[cls->package()]) {
        const TypeEntry *te = arg_type->instantiations().first()->typeEntry();
        s << "// " << te->targetLangName() << endl
          << "extern \"C\" DLL_PUBLIC void " << cppContainerConversionName(cls, arg_type, FromCpp) << "(void *cpp_ptr, DArray* __d_container) {" << endl;

        m_cpp_impl_generator->writeTypeInfo(s, arg_type, NoOption);
        s << "container = (*reinterpret_cast< ";
        m_cpp_impl_generator->writeTypeInfo(s, arg_type, ExcludeReference);
        s << "(*)>(cpp_ptr));" << endl;

        m_cpp_impl_generator->writeQtToJavaContainer(s, arg_type, "container", "__d_container", 0, -1);
        s << "}" << endl;
    }
}

void ContainerGenerator::writeHeaderContent(QTextStream &s, AbstractMetaClass *cls)
{
    QString file_upper = "ArrayOps_" + QString(cls->package()).replace(".", "_") + "_h";
    file_upper = file_upper.toUpper();
    s << "#ifndef " << file_upper << endl
      << "#define " << file_upper << endl << endl
      << "#include <cstring>" << endl
      << "#include \"qtd_core.h\"" << endl << endl;

    foreach (const TypeEntry *te, containerTypes) {
        if (te->javaPackage() == cls->package()) {
            const ComplexTypeEntry *typeEntry = static_cast<const ComplexTypeEntry *>(te);
            s << "// " << typeEntry->name() << endl; // " in " << it.second->name() << endl;

            Indentation indent(INDENT);
            writeHeaderArrayFunctions(s, typeEntry);
        }
    }

    s << "#endif // " << file_upper << endl;
}

void ContainerGenerator::setFuncNames(const QString& cls_name)
{
    all_name = QString("qtd_allocate_%1_array").arg(cls_name);
    ass_name = QString("qtd_assign_%1_array_element").arg(cls_name);
    get_name = QString("qtd_get_%1_from_array").arg(cls_name);
}

void ContainerGenerator::writeHeaderArrayFunctions(QTextStream &s, const ComplexTypeEntry *centry)
{
    QString cls_name = centry->name();
    bool d_export = true;
    QString d_type, cpp_type, cpp_type_assign;

    if (centry->name() == "QModelIndex") {
        cpp_type = "QModelIndexAccessor*";
    } else if (centry->isStructInD()) {
        cpp_type = centry->qualifiedCppName() + "*";
    } else if (centry->isObject() || centry->isQObject() || centry->isValue() || centry->isInterface() || centry->isVariant()) {
        cpp_type = "void*";
    }

    setFuncNames(cls_name);

    s << "QTD_EXPORT(void, " << all_name << ", (void* arr, size_t len))" << endl
      << "QTD_EXPORT(void, " << ass_name << ", (void* arr, size_t pos, " << cpp_type << " elem))" << endl
      << "QTD_EXPORT(void, " << get_name << ", (void* arr, size_t pos, " << cpp_type << " elem))" << endl;

    s << "#ifdef CPP_SHARED" << endl
      << "#define " << all_name << " qtd_get_" << all_name << "()" << endl
      << "#define " << ass_name << " qtd_get_" << ass_name << "()" << endl
      << "#define " << get_name << " qtd_get_" << get_name << "()" << endl
      << "#endif" << endl;

    s << endl;
}

void ContainerGenerator::writeDContent(QTextStream &s, AbstractMetaClass *cls)
{
    s << "module " << cls->package() << ".ArrayOps;" << endl << endl;

    int num_funcs = 0;
    foreach (const TypeEntry *te, containerTypes) {
        if (te->javaPackage() == cls->package()) {
            const ComplexTypeEntry *typeEntry = static_cast<const ComplexTypeEntry *>(te);
            s << "// " << typeEntry->name() << endl;
            writeImportString(s, typeEntry);
            s << endl;

            Indentation indent(INDENT);

            writeArrayFunctions(s, typeEntry);
            s << endl;
            num_funcs += NUM_ARRAY_FUNCS;
        }
    }
    if (num_funcs == 0)
        return;

    s << "version (cpp_shared) {" << endl
      << "    private extern (C) void qtd_" << cls->package().replace(".", "_") << "_ArrayOps_initCallBacks(void* callbacks);" << endl << endl
      << "    static this() {" << endl
      << "        void*[" << num_funcs << "] callbacks; " << endl << endl;

    num_funcs = 0;
    foreach (const TypeEntry *te, containerTypes) {
        if (te->javaPackage() == cls->package()) {
            const ComplexTypeEntry *centry = static_cast<const ComplexTypeEntry *>(te);

            QString cls_name = centry->name();
            setFuncNames(cls_name);

            s << "        callbacks[" << num_funcs + 0 << "] = &" << all_name << ";" << endl
              << "        callbacks[" << num_funcs + 1 << "] = &" << ass_name << ";" << endl
              << "        callbacks[" << num_funcs + 2 << "] = &" << get_name << ";" << endl;

            s << endl;
            num_funcs += NUM_ARRAY_FUNCS;
        }
    }
    s << "        qtd_" << cls->package().replace(".", "_") << "_ArrayOps_initCallBacks(callbacks.ptr);" << endl
      << "    }" << endl
      << "}" << endl;


}

void ContainerGenerator::writeDContent2(QTextStream &s, AbstractMetaClass *cls)
{
    s << "module " << cls->package() << ".ArrayOps2;" << endl << endl
	  << "import qt.QGlobal;" << endl << endl;

    foreach(AbstractMetaType* arg_type, signalEntries[cls->package()]) {
        const TypeEntry *te = arg_type->instantiations().first()->typeEntry();
        if(!te->isPrimitive() && !te->isString())
            writeImportString(s, te);
        s << "extern (C) void " << cppContainerConversionName(cls, arg_type, FromCpp) << "(void *cpp_ptr, " << te->targetLangName() << "[]* __d_container);" << endl;
    }
}

void ContainerGenerator::writeNotice(QTextStream &s)
{
    s << "/****************************************************************************" << endl
      << "**" << endl
      << "** This is a generated file, please don't touch." << endl
      << "**" << endl
      << "****************************************************************************/" << endl << endl;
}

void ContainerGenerator::writeArrayFunctions(QTextStream &s, const ComplexTypeEntry *centry)
{
    QString cls_name = centry->name();
    QString type_name = cls_name;

    bool d_export = true;
    QString d_type, cpp_type, cpp_assign_type, convert, nativeId;

    convert = "qtd_" + cls_name + "_cpp_to_d(elem)";
    nativeId = "";

    if (centry->name() == "QModelIndex") {
        cpp_type = "QModelIndexAccessor*";
        cpp_assign_type = cpp_type;
        d_type = cpp_type;
        convert = "*elem";
    } else if (centry->isStructInD()) {
        cpp_type = centry->qualifiedCppName() + "*";
        cpp_assign_type = cpp_type;
        d_type = cpp_type;
        convert = "*elem";
    } else if (centry->isObject() || centry->isQObject() || centry->isValue() || centry->isInterface() || centry->isVariant()) {
        cpp_type = "void*";
        cpp_assign_type = cpp_type + "*";
        d_type = cls_name;
        if (centry->designatedInterface())
            d_type = centry->designatedInterface()->name();
        nativeId = ".__nativeId";
    }

    if (centry->designatedInterface()) {
        type_name = centry->designatedInterface()->name();
        nativeId = ".__ptr_" + type_name;
    }

    s << "private extern(C) void qtd_allocate_" << cls_name << "_array(" << type_name << "[]* arr, size_t len)" << endl
      << "{" << endl
      << INDENT << "*arr = new " << type_name << "[len];" << endl
      << "}" << endl << endl;

    s << "private extern(C) void qtd_assign_" << cls_name << "_array_element(" << type_name << "[]* arr, size_t pos, " << cpp_type << " elem)" << endl
      << "{" << endl
      << INDENT << "(*arr)[pos] = " << convert << ";" << endl
      << "}" << endl << endl

      << "private extern(C) void qtd_get_" << cls_name << "_from_array(" << type_name << "* arr, size_t pos, " << cpp_assign_type << " elem)" << endl
      << "{" << endl
      << INDENT << "*elem = arr[pos]" << nativeId << ";" << endl
      << "}" << endl << endl

      << "package " << d_type << " qtd_" << cls_name << "_cpp_to_d(" << cpp_type << " ret)" << endl
      << "{" << endl;

    marshalFromCppToD(s, centry);

    s << "}" << endl;
}
