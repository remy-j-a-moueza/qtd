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

#ifndef ARRAY_OPS_PRIMITIVE_H
#define ARRAY_OPS_PRIMITIVE_H

#include "qtd_core.h"

// int
QTD_EXPORT(void, qtd_allocate_int_array, (void* arr, size_t len))
QTD_EXPORT(void, qtd_assign_int_array_element, (void* arr, size_t pos, int elem))
QTD_EXPORT(void, qtd_get_int_from_array, (void* arr, size_t pos, int* elem))

// uint
QTD_EXPORT(void, qtd_allocate_uint_array, (void* arr, size_t len))
QTD_EXPORT(void, qtd_assign_uint_array_element, (void* arr, size_t pos, uint elem))
QTD_EXPORT(void, qtd_get_uint_from_array, (void* arr, size_t pos, uint* elem))

// double
QTD_EXPORT(void, qtd_allocate_double_array, (void* arr, size_t len))
QTD_EXPORT(void, qtd_assign_double_array_element, (void* arr, size_t pos, double elem))
QTD_EXPORT(void, qtd_get_double_from_array, (void* arr, size_t pos, double* elem))

// string
QTD_EXPORT(void, qtd_allocate_string_array, (void* arr, size_t len))
QTD_EXPORT(void, qtd_assign_string_array_element, (void* arr, size_t pos, void* elem))
QTD_EXPORT(void*, qtd_string_from_array, (void* arr, size_t pos))
QTD_EXPORT(void, qtd_get_string_from_array, (void* arr, size_t pos, char** elem, size_t* elem_size))

#ifdef CPP_SHARED

#define qtd_allocate_int_array qtd_get_qtd_allocate_int_array()
#define qtd_assign_int_array_element qtd_get_qtd_assign_int_array_element()
#define qtd_get_int_from_array qtd_get_qtd_get_int_from_array()

#define qtd_allocate_uint_array qtd_get_qtd_allocate_uint_array()
#define qtd_assign_uint_array_element qtd_get_qtd_assign_uint_array_element()
#define qtd_get_uint_from_array qtd_get_qtd_get_uint_from_array()

#define qtd_allocate_double_array qtd_get_qtd_allocate_double_array()
#define qtd_assign_double_array_element qtd_get_qtd_assign_double_array_element()
#define qtd_get_double_from_array qtd_get_qtd_get_double_from_array()

#define qtd_allocate_string_array qtd_get_qtd_allocate_string_array()
#define qtd_assign_string_array_element qtd_get_qtd_assign_string_array_element()
#define qtd_string_from_array qtd_get_qtd_string_from_array()
#define qtd_get_string_from_array qtd_get_qtd_get_string_from_array()

#endif

/*
// int
extern "C" void qtd_allocate_int_array(void* arr, size_t len);
extern "C" void qtd_assign_int_array_element(void* arr, size_t pos, int elem);

// uint
extern "C" void qtd_allocate_uint_array(void* arr, size_t len);
extern "C" void qtd_assign_uint_array_element(void* arr, size_t pos, uint elem);

// double
extern "C" void qtd_allocate_double_array(void* arr, size_t len);
extern "C" void qtd_assign_double_array_element(void* arr, size_t pos, double elem);

// string
extern "C" void qtd_allocate_string_array(void* arr, size_t len);
extern "C" void qtd_assign_string_array_element(void* arr, size_t pos, void* elem);
extern "C" void* qtd_string_from_array(void* arr, size_t pos);
extern "C" void qtd_get_string_from_array(void* arr, size_t pos, char** elem, size_t* elem_size);
*/

#endif // ARRAY_OPS_PRIMITIVE_H
