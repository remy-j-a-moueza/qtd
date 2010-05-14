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

module qt.qtd.ArrayOpsPrimitive;

import qt.QGlobal;

// int
private extern(C) void qtd_allocate_int_array(int[]* arr, size_t len)
{
    *arr = new int[len];
}

private extern(C) void qtd_assign_int_array_element(int[]* arr, size_t pos, int elem)
{
    (*arr)[pos] = elem;
}

private extern(C) void qtd_get_int_from_array(int* arr, size_t pos, int* elem)
{
    *elem = arr[pos];
}

// uint
private extern(C) void qtd_allocate_uint_array(int[]* arr, size_t len)
{
    *arr = new int[len];
}

private extern(C) void qtd_assign_uint_array_element(int[]* arr, size_t pos, uint elem)
{
    (*arr)[pos] = elem;
}

private extern(C) void qtd_get_uint_from_array(uint* arr, size_t pos, uint* elem)
{
    *elem = arr[pos];
}

// double
private extern(C) void qtd_allocate_double_array(double[]* arr, size_t len)
{
    *arr = new double[len];
}

private extern(C) void qtd_assign_double_array_element(double[]* arr, size_t pos, double elem)
{
    (*arr)[pos] = elem;
}

private extern(C) void qtd_get_double_from_array(double* arr, size_t pos, double* elem)
{
    *elem = arr[pos];
}

// string
private extern(C) void qtd_allocate_string_array(string[]* arr, size_t len)
{
    *arr = new string[len];
}

private extern(C) void qtd_assign_string_array_element(string[]* arr, size_t pos, string* elem)
{
}

private extern(C) void* qtd_string_from_array(string[]* arr, size_t pos)
{
    return &((*arr)[pos]);
}
/*
private extern(C) void qtd_get_string_from_array(string* arr, size_t pos, char** elem, size_t* elem_size)
{
    *elem = arr[pos].ptr;
    *elem_size = arr[pos].length;
}
*/

private extern(C) void qtd_get_string_from_array(string* arr, size_t pos, string* elem)
{
    *elem = arr[pos];
}

version(cpp_shared)
{
    extern (C) void qtd_core_ArrayOps_initCallBacks(void* callbacks);

    static this() {
        void*[13] callbacks;

        callbacks[0] = &qtd_allocate_int_array;
        callbacks[1] = &qtd_assign_int_array_element;
        callbacks[2] = &qtd_get_int_from_array;
        
        callbacks[3] = &qtd_allocate_uint_array;
        callbacks[4] = &qtd_assign_uint_array_element;
        callbacks[5] = &qtd_get_uint_from_array;
        
        callbacks[6] = &qtd_allocate_double_array;
        callbacks[7] = &qtd_assign_double_array_element;
        callbacks[8] = &qtd_get_double_from_array;
        
        callbacks[9] = &qtd_allocate_string_array;
        callbacks[10] = &qtd_assign_string_array_element;
        callbacks[11] = &qtd_string_from_array;
        callbacks[12] = &qtd_get_string_from_array;
        
        qtd_core_ArrayOps_initCallBacks(callbacks.ptr);
    }
}