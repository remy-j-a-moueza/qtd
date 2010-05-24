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

#include "qtd_core.h"
#include <iostream>

extern "C" DLL_PUBLIC QModelIndex qtd_to_QModelIndex(QModelIndexAccessor mia)
{
    return * (QModelIndex *) (&mia) ;
}

extern "C" DLL_PUBLIC QModelIndexAccessor qtd_from_QModelIndex(const QModelIndex &index)
{
    QModelIndexAccessor mia = {
        index.row(),
        index.column(),
        index.internalPointer(),
        (QAbstractItemModel *) index.model()
    };

    return mia;
}

extern "C" DLL_PUBLIC const char* qtd_qVersion()
{
    return qVersion();
}

extern "C" DLL_PUBLIC bool qtd_qSharedBuild()
{
    return qSharedBuild();
}

//TODO: this has to be replaced with something that makes some sense
#ifdef CPP_SHARED
QTD_EXPORT_VAR(qtd_toUtf8);
QTD_EXPORT_VAR(qtd_QtdObject_delete);

extern "C" DLL_PUBLIC void qtd_core_initCallBacks(pfunc_abstr d_func, pfunc_abstr del_d_qobj) {
    QTD_EXPORT_VAR_SET(qtd_toUtf8, d_func);
    QTD_EXPORT_VAR_SET(qtd_QtdObject_delete, del_d_qobj);
}
#endif

extern bool qRegisterResourceData
    (int, const unsigned char *, const unsigned char *, const unsigned char *);

extern bool qUnregisterResourceData
    (int, const unsigned char *, const unsigned char *, const unsigned char *);

extern "C" DLL_PUBLIC bool qtd_register_resource_data(int version, const unsigned char *tree,
                                         const unsigned char *name, const unsigned char *data)
{
    return qRegisterResourceData(version, tree, name, data);
}

extern "C" DLL_PUBLIC bool qtd_unregister_resource_data(int version, const unsigned char *tree,
                                           const unsigned char *name, const unsigned char *data)
{
    return qUnregisterResourceData(version, tree, name, data);
}
