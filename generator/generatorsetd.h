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

#ifndef GENERATOR_SET_D_H
#define GENERATOR_SET_D_H

#include "generatorset.h"
#include "metajavabuilder.h"

class GeneratorSetD : public GeneratorSet
{
    Q_OBJECT

public:
    GeneratorSetD();

    QString usage();
    bool readParameters(const QMap<QString, QString> args);

    void buildModel(const QString pp_file);
    void dumpObjectTree();

    QString generate();

private:

    bool no_d;
    bool no_cpp_h;
    bool no_cpp_impl;
    bool no_metainfo;
    bool build_class_list;
    bool build_qdoc_japi;
    bool docs_enabled;
    bool do_ui_convert;
    bool native_jump_table;

    QString doc_dir;
    QString ui_file_name;
    QString custom_widgets;

    MetaJavaBuilder builder;

};

#endif // GENERATOR_SET_D_H
