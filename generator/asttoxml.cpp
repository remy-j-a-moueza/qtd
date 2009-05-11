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

#include "asttoxml.h"
#include "control.h"
#include "parser.h"
#include "binder.h"


#include <QXmlStreamWriter>
#include <QTextStream>
#include <QTextCodec>
#include <QFile>

void astToXML(QString name) {
    QFile file(name);

    if (!file.open(QFile::ReadOnly))
        return;

    QTextStream stream(&file);
    stream.setCodec(QTextCodec::codecForName("UTF-8"));
    QByteArray contents = stream.readAll().toUtf8();
    file.close();

    Control control;
    Parser p(&control);
    pool __pool;

    TranslationUnitAST *ast = p.parse(contents, contents.size(), &__pool);

    CodeModel model;
    Binder binder(&model, p.location());
    FileModelItem dom = binder.run(ast);

    QFile outputFile;
    if (!outputFile.open(stdout, QIODevice::WriteOnly))
    {
        return;
    }

    QXmlStreamWriter s( &outputFile);
    s.setAutoFormatting( true );

    s.writeStartElement("code");

    QHash<QString, NamespaceModelItem> namespaceMap = dom->namespaceMap();
    foreach (NamespaceModelItem item, namespaceMap.values()) {
        writeOutNamespace(s, item);
    }

    QHash<QString, ClassModelItem> typeMap = dom->classMap();
    foreach (ClassModelItem item, typeMap.values()) {
        writeOutClass(s, item);
    }
    s.writeEndElement();
}


void writeOutNamespace(QXmlStreamWriter &s, NamespaceModelItem &item) {
    s.writeStartElement("namespace");
    s.writeAttribute("name", item->name());

    QHash<QString, NamespaceModelItem> namespaceMap = item->namespaceMap();
    foreach (NamespaceModelItem item, namespaceMap.values()) {
        writeOutNamespace(s, item);
    }

    QHash<QString, ClassModelItem> typeMap = item->classMap();
    foreach (ClassModelItem item, typeMap.values()) {
        writeOutClass(s, item);
    }

    QHash<QString, EnumModelItem> enumMap = item->enumMap();
    foreach (EnumModelItem item, enumMap.values()) {
        writeOutEnum(s, item);
    }

    s.writeEndElement();
}

void writeOutEnum(QXmlStreamWriter &s, EnumModelItem &item) {
    QString qualified_name = item->qualifiedName().join("::");
    s.writeStartElement("enum");
    s.writeAttribute("name", qualified_name);

    EnumeratorList enumList = item->enumerators();
    for(int i=0; i < enumList.size() ; i++) {
        s.writeStartElement("enumerator");
        if( !enumList[i]->value().isEmpty() )
            s.writeAttribute("value", enumList[i]->value());
        s.writeCharacters(enumList[i]->name());

        s.writeEndElement();
    }
    s.writeEndElement();
}

void writeOutFunction(QXmlStreamWriter &s, FunctionModelItem &item) {
    QString qualified_name = item->qualifiedName().join("::");
    s.writeStartElement("function");
    s.writeAttribute("name", qualified_name);

    ArgumentList arguments = item->arguments();
    for(int i=0; i < arguments.size() ; i++) {
        s.writeStartElement("argument");
        s.writeAttribute("type",  arguments[i]->type().qualifiedName().join("::"));
        s.writeEndElement();
    }
    s.writeEndElement();
}

void writeOutClass(QXmlStreamWriter &s, ClassModelItem &item) {
    QString qualified_name = item->qualifiedName().join("::");
    s.writeStartElement("class");
    s.writeAttribute("name", qualified_name);

    QHash<QString, EnumModelItem> enumMap = item->enumMap();
    foreach (EnumModelItem item, enumMap.values()) {
        writeOutEnum(s, item);
    }

    QHash<QString, FunctionModelItem> functionMap = item->functionMap();
    foreach (FunctionModelItem item, functionMap.values()) {
        writeOutFunction(s, item);
    }

    QHash<QString, ClassModelItem> typeMap = item->classMap();
    foreach (ClassModelItem item, typeMap.values()) {
        writeOutClass(s, item);
    }
    s.writeEndElement();
}
