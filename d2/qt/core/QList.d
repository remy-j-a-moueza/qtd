module qt.core.QList;

import qt.QGlobal;
import qt.core.QTypeInfo;
import qt.core.QString;
import qtd.QtdObject;
import qtd.Atomic;
import qtd.Marshal;

import core.stdc.stdlib : qRealloc = realloc, qFree = free, qMalloc = malloc;
import core.stdc.string : memcpy, memmove;

import std.traits;

enum INT_MAX = int.max;

bool isComplex(T)()
    if (is(T.QTypeInfo))
{
    return T.QTypeInfo.isComplex;
}

bool isStatic(T)()
    if (is(T.QTypeInfo))
{
    return T.QTypeInfo.isStatic;
}

bool isLarge(T)()
    if (is(T.QTypeInfo))
{
    return T.QTypeInfo.isLarge;
}

template isQtReference(T)
{
    enum isQtReference = isQObjectType!T || isObjectType!T || isValueType!T || is(T == string);
}

int qAllocMore(int alloc, int extra)
{
    if (alloc == 0 && extra == 0)
        return 0;
    const int page = 1 << 12;
    int nalloc;
    alloc += extra;
    if (alloc < 1<<6) {
        nalloc = (1<<3) + ((alloc >>3) << 3);
    } else  {
        // don't do anything if the loop will overflow signed int.
        if (alloc >= INT_MAX/2)
            return INT_MAX;
        nalloc = (alloc < page) ? 1 << 3 : page;
        while (nalloc < alloc) {
            if (nalloc <= 0)
                return INT_MAX;
            nalloc *= 2;
        }
    }
    return nalloc - extra;
}

void q_new_at(T)(T* ptr, const ref T t)
{
    memcpy(ptr, &t, T.sizeof);
/*    static if (__traits(compiles, ptr.__postblit())) DMD bug #3539
        ptr.__postblit();*/
}

T* q_new(T)(const ref T t)
{
    T* ptr = cast(T*) qMalloc(T.sizeof);
    q_new_at!T(ptr, t);
    return ptr;
}

void q_delete(T)(T* t)
{
    static if (__traits(compiles, t.__dtor()))
        t.__dtor();
    qFree(t);
}

private int grow(int size)
{
    // dear compiler: don't optimize me out.
//    synchronized {
        int x = cast(int) (qAllocMore(cast(int)(size * (void*).sizeof), QListData.DataHeaderSize) / (void*).sizeof);
        return x;
//    }
}

struct QListData {
private:
    struct Data {
        Atomic!int ref_;
        int alloc, begin, end;
        uint sharable;
        void*[1] array;
    }

    enum { DataHeaderSize = Data.sizeof - (void*).sizeof }

    static Data shared_null;
    Data *d;

    static this()
    {
        shared_null = Data(Atomic!int(1), 0, 0, 0, true, [null]);
    }


//    Data *detach(); // remove in 5.0

    Data* detach2()
    {
        Data* x = d;
        d = cast(Data*)(qMalloc(DataHeaderSize + x.alloc * (void*).sizeof));
        if (!d)
            qFatal("QList: Out of memory");

        memcpy(d, x, DataHeaderSize + x.alloc * (void*).sizeof);
        d.alloc = x.alloc;
        d.ref_.store(1);
        d.sharable = true;
        if (!d.alloc)
            d.begin = d.end = 0;

        return x;
    }

    void realloc(int alloc)
    {
//        assert(d.ref_ == 1);
        Data* x = cast(Data*)(qRealloc(d, DataHeaderSize + alloc * (void*).sizeof));
        if (!x)
            qFatal("QList: Out of memory");

        d = x;
        d.alloc = alloc;
        if (!alloc)
            d.begin = d.end = 0;
    }

    void** append()
    {
// #TODO        Q_ASSERT(d.ref_ == 1);
        if (d.end == d.alloc) {
            int n = d.end - d.begin;
            if (d.begin > 2 * d.alloc / 3) {
                memcpy(d.array.ptr + n, d.array.ptr + d.begin, n * (void*).sizeof);
                d.begin = n;
                d.end = n * 2;
            } else {
                realloc(grow(d.alloc + 1));
            }
        }
        return d.array.ptr + d.end++;
    }

    void **append(const ref QListData l)
    {
//        Q_ASSERT(d.ref_ == 1);
        int e = d.end;
        int n = l.d.end - l.d.begin;
        if (n) {
            if (e + n > d.alloc)
                realloc(grow(e + l.d.end - l.d.begin));
            memcpy(d.array.ptr + d.end, l.d.array.ptr + l.d.begin, n * (void*).sizeof);
            d.end += n;
        }
        return d.array.ptr + e;
    }

    void **prepend()
    {
//        Q_ASSERT(d.ref_ == 1);
        if (d.begin == 0) {
            if (d.end >= d.alloc / 3)
                realloc(grow(d.alloc + 1));

            if (d.end < d.alloc / 3)
                d.begin = d.alloc - 2 * d.end;
            else
                d.begin = d.alloc - d.end;

            memmove(d.array.ptr + d.begin, d.array.ptr, d.end * (void*).sizeof);
            d.end += d.begin;
        }
        return d.array.ptr + --d.begin;
    }

    void **insert(int i)
    {
//        Q_ASSERT(d.ref_ == 1);
        if (i <= 0)
            return prepend();
        if (i >= d.end - d.begin)
            return append();

        bool leftward = false;
        int size = d.end - d.begin;

        if (d.begin == 0) {
            if (d.end == d.alloc) {
                // If the array is full, we expand it and move some items rightward
                realloc(grow(d.alloc + 1));
            } else {
                // If there is free space at the end of the array, we move some items rightward
            }
        } else {
            if (d.end == d.alloc) {
                // If there is free space at the beginning of the array, we move some items leftward
                leftward = true;
            } else {
                // If there is free space at both ends, we move as few items as possible
                leftward = (i < size - i);
            }
        }

        if (leftward) {
            --d.begin;
            memmove(d.array.ptr + d.begin, d.array.ptr + d.begin + 1, i * (void*).sizeof);
        } else {
            memmove(d.array.ptr + d.begin + i + 1, d.array.ptr + d.begin + i,
                    (size - i) * (void*).sizeof);
            ++d.end;
        }
        return d.array.ptr + d.begin + i;
    }

    void remove(int i)
    {
//        Q_ASSERT(d.ref_ == 1);
        i += d.begin;
        if (i - d.begin < d.end - i) {
            if (int offset = i - d.begin)
                memmove(d.array.ptr + d.begin + 1, d.array.ptr + d.begin, offset * (void*).sizeof);
            d.begin++;
        } else {
            if (int offset = d.end - i - 1)
                memmove(d.array.ptr + i, d.array.ptr + i + 1, offset * (void*).sizeof);
            d.end--;
        }
    }

    void remove(int i, int n)
    {
//        Q_ASSERT(d.ref_ == 1);
        i += d.begin;
        int middle = i + n/2;
        if (middle - d.begin < d.end - middle) {
            memmove(d.array.ptr + d.begin + n, d.array.ptr + d.begin,
                    (i - d.begin) * (void*).sizeof);
            d.begin += n;
        } else {
            memmove(d.array.ptr + i, d.array.ptr + i + n,
                    (d.end - i - n) * (void*).sizeof);
            d.end -= n;
        }
    }

    void move(int from, int to)
    {
//        Q_ASSERT(d.ref_ == 1);
        if (from == to)
            return;

        from += d.begin;
        to += d.begin;
        void *t = d.array.ptr[from];

        if (from < to) {
            if (d.end == d.alloc || 3 * (to - from) < 2 * (d.end - d.begin)) {
                memmove(d.array.ptr + from, d.array.ptr + from + 1, (to - from) * (void*).sizeof);
            } else {
                // optimization
                if (int offset = from - d.begin)
                    memmove(d.array.ptr + d.begin + 1, d.array.ptr + d.begin, offset * (void*).sizeof);
                if (int offset = d.end - (to + 1))
                    memmove(d.array.ptr + to + 2, d.array.ptr + to + 1, offset * (void*).sizeof);
                ++d.begin;
                ++d.end;
                ++to;
            }
        } else {
            if (d.begin == 0 || 3 * (from - to) < 2 * (d.end - d.begin)) {
                memmove(d.array.ptr + to + 1, d.array.ptr + to, (from - to) * (void*).sizeof);
            } else {
                // optimization
                if (int offset = to - d.begin)
                    memmove(d.array.ptr + d.begin - 1, d.array.ptr + d.begin, offset * (void*).sizeof);
                if (int offset = d.end - (from + 1))
                    memmove(d.array.ptr + from, d.array.ptr + from + 1, offset * (void*).sizeof);
                --d.begin;
                --d.end;
                --to;
            }
        }
        d.array.ptr[to] = t;
    }

    void **erase(void **xi)
    {
//        Q_ASSERT(d.ref_ == 1);
        int i = cast(int)(xi - (d.array.ptr + d.begin));
        remove(i);
        return d.array.ptr + d.begin + i;
    }

    int size() const { return d.end - d.begin; }
    bool isEmpty() const { return d.end  == d.begin; }
    const (void*)* at(int i) const { return d.array.ptr + d.begin + i; }
    const (void*)* begin() const { return d.array.ptr + d.begin; }
    const (void*)* end() const { return d.array.ptr + d.end; }
}

import std.stdio;
import std.conv;

alias void Dummy; // DMD bug #3538

struct QList(T, alias Default = Dummy)
{
    alias T ElementType;

    static if (is(Default == Dummy))
        alias QTypeInfo!T TI;
    else
        alias Default TI;

    struct Node
    {
        void *v;

        static if (isQObjectType!T || isObjectType!T || isValueType!T || is(T == string)) // binded Qt types
        {
            T t()
            {
                static if(is(T == string))
                {
                    void* ptr = cast(void*)(TI.isLarge || TI.isStatic ? v : &this);
                    return QStringUtil.toNativeString(ptr);
                }
                else static if (isValueType!T)
                {
                    void* ptr = cast(void*)(isLarge!T() || isStatic!T() ? v : &this);
                    return new T(ptr, QtdObjectInitFlags.nativeOwnership);
                }
                else
                {
                    return T.__getObject( *cast(void**)(&this) );
                }
            }
        }
        else // native types
        {
            ref T t()
            {
                static if(TI.isLarge || TI.isStatic)
                    return *cast(T*)(this.v);
                else
                    return *cast(T*)(&this);
            }
        }
    }

    union {
        QListData p;
        QListData.Data* d;
    }

public:
    /*
    void output()
    {
        writeln("QList atomic ", d.ref_.load());
    }
    */

    static QList!T opCall()
    {
        QList!T res;
//        writeln("QList opCall");

        res.d = &QListData.shared_null;
        res.d.ref_.increment();

        return res;
    }

    this(this)
    {
//        writeln("QList postblit");
        d.ref_.increment();
        if (!d.sharable)
            detach_helper();
    }

    ~this()
    {
//        writeln("QList ~this");
        if (d && !d.ref_.decrement())
            free(d);
    }

    ref QList!T opAssign(const ref QList!T l)
    {
//        writeln("QList opAssign");
        if (d != l.d) {
            QListData.Data* nd = cast(QListData.Data*)l.d;
            nd.ref_.increment();
            if (!d.ref_.decrement())
                free(d);
            d = nd;
            if (!d.sharable)
                detach_helper();
        }
        return this;
    }

    int length() const { return p.size(); }
    int size() const { return length; }

    void detach() { if (d.ref_.load() != 1) detach_helper(); }

    private void detach_helper()
    {
        Node *n = cast(Node*)(p.begin());
        QListData.Data* x = p.detach2();
        node_copy(cast(Node*)(p.begin()), cast(Node*)(p.end()), n);
        if (!x.ref_.decrement())
            free(x);
    }

    void append(const T t) // fix to const ref for complex types TODO
    {
        detach();
        static if (isQObjectType!T || isObjectType!T || isValueType!T)
        {
            node_construct(cast(Node*)(p.append()), t);
        }
        else
        {
            const T cpy = t;
            node_construct(cast(Node*)(p.append()), cpy);
        }
    }

    alias append opCatAssign;

    static if (isQObjectType!T || isObjectType!T || isValueType!T || is(T == string))
    {
        T at(int i) const
        {
            assert(i >= 0 && i < p.size(), "QList!T.at(): index out of range");
            return (cast(Node*)(p.at(i))).t();
        }
        T opIndex(int i)
        {
            assert(i >= 0 && i < p.size(), "QList!T.at(): index out of range");
            return (cast(Node*)(p.at(i))).t();
        }
    }
    else
    {
        const (T) at(int i) const // DMD BUG
        {
            assert(i >= 0 && i < p.size(), "QList!T.at(): index out of range");
            return (cast(Node*)(p.at(i))).t();
        }
        ref T opIndex(int i)
        {
            assert(i >= 0 && i < p.size(), "QList!T.at(): index out of range");
            return (cast(Node*)(p.at(i))).t();
        }
    }

    static if (isQObjectType!T || isObjectType!T || isValueType!T) //binded types
        void node_construct(Node *n, const T t)
        {
            static if (isValueType!T)
                {
                    if (isLarge!T() || isStatic!T()) // TODO should be static if
                        n.v = T.__constructNativeCopy(t.qtdNativeId); // n.v = new T(t);
                    else if (isComplex!T())
                        T.__constructPlacedNativeCopy(t.qtdNativeId, n); //  new (n) T(t);
                    else
                        T.__constructPlacedNativeCopy(t.qtdNativeId, n); // TODO should be *cast(T*)(n) = cast(T)(t); as it is a primitive type. fix when they are implemented with structs
                }
            else // in case of QObject or Object Qt types we place a pointer to a native object in the node
                n = cast(Node*) t.qtdNativeId;
        }
    else static if (is(T == string))
    {
        void node_construct(Node *n, T t)
        {
            QString.__constructPlacedQString(n, t);
        }
    }
    else // native types
        void node_construct(Node *n, const ref T t)
        {
            static if (TI.isLarge || TI.isStatic)
                n.v = q_new!T(t); // n.v = new T(t);
            else static if (TI.isComplex)
                q_new_at(n, t); // new (n) T(t);
            else
                *cast(T*)(n) = cast(T)(t);
        }

    void node_copy(Node *from, Node *to, Node *src)
    {
//        writeln("QList node_copy");
        static if (isQObjectType!T || isObjectType!T)
            {} // ensure to do nothing. copying only a pointer
        else static if(is(T == string))
        {
            while(from != to) // TODO when porting to Qt 5 ensure that QTypeInfo<QString>.isLarge and .isStatic == false
                QString.__constructPlacedNativeCopy(src++, from++); // new (from++) T(*reinterpret_cast<T*>(src++));
        }
        else static if (isValueType!T)
        {
            if (TI.isLarge || TI.isStatic) // TODO should be static if
                while(from != to)
                    (from++).v = T.__constructNativeCopy((src++).v); // (from++)->v = new T(*reinterpret_cast<T*>((src++)->v));
            else if (TI.isComplex)
                while(from != to)
                    T.__constructPlacedNativeCopy(src++, from++); // new (from++) T(*reinterpret_cast<T*>(src++));
        }
        else static if (TI.isLarge || TI.isStatic)
            while(from != to)
                (from++).v = q_new!T(*cast(T*)((src++).v));
        else static if (TI.isComplex)
            while(from != to)
                q_new_at(from++, *cast(T*)(src++));
    }

    T[] toArray()
    {
        T[] res;
        res.length = this.length;
        for(int i = 0; i < res.length; ++i)
        {
            static if (isValueType!T)
                res[i] = new T(T.__constructNativeCopy(this.at(i).qtdNativeId)); // Node should probably provide a ptr method to directly extract pointer to the native value stored in the list to avoid creating a dummy D object in t()
            else
                res[i] = this.opIndex(i);
        }
        return res;
    }

    void free(QListData.Data* data)
    {
//        writeln("QList data destroyed");
        node_destruct(cast(Node*)(data.array.ptr + data.begin),
                      cast(Node*)(data.array.ptr + data.end));
        if (data.ref_.load() == 0)
            qFree(data);
    }

    void node_destruct(Node *from, Node *to)
    {
        static if (isQObjectType!T || isObjectType!T) //binded types
            {} // removing just pointers, do nothing
        else static if (is(T == string))
        {
            while (from != to)
                --to, QString.__callNativeDestructor(to);
        }
        else static if (isValueType!T) //binded value types
        {
            if (isLarge!T() || isStatic!T()) // TODO should be static if
                while (from != to)
                    --to, T.__deleteNativeObject(to.v);
            else if (isComplex!T())
                while (from != to)
                    --to, T.__callNativeDestructor(to);
        }
        else
        {
            static if (TI.isLarge || TI.isStatic)
                while (from != to) --to, q_delete(cast(T*)(to.v));
            else static if (TI.isComplex)
                while (from != to) --to, cast(T*)(to).__dtor();
        }
    }

    //iteration support
    int opApply(int delegate(ref T) dg)
    {
        int result = 0;
        int sz = this.length;
        for (int i = 0; i < sz; i++)
        {
            static if (isQtReference!T)
            {
                T t = this[i]; // hack to avoid "is not an lvalue" error, since dg accepts ref T
                result = dg(t);
            }
            else
                result = dg(this[i]);

            if (result)
                break;
        }
        return result;
    }
}

alias QList!string QStringList;

QList!T toQList(T)(T[] src)
{
    auto res = QList!T.opCall();
    foreach(elem; src)
        res.append(elem);
    return res;
}

QList!T qList(T)()
{
    return QList!T.opCall();
}

extern(C) void qtd_create_QList(void *nativeId);
extern(C) void qtd_create_QList_double(void *nativeId);

extern(C) void qtd_create_QList_QObject(void *nativeId);
