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

#include "generator.h"
#include "reporthandler.h"
#include "fileout.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>

Generator::Generator()
{
    m_num_generated = 0;
    m_num_generated_written = 0;
    m_out_dir = ".";
}

void Generator::generate()
{
    if (m_classes.size() == 0) {
        ReportHandler::warning(QString("%1: no java classes, skipping")
                               .arg(metaObject()->className()));
        return;
    }


    foreach (AbstractMetaClass *cls, m_classes) {
        if (!shouldGenerate(cls))
            continue;

        QString fileName = fileNameForClass(cls);
        ReportHandler::debugSparse(QString("generating: %1").arg(fileName));

        FileOut fileOut(outputDirectory() + "/" + subDirectoryForClass(cls) + "/" + fileName);
        write(fileOut.stream, cls);

        if( fileOut.done() )
            ++m_num_generated_written;
        ++m_num_generated;
    }
}


void Generator::printClasses()
{
    QTextStream s(stdout);

    AbstractMetaClassList classes = m_classes;
    qSort(classes);

    foreach (AbstractMetaClass *cls, classes) {
        if (!shouldGenerate(cls))
            continue;
        write(s, cls);
        s << endl << endl;
    }
}

void Generator::verifyDirectoryFor(const QFile &file)
{
    QDir dir = QFileInfo(file).dir();
    if (!dir.exists()) {
        if (!dir.mkpath(dir.absolutePath()))
            ReportHandler::warning(QString("unable to create directory '%1'")
                                   .arg(dir.absolutePath()));
    }
}

QString Generator::subDirectoryForClass(const AbstractMetaClass *) const
{
    Q_ASSERT(false);
    return QString();
}

QString Generator::fileNameForClass(const AbstractMetaClass *) const
{
    Q_ASSERT(false);
    return QString();
}

void Generator::write(QTextStream &, const AbstractMetaClass *)
{
    Q_ASSERT(false);
}

bool Generator::hasDefaultConstructor(const AbstractMetaType *type)
{
    QString full_name = type->typeEntry()->qualifiedTargetLangName();
    QString class_name = type->typeEntry()->targetLangName();

    foreach (const AbstractMetaClass *java_class, m_classes) {
        if (java_class->typeEntry()->qualifiedTargetLangName() == full_name) {
            AbstractMetaFunctionList functions = java_class->functions();
            foreach (const AbstractMetaFunction *function, functions) {
                if (function->arguments().size() == 0 && function->name() == class_name)
                    return true;
            }
            return false;
        }
    }
    return false;
}

// hackery to get qt module names
QString Generator::packageToQtModule(QString package, ModuleNameType nameType)
{
    if (!package.startsWith("qt."))
        qFatal(qPrintable("Package " + package + " does not start with 'qt.'"));

    QString module = package.right(package.length() - 3);

    if (nameType == ShortUpper)
        return module.toUpper();
    else if (nameType == LongCamel) {
        module[0] = module[0].toTitleCase();
        return "Qt" + module;
    }
    else
        Q_ASSERT(0);
}

bool isLinearContainer(const ContainerTypeEntry *type)
{
    if (type->type() == ContainerTypeEntry::ListContainer
        || type->type() == ContainerTypeEntry::VectorContainer
        || type->type() == ContainerTypeEntry::StringListContainer
        || type->type() == ContainerTypeEntry::LinkedListContainer
        || type->type() == ContainerTypeEntry::StackContainer
        || type->type() == ContainerTypeEntry::SetContainer
        || type->type() == ContainerTypeEntry::QueueContainer)
        return true;
    else
        return false;
}

bool skipType(const AbstractMetaType *d_type)
{
    if (d_type->isContainer()) {
        const ContainerTypeEntry* c_entry = static_cast<const ContainerTypeEntry*>(d_type->typeEntry());
        if (c_entry->type() == ContainerTypeEntry::MapContainer ||
            c_entry->type() == ContainerTypeEntry::MultiMapContainer ||
            c_entry->type() == ContainerTypeEntry::MapContainer ||
            c_entry->type() == ContainerTypeEntry::MultiHashContainer ||
            c_entry->type() == ContainerTypeEntry::SetContainer)
            return true;

        QList<AbstractMetaType *> args = d_type->instantiations();

        if (args.size() != 1 || args.at(0)->isContainer()) // not QVector or QList
            return true;
    }

    return d_type->isThread() || d_type->isTargetLangChar();
}

bool notWrappedYet(const AbstractMetaFunction *java_function)
{
    AbstractMetaType *d_type = java_function->type();
    if (d_type)
    {
        if(skipType(d_type))
            return true;
    }

    AbstractMetaArgumentList arguments = java_function->arguments();
    foreach (const AbstractMetaArgument *argument, arguments) {
        if (!java_function->argumentRemoved(argument->argumentIndex() + 1))
            if (skipType(argument->type()))
                return true;
    }

    return false;
}

AbstractMetaFunctionList signalFunctions(const AbstractMetaClass *cls, bool includeBase)
{
    AbstractMetaFunctionList r;
    if (cls->generateShellClass())
    {
        if (includeBase)
        {
            AbstractMetaClass *base = cls->baseClass();
            if (base)
                r += signalFunctions(base);
        }

        foreach (AbstractMetaFunction *f, cls->functions())
        {
            if (!f->isSignal()
                || cls != f->implementingClass()
                || notWrappedYet(f)
                || f->isModifiedRemoved(TypeSystem::TargetLangCode))
                continue;

            r.append(f);
        }
    }
    return r;
}
