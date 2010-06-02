/**
    Copyright: Copyright QtD Team, 2008-2010
    License: Boost License 1.0
 */

module qtd.ArrayOpsPrimitive;
import qtd.Core;

// int
mixin (qtdExport("void", "allocate_int_array", "int[]* arr, size_t len",
    q{
        *arr = new int[len];
    }));

mixin (qtdExport("void", "assign_int_array_element", "int[]* arr, size_t pos, int elem",
    q{
        (*arr)[pos] = elem;
    }));

mixin (qtdExport("void", "get_int_from_array", "int* arr, size_t pos, int* elem",
    q{
        *elem = arr[pos];
    }));

// uint
mixin (qtdExport("void", "allocate_uint_array", "int[]* arr, size_t len",
    q{
        *arr = new int[len];
    }));

mixin (qtdExport("void", "assign_uint_array_element", "int[]* arr, size_t pos, uint elem",
    q{
        (*arr)[pos] = elem;
    }));

mixin (qtdExport("void", "get_uint_from_array", "uint* arr, size_t pos, uint* elem",
    q{
        *elem = arr[pos];
    }));

// double
mixin (qtdExport("void", "allocate_double_array", "double[]* arr, size_t len",
    q{
        *arr = new double[len];
    }));

mixin (qtdExport("void", "assign_double_array_element", "double[]* arr, size_t pos, double elem",
    q{
        (*arr)[pos] = elem;
    }));

mixin (qtdExport("void", "get_double_from_array", "double* arr, size_t pos, double* elem",
    q{
        *elem = arr[pos];
    }));

// string
mixin (qtdExport("void", "allocate_string_array", "string[]* arr, size_t len",
    q{
        *arr = new string[len];
    }));

mixin (qtdExport("void", "assign_string_array_element", "string[]* arr, size_t pos, string* elem",
    q{
    }));

mixin (qtdExport("void*", "string_from_array", "string[]* arr, size_t pos",
    q{
        return &((*arr)[pos]);
    }));

mixin (qtdExport("void", "get_string_from_array", "string* arr, size_t pos, string* elem",
    q{
        *elem = arr[pos];
    }));

