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
    public static QString opCall()
    {
        QString str;
        qtd_QString_placed_ctor(&str);
        return str;
    }
    
    ~this()
    {
        qtd_QString_call_destructor(&this);
    }
    
    void opAssign(string str)
    {
        qtd_QString_assign_fromUtf8(&this, str);
    }
    
    this(string str)
    {
        qtd_QString_new_fromUtf8_at(&this, str);
    }
    
    public static void __constructPlacedQString(void* place, string source) {
        qtd_QString_new_fromUtf8_at(place, source);
    }
    
    // service stuff
    static void* __constructNativeCopy(const void* orig) {
        return qtd_QString_QString_QString(cast(void*)orig);
    }

    static void* __constructPlacedNativeCopy(const void* orig, void* place) {
        return qtd_QString_placed_copy(orig, place);
    }
    
    public static void __deleteNativeObject(void* ptr) {
        qtd_QString_destructor(ptr);
    }
    
    public static void __callNativeDestructor(void* ptr) {
        qtd_QString_call_destructor(ptr);
    }
    struct QTypeInfo
    {
        enum bool isComplex = true;
        enum bool isStatic = false;
        enum bool isLarge = false;
        enum bool isPointer = false;
        enum bool isDummy = false;
    }
    
private:
    void *dummy; // sizeof(QString) == sizeof(void*)
}

struct QStringUtil
{
    public static final string toNativeString(void* qstring) {
        wchar* arr = qtd_QString_utf16(qstring);
        int size = qtd_QString_size(qstring);
        return .toUTF8(arr[0..size]);
    }

    public static string fromUtf8(string source) {
        return source;
    }

    public static QStringUtil opCall(void* ptr, bool proxy) {
        QStringUtil str;
        str.__nativeId = ptr;
        return str;
    }
    
    public void* __nativeId;

    public final string toNativeString() {
        return QStringUtil.toNativeString(__nativeId);
    }
    
    public void assign(string text) {
        qtd_QString_operatorAssign(__nativeId, text);
    }
}
private extern(C) void* qtd_QString_placed_copy(const void* orig, void* place);

private extern (C) void qtd_QString_destructor(void* __this_nativeId);
private extern (C) void qtd_QString_call_destructor(void *ptr);

private extern (C) void* qtd_QString_QString_QString(void* orig);

private extern (C) wchar* qtd_QString_utf16(void* __this_nativeId);
private extern (C) int qtd_QString_size(void* __this_nativeId);
private extern (C) void qtd_QString_operatorAssign(void* __this_nativeId, string text);
private extern (C) void* qtd_QString_new_fromUtf8_at(void* place, string text);

private extern (C) void qtd_QString_placed_ctor(void* place);
private extern (C) void qtd_QString_assign_fromUtf8(QString *__qt_this, string text);