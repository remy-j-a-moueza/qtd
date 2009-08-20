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

// stuff for passing D function pointers!

#ifdef CPP_SHARED

#include "ArrayOpsPrimitive.h"

QTD_EXPORT_VAR(qtd_allocate_int_array)
QTD_EXPORT_VAR(qtd_assign_int_array_element)
QTD_EXPORT_VAR(qtd_get_int_from_array)

QTD_EXPORT_VAR(qtd_allocate_uint_array)
QTD_EXPORT_VAR(qtd_assign_uint_array_element)
QTD_EXPORT_VAR(qtd_get_uint_from_array)

QTD_EXPORT_VAR(qtd_allocate_double_array)
QTD_EXPORT_VAR(qtd_assign_double_array_element)
QTD_EXPORT_VAR(qtd_get_double_from_array)

QTD_EXPORT_VAR(qtd_allocate_string_array)
QTD_EXPORT_VAR(qtd_assign_string_array_element)
QTD_EXPORT_VAR(qtd_string_from_array)
QTD_EXPORT_VAR(qtd_get_string_from_array)

extern "C" DLL_PUBLIC void qtd_core_ArrayOps_initCallBacks(pfunc_abstr *callbacks)
{
    QTD_EXPORT_VAR_SET(qtd_allocate_int_array, callbacks[0]);
    QTD_EXPORT_VAR_SET(qtd_assign_int_array_element, callbacks[1]);
    QTD_EXPORT_VAR_SET(qtd_get_int_from_array, callbacks[2]);

    QTD_EXPORT_VAR_SET(qtd_allocate_uint_array, callbacks[3]);
    QTD_EXPORT_VAR_SET(qtd_assign_uint_array_element, callbacks[4]);
    QTD_EXPORT_VAR_SET(qtd_get_uint_from_array, callbacks[5]);

    QTD_EXPORT_VAR_SET(qtd_allocate_double_array, callbacks[6]);
    QTD_EXPORT_VAR_SET(qtd_assign_double_array_element, callbacks[7]);
    QTD_EXPORT_VAR_SET(qtd_get_double_from_array, callbacks[8]);

    QTD_EXPORT_VAR_SET(qtd_allocate_string_array, callbacks[9]);
    QTD_EXPORT_VAR_SET(qtd_assign_string_array_element, callbacks[10]);
    QTD_EXPORT_VAR_SET(qtd_string_from_array, callbacks[11]);
    QTD_EXPORT_VAR_SET(qtd_get_string_from_array, callbacks[12]);
}

#endif
