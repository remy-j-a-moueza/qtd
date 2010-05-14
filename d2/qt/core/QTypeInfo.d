module qt.core.QTypeInfo;

//import qt.QGlobal;
//import qtd.Atomic;

/*
  The catch-all template.
*/
import std.traits;

import qtd.Marshal;
import qt.core.QString;

bool qIsDetached(T)(ref T) { return true; }

template isBasicType(T)
{
    enum isBasicType = isNumeric!T || is(T == bool) || is(T == enum);
}

template QTypeInfo(T)
{
    static if(is(T == string))
    {
        alias QString.QTypeInfo QTypeInfo;
    }
    else static if(isBasicType!T)
    {
        public enum
        {
            isPointer = false,
            isComplex = false,
            isStatic = false,
            isLarge = (T.sizeof > (void*).sizeof),
            isDummy = false
        }
    }
    else static if(is(T.QTypeInfo))
    {
        alias T.QTypeInfo QTypeInfo; // alias member QTypeInfo
    }
    else static if ( isQObjectType!T || isObjectType!T )
    {
        public enum // are pointers
        {
            isPointer = true,
            isComplex = false,
            isStatic = false,
            isLarge = false,
            isDummy = false
        }
    }
    else // default parameters
    {
        public enum
        {
            isPointer = isPointer!T,
            isComplex = !isPointer,
            isStatic = !isPointer,
            isLarge = (T.sizeof > (void*).sizeof),
            isDummy = false
        }
    }
}


/*
   Specialize a specific type with:

     Q_DECLARE_TYPEINFO(type, flags);

   where 'type' is the name of the type to specialize and 'flags' is
   logically-OR'ed combination of the flags below.
*/

/* presents in QGlobal
enum { /* TYPEINFO flags
    Q_COMPLEX_TYPE = 0,
    Q_PRIMITIVE_TYPE = 0x1,
    Q_STATIC_TYPE = 0,
    Q_MOVABLE_TYPE = 0x2,
    Q_DUMMY_TYPE = 0x4
}
*/

/*
template QTypeInfo(alias FLAGS)
{
    template QTypeInfo(TYPE)
    {
    public:
        enum {
            isComplex = (((FLAGS) & Q_PRIMITIVE_TYPE) == 0),
            isStatic = (((FLAGS) & (Q_MOVABLE_TYPE | Q_PRIMITIVE_TYPE)) == 0),
            isLarge = (TYPE.sizeof > (void*).sizeof),
            isPointer = false,
            isDummy = (((FLAGS) & Q_DUMMY_TYPE) != 0)
        }
    }
}
*/
/*
   Specialize a shared type with:

     Q_DECLARE_SHARED(type);

   where 'type' is the name of the type to specialize.  NOTE: shared
   types must declare a 'bool isDetached(void) const;' member for this
   to work.
*/
/*
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
*/
