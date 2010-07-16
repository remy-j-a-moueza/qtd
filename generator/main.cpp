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

#include "main.h"
#include "asttoxml.h"
#include "reporthandler.h"
#include "typesystem.h"
#include "generatorset.h"
#include "fileout.h"
#include "binder.h"
#include "global.h"

#include "abstractmetalang.h"

#include <QDir>

void ReportHandler_message_handler(const std::string &str)
{
    ReportHandler::warning(QString::fromStdString(str));
}


void displayHelp(GeneratorSet *generatorSet);

#include <QDebug>
int main(int argc, char *argv[])
{
    GeneratorSet *gs = GeneratorSet::getInstance();

    QString default_file = "qtjambi_masterinclude.h";
    QString default_system = "build_all.txt";

    QString fileName;
    QString typesystemFileName;
    QString pp_file = ".preprocessed.tmp";
    QStringList rebuild_classes;
    QString source_dir;

    QMap<QString, QString> args;

    int argNum = 0;
    for (int i=1; i<argc; ++i) {
        QString arg(argv[i]);
        arg = arg.trimmed();
        if( arg.startsWith("--") ) {
            int split = arg.indexOf("=");
            if( split > 0 )
                args[arg.mid(2).left(split-2)] = arg.mid(split + 1).trimmed();
            else
                args[arg.mid(2)] = QString();
        } else if( arg.startsWith("-")) {
            args[arg.mid(1)] = QString();
        } else {
            argNum++;
            args[QString("arg-%1").arg(argNum)] = arg;
        }
    }

    if (args.contains("no-suppress-warnings")) {
        TypeDatabase *db = TypeDatabase::instance();
        db->setSuppressWarnings(false);
    }

    if (args.contains("include-eclipse-warnings")) {
        TypeDatabase *db = TypeDatabase::instance();
        db->setIncludeEclipseWarnings(true);
    }

    if (args.contains("debug-level")) {
        QString level = args.value("debug-level");
        if (level == "sparse")
            ReportHandler::setDebugLevel(ReportHandler::SparseDebug);
        else if (level == "medium")
            ReportHandler::setDebugLevel(ReportHandler::MediumDebug);
        else if (level == "full")
            ReportHandler::setDebugLevel(ReportHandler::FullDebug);
    }

    if (args.contains("dummy")) {
        FileOut::dummy = true;
    }

    if (args.contains("diff")) {
        FileOut::diff = true;
    }

    if (args.contains("rebuild-only")) {
        QStringList classes = args.value("rebuild-only").split(",", QString::SkipEmptyParts);
        TypeDatabase::instance()->setRebuildClasses(classes);
    }

    QString dTarget = args.value("d-target");
    if (!dTarget.isEmpty())
    {
        dTarget = args.value("d-target");
        if (dTarget == "d1-tango")
            global.dVersion = 1;
        /*
        else if (dtarget == "d2-tango")
            qFatal("Tango D2 target is not supported");
        */
        else if (dTarget == "d2-phobos")
        {
            global.dVersion = 2;
            global.dPhobos = true;
        }
        else
        {
            fprintf(stderr, "D target '%s' is not recognized", qPrintable(dTarget));
            return 1;
        }
    }

    source_dir = args.value("source-directory");
    fileName = args.value("arg-1");
    if (!source_dir.isEmpty() && !QFileInfo(fileName).exists())
    {
        fileName = source_dir + "/" + fileName;
        if(!QFileInfo(fileName).exists())
        {
            fprintf(stderr, "Master include '%s' is not found", fileName.toAscii().data());
            return 1;
        }
    }

    typesystemFileName = args.value("arg-2");
    if (args.contains("arg-3"))
        displayHelp(gs);

    if (fileName.isEmpty())
        fileName = default_file;

    if (typesystemFileName.isEmpty())
        typesystemFileName = default_system;

    if (fileName.isEmpty() || typesystemFileName.isEmpty() )
        displayHelp(gs);

    if (!gs->readParameters(args))
        displayHelp(gs);

    global.cppShared = args.contains("cpp-shared");

    global.setTargetPlatform(args.value("target-platform"));

    printf("Running the QtD Generator. Please wait while source files are being generated...\n");

    if (!TypeDatabase::instance()->parseFile(typesystemFileName, source_dir))
        qFatal("Cannot parse file: '%s'", qPrintable(typesystemFileName));

    if (!Preprocess::preprocess(fileName, pp_file, args.value("include-paths"), source_dir, args.value("qt-include-directory"))) {
        fprintf(stderr, "Preprocessor failed on file: '%s'\n", qPrintable(fileName));
        return 1;
    }

    if (args.contains("ast-to-xml")) {
    astToXML(pp_file);
    return 0;
    }

    ArgumentReplace::init(); // replacer for arguments which are D keywords such as "version"

    Binder::installMessageHandler(ReportHandler_message_handler);
    gs->buildModel(pp_file);
    if (args.contains("dump-object-tree")) {
        gs->dumpObjectTree();
        return 0;
    }
    printf("%s\n", qPrintable(gs->generate()));

    printf("Done, %d warnings (%d known issues)\n", ReportHandler::warningCount(),
           ReportHandler::suppressedCount());
}


void displayHelp(GeneratorSet* generatorSet) {
#if defined(Q_OS_WIN32)
    char path_splitter = ';';
#else
    char path_splitter = ':';
#endif
    printf("Usage:\n  generator [options] header-file typesystem-file\n\n");
    printf("Available options:\n\n");
    printf("General:\n");
    printf(
           "  --cpp-shared                              \n"
           "  --qt-include-directory                    \n"
           "  --qt-directory                            \n"
           "  --source-directory                        \n"
           "  --debug-level=[sparse|medium|full]        \n"
           "  --d-target=[d1-tango|d2-phobos]           \n"
           "  --dump-object-tree                        \n"
           "  --help, -h or -?                          \n"
           "  --no-suppress-warnings                    \n"
           "  --include-eclipse-warnings                \n"
           "  --output-directory=[dir]                  \n"
           "  --include-paths=<path>[%c<path>%c...]     \n"
           "  --print-stdout                            \n"
           ,
           path_splitter, path_splitter);

    printf("%s", qPrintable( generatorSet->usage()));
    exit(0);
}
