module qt.core.QVariant;

public import qt.QGlobal;
private import qt.QtDObject;

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
}


public class QVariant : QtDObject
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

    public this() {
        void* __qt_return_value = qtd_QVariant_QVariant();
        super(__qt_return_value);
    }


    public this(QDataStream s) {
        void* __qt_return_value = qtd_QVariant_QVariant_QDataStream(s is null ? null : s.nativeId);
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
        void* __qt_return_value = qtd_QVariant_QVariant_QBitArray(bitarray is null ? null : bitarray.nativeId);
        super(__qt_return_value);
    }


    public this(QByteArray bytearray) {
        void* __qt_return_value = qtd_QVariant_QVariant_QByteArray(bytearray is null ? null : bytearray.nativeId);
        super(__qt_return_value);
    }


    public this(QDate date) {
        void* __qt_return_value = qtd_QVariant_QVariant_QDate(date is null ? null : date.nativeId);
        super(__qt_return_value);
    }


    public this(QDateTime datetime) {
        void* __qt_return_value = qtd_QVariant_QVariant_QDateTime(datetime is null ? null : datetime.nativeId);
        super(__qt_return_value);
    }


    public this(char[] str) {
        void* __qt_return_value = qtd_QVariant_QVariant_String(str.ptr, str.length);
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
        void* __qt_return_value = qtd_QVariant_QVariant_QLocale(locale is null ? null : locale.nativeId);
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
        void* __qt_return_value = qtd_QVariant_QVariant_QRect(rect is null ? null : rect.nativeId);
        super(__qt_return_value);
    }


    public this(QRectF rect) {
        void* __qt_return_value = qtd_QVariant_QVariant_QRectF(rect is null ? null : rect.nativeId);
        super(__qt_return_value);
    }


    public this(QRegExp regExp) {
        void* __qt_return_value = qtd_QVariant_QVariant_QRegExp(regExp is null ? null : regExp.nativeId);
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
        void* __qt_return_value = qtd_QVariant_QVariant_QTime(time is null ? null : time.nativeId);
        super(__qt_return_value);
    }


    public this(QUrl url) {
        void* __qt_return_value = qtd_QVariant_QVariant_QUrl(url is null ? null : url.nativeId);
        super(__qt_return_value);
    }


    public this(QVariant other) {
        void* __qt_return_value = qtd_QVariant_QVariant_QVariant(other is null ? null : other.nativeId);
        super(__qt_return_value);
    }


    public this(char* str) {
        void* __qt_return_value = qtd_QVariant_QVariant_nativepointerchar(str);
        super(__qt_return_value);
    }


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


    public final bool canConvert(Type type) {
        return qtd_QVariant_canConvert(nativeId, type);
    }

    public final void clear() {
        qtd_QVariant_clear(nativeId);
    }

    protected final bool cmp(QVariant other) {
        return qtd_QVariant_cmp_QVariant(nativeId, other is null ? null : other.nativeId);
    }

    protected final void create(int type, void* copy) {
        qtd_QVariant_create_int_nativepointervoid(nativeId, type, copy);
    }

    public final bool isNull() {
        return qtd_QVariant_isNull(nativeId);
    }

    public final bool isValid() {
        return qtd_QVariant_isValid(nativeId);
    }

    public final void load(QDataStream ds) {
        qtd_QVariant_load_QDataStream(nativeId, ds is null ? null : ds.nativeId);
    }

    public final void writeTo(QDataStream s) {
        qtd_QVariant_writeTo_QDataStream(nativeId, s is null ? null : s.nativeId);
    }

    public final QVariant operator_assign(QVariant other) {
        void* __qt_return_value = qtd_QVariant_operator_assign_QVariant(nativeId, other is null ? null : other.nativeId);
        return new QVariant(__qt_return_value, true);
    }

    private final bool operator_equal(QVariant v) {
        return qtd_QVariant_operator_equal_QVariant(nativeId, v is null ? null : v.nativeId);
    }

    public final void readFrom(QDataStream s) {
        qtd_QVariant_readFrom_QDataStream(nativeId, s is null ? null : s.nativeId);
    }

    public final void save(QDataStream ds) {
        qtd_QVariant_save_QDataStream(nativeId, ds is null ? null : ds.nativeId);
    }

    public final QBitArray toBitArray() {
        void* __qt_return_value = qtd_QVariant_toBitArray(nativeId);
        return new QBitArray(__qt_return_value, false);
    }

    public final bool toBool() {
        return qtd_QVariant_toBool(nativeId);
    }

    public final QByteArray toByteArray() {
        void* __qt_return_value = qtd_QVariant_toByteArray(nativeId);
        return new QByteArray(__qt_return_value, false);
    }

    public final QDate toDate() {
        void* __qt_return_value = qtd_QVariant_toDate(nativeId);
        return new QDate(__qt_return_value, false);
    }

    public final QDateTime toDateTime() {
        void* __qt_return_value = qtd_QVariant_toDateTime(nativeId);
        return new QDateTime(__qt_return_value, false);
    }

    public final double toDouble(bool* ok = null) {
        return qtd_QVariant_toDouble_nativepointerbool(nativeId, ok);
    }

    public final int toInt(bool* ok = null) {
        return qtd_QVariant_toInt_nativepointerbool(nativeId, ok);
    }

    public final QLine toLine() {
        return qtd_QVariant_toLine(nativeId);
    }

    public final QLineF toLineF() {
        return qtd_QVariant_toLineF(nativeId);
    }

    public final QLocale toLocale() {
        void* __qt_return_value = qtd_QVariant_toLocale(nativeId);
        return new QLocale(__qt_return_value, false);
    }

    public final long toLongLong(bool* ok = null) {
        return qtd_QVariant_toLongLong_nativepointerbool(nativeId, ok);
    }

    public final QPoint toPoint() {
        return qtd_QVariant_toPoint(nativeId);
    }

    public final QPointF toPointF() {
        return qtd_QVariant_toPointF(nativeId);
    }

    public final QRect toRect() {
        void* __qt_return_value = qtd_QVariant_toRect(nativeId);
        return new QRect(__qt_return_value, false);
    }

    public final QRectF toRectF() {
        void* __qt_return_value = qtd_QVariant_toRectF(nativeId);
        return new QRectF(__qt_return_value, false);
    }

    public final QRegExp toRegExp() {
        void* __qt_return_value = qtd_QVariant_toRegExp(nativeId);
        return new QRegExp(__qt_return_value, false);
    }

    public final QSize toSize() {
        return qtd_QVariant_toSize(nativeId);
    }

    public final QSizeF toSizeF() {
        return qtd_QVariant_toSizeF(nativeId);
    }

    public final string toString() {
        char[] res;
        qtd_QVariant_toString(nativeId, &res);
        return cast(string)res;
    }

    public final QTime toTime() {
        void* __qt_return_value = qtd_QVariant_toTime(nativeId);
        return new QTime(__qt_return_value, false);
    }

    public final uint toUInt(bool* ok = null) {
        return qtd_QVariant_toUInt_nativepointerbool(nativeId, ok);
    }

    public final ulong toULongLong(bool* ok = null) {
        return qtd_QVariant_toULongLong_nativepointerbool(nativeId, ok);
    }

    public final QUrl toUrl() {
        void* __qt_return_value = qtd_QVariant_toUrl(nativeId);
        return new QUrl(__qt_return_value, false);
    }

    public final char* typeName() {
        return qtd_QVariant_typeName(nativeId);
    }

    public final int userType() {
        return qtd_QVariant_userType(nativeId);
    }
// Field accessors

    public this(void* native_id, bool no_real_delete = false) {
        super(native_id, no_real_delete);
    }


    ~this() {
        if(!__no_real_delete)
            __free_native_resources();
    }

    protected void __free_native_resources() {
        qtd_QVariant_destructor(nativeId());
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
private extern(C) void* qtd_QVariant_QVariant_String(char* string0, uint string0_size);
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
private extern(C) void*  qtd_QVariant_toRect(void* __this_nativeId);
private extern(C) void*  qtd_QVariant_toRectF(void* __this_nativeId);
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
private extern(C) int  qtd_QVariant_userType(void* __this_nativeId);
// Just the private functions for abstract functions implemeneted in superclasses



// Virtual Dispatch functions
