module qt.core.QVariant;

public import qt.QGlobal;
private import qt.QtdObject;
private import qt.core.QMetaType;

// automatic imports-------------
private import qt.core.QSizeF;
private import qt.core.QPoint;
private import qt.core.QRectF;
public import qt.core.Qt;
private import qt.core.QDateTime;
private import qt.core.QDataStream;
private import qt.core.QTime;
private import qt.core.QUrl;
private import qt.core.QRegExp;
private import qt.core.QBitArray;
private import qt.core.QLine;
private import qt.core.QByteArray;
private import qt.core.QSize;
private import qt.core.QDate;
private import qt.core.QPointF;
private import qt.core.QLineF;
private import qt.core.QRect;
private import qt.core.QLocale;

version (Tango)
{
    import tango.core.Array;
    import tango.stdc.stringz;
    import tango.text.convert.Utf;
    import tango.core.Traits;
}


public class QVariant : QtdObject
{
    enum Type {
        Invalid = 0,

        Bool = 1,
        Int = 2,
        UInt = 3,
        LongLong = 4,
        ULongLong = 5,
        Double = 6,
        Char = 7,
        Map = 8,
        List = 9,
        String = 10,
        StringList = 11,
        ByteArray = 12,
        BitArray = 13,
        Date = 14,
        Time = 15,
        DateTime = 16,
        Url = 17,
        Locale = 18,
        Rect = 19,
        RectF = 20,
        Size = 21,
        SizeF = 22,
        Line = 23,
        LineF = 24,
        Point = 25,
        PointF = 26,
        RegExp = 27,
        LastCoreType = RegExp,

        // value 62 is internally reserved

        Font = 64,
        Pixmap = 65,
        Brush = 66,
        Color = 67,
        Palette = 68,
        Icon = 69,
        Image = 70,
        Polygon = 71,
        Region = 72,
        Bitmap = 73,
        Cursor = 74,
        SizePolicy = 75,
        KeySequence = 76,
        Pen = 77,
        TextLength = 78,
        TextFormat = 79,
        Matrix = 80,
        Transform = 81,
        LastGuiType = Transform,

        UserType = 127,

        LastType = 0xffffffff // need this so that gcc >= 3.4 allocates 32 bits for Type
    }

// Functions

    private template getMetaId()
    {
	const char[] getMetaId = "
	    int i = qtd_MetatypeId(toStringz(name));
	    if(i <= 0)
		i = qRegisterMetaType!(T)(name);";
    }

    static public QVariant fromValue(T)(T obj)
    {
	QVariant var;
	static if (is(T == class) || is(T == interface))
	{
	    string name = obj.classinfo.name;
	    mixin(getMetaId!());
	    var = new QVariant(i, cast(void*)(obj));
	}
	else static if (isDynamicArrayType!(T) || isStaticArrayType!(T) )
	{
	    string name = typeid(ElementTypeOfArray!(T)).toString ~ "[]";
	    mixin(getMetaId!());
	    auto darray = new DArrayToC;
	    darray.array = obj.dup;
	    var = new QVariant(i, cast(void*)(darray));
	}
	else
	{
	    string name = typeid(T).toString;
	    mixin(getMetaId!());
	    auto data = new T;
	    *data = obj;
	    var = new QVariant(i, cast(void*)(data));
	}
	return var;
    }

    static public QVariant opCall(T)(T obj)
    {
	return fromValue(obj);
    }

    public this() {
        void* __qt_return_value = qtd_QVariant_QVariant();
        super(__qt_return_value);
    }


    public this(QDataStream s) {
        void* __qt_return_value = qtd_QVariant_QVariant_QDataStream(s is null ? null : s.__nativeId);
        super(__qt_return_value);
    }


    public this(Qt.GlobalColor color) {
        void* __qt_return_value = qtd_QVariant_QVariant_GlobalColor(color);
        super(__qt_return_value);
    }


    public this(bool b) {
        void* __qt_return_value = qtd_QVariant_QVariant_bool(b);
        super(__qt_return_value);
    }


    public this(QBitArray bitarray) {
        void* __qt_return_value = qtd_QVariant_QVariant_QBitArray(bitarray is null ? null : bitarray.__nativeId);
        super(__qt_return_value);
    }


    public this(QByteArray bytearray) {
        void* __qt_return_value = qtd_QVariant_QVariant_QByteArray(bytearray is null ? null : bytearray.__nativeId);
        super(__qt_return_value);
    }


    public this(QDate date) {
        void* __qt_return_value = qtd_QVariant_QVariant_QDate(date is null ? null : date.__nativeId);
        super(__qt_return_value);
    }


    public this(QDateTime datetime) {
        void* __qt_return_value = qtd_QVariant_QVariant_QDateTime(datetime is null ? null : datetime.__nativeId);
        super(__qt_return_value);
    }


    public this(string str) {
        void* __qt_return_value = qtd_QVariant_QVariant_String(str);
        super(__qt_return_value);
    }


    public this(QLine line) {
        void* __qt_return_value = qtd_QVariant_QVariant_QLine(&line);
        super(__qt_return_value);
    }


    public this(QLineF line) {
        void* __qt_return_value = qtd_QVariant_QVariant_QLineF(&line);
        super(__qt_return_value);
    }


    public this(QLocale locale) {
        void* __qt_return_value = qtd_QVariant_QVariant_QLocale(locale is null ? null : locale.__nativeId);
        super(__qt_return_value);
    }


    public this(QPoint pt) {
        void* __qt_return_value = qtd_QVariant_QVariant_QPoint(&pt);
        super(__qt_return_value);
    }


    public this(QPointF pt) {
        void* __qt_return_value = qtd_QVariant_QVariant_QPointF(&pt);
        super(__qt_return_value);
    }


    public this(QRect rect) {
        void* __qt_return_value = qtd_QVariant_QVariant_QRect(&rect);
        super(__qt_return_value);
    }


    public this(QRectF rect) {
        void* __qt_return_value = qtd_QVariant_QVariant_QRectF(&rect);
        super(__qt_return_value);
    }


    public this(QRegExp regExp) {
        void* __qt_return_value = qtd_QVariant_QVariant_QRegExp(regExp is null ? null : regExp.__nativeId);
        super(__qt_return_value);
    }


    public this(QSize size) {
        void* __qt_return_value = qtd_QVariant_QVariant_QSize(&size);
        super(__qt_return_value);
    }


    public this(QSizeF size) {
        void* __qt_return_value = qtd_QVariant_QVariant_QSizeF(&size);
        super(__qt_return_value);
    }


    public this(QTime time) {
        void* __qt_return_value = qtd_QVariant_QVariant_QTime(time is null ? null : time.__nativeId);
        super(__qt_return_value);
    }


    public this(QUrl url) {
        void* __qt_return_value = qtd_QVariant_QVariant_QUrl(url is null ? null : url.__nativeId);
        super(__qt_return_value);
    }


    public this(QVariant other) {
        void* __qt_return_value = qtd_QVariant_QVariant_QVariant(other is null ? null : other.__nativeId);
        super(__qt_return_value);
    }

/*
    public this(char* str) {
        void* __qt_return_value = qtd_QVariant_QVariant_nativepointerchar(str);
        super(__qt_return_value);
    }
*/

    public this(double d) {
        void* __qt_return_value = qtd_QVariant_QVariant_double(d);
        super(__qt_return_value);
    }


    public this(int i) {
        void* __qt_return_value = qtd_QVariant_QVariant_int(i);
        super(__qt_return_value);
    }


    public this(int typeOrUserType, void* copy) {
        void* __qt_return_value = qtd_QVariant_QVariant_int_nativepointervoid(typeOrUserType, copy);
        super(__qt_return_value);
    }


    public this(long ll) {
        void* __qt_return_value = qtd_QVariant_QVariant_long(ll);
        super(__qt_return_value);
    }


    public this(uint ui) {
        void* __qt_return_value = qtd_QVariant_QVariant_uint(ui);
        super(__qt_return_value);
    }


    public this(ulong ull) {
        void* __qt_return_value = qtd_QVariant_QVariant_ulong(ull);
        super(__qt_return_value);
    }

    private final bool canConvertImpl(string name)
    {
	int i = qtd_MetatypeId(toStringz(name));
	assert(i > 0);
	return qtd_QVariant_canConvert(__nativeId, i);
    }

    public final bool canConvert(Type)() {
	static if ( is(Type == QBitArray) )
	    return canConvertImpl("QBitArray");
	else static if ( is(Type == bool) )
	    return canConvertImpl("bool");
	else static if ( is(Type == QByteArray) )
	    return canConvertImpl("QByteArray");
	else static if ( is(Type == QDate) )
	    return canConvertImpl("QDate");
	else static if ( is(Type == QDateTime) )
	    return canConvertImpl("QDateTime");
	else static if ( is(Type == double) )
	    return canConvertImpl("double");
	else static if ( is(Type == int) )
	    return canConvertImpl("int");
	else static if ( is(Type == QLine) )
	    return canConvertImpl("QLine");
	else static if ( is(Type == QLineF) )
	    return canConvertImpl("QLineF");
	else static if ( is(Type == QLocale) )
	    return canConvertImpl("QLocale");
	else static if ( is(Type == long) )
	    return canConvertImpl("long");
	else static if ( is(Type == QPoint) )
	    return canConvertImpl("QPoint");
	else static if ( is(Type == QPointF) )
	    return canConvertImpl("QPointF");
	else static if ( is(Type == QRect) )
	    return canConvertImpl("QRect");
	else static if ( is(Type == QRectF) )
	    return canConvertImpl("QRectF");
	else static if ( is(Type == QRegExp) )
	    return canConvertImpl("QRegExp");
	else static if ( is(Type == QSize) )
	    return canConvertImpl("QSize");
	else static if ( is(Type == QSizeF) )
	    return canConvertImpl("QSizeF");
	else  static if ( is(Type == string) )
	    return canConvertImpl("QString");
	else  static if ( is(Type == QTime) )
	    return canConvertImpl("QTime");
	else static if ( is(Type == uint) )
	    return canConvertImpl("unsigned int"); // TODO:
	else static if ( is(Type == ulong) )
	    return canConvertImpl("unsigned long long"); // TODO:
	else static if ( is(Type == QUrl) )
	    return canConvertImpl("QUrl");
	else
	{
	    static if( is( Type == class ) || is( Type == interface ) )
	    {
		Object object = cast(Object)qtd_QVariant_data(__nativeId);
		if(object)
		    return cast(Type)(object) !is null;
		return false;
	    }
	    else static if (isDynamicArrayType!(Type) || isStaticArrayType!(Type) )
	    {
		auto array = cast(DArrayToC*)qtd_QVariant_data(__nativeId);
		return cast(Type)(array.array) !is null;
	    }
	    else
	    {
		int i = qtd_MetatypeId(toStringz(typeid(Type).toString));
		return qtd_QVariant_canConvert(__nativeId, i);
	    }
	}
    }

    public final Type value(Type)() {
	static if ( is(Type == QBitArray) )
	    return toBitArra;
	else static if ( is(Type == bool) )
	    return toBool;
	else static if ( is(Type == QByteArray) )
	    return toByteArray;
	else static if ( is(Type == QDate) )
	    return toDate;
	else static if ( is(Type == QDateTime) )
	    return toDateTime;
	else static if ( is(Type == double) )
	    return toDouble;
	else static if ( is(Type == int) )
	    return toInt;
	else static if ( is(Type == QLine) )
	    return toLine;
	else static if ( is(Type == QLineF) )
	    return toLineF;
	else static if ( is(Type == QLocale) )
	    return toLocale;
	else static if ( is(Type == long) )
	    return toLongLong;
	else static if ( is(Type == QPoint) )
	    return toPoint;
	else static if ( is(Type == QPointF) )
	    return toPointF;
	else static if ( is(Type == QRect) )
	    return toRect;
	else static if ( is(Type == QRectF) )
	    return toRectF;
	else static if ( is(Type == QRegExp) )
	    return toRegExp;
	else static if ( is(Type == QSize) )
	    return toSize;
	else static if ( is(Type == QSizeF) )
	    return toSizeF;
	else  static if ( is(Type == string) )
	    return toString;
	else  static if ( is(Type == QTime) )
	    return toTime;
	else static if ( is(Type == uint) )
	    return toUInt;
	else static if ( is(Type == ulong) )
	    return toULongLong;
	else static if ( is(Type == QUrl) )
	    return toUrl;
	else static if( is( Type == class ) || is( Type == interface ) )
	{
	    Object object = cast(Object)qtd_QVariant_data(__nativeId);
	    if(object)
		return cast(Type)(object);
	    return null;
	}
	else static if (isDynamicArrayType!(Type) || isStaticArrayType!(Type) )
	{
	    auto array = cast(DArrayToC*)qtd_QVariant_data(__nativeId);
	    return cast(Type)(array.array);
	}
	else
	{
	    return *cast(Type*)qtd_QVariant_data(__nativeId);
	}
    }

    public final void clear() {
        qtd_QVariant_clear(__nativeId);
    }

    protected final bool cmp(QVariant other) {
        return qtd_QVariant_cmp_QVariant(__nativeId, other is null ? null : other.__nativeId);
    }

    protected final void create(int type, void* copy) {
        qtd_QVariant_create_int_nativepointervoid(__nativeId, type, copy);
    }

    public final bool isNull() {
        return qtd_QVariant_isNull(__nativeId);
    }

    public final bool isValid() {
        return qtd_QVariant_isValid(__nativeId);
    }

    public final void load(QDataStream ds) {
        qtd_QVariant_load_QDataStream(__nativeId, ds is null ? null : ds.__nativeId);
    }

    public final void writeTo(QDataStream s) {
        qtd_QVariant_writeTo_QDataStream(__nativeId, s is null ? null : s.__nativeId);
    }

    public final QVariant operator_assign(QVariant other) {
        void* __qt_return_value = qtd_QVariant_operator_assign_QVariant(__nativeId, other is null ? null : other.__nativeId);
        return new QVariant(__qt_return_value, QtdObjectFlags.nativeOwnership);
    }

    private final bool operator_equal(QVariant v) {
        return qtd_QVariant_operator_equal_QVariant(__nativeId, v is null ? null : v.__nativeId);
    }

    public final void readFrom(QDataStream s) {
        qtd_QVariant_readFrom_QDataStream(__nativeId, s is null ? null : s.__nativeId);
    }

    public final void save(QDataStream ds) {
        qtd_QVariant_save_QDataStream(__nativeId, ds is null ? null : ds.__nativeId);
    }

    public final QBitArray toBitArray() {
        void* __qt_return_value = qtd_QVariant_toBitArray(__nativeId);
        return new QBitArray(__qt_return_value);
    }

    public final bool toBool() {
        return qtd_QVariant_toBool(__nativeId);
    }

    public final QByteArray toByteArray() {
        void* __qt_return_value = qtd_QVariant_toByteArray(__nativeId);
        return new QByteArray(__qt_return_value);
    }

    public final QDate toDate() {
        void* __qt_return_value = qtd_QVariant_toDate(__nativeId);
        return new QDate(__qt_return_value);
    }

    public final QDateTime toDateTime() {
        void* __qt_return_value = qtd_QVariant_toDateTime(__nativeId);
        return new QDateTime(__qt_return_value);
    }

    public final double toDouble(bool* ok = null) {
        return qtd_QVariant_toDouble_nativepointerbool(__nativeId, ok);
    }

    public final int toInt(bool* ok = null) {
        return qtd_QVariant_toInt_nativepointerbool(__nativeId, ok);
    }

    public final QLine toLine() {
        return qtd_QVariant_toLine(__nativeId);
    }

    public final QLineF toLineF() {
        return qtd_QVariant_toLineF(__nativeId);
    }

    public final QLocale toLocale() {
        void* __qt_return_value = qtd_QVariant_toLocale(__nativeId);
        return new QLocale(__qt_return_value);
    }

    public final long toLongLong(bool* ok = null) {
        return qtd_QVariant_toLongLong_nativepointerbool(__nativeId, ok);
    }

    public final QPoint toPoint() {
        return qtd_QVariant_toPoint(__nativeId);
    }

    public final QPointF toPointF() {
        return qtd_QVariant_toPointF(__nativeId);
    }

    public final QRect toRect() {
        return qtd_QVariant_toRect(__nativeId);
    }

    public final QRectF toRectF() {
        return qtd_QVariant_toRectF(__nativeId);
    }

    public final QRegExp toRegExp() {
        void* __qt_return_value = qtd_QVariant_toRegExp(__nativeId);
        return new QRegExp(__qt_return_value);
    }

    public final QSize toSize() {
        return qtd_QVariant_toSize(__nativeId);
    }

    public final QSizeF toSizeF() {
        return qtd_QVariant_toSizeF(__nativeId);
    }

    public final string toString() {
        string res;
        qtd_QVariant_toString(__nativeId, &res);
        return res;
    }

    public final QTime toTime() {
        void* __qt_return_value = qtd_QVariant_toTime(__nativeId);
        return new QTime(__qt_return_value);
    }

    public final uint toUInt(bool* ok = null) {
        return qtd_QVariant_toUInt_nativepointerbool(__nativeId, ok);
    }

    public final ulong toULongLong(bool* ok = null) {
        return qtd_QVariant_toULongLong_nativepointerbool(__nativeId, ok);
    }

    public final QUrl toUrl() {
        void* __qt_return_value = qtd_QVariant_toUrl(__nativeId);
        return new QUrl(__qt_return_value);
    }

    public final char* typeName() {
        return qtd_QVariant_typeName(__nativeId);
    }

    public final Type type() {
        return cast(Type)qtd_QVariant_type(__nativeId);
    }

    public final int userType() {
        return qtd_QVariant_userType(__nativeId);
    }
// Field accessors

    public this(void* native_id, QtdObjectFlags flags = QtdObjectFlags.none) {
        super(native_id, flags);
    }

    protected override void __deleteNative() {
        qtd_QVariant_destructor(__nativeId);
    }

// Injected code in class
}
extern (C) void qtd_QVariant_destructor(void *ptr);


// C wrappers
private extern(C) void* qtd_QVariant_QVariant();
private extern(C) void* qtd_QVariant_QVariant_QDataStream(void* s0);
private extern(C) void* qtd_QVariant_QVariant_GlobalColor(int color0);
private extern(C) void* qtd_QVariant_QVariant_bool(bool b0);
private extern(C) void* qtd_QVariant_QVariant_QBitArray(void* bitarray0);
private extern(C) void* qtd_QVariant_QVariant_QByteArray(void* bytearray0);
private extern(C) void* qtd_QVariant_QVariant_QDate(void* date0);
private extern(C) void* qtd_QVariant_QVariant_QDateTime(void* datetime0);
private extern(C) void* qtd_QVariant_QVariant_String(string string0);
private extern(C) void* qtd_QVariant_QVariant_QLine(void* line0);
private extern(C) void* qtd_QVariant_QVariant_QLineF(void* line0);
private extern(C) void* qtd_QVariant_QVariant_QLocale(void* locale0);
private extern(C) void* qtd_QVariant_QVariant_QPoint(void* pt0);
private extern(C) void* qtd_QVariant_QVariant_QPointF(void* pt0);
private extern(C) void* qtd_QVariant_QVariant_QRect(void* rect0);
private extern(C) void* qtd_QVariant_QVariant_QRectF(void* rect0);
private extern(C) void* qtd_QVariant_QVariant_QRegExp(void* regExp0);
private extern(C) void* qtd_QVariant_QVariant_QSize(void* size0);
private extern(C) void* qtd_QVariant_QVariant_QSizeF(void* size0);
private extern(C) void* qtd_QVariant_QVariant_QTime(void* time0);
private extern(C) void* qtd_QVariant_QVariant_QUrl(void* url0);
private extern(C) void* qtd_QVariant_QVariant_QVariant(void* other0);
private extern(C) void* qtd_QVariant_QVariant_nativepointerchar(char* str0);
private extern(C) void* qtd_QVariant_QVariant_double(double d0);
private extern(C) void* qtd_QVariant_QVariant_int(int i0);
private extern(C) void* qtd_QVariant_QVariant_int_nativepointervoid(int typeOrUserType0,
 void* copy1);
private extern(C) void* qtd_QVariant_QVariant_long(long ll0);
private extern(C) void* qtd_QVariant_QVariant_uint(uint ui0);
private extern(C) void* qtd_QVariant_QVariant_ulong(ulong ull0);
private extern(C) bool  qtd_QVariant_canConvert(void* __this_nativeId, int);
private extern(C) void  qtd_QVariant_clear(void* __this_nativeId);
private extern(C) bool  qtd_QVariant_cmp_QVariant(void* __this_nativeId,
 void* other0);
private extern(C) void  qtd_QVariant_create_int_nativepointervoid(void* __this_nativeId,
 int type0,
 void* copy1);
private extern(C) bool  qtd_QVariant_isNull(void* __this_nativeId);
private extern(C) bool  qtd_QVariant_isValid(void* __this_nativeId);
private extern(C) void  qtd_QVariant_load_QDataStream(void* __this_nativeId,
 void* ds0);
private extern(C) void  qtd_QVariant_writeTo_QDataStream(void* __this_nativeId,
 void* s0);
private extern(C) void*  qtd_QVariant_operator_assign_QVariant(void* __this_nativeId,
 void* other0);
private extern(C) bool  qtd_QVariant_operator_equal_QVariant(void* __this_nativeId,
 void* v0);
private extern(C) void  qtd_QVariant_readFrom_QDataStream(void* __this_nativeId,
 void* s0);
private extern(C) void  qtd_QVariant_save_QDataStream(void* __this_nativeId,
 void* ds0);
private extern(C) void*  qtd_QVariant_toBitArray(void* __this_nativeId);
private extern(C) bool  qtd_QVariant_toBool(void* __this_nativeId);
private extern(C) void*  qtd_QVariant_toByteArray(void* __this_nativeId);
private extern(C) void*  qtd_QVariant_toDate(void* __this_nativeId);
private extern(C) void*  qtd_QVariant_toDateTime(void* __this_nativeId);
private extern(C) double  qtd_QVariant_toDouble_nativepointerbool(void* __this_nativeId,
 bool* ok0);
private extern(C) int  qtd_QVariant_toInt_nativepointerbool(void* __this_nativeId,
 bool* ok0);
private extern(C) QLine  qtd_QVariant_toLine(void* __this_nativeId);
private extern(C) QLineF  qtd_QVariant_toLineF(void* __this_nativeId);
private extern(C) void*  qtd_QVariant_toLocale(void* __this_nativeId);
private extern(C) long  qtd_QVariant_toLongLong_nativepointerbool(void* __this_nativeId,
 bool* ok0);
private extern(C) QPoint  qtd_QVariant_toPoint(void* __this_nativeId);
private extern(C) QPointF  qtd_QVariant_toPointF(void* __this_nativeId);
private extern(C) QRect  qtd_QVariant_toRect(void* __this_nativeId);
private extern(C) QRectF  qtd_QVariant_toRectF(void* __this_nativeId);
private extern(C) void*  qtd_QVariant_toRegExp(void* __this_nativeId);
private extern(C) QSize  qtd_QVariant_toSize(void* __this_nativeId);
private extern(C) QSizeF  qtd_QVariant_toSizeF(void* __this_nativeId);
private extern(C) void  qtd_QVariant_toString(void* __this_nativeId,
 void* __java_return_value);
private extern(C) void*  qtd_QVariant_toTime(void* __this_nativeId);
private extern(C) uint  qtd_QVariant_toUInt_nativepointerbool(void* __this_nativeId,
 bool* ok0);
private extern(C) ulong  qtd_QVariant_toULongLong_nativepointerbool(void* __this_nativeId,
 bool* ok0);
private extern(C) void*  qtd_QVariant_toUrl(void* __this_nativeId);
private extern(C) char*  qtd_QVariant_typeName(void* __this_nativeId);
private extern(C) int  qtd_QVariant_type(void* __this_nativeId);
private extern(C) int  qtd_QVariant_userType(void* __this_nativeId);
private extern(C) void *qtd_QVariant_data(void* __this_nativeId);

// Just the private functions for abstract functions implemeneted in superclasses

// Virtual Dispatch functions
