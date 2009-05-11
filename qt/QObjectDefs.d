module qt.QObjectDefs;

//import qt.core.QGlobal;
//import qt.core.Qt;
import QGlobal;

const byte Q_MOC_OUTPUT_REVISION = 59;

template QT_TR_FUNCTIONS_NOUTF8()
{
	static QString tr(char[] s, char[] c = null)
	{ return staticMetaObject.tr(s, c); }
	static QString tr(char[] s, char[] c, int n)
	{ return staticMetaObject.tr(s, c, n); }
}

template QT_TR_FUNCTIONS_UTF8()
{
	static QString trUtf8(char[] s, char[] c = null)
	{ return staticMetaObject.trUtf8(s, c); }
	static QString trUtf8(char[] s, char[] c, int n)
	{ return staticMetaObject.trUtf8(s, c, n); }
}

template QT_TR_FUNCTIONS()
{
	mixin QT_TR_FUNCTIONS_NOUTF8;
	mixin QT_TR_FUNCTIONS_UTF8;
}

template Q_OBJECT_CHECK()
{
	void qt_check_for_QOBJECT_macro(T)(T _q_argument) const
	{ int i = qYouForgotTheQ_OBJECT_Macro(this, _q_argument); i = i; }
}

int qYouForgotTheQ_OBJECT_Macro(T)(T, T) { return 0; }

void qYouForgotTheQ_OBJECT_Macro(T1,T2)(T1, T2) {}

template Q_OBJECT()
{
	public mixin Q_OBJECT_CHECK;
	public static const QMetaObject staticMetaObject;
	public const QMetaObject *metaObject() const{}
	public void *qt_metacast(const char *){}
	public mixin QT_TR_FUNCTIONS;
	public int qt_metacall(QMetaObject.Call, int, void **){}
}

template Q_OBJECT_FAKE()
{
	mixin Q_OBJECT;
}

template Q_GADGET()
{
    public static const QMetaObject staticMetaObject;
}

char[] METHOD( char[] a ) { return "0"~a; }
char[] SLOT( char[] a ) { return "1"~a; }
char[] SIGNAL( char[] a ) { return "2"~a; }

version(QT3_SUPPORT) {
	const byte METHOD_CODE = 0;                        // member type codes
	const byte SLOT_CODE = 1;
	const byte SIGNAL_CODE = 2;
}

const byte QMETHOD_CODE = 0;                        // member type codes
const byte QSLOT_CODE = 1;
const byte QSIGNAL_CODE = 2;

QArgument!(T) Q_ARG(T)(char [] type, T data)
	{ return QArgument!(T)(type, data); }

QReturnArgument!(T) Q_RETURN_ARG(T)(char [] type, T data)
	{ return QReturnArgument!(T)(type, data); }

class QGenericArgument
{
public:
    this(char[] aName = null, const void *aData = null)
        { _data = aData; _name = aName; }
    void *data() const { return cast(void *)(_data); }
    char[] name() { return _name; }

private:
    const void *_data;
    char[] _name;
};

class QGenericReturnArgument : QGenericArgument
{
};

class QArgument(T) : QGenericArgument
{
public:
    this(char[] aName, T aData)
    { this(aName, cast(void *)aData); }
};

class QReturnArgument(T) : QGenericReturnArgument
{
public:
    this(char[] aName, T aData)
    { this(aName, cast(void *)aData); }
};

//TODO(katrina) enable this when all the classes it uses are available
/*struct QMetaObject
{
    char[] className() const;
    const QMetaObject *superClass() const;

    //TODO(katrina) enable QObject cast(QObject obj) const;

    // ### Qt 4: Merge overloads
    QString tr(const char *s, const char *c) const;
    QString trUtf8(const char *s, const char *c) const;
    QString tr(const char *s, const char *c, int n) const;
    QString trUtf8(const char *s, const char *c, int n) const;

    int methodOffset() const;
    int enumeratorOffset() const;
    int propertyOffset() const;
    int classInfoOffset() const;

    int methodCount() const;
    int enumeratorCount() const;
    int propertyCount() const;
    int classInfoCount() const;

    int indexOfMethod(const char *method) const;
    int indexOfSignal(const char *signal) const;
    int indexOfSlot(const char *slot) const;
    int indexOfEnumerator(const char *name) const;
    int indexOfProperty(const char *name) const;
    int indexOfClassInfo(const char *name) const;

    QMetaMethod method(int index) const;
    QMetaEnum enumerator(int index) const;
    QMetaProperty property(int index) const;
    QMetaClassInfo classInfo(int index) const;
    QMetaProperty userProperty() const;

    static bool checkConnectArgs(const char *signal, const char *method);
    static QByteArray normalizedSignature(const char *method);
    static QByteArray normalizedType(const char *type);

    // internal index-based connect
    static bool connect(const QObject *sender, int signal_index,
                        const QObject *receiver, int method_index,
                        int type = 0, int *types = 0);
    // internal index-based disconnect
    static bool disconnect(const QObject *sender, int signal_index,
                           const QObject *receiver, int method_index);
    // internal slot-name based connect
    static void connectSlotsByName(QObject *o);

    // internal index-based signal activation
    static void activate(QObject *sender, int signal_index, void **argv);
    static void activate(QObject *sender, int from_signal_index, int to_signal_index, void **argv);
    static void activate(QObject *sender, const QMetaObject *, int local_signal_index, void **argv);
    static void activate(QObject *sender, const QMetaObject *, int from_local_signal_index, int to_local_signal_index, void **argv);
    // internal guarded pointers
    static void addGuard(QObject **ptr);
    static void removeGuard(QObject **ptr);
    static void changeGuard(QObject **ptr, QObject *o);

    static bool invokeMethod(QObject *obj, const char *member,
                             qt.core.Qt.ConnectionType,
                             QGenericReturnArgument ret,
                             QGenericArgument val0 = QGenericArgument(0),
                             QGenericArgument val1 = QGenericArgument(),
                             QGenericArgument val2 = QGenericArgument(),
                             QGenericArgument val3 = QGenericArgument(),
                             QGenericArgument val4 = QGenericArgument(),
                             QGenericArgument val5 = QGenericArgument(),
                             QGenericArgument val6 = QGenericArgument(),
                             QGenericArgument val7 = QGenericArgument(),
                             QGenericArgument val8 = QGenericArgument(),
                             QGenericArgument val9 = QGenericArgument());

    static bool invokeMethod(QObject *obj, const char *member,
                             QGenericReturnArgument ret,
                             QGenericArgument val0 = QGenericArgument(0),
                             QGenericArgument val1 = QGenericArgument(),
                             QGenericArgument val2 = QGenericArgument(),
                             QGenericArgument val3 = QGenericArgument(),
                             QGenericArgument val4 = QGenericArgument(),
                             QGenericArgument val5 = QGenericArgument(),
                             QGenericArgument val6 = QGenericArgument(),
                             QGenericArgument val7 = QGenericArgument(),
                             QGenericArgument val8 = QGenericArgument(),
                             QGenericArgument val9 = QGenericArgument())
    {
        return invokeMethod(obj, member, qt.core.Qt.AutoConnection, ret, val0, val1, val2, val3,
                val4, val5, val6, val7, val8, val9);
    }

    static bool invokeMethod(QObject *obj, const char *member,
                             qt.core.Qt.ConnectionType type,
                             QGenericArgument val0 = QGenericArgument(0),
                             QGenericArgument val1 = QGenericArgument(),
                             QGenericArgument val2 = QGenericArgument(),
                             QGenericArgument val3 = QGenericArgument(),
                             QGenericArgument val4 = QGenericArgument(),
                             QGenericArgument val5 = QGenericArgument(),
                             QGenericArgument val6 = QGenericArgument(),
                             QGenericArgument val7 = QGenericArgument(),
                             QGenericArgument val8 = QGenericArgument(),
                             QGenericArgument val9 = QGenericArgument())
    {
        return invokeMethod(obj, member, type, QGenericReturnArgument(), val0, val1, val2,
                                 val3, val4, val5, val6, val7, val8, val9);
    }


    static bool invokeMethod(QObject *obj, const char *member,
                             QGenericArgument val0 = QGenericArgument(0),
                             QGenericArgument val1 = QGenericArgument(),
                             QGenericArgument val2 = QGenericArgument(),
                             QGenericArgument val3 = QGenericArgument(),
                             QGenericArgument val4 = QGenericArgument(),
                             QGenericArgument val5 = QGenericArgument(),
                             QGenericArgument val6 = QGenericArgument(),
                             QGenericArgument val7 = QGenericArgument(),
                             QGenericArgument val8 = QGenericArgument(),
                             QGenericArgument val9 = QGenericArgument())
    {
        return invokeMethod(obj, member, qt.core.Qt.AutoConnection, QGenericReturnArgument(), val0,
                val1, val2, val3, val4, val5, val6, val7, val8, val9);
    }

    enum Call {
        InvokeMetaMethod,
        ReadProperty,
        WriteProperty,
        ResetProperty,
        QueryPropertyDesignable,
        QueryPropertyScriptable,
        QueryPropertyStored,
        QueryPropertyEditable,
        QueryPropertyUser
    };

version(QT3_SUPPORT) {
    const char *superClassName() const;
}

    struct d_struct{ // private data
        const QMetaObject *superdata;
        const char *stringdata;
        const uint *data;
        const QMetaObject **extradata;
    };
    d_struct d;
};
*/
