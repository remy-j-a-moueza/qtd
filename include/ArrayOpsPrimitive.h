/**
    Copyright: Copyright QtD Team, 2008-2010
    License: Boost License 1.0
 */

#ifndef ARRAY_OPS_PRIMITIVE_H
#define ARRAY_OPS_PRIMITIVE_H

#include "qtd_core.h"

// int
QTD_FUNC_DECL(CORE, void, allocate_int_array, (void* arr, size_t len))
QTD_FUNC_DECL(CORE, void, assign_int_array_element, (void* arr, size_t pos, int elem))
QTD_FUNC_DECL(CORE, void, get_int_from_array, (void* arr, size_t pos, int* elem))

// uint
QTD_FUNC_DECL(CORE, void, allocate_uint_array, (void* arr, size_t len))
QTD_FUNC_DECL(CORE, void, assign_uint_array_element, (void* arr, size_t pos, uint elem))
QTD_FUNC_DECL(CORE, void, get_uint_from_array, (void* arr, size_t pos, uint* elem))

// double
QTD_FUNC_DECL(CORE, void, allocate_double_array, (void* arr, size_t len))
QTD_FUNC_DECL(CORE, void, assign_double_array_element, (void* arr, size_t pos, double elem))
QTD_FUNC_DECL(CORE, void, get_double_from_array, (void* arr, size_t pos, double* elem))

// string
QTD_FUNC_DECL(CORE, void, allocate_string_array, (void* arr, size_t len))
QTD_FUNC_DECL(CORE, void, assign_string_array_element, (void* arr, size_t pos, void* elem))
QTD_FUNC_DECL(CORE, void*, string_from_array, (void* arr, size_t pos))
QTD_FUNC_DECL(CORE, void, get_string_from_array, (void* arr, size_t pos, DArray* elem))

#endif // ARRAY_OPS_PRIMITIVE_H
