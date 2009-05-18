module qt.core.QString;

import qt.QGlobal;

version (Tango)
{
    import tango.text.convert.Utf : toString;
}
else
{
    import std.utf : toString = toUTF8;
}

struct QString
{
    public static QString opCall(void* ptr, bool proxy) {
        QString str;
        str.native_id = ptr;
        return str;
    }
    
    private void* native_id;
    
    public static final char[] toNativeString(void* qstring) {
        wchar* arr = __qtd_QString_utf16(qstring);
        int size = __qtd_QString_size(qstring);
        return .toString(arr[0..size]);
    }
    
    public final char[] toNativeString() {
        return toNativeString(native_id);
    }
    
    public void assign(char[] text) {
        __qtd_QString_operatorAssign(native_id, text.ptr, text.length);
    }
    
    public static string fromUtf8(string source) {
        return source;
    }
}

private extern (C) wchar* __qtd_QString_utf16(void* __this_nativeId);
private extern (C) int __qtd_QString_size(void* __this_nativeId);
private extern (C) void __qtd_QString_operatorAssign(void* __this_nativeId, char* text, uint text_size);