module qt.core.QTypeInfo;

//import qt.QGlobal;
//import qt.qtd.Atomic;

/*
  The catch-all template.
*/

bool qIsDetached(T)(ref T) { return true; }

struct QTypeInfo(T)
{
public:
    enum {
        isPointer = false,
        isComplex = true,
        isStatic = true,
        isLarge = (T.sizeof > sizeof(void*)),
        isDummy = false
    }
}

struct QTypeInfo(T : T*)
{
public:
    enum {
        isPointer = true,
        isComplex = false,
        isStatic = false,
        isLarge = false,
        isDummy = false
    }
}

#else

template <typename T> char QTypeInfoHelper(T*(*)());
void* QTypeInfoHelper(...);

template <typename T> inline bool qIsDetached(T &) { return true; }

template <typename T>
class QTypeInfo
{
public:
    enum {
        isPointer = (1 == sizeof(QTypeInfoHelper((T(*)())0))),
        isComplex = !isPointer,
        isStatic = !isPointer,
        isLarge = (sizeof(T)>sizeof(void*)),
        isDummy = false
    };
};

#endif /* QT_NO_PARTIAL_TEMPLATE_SPECIALIZATION */

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

#define Q_DECLARE_TYPEINFO(TYPE, FLAGS) \
template <> \
class QTypeInfo<TYPE> \
{ \
public: \
    enum { \
        isComplex = (((FLAGS) & Q_PRIMITIVE_TYPE) == 0), \
        isStatic = (((FLAGS) & (Q_MOVABLE_TYPE | Q_PRIMITIVE_TYPE)) == 0), \
        isLarge = (sizeof(TYPE)>sizeof(void*)), \
        isPointer = false, \
        isDummy = (((FLAGS) & Q_DUMMY_TYPE) != 0) \
    }; \
    static inline const char *name() { return #TYPE; } \
}

/*
   Specialize a shared type with:

     Q_DECLARE_SHARED(type);

   where 'type' is the name of the type to specialize.  NOTE: shared
   types must declare a 'bool isDetached(void) const;' member for this
   to work.
*/
#if defined Q_CC_MSVC && _MSC_VER < 1300
template <typename T>
inline void qSwap_helper(T &value1, T &value2, T*)
{
    T t = value1;
    value1 = value2;
    value2 = t;
}
#define Q_DECLARE_SHARED(TYPE)                                          \
template <> inline bool qIsDetached<TYPE>(TYPE &t) { return t.isDetached(); } \
template <> inline void qSwap_helper<TYPE>(TYPE &value1, TYPE &value2, TYPE*) \
{ \
    const TYPE::DataPtr t = value1.data_ptr(); \
    value1.data_ptr() = value2.data_ptr(); \
    value2.data_ptr() = t; \
}
#else
#define Q_DECLARE_SHARED(TYPE)                                          \
template <> inline bool qIsDetached<TYPE>(TYPE &t) { return t.isDetached(); } \
template <typename T> inline void qSwap(T &, T &); \
template <> inline void qSwap<TYPE>(TYPE &value1, TYPE &value2) \
{ \
    const TYPE::DataPtr t = value1.data_ptr(); \
    value1.data_ptr() = value2.data_ptr(); \
    value2.data_ptr() = t; \
}
#endif
