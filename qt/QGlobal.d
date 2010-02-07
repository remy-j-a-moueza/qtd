module qt.QGlobal;

public import qt.qtd.Str;
public import qt.QDefines;

version (Tango)
{
    import tango.io.Stdout;
    void writeln(string s)
    {
        Stdout(s).newline;
    }
    package import tango.stdc.stdlib,
                   tango.core.Memory;
}
else
{
    import std.stdio;
    package import std.c.stdlib,
                   core.memory;
}

T static_cast(T, U)(U obj)
{
    return cast(T)cast(void*)obj;
}

template QT_BEGIN_NAMESPACE() {
}

template QT_END_NAMESPACE() {
}

template QT_BEGIN_HEADER() {
}

template QT_END_HEADER() {
}

mixin QT_BEGIN_HEADER;
mixin QT_BEGIN_NAMESPACE;

//TODO: this sucks
extern(C) void qtd_dummy() {}
// Defined in QObject.d
extern(C) void qtd_delete_d_qobject(void* dPtr);

version(cpp_shared)
{
    extern (C) void qtd_core_initCallBacks(void* toUtf8, void* dummy);
    static this() {
        qtd_core_initCallBacks(&qtd_toUtf8, &qtd_dummy);
    }

    extern (C) void qtd_QObjectEntity_initCallBacks(void* del_d_obj);
    static this() {
        qtd_QObjectEntity_initCallBacks(&qtd_delete_d_qobject);
    }
}

string tr(string arg) {
    return arg;
}

/*
   can be used like #if (QT_VERSION >= QT_VERSION_CHECK(4, 4, 0))
*/
bool QT_VERSION_CHECK( ushort major, ushort minor, ushort patch )
{
	return cast(bool)((major<<16)|(minor<<8)|(patch));
}
//TODO(katrina) get this from the C++ side
const char[] QT_PACKAGEDATE_STR = "2008-09-27";
//TODO(katrina) get this from the C++ side
const char[] QT_PACKAGE_TAG = "gc9953de622c6a0f655322e0d9f5bd6dc2803b470";

/*
   Size-dependent types (architechture-dependent byte order)

   Make sure to update QMetaType when changing these typedefs
*/

alias char qint8;         /* 8 bit signed */
alias char quint8;      /* 8 bit unsigned */
alias short qint16;              /* 16 bit signed */
alias ushort quint16;    /* 16 bit unsigned */
alias int qint32;                /* 32 bit signed */
alias uint quint32;      /* 32 bit unsigned */
alias long qint64;            /* 64 bit signed */
alias ulong quint64;  /* 64 bit unsigned */

version (X86)
{
    alias quint32 quintptr;
    alias qint32 qptrdiff;
}
else version (X86_64)
{
    alias quint64 quintptr;
    alias qint64 qptrdiff;
}

const byte QT_POINTER_SIZE = 8;

alias int QNoImplicitBoolCast;

alias double qreal;


/*
   Utility macros and inline functions
   TODO(katrina) see if we need to do anything to make these
   able to be evaluated at compile time
*/

T qAbs(T)(T t) { return t >= 0 ? t : -t; }

int qRound(qreal d)
{ return d >= 0.0 ? cast(int)(d + 0.5) : cast(int)(d - cast(int)(d-1) + 0.5) + cast(int)(d-1); }

qint64 qRound64(qreal d)
{ return d >= 0.0 ? cast(qint64)(d + 0.5) : cast(qint64)(d - cast(qint64)(d-1) + 0.5) + cast(qint64)(d-1); }

T qMin(T)(T a,T b) { if (a < b) return a; return b; }
T qMax(T)(T a, T b) { if (a < b) return b; return a; }
T qBound(T)(T min, T val,T max) { return qMax(min, qMin(max, val)); }

/*
   Data stream functions are provided by many classes (defined in qdatastream.h)
*/

//class QDataStream;

/*
   System information
*/

class QSysInfo {
public:
    enum Sizes {
        WordSize = ((void *).sizeof<<3)
    };

    enum Endian {
        BigEndian,
        LittleEndian,
        ByteOrder = BigEndian
    };
    /* needed to bootstrap qmake */
    static const int ByteOrder;

    enum WinVersion {
        WV_32s      = 0x0001,
        WV_95       = 0x0002,
        WV_98       = 0x0003,
        WV_Me       = 0x0004,
        WV_DOS_based= 0x000f,

        WV_NT       = 0x0010,
        WV_2000     = 0x0020,
        WV_XP       = 0x0030,
        WV_2003     = 0x0040,
        WV_VISTA    = 0x0080,
        WV_NT_based = 0x00f0,

        WV_CE       = 0x0100,
        WV_CENET    = 0x0200,
        WV_CE_5     = 0x0300,
        WV_CE_6     = 0x0400,
        WV_CE_based = 0x0f00
    };
    static const WinVersion WindowsVersion;
    static WinVersion windowsVersion();

    enum MacVersion {
        MV_Unknown = 0x0000,

        /* version */
        MV_9 = 0x0001,
        MV_10_0 = 0x0002,
        MV_10_1 = 0x0003,
        MV_10_2 = 0x0004,
        MV_10_3 = 0x0005,
        MV_10_4 = 0x0006,
        MV_10_5 = 0x0007,

        /* codenames */
        MV_CHEETAH = MV_10_0,
        MV_PUMA = MV_10_1,
        MV_JAGUAR = MV_10_2,
        MV_PANTHER = MV_10_3,
        MV_TIGER = MV_10_4,
        MV_LEOPARD = MV_10_5
    };
    static const MacVersion MacintoshVersion;
};


extern(C) stringz qtd_qVersion();
///
string qVersion()
{
    return fromStringz(qtd_qVersion);
}

extern(C) bool qtd_qSharedBuild();
///
bool qSharedBuild()
{
    return qtd_qSharedBuild;
}

///
int qMacVersion() { return QSysInfo.MacintoshVersion; }

///
void qUnused(T)(T x) { cast(void) x; }
///
void Q_UNUSED(T)(T x) { qUnused(x); }

/*
   Debugging and error handling
*/

//class QString;
//char[] qPrintable(QString string) { string.toLocal8Bit().constData(); }
//TODO(katrina) These should probably actually call into the c++ functions
void qFatal(string str)
{
    throw new Exception(str);
}

void qDebug( char[] str ) /* print debug message */
{ writeln(str); }

extern (C) void Qt_qWarning( char * );

void qWarning(char[] str) /* print warning message */
{ writeln(str); }

//QString qt_error_string(int errorCode = -1);
void qCritical(char[] str) /* print critical message */
{ writeln(str); }

/*
  Forward declarations only.

  In order to use the qDebug() stream, you must #include<QDebug>
*/
//class QDebug;
//class QNoDebug;
//QDebug qDebug();
//QDebug qWarning();
//QDebug qCritical();

void qt_noop() {}
//TODO(katrina) Implement these
void qt_assert(char[] assertion, char[] file, int line);

void qt_assert_x(char[] where, char[] what, char[] file, int line);

void qt_check_pointer(char[], int);

enum QtMsgType { QtDebugMsg, QtWarningMsg, QtCriticalMsg, QtFatalMsg, QtSystemMsg = QtCriticalMsg };

void qt_message_output(QtMsgType, char[] buf);
//class QtMsgHandler;
//QtMsgHandler qInstallMsgHandler(QtMsgHandler);

// forward declaration, since qatomic.h needs qglobal.h
class QBasicAtomicPointer(T);

// POD for Q_GLOBAL_STATIC
class QGlobalStatic(T)
{
public:
    QBasicAtomicPointer!(T) pointer;
    bool destroyed;
};

// Created as a function-local static to delete a QGlobalStatic<T>
class QGlobalStaticDeleter(T)
{
public:
    QGlobalStatic!(T) globalStatic;
    this(QGlobalStatic!(T) _globalStatic) {
        globalStatic(_globalStatic);
    }

    ~this()
    {
        delete globalStatic.pointer;
        globalStatic.pointer = 0;
        globalStatic.destroyed = true;
    }
};

class QBool
{
    bool b;

public:
    this(bool B) { b = B; }
//    void *() const
//    { return b ? static_cast<const void *>(this) : static_cast<const void *>(0); }
}

bool qFuzzyCompare(double p1, double p2)
{
    return (qAbs(p1 - p2) <= 0.000000000001 * qMin(qAbs(p1), qAbs(p2)));
}

bool qFuzzyCompare(float p1, float p2)
{
    return (qAbs(p1 - p2) <= 0.00001f * qMin(qAbs(p1), qAbs(p2)));
}

/*
   This function tests a double for a null value. It doesn't
   check whether the actual value is 0 or close to 0, but whether
   it is binary 0.
*/
bool qIsNull(double d)
{
    union U {
        double d;
        quint64 u;
    };
    U val;
    val.d = d;
    return val.u == cast(quint64)(0);
}

/*
   This function tests a float for a null value. It doesn't
   check whether the actual value is 0 or close to 0, but whether
   it is binary 0.
*/
bool qIsNull(float f)
{
    union U {
        float f;
        quint32 u;
    };
    U val;
    val.f = f;
    return val.u == 0u;
}

/*
   Compilers which follow outdated template instantiation rules
   require a class to have a comparison operator to exist when
   a QList of this type is instantiated. It's not actually
   used in the list, though. Hence the dummy implementation.
   Just in case other code relies on it we better trigger a warning
   mandating a real implementation.
*/


/*
   QTypeInfo     - type trait functionality
   qIsDetached   - data sharing functionality
*/

/*
  The catch-all template.
*/
/*
bool qIsDetached(T)(T) { return true; }

class QTypeInfossss(T)
{
public:
    enum {
        isPointer = false,
        isComplex = true,
        isStatic = true,
        isLarge = ((T).sizeof>(void*).sizeof),
        isDummy = false
    };
};

class QTypeInfo(T)
{
public:
    enum {
        isPointer = true,
        isComplex = false,
        isStatic = false,
        isLarge = false,
        isDummy = false
    };
};
*/

/*
   Specialize a specific type with:

     Q_DECLARE_TYPEINFO(type, flags);

   where 'type' is the name of the type to specialize and 'flags' is
   logically-OR'ed combination of the flags below.
*/
enum { /* TYPEINFO flags */
    Q_COMPLEX_TYPE = 0,
    Q_PRIMITIVE_TYPE = 0x1,
    Q_STATIC_TYPE = 0,
    Q_MOVABLE_TYPE = 0x2,
    Q_DUMMY_TYPE = 0x4
};

/*
   Specialize a shared type with:

     Q_DECLARE_SHARED(type);

   where 'type' is the name of the type to specialize.  NOTE: shared
   types must declare a 'bool isDetached(void) const;' member for this
   to work.
*/
void qSwap_helper(T)(ref T value1, ref T value2, T*)
{
    T t = value1;
    value1 = value2;
    value2 = t;
}
bool qIsDetached(T)(ref T t) { return t.isDetached(); }
void qSwap_helper(T)(ref T value1, ref T value2, T*)
{
    const T.DataPtr t = value1.data_ptr();
    value1.data_ptr() = value2.data_ptr();
    value2.data_ptr() = t;
}

void qSwap(T)(ref T value1, ref T value2)
{
    T t = value1;
    value1 = value2;
    value2 = t;
}

/*
   QTypeInfo primitive specializations
   TODO(katrina) Find out what we need to do here
*/
/*
Q_DECLARE_TYPEINFO(bool, Q_PRIMITIVE_TYPE);
Q_DECLARE_TYPEINFO(char, Q_PRIMITIVE_TYPE);
Q_DECLARE_TYPEINFO(signed char, Q_PRIMITIVE_TYPE);
Q_DECLARE_TYPEINFO(uchar, Q_PRIMITIVE_TYPE);
Q_DECLARE_TYPEINFO(short, Q_PRIMITIVE_TYPE);
Q_DECLARE_TYPEINFO(ushort, Q_PRIMITIVE_TYPE);
Q_DECLARE_TYPEINFO(int, Q_PRIMITIVE_TYPE);
Q_DECLARE_TYPEINFO(uint, Q_PRIMITIVE_TYPE);
Q_DECLARE_TYPEINFO(long, Q_PRIMITIVE_TYPE);
Q_DECLARE_TYPEINFO(ulong, Q_PRIMITIVE_TYPE);
Q_DECLARE_TYPEINFO(qint64, Q_PRIMITIVE_TYPE);
Q_DECLARE_TYPEINFO(quint64, Q_PRIMITIVE_TYPE);
Q_DECLARE_TYPEINFO(float, Q_PRIMITIVE_TYPE);
Q_DECLARE_TYPEINFO(double, Q_PRIMITIVE_TYPE);
#ifndef Q_OS_DARWIN
Q_DECLARE_TYPEINFO(long double, Q_PRIMITIVE_TYPE);
#endif
*/
/*
   These functions make it possible to use standard C++ functions with
   a similar name from Qt header files (especially template classes).
   TODO(katrina) Implement these
*/
void * qMalloc(size_t size);
void qFree(void * ptr);
void * qRealloc(void * ptr, size_t size);
void * qMemCopy(void * dest, void * src, size_t n);
void * qMemSet(void * dest, int c, size_t n);

struct QFlags(Enum)
{
private:
    alias void **Zero;
    int i;

public:
    alias Enum enum_type;

    public static QFlags!(Enum) opCall(Enum)(QFlags f) {
        QFlags!(Enum) res;
        res.i = f.i;
        return res;
	}

    public static QFlags opCall(Enum)(Enum f) {
	    QFlags!(Enum) res;
	    res.i = f;
		return res;
	}

    public static QFlags opCall(Enum)(int f) {
	    QFlags!(Enum) res;
	    res.i = cast(Enum) f;
		return res;
	}

//    this(Zero = 0) : i(0) {}
//    this(QFlag f) : i(f) {}

//    QFlags!(Enum) opAssign(QFlags f) { i = f.i; return *this; }
    QFlags!(Enum) opAssign(int f) { i = f; return *this; }
    QFlags!(Enum) opAndAssign(int mask) { i &= mask; return *this; }
    QFlags!(Enum) opAndAssign(uint mask) { i &= mask; return *this; }
    QFlags!(Enum) opOrAssign(QFlags f) { i |= f.i; return *this; }
    QFlags!(Enum) opOrAssign(Enum f) { i |= f; return *this; }
    QFlags!(Enum) opXorAssign(QFlags f) { i ^= f.i; return *this; }
    QFlags!(Enum) opXorAssign(Enum f) { i ^= f; return *this; }

    int toInt() { return i; }

    QFlags!(Enum) opOr(QFlags f) { QFlags g; g.i = i | f.i; return g; }
    QFlags!(Enum) opOr(Enum f) { QFlags g; g.i = i | f; return g; }
    QFlags!(Enum) opXor(QFlags f) { QFlags g; g.i = i ^ f.i; return g; }
    QFlags!(Enum) opXor(Enum f) { QFlags g; g.i = i ^ f; return g; }
    QFlags!(Enum) opAnd(int mask) { QFlags g; g.i = i & mask; return g; }
    QFlags!(Enum) opAnd(uint mask) { QFlags g; g.i = i & mask; return g; }
    QFlags!(Enum) opAnd(Enum f) { QFlags g; g.i = i & f; return g; }
    QFlags!(Enum) opCom() { QFlags g; g.i = ~i; return g; }

//    bool operator!() { return !i; }

//    bool testFlag(Enum f) { return i & f; }
}

/* TODO typesafety
#define Q_DECLARE_FLAGS(Flags, Enum)\
typedef QFlags<Enum> Flags;
#define Q_DECLARE_OPERATORS_FOR_FLAGS(Flags) \
QFlags<Flags::enum_type> operator|(Flags::enum_type f1, Flags::enum_type f2) \
{ return QFlags<Flags::enum_type>(f1) | f2; } \
QFlags<Flags::enum_type> operator|(Flags::enum_type f1, QFlags<Flags::enum_type> f2) \
{ return f2 | f1; }
*/

char[] QT_TR_NOOP(char[] x) { return x; }
char[] QT_TRANSLATE_NOOP(char[] s, char[] x) { return x; }
char[] QT_TRANSLATE_NOOP3(char[] s, char[] x, char[] comment) { return x; }

//class QByteArray;
//QByteArray qgetenv(char[] varName);
//bool qputenv(char[] varName, QByteArray value);

int qIntCast(double f) { return cast(int)(f); }
int qIntCast(float f) { return cast(int)(f); }

/*
  Reentrant versions of basic rand() functions for random number generation
*/
void qsrand(uint seed);
int qrand();


/*
   This gives us the possibility to check which modules the user can
   use. These are purely compile time checks and will generate no code.
*/

/* Qt modules */

const ushort QT_MODULE_CORE =                 0x0001;
const ushort QT_MODULE_GUI =                  0x0002;
const ushort QT_MODULE_NETWORK =              0x0004;
const ushort QT_MODULE_OPENGL =               0x0008;
const ushort QT_MODULE_SQL =                  0x0010;
const ushort QT_MODULE_XML =                  0x0020;
const ushort QT_MODULE_QT3SUPPORTLIGHT =      0x0040;
const ushort QT_MODULE_QT3SUPPORT =           0x0080;
const ushort QT_MODULE_SVG =                  0x0100;
const ushort QT_MODULE_ACTIVEQT =             0x0200;
const ushort QT_MODULE_GRAPHICSVIEW =         0x0400;
const ushort QT_MODULE_SCRIPT =               0x0800;
const ushort QT_MODULE_XMLPATTERNS =          0x1000;
const ushort QT_MODULE_HELP =                 0x2000;
const ushort QT_MODULE_TEST =                 0x4000;
const ushort QT_MODULE_DBUS =                 0x8000;

/* Qt editions */

const ushort QT_EDITION_CONSOLE = (QT_MODULE_CORE
                                 | QT_MODULE_NETWORK
                                 | QT_MODULE_SQL
                                 | QT_MODULE_SCRIPT
                                 | QT_MODULE_XML
                                 | QT_MODULE_XMLPATTERNS
                                 | QT_MODULE_TEST
                                 | QT_MODULE_DBUS);
const ushort QT_EDITION_DESKTOPLIGHT = (QT_MODULE_CORE
                                 | QT_MODULE_GUI
                                 | QT_MODULE_QT3SUPPORTLIGHT
                                 | QT_MODULE_TEST
                                 | QT_MODULE_DBUS);
const ushort QT_EDITION_OPENSOURCE = (QT_MODULE_CORE
                                 | QT_MODULE_GUI
                                 | QT_MODULE_NETWORK
                                 | QT_MODULE_OPENGL
                                 | QT_MODULE_SQL
                                 | QT_MODULE_XML
                                 | QT_MODULE_XMLPATTERNS
                                 | QT_MODULE_SCRIPT
                                 | QT_MODULE_QT3SUPPORTLIGHT
                                 | QT_MODULE_QT3SUPPORT
                                 | QT_MODULE_SVG
                                 | QT_MODULE_GRAPHICSVIEW
                                 | QT_MODULE_HELP
                                 | QT_MODULE_TEST
                                 | QT_MODULE_DBUS);
const ushort QT_EDITION_DESKTOP = (QT_EDITION_OPENSOURCE
                                 | QT_MODULE_ACTIVEQT);
const ushort QT_EDITION_UNIVERSAL =   QT_EDITION_DESKTOP;
const ushort QT_EDITION_ACADEMIC =    QT_EDITION_DESKTOP;
const ushort QT_EDITION_EDUCATIONAL = QT_EDITION_DESKTOP;
const ushort QT_EDITION_EVALUATION =  QT_EDITION_DESKTOP;

mixin QT_END_NAMESPACE;

private
struct Align
{
    ubyte a;
    void* b;
}

private
const PTR_ALIGN = Align.tupleof[1].alignof;

private
template AlignPad(size_t base, size_t aligned)
{
    static if( aligned == 0 )
        const AlignPad = base;
    else
        const AlignPad = ((base+PTR_ALIGN-1)/PTR_ALIGN)*PTR_ALIGN
            + aligned;
}

template InstanceSize(T)
{
    static if( is( T == Object ) )
        const InstanceSize = 2*(void*).sizeof;
    else
        const InstanceSize = Max!(
            AlignPad!(
                InstanceSize!(Super!(T)),
                InterfaceCount!(T)*(void*).sizeof),

            AlignPad!(
                InstanceSizeImpl!(T, 0),
                + InterfaceCount!(T)*(void*).sizeof));
}

private
template Super(T)
{
    static if( is( T S == super ) )
        alias First!(S) Super;
    else
        static assert(false, "Can't get super of "~T.mangleof);
}

private
template First(T)
{
    alias T First;
}

private
template First(T, Ts...)
{
    alias T First;
}

private
template InstanceSizeImpl(T, size_t i)
{
    static if( i < T.tupleof.length )
        const InstanceSizeImpl = Max!(
            T.tupleof[i].offsetof + T.tupleof[i].sizeof,
            InstanceSizeImpl!(T, i+1));
    else
        // This is necessary to account for classes without member
        // variables.
        const InstanceSizeImpl = 2*(void*).sizeof;
}

private
template Max(size_t a, size_t b)
{
    static if( a > b )
        const Max = a;
    else
        const Max = b;
}

private
template InterfaceCount(T)
{
    static if( is( T == Object ) )
        const InterfaceCount = 0u;
    else static if( is( T S == super ) )
        const InterfaceCount = InterfaceCountImpl!(S);
}

private
template InterfaceCountImpl(TBase, TInterfaces...)
{
    const InterfaceCountImpl = TInterfaces.length;
}

/+
scope class StackObject(C)
{
    byte[InstanceSize!(C)] data;
    bool constructed;

    C opCall(A...)(A args)
    {
        assert(!constructed);

        auto r = new(&data)C(args);
        r.__stackAllocated = true;
        constructed = true;

        return r;
    }

    ~this()
    {
        if (constructed)
        {
            auto obj = cast(C)&data;
            delete obj;
        }
    }
}
+/

alias void DArray;

mixin QT_END_HEADER;

