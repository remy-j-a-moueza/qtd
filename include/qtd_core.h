/**
*
*  Copyright: Copyright QtD Team, 2008-2009
*  License: <a href="http://www.boost.org/LICENSE_1_0.txt>Boost License 1.0</a>
*
*  Copyright QtD Team, 2008-2009
*  Distributed under the Boost Software License, Version 1.0.
*  (See accompanying file boost-license-1.0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
*
*/

#ifndef QTD_CORE_H
#define QTD_CORE_H

#include <QAbstractItemModel>

#if defined WIN32
  #define DLL_PUBLIC __declspec(dllexport)
#else
  #define DLL_PUBLIC
#endif

#ifdef CPP_SHARED
  #define QTD_EXPORT(TYPE, NAME, ARGS)      \
    extern "C" typedef TYPE (*pf_##NAME)ARGS; \
    extern "C" pf_##NAME qtd_get_##NAME();
  #define QTD_EXPORT_VAR(NAME) \
    pf_##NAME m_##NAME;        \
    extern "C" DLL_PUBLIC pf_##NAME qtd_get_##NAME() { return m_##NAME; }
  #define QTD_EXPORT_VAR_SET(NAME, VALUE) \
    m_##NAME = (pf_##NAME) VALUE
#else
  #define QTD_EXPORT(TYPE, NAME, ARGS)      \
    extern "C" TYPE NAME ARGS;
#endif

struct QModelIndexAccessor {
	int row;
	int col;
	void *ptr;
	QAbstractItemModel *model;
};

struct DArray {
    size_t length;
    void* ptr;
};

#define Array DArray

#ifdef CPP_SHARED
typedef void (*pfunc_abstr)();
#endif

QTD_EXPORT(void, _d_toUtf8, (const unsigned short* arr, uint size, void* str))
QTD_EXPORT(void, __qtd_dummy, ())

#ifdef CPP_SHARED
#define _d_toUtf8 qtd_get__d_toUtf8()
#define __qtd_dummy qtd_get___qtd_dummy()
#endif

extern "C" QModelIndex qtd_to_QModelIndex(QModelIndexAccessor mia);
extern "C" QModelIndexAccessor qtd_from_QModelIndex(const QModelIndex &index);

#endif // QTD_CORE_H
