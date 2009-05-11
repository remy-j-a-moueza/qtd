/****************************************************************************
**
** Copyright (C) 1992-2008 Nokia. All rights reserved.
** Copyright (C) 2002-2005 Roberto Raggi <roberto@kdevelop.org>
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


#ifndef CONTROL_H
#define CONTROL_H

#include "symbol.h"
#include "smallobject.h"

#include <QtCore/QHash>

struct Declarator;
struct Type;
class Lexer;
class Parser;

struct Context
{
  Context *parent;

  inline void bind(const NameSymbol *name, Type *type)
  { symbol_table.insert(name, type); }

  inline Type *resolve(const NameSymbol *name) const
  {
    if (Type *type = symbol_table.value(name))
      return type;
    else if (parent)
      return parent->resolve(name);

    return 0;
  }

  typedef QHash<const NameSymbol*, Type*> symbol_table_t;

  symbol_table_t symbol_table;
};

class Control
{
public:
  class ErrorMessage
  {
  public:
    ErrorMessage ():
      _M_line (0),
      _M_column (0) {}

    inline int line () const { return _M_line; }
    inline void setLine (int line) { _M_line = line; }

    inline int column () const { return _M_column; }
    inline void setColumn (int column) { _M_column = column; }

    inline QString fileName () const { return _M_fileName; }
    inline void setFileName (const QString &fileName) { _M_fileName = fileName; }

    inline QString message () const { return _M_message; }
    inline void setMessage (const QString &message) { _M_message = message; }

  private:
    int _M_line;
    int _M_column;
    QString _M_fileName;
    QString _M_message;
  };

  Control();
  ~Control();

  inline bool skipFunctionBody() const { return _M_skipFunctionBody; }
  inline void setSkipFunctionBody(bool skip) { _M_skipFunctionBody = skip; }

  Lexer *changeLexer(Lexer *lexer);
  Parser *changeParser(Parser *parser);

  Lexer *currentLexer() const { return _M_lexer; }
  Parser *currentParser() const { return _M_parser; }

  Context *current_context;

  inline Context *currentContext() const
    { return current_context; }

  void pushContext();
  void popContext();

  Type *lookupType(const NameSymbol *name) const;
  void declare(const NameSymbol *name, Type *type);

  inline const NameSymbol *findOrInsertName(const char *data, size_t count)
  { return name_table.findOrInsert(data, count); }

  void declareTypedef(const NameSymbol *name, Declarator *d);
  bool isTypedef(const NameSymbol *name) const;

  void reportError (const ErrorMessage &errmsg);
  QList<ErrorMessage> errorMessages () const;
  void clearErrorMessages ();

private:
  NameTable name_table;
  QHash<const NameSymbol*, Declarator*> stl_typedef_table;
  bool _M_skipFunctionBody;
  Lexer *_M_lexer;
  Parser *_M_parser;

  QList<ErrorMessage> _M_error_messages;
};

#endif // CONTROL_H

// kate: space-indent on; indent-width 2; replace-tabs on;
