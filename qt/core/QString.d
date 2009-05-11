module qt.core.QString;

version (Tango)
{
    import tango.text.convert.Utf : toString;
}
else
{
    import std.utf : toString = toUTF8;
}

class QString
{
    private void* native_id;
    
    public static final char[] toNativeString(void* qstring) {
        wchar* arr = __qtd_QString_utf16(qstring);
        int size = __qtd_QString_size(qstring);
        return .toString(arr[0..size]);
    }
    
    public final char[] toNativeString() {
        return toNativeString(native_id);
    }
    
    public this(void* ptr, bool proxy) {
        native_id = ptr;
    }
    
    public void assign(char[] text) {
        __qtd_QString_operatorAssign(native_id, text.ptr, text.length);
    }
}

private extern (C) wchar* __qtd_QString_utf16(void* __this_nativeId);
private extern (C) int __qtd_QString_size(void* __this_nativeId);
private extern (C) void __qtd_QString_operatorAssign(void* __this_nativeId, char* text, uint text_size);