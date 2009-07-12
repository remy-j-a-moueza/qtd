module qt.core.QString;

import qt.QGlobal;

version (Tango)
{
    public import tango.text.convert.Utf : toUTF8 = toString;
}
else
{
    public import std.utf : toUTF8;
}

struct QString
{
    public static QString opCall(void* ptr, bool proxy) {
        QString str;
        str.native_id = ptr;
        return str;
    }
    
    private void* native_id;
    
    public static final string toNativeString(void* qstring) {
        wchar* arr = __qtd_QString_utf16(qstring);
        int size = __qtd_QString_size(qstring);
        return .toUTF8(arr[0..size]);
    }
    
    public final string toNativeString() {
        return toNativeString(native_id);
    }
    
    public void assign(string text) {
        __qtd_QString_operatorAssign(native_id, text);
    }
    
    public static string fromUtf8(string source) {
        return source;
    }
/*    
    public static string fromUtf16(wstring src) {
        version(Tango)
    }*/
}

private extern (C) wchar* __qtd_QString_utf16(void* __this_nativeId);
private extern (C) int __qtd_QString_size(void* __this_nativeId);
private extern (C) void __qtd_QString_operatorAssign(void* __this_nativeId, string text);