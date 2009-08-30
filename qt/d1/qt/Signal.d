/**
 *
 *  Copyright: Copyright QtD Team, 2008-2009
 *  Authors: Max Samukha, Eldar Insafutdinov
 *  License: <a href="http://www.boost.org/LICENSE_1_0.txt>Boost License 1.0</a>
 *
 *  Copyright QtD Team, 2008-2009
 *  Distributed under the Boost Software License, Version 1.0.
 *  (See accompanying file boost-license-1.0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
 *
 */
module qt.Signal;

public import qt.QGlobal;
import tango.core.Exception;
import tango.core.Traits;
import tango.core.Thread;
import tango.stdc.stdlib : crealloc = realloc, cfree = free;
import tango.stdc.string : memmove;

private: // private by default

alias void delegate(Object) DEvent;

extern(C) void rt_attachDisposeEvent(Object o, DEvent e);
extern(C) void rt_detachDisposeEvent(Object o, DEvent e);
extern(C) Object _d_toObject(void* p);

void realloc(T)(ref T[] a, size_t length)
{
    a = (cast(T*)crealloc(a.ptr, length * T.sizeof))[0..length];
    if (!a.ptr)
        new OutOfMemoryException(__FILE__, __LINE__);
}

unittest
{
    int[] a;
    realloc(a, 16);
    assert(a.length == 16);
    foreach (i, ref e; a)
        e = i;
    realloc(a, 4096);
    assert(a.length == 4096);
    foreach (i, e; a[0..16])
        assert(e == i);
    cfree(a.ptr);
}

// TODO: This one should be replaced with an appropriate library function
char[] __toString(long v)
{
    if (v == 0)
        return "0";

    char[] ret;

    bool neg;
    if (v < 0)
    {
        neg = true;
        v = -v;
    }

    while (v != 0)
    {
        ret = cast(char)(v % 10 + '0') ~ ret;
        v = cast(long)(v / 10);
    }

    if (neg)
        ret = "-" ~ ret;

    return ret;
}

template ToString(long i)
{
    const string ToString = __toString(i);
}

//TODO: should be in the standard library
struct STuple(A...)
{
    static string genSTuple()
    {
        string r = "";
        foreach (i, e; A)
            r ~= A[i].stringof ~ " _" ~ ToString!(i) ~ ";";
        return r;
    }

    mixin (genSTuple);
    template at(size_t i) { mixin("alias _" ~ ToString!(i) ~ " at;"); };
}

void move(T)(ref T[] a, size_t src, size_t dest, size_t length)
{
    if (a.length > 1)
        memmove(a.ptr + dest, a.ptr + src, length * T.sizeof);
}

enum SignalEventId
{
    firstSlotConnected,
    lastSlotDisconnected
}

public class SignalException : Exception
{
    this(char[] msg)
    {
        super(msg);
    }
}

struct Fn
{
    void* funcptr;

    static typeof(*this) opCall(R, A...)(R function(A) fn)
    {
        typeof(*this) r;
        r.funcptr = fn;
        return r;
    }

    template call(R)
    {
        R call(A...)(A args)
        {
            alias R function(A) Fn;
            return (cast(Fn)funcptr)(args);
        }
    }

    S get(S)()
    {
        static assert (is(typeof(*S.init) == function));
        return cast(S)funcptr;
    }
}

struct Dg
{
    void* context;
    void* funcptr;

    static typeof(*this) opCall(R, A...)(R delegate(A) dg)
    {
        typeof(*this) r;
        r.context = dg.ptr;
        r.funcptr = dg.funcptr;
        return r;
    }

    template call(R)
    {
        R call(A...)(A args)
        {
            R delegate(A) dg; // BUG: parameter storage classes are ignored
            dg.ptr = context;
            dg.funcptr = cast(typeof(dg.funcptr))funcptr;
            return dg(args);
        }
    }

    S get(S)()
    {
        static assert (is(S == delegate));
        S r;
        r.ptr = context;
        r.funcptr = cast(typeof(r.funcptr))funcptr;
        return r;
    }
}

struct Slot(R)
{
    alias R Receiver;

    Receiver receiver;
    Dg invoker;

    static if (is(Receiver == Dg))
    {
        static const isDelegate = true;

        void onReceiverDisposed(Object o)
        {
            assert (lock !is null);
            synchronized(lock)
            {
                receiver.context = null;
                receiver.funcptr = null;
            }
        }

        // null if receiver doesn't point to a disposable object
        Object lock;

        bool isDisposed()
        {
            return !receiver.funcptr;
        }

        Object getObject()
        {
            return lock ? _d_toObject(receiver.context) : null;
        }
    }
    else
        static const isDelegate = false;

    static typeof(*this) opCall(Receiver r, Dg c)
    {
        typeof(*this) ret;
        ret.receiver = r;
        ret.invoker = c;
        return ret;
    }
}

enum SlotListId
{
    Func, // function pointers
    Weak, // object delegates stored in C heap
    Strong // delegates stored in GC heap
}

/**
    Used to specify the type of a signal-to-slot connection.

    Examples:
----
class Sender
{
    mixin Signal!("changed");
    void change()
    {
        changed.emit;
    }
}


class Receiver
{
    void alarm() {}
}

void main()
{
    auto s = new Sender;
    auto r = new Receiver;
    s.changed.connect(&r.alarm); // now s weakly references r

    r = null;
    // collect garbage (assume there is no more reachable pointers
    // to the receiver and it gets finalized)
    ...

    s.change;
    // weak reference to the receiving object
    // has been removed from the sender's connection lists.

    r = new Receiver;
    s.changed.connect(&r.alarm, ConnectionFlags.Strong);

    r = null;
    // collect garbage
    ...
    // the receiving object has not been finalized because s strongly references it.

    s.change; // the receiver is called.
    delete r;
    s.change; // the receiver is disconnected from the sender.

    static void foo()
    {
    }

    s.changed.connect(&foo);
    s.changed.emit; // foo is called.
    s.changed.disconnect(&foo); // must be explicitly disconnected.

    void bar()
    {
    }

    // ConnectionFlags.NoObject must be specified for delegates
    // to non-static local functions or struct member functions.
    s.changed.connect(&bar, ConnectionFlags.NoObject);
    s.changed.emit; // bar is called.
    s.changed.disconnect(&bar); // must be explicitly disconnected.
}
----
*/
public enum ConnectionFlags
{
    ///
    None,
    /**
        The receiver will be stored as weak reference (implied if ConnectionFlags.NoObject is not specified).
        If the signal receiver is not a function pointer or a delegate referencing a D class instance.
        the sender will not be notified when the receiving object is deleted and emitting the signal
        connected to that receiving object will result in undefined behavior.
    */
    Weak                = 0x0001,
    /**
        The receiver is stored as strong reference (implied if ConnectionFlags.NoObject is specified).
    */
    Strong              = 0x0002,
    /**
        Must be specified if the receiver is not a function pointer or a delegate referencing a D class instance.
    */
    NoObject            = 0x0004

    // Queued           = 0x0004,
    // BlockingQueued   = 0x0008
}


struct SlotList(SlotT, bool strong = false)
{
    alias SlotT SlotType;
    SlotType[] data;

    void length(size_t length)
    {
        static if (strong)
            data.length = length;
        else
            realloc(data, length);
    }

    SlotType* add(SlotType slot)
    {
        auto oldLen = data.length;
        length = oldLen + 1;
        auto p = &data[oldLen];
        *p = slot;
        return p;
    }

    SlotType* get(int slotId)
    {
        return &data[slotId];
    }

    void remove(int slotId)
    {
        move(data, slotId, slotId + 1, data.length - slotId - 1);
        data = data[0..$ - 1];
    }

    size_t length()
    {
        return data.length;
    }

    void free()
    {
        static if (SlotType.isDelegate)
        {
            foreach (ref slot; data)
            {
                if (auto obj = slot.getObject)
                    rt_detachDisposeEvent(obj, &slot.onReceiverDisposed);
            }
        }
        static if (!strong)
            cfree(data.ptr);
    }
}

public alias void delegate(int signalId, SignalEventId event) SignalEvent;

struct SignalConnections
{
    bool isInUse;

    STuple!(
        SlotList!(Slot!(Fn)),
        SlotList!(Slot!(Dg)),
        SlotList!(Slot!(Dg), true)
    ) slotLists;

    STuple!(
        Fn[],
        Dg[]
    ) delayedDisconnects;

    void addDelayedDisconnect(Fn r)
    {
        delayedDisconnects.at!(0) ~= r;
    }

    void addDelayedDisconnect(Dg r)
    {
        delayedDisconnects.at!(1) ~= r;
    }

    SlotListType!(slotListId)* getSlotList(int slotListId)()
    {
        return &slotLists.tupleof[slotListId];
    }

    bool hasSlots()
    {
        foreach(i, e; slotLists.tupleof)
        {
            if (slotLists.tupleof[i].length)
                return true;
        }
        return false;
    }

    int slotCount()
    {
        int count;
        foreach(i, e; slotLists.tupleof)
            count += slotLists.at!(i).length;
        return count;
    }

    void slotListLengths(int[] lengths)
    {
        foreach(i, e; slotLists.tupleof)
             lengths[i] = slotLists.at!(i).length;
    }

    SlotType!(slotListId)* addSlot(int slotListId)(SlotType!(slotListId) slot)
    {
        return getSlotList!(slotListId).add(slot);
    }

    void removeSlot(int slotListId)(int slotId)
    {
        slotLists.at!(slotListId).remove(slotId);
    }

    void free()
    {
        foreach(i, e; slotLists.tupleof)
        {
            static if (is(typeof(slotLists.at!(i).free)))
                slotLists.at!(i).free;
        }
    }

    template SlotListType(int slotListId)
    {
        alias typeof(slotLists.tupleof)[slotListId] SlotListType;
    }

    template SlotType(int slotListId)
    {
        alias SlotListType!(slotListId).SlotType SlotType;
    }

    template ReceiverType(int slotListId)
    {
        alias SlotType!(slotListId).Receiver ReceiverType;
    }

    static const slotListCount = slotLists.tupleof.length;
}


private ThreadLocal!(Object) signalSender_;
static this()
{
    signalSender_ = new ThreadLocal!(Object);
}

/**
    If called from a slot, returns the object
    that is emitting the signal. Otherwise, returns null.
*/
public Object signalSender() {
    return signalSender_.val;
}

public class SignalHandler
{
    SignalConnections[] connections;
    Object owner;
    int blocked;
    
    SignalEvent signalEvent;
   
    alias SignalConnections.SlotType SlotType;
    alias SignalConnections.ReceiverType ReceiverType;

    public this(Object owner_) {
        owner = owner_;
    }

    private SignalConnections* getConnections(int signalId)
    {
        if (signalId < connections.length)
            return &connections[signalId];
        return null;
    }

    private SlotType!(slotListId)* addSlot(int slotListId)(int signalId, ReceiverType!(slotListId) receiver,
        Dg invoker)
    {
        if (signalId >= connections.length)
            connections.length = signalId + 1;
        auto slot = connections[signalId].addSlot!(slotListId)(SlotType!(slotListId)(receiver, invoker));

        if (signalEvent && connections[signalId].slotCount == 1)
            signalEvent(signalId, SignalEventId.firstSlotConnected);

        return slot;
    }

    private void removeSlot(int slotListId)(int signalId, int slotId)
    {
        connections[signalId].removeSlot!(slotListId)(slotId);

        if (signalEvent && !connections[signalId].slotCount)
            signalEvent(signalId, SignalEventId.lastSlotDisconnected);
    }

    private SlotType!(slotListId)* addObjectSlot(int slotListId)(size_t signalId, Object obj, Dg receiver,
        Dg invoker)
    {
        auto slot = addSlot!(slotListId)(signalId, receiver, invoker);
        slot.lock = this;
        rt_attachDisposeEvent(obj, &slot.onReceiverDisposed);
        return slot;
    }

    size_t slotCount(int signalId)
    {
        synchronized(this)
        {
            auto con = getConnections(signalId);
            if (con)
                return con.slotCount;
            return 0;
        }
    }

    void connect(Receiver)(size_t signalId, Receiver receiver,
        Dg invoker, ConnectionFlags flags)
    {
        synchronized(this)
        {
            static if (is(typeof(receiver.context)))
            {
                Object obj;
                if ((flags & ConnectionFlags.NoObject) || (obj = _d_toObject(receiver.context)) is null)
                {
                    // strong by default
                    if (flags & ConnectionFlags.Weak)
                        addSlot!(SlotListId.Weak)(signalId, receiver, invoker);
                    else
                        addSlot!(SlotListId.Strong)(signalId, receiver, invoker);
                }
                else
                {
                    // weak by default
                    if (flags & ConnectionFlags.Strong)
                        addObjectSlot!(SlotListId.Strong)(signalId, obj, receiver, invoker);
                    else
                        addObjectSlot!(SlotListId.Weak)(signalId, obj, receiver, invoker);
                }
            }
            else
                addSlot!(SlotListId.Func)(signalId, receiver, invoker);
        }
    }

    void disconnect(Receiver)(int signalId, Receiver receiver)
    {
        synchronized(this)
        {
            auto cons = getConnections(signalId);
            if (!cons)
                return;

            // if called from a slot being executed by this signal, delay disconnection
            // until all slots has been called.
            if (cons.isInUse)
            {
                cons.addDelayedDisconnect(receiver);
                return;
            }

        TOP:
            foreach (slotListId, e; cons.slotLists.tupleof)
            {
                /// COMPILER BUG: ReceiverType is evaluated to expression instead of type.
                static if (is(typeof(cons.ReceiverType!(slotListId)) == Receiver))
                {
                    auto slotList = cons.getSlotList!(slotListId);
                    for (int slotId; slotId < slotList.length;)
                    {
                        auto slot = slotList.get(slotId);
                        static if (slot.isDelegate)
                        {
                            if (slot.isDisposed)
                            {
                                removeSlot!(slotListId)(signalId, slotId);
                                continue;
                            }
                        }

                        if (slot.receiver == receiver)
                        {
                            static if (slot.isDelegate)
                            {
                                if (auto obj = slot.getObject)
                                    rt_detachDisposeEvent(obj, &slot.onReceiverDisposed);
                            }
                            removeSlot!(slotListId)(signalId, slotId);
                            break TOP;
                        }

                        slotId++;
                    }
                }
            }
        }
    }

    void emit(A...)(size_t signalId, A args)
    {
        synchronized(this)
        {
            if (signalId >= connections.length || blocked)
                return;
            auto cons = &connections[signalId];

            if (cons.hasSlots)
            {
                {
                    cons.isInUse = true;
                    signalSender_.val = owner;
                    scope(exit)
                    {
                        cons.isInUse = false;
                        signalSender_.val = null;
                    }

                    // Store the lengths to avoid calling new slots
                    // connected in the slots being called.
                    // dmd bug: int[cons.slotListCount] fails
                    static const c = cons.slotListCount;
                    int[c] lengths = void;
                    cons.slotListLengths(lengths);

                    foreach (slotListId, e; cons.slotLists.tupleof)
                    {
                        auto slotList = cons.getSlotList!(slotListId);
                        for (size_t slotId; slotId < lengths[slotListId];)
                        {
                            auto slot = slotList.get(slotId);
                            static if (slot.isDelegate)
                            {
                                if (slot.isDisposed)
                                {
                                    removeSlot!(slotListId)(signalId, slotId);
                                    lengths[slotListId]--;
                                    continue;
                                }
                            }

                            slot.invoker.call!(void)(slot.receiver, args);
                            ++slotId;
                        }
                    }
                }


                // process delayed disconnects if any
                foreach(i, e; cons.delayedDisconnects.tupleof)
                {
                    if (cons.delayedDisconnects.at!(i).length)
                    {
                        foreach (d; cons.delayedDisconnects.at!(i))
                            disconnect(signalId, d);
                        cons.delayedDisconnects.at!(i).length = 0;
                    }
                }
            }
        }
    }

    // Adjusts signal arguments and calls the slot. S - slot signature, A - signal arguments
    private void invokeSlot(S, Receiver, A...)(Receiver r, A args)
    {
        r.get!(S)()(args[0..ParameterTupleOf!(S).length]);
    }

    void blockSignals()
    {
        synchronized(this)
            blocked++;
    }

    void unblockSignals()
    {
        synchronized(this)
        {
            if(!blocked)
                throw new SignalException("Signals are not blocked");
            blocked--;
        }
    }

    ~this()
    {
        foreach(ref c; connections)
            c.free;
    }
}

//TODO: this could be avoided if named mixins didn't suck.
public struct SignalOps(int sigId, A...)
{
    private SignalHandler sh;
    enum { signalId = sigId }

    void connect(R, B...)(R function(B) fn, ConnectionFlags flags = ConnectionFlags.None)
    {
        alias CheckSlot!(typeof(fn), A) check;
        auto invoker = Dg(&sh.invokeSlot!(typeof(fn), Fn, A));
        sh.connect(signalId, Fn(fn), invoker, flags);
    }

    void connect(R, B...)(R delegate(B) dg, ConnectionFlags flags = ConnectionFlags.None)
    {
        alias CheckSlot!(typeof(dg), A) check;
        auto invoker = Dg(&sh.invokeSlot!(typeof(dg), Dg, A));
        sh.connect(signalId, Dg(dg), invoker, flags);
    }

    void disconnect(R, B...)(R function(B) fn)
    {
        sh.disconnect(signalId, Fn(fn));
    }

    void disconnect(R, B...)(R delegate(B) dg)
    {
        sh.disconnect(signalId, Dg(dg));
    }

    void emit(A args)
    {
        sh.emit(signalId, args);
    }

    debug size_t slotCount()
    {
        return sh.slotCount(signalId);
    }
}

template CheckSlot(Slot, A...)
{
    static assert(ParameterTupleOf!(Slot).length <= A.length, "Slot " ~ ParameterTypeTuple!(Slot).stringof ~
        " has more prameters than signal " ~ A.stringof);
    alias CheckSlotImpl!(Slot, 0, A) check;
}

template CheckSlotImpl(Slot, int i, A...)
{
    alias ParameterTupleOf!(Slot) SlotArgs;
    static if (i < SlotArgs.length)
    {
        static assert (is(SlotArgs[i] : A[i]), "Argument " ~ __toString(i) ~
            ":" ~ A[i].stringof ~ " of signal " ~ A.stringof ~ " is not implicitly convertible to parameter "
            ~ SlotArgs[i].stringof ~ " of slot " ~ SlotArgs.stringof);
        alias CheckSlotImpl!(Slot, i + 1, A) next;
    }
}

public template SignalHandlerOps()
{
    static assert (is(typeof(this.signalHandler)),
        "SignalHandlerOps is already instantiated in " ~ typeof(this).stringof ~ " or one of its base classes");

protected:
    SignalHandler signalHandler_; // manages signal-to-slot connections

    final SignalHandler signalHandler()
    {
        if (!signalHandler_)
        {
            signalHandler_ = new SignalHandler(this);
            onSignalHandlerCreated(signalHandler_);
        }
        return signalHandler_;
    }

    void onSignalHandlerCreated(ref SignalHandler sh)
    {
    }

public:
    final void blockSignals()
    {
        signalHandler.blockSignals();
    }

    final void unblockSignals()
    {
        signalHandler.unblockSignals();
    }
}

/**
    Examples:
----
struct Args
{
    bool cancel;
}

class C
{
    private int _x;
    // reference parameters are not supported yet,
    // so we pass arguments by pointer.
    mixin Signal!("xChanging", int, Args*);
    mixin Signal!("xChanged");

    void x(int v)
    {
        if (v != _x)
        {
            Args args;
            xChanging.emit(v, &args);
            if (!args.cancel)
            {
                _x = v;
                xChanged.emit;
            }
        }
    }
}
----
*/
template Signal(string name, A...)
{
    mixin SignalImpl!(0, name, A);
}

template SignalImpl(int index, string name, A...)
{
    static if (is(typeof(mixin(typeof(this).stringof ~ ".__sig" ~ ToString!(index)))))
        mixin SignalImpl!(index + 1, name, A);
    else
    {
        // mixed-in once
        static if (!is(typeof(this.signalHandler)))
        {
            mixin SignalHandlerOps;
        }
        mixin("private static const int __sig" ~ ToString!(index) ~ " = " ~ ToString!(index) ~ ";");
        mixin("SignalOps!(" ~ ToString!(index) ~ ", A) " ~ name ~ "(){ return SignalOps!("
            ~ ToString!(index) ~ ", A)(signalHandler); }");
    }
}

extern(C) alias void function(void*) SlotConnector;

debug (UnitTest)
{
    class A
    {
        mixin Signal!("scorched", int);

        int signalId1 = -1;
        int signalId2 = -1;

        void onFirstConnect(int sId)
        {
            signalId1 = sId;
        }

        void onLastDisconnect(int sId)
        {
            signalId2 = sId;
        }

        this()
        {
            signalHandler.firstSlotConnected = &onFirstConnect;
            signalHandler.lastSlotDisconnected = &onLastDisconnect;
        }
    }

    class B : A
    {
        mixin Signal!("booed", int);

        int bazSum;
        void baz(int i)
        {
            bazSum += i;
        }
    }

    class C : A
    {
        mixin Signal!("cooked");
    }
}

unittest
{
    static int fooSum;
    static int barSum;

    static void foo(int i)
    {
        fooSum += i;
    }

    void bar(long i)
    {
        barSum += i;
    }

    auto a = new A;
    auto b = new B;
    auto c = new C;
    assert(b.scorched.signalId == 0);
    assert(b.booed.signalId == 1);
    assert(c.cooked.signalId == 1);

    auto sh = b.signalHandler;

    b.scorched.connect(&foo);
    assert(sh.connections.length == 1);
    assert(b.signalId1 == 0);
    auto scCons = &sh.connections[0];

    assert(scCons.getSlotList!(SlotListId.Func).length == 1);
    b.scorched.emit(1);
    assert(fooSum == 1);

    b.scorched.connect(&bar, ConnectionFlags.NoObject);
    assert(sh.connections.length == 1);
    assert(scCons.getSlotList!(SlotListId.Strong).length == 1);
    b.scorched.emit(1);
    assert (fooSum == 2 && barSum == 1);

    b.scorched.connect(&b.baz);
    assert(scCons.getSlotList!(SlotListId.Weak).length == 1);
    b.scorched.emit(1);
    assert (fooSum == 3 && barSum == 2 && b.bazSum == 1);

    b.scorched.disconnect(&bar);
    assert(scCons.slotCount == 2);
    b.scorched.disconnect(&b.baz);
    assert(scCons.slotCount == 1);
    b.scorched.disconnect(&foo);
    assert(scCons.slotCount == 0);
    assert(b.signalId2 == 0);

    fooSum = 0;
    void connectFoo()
    {
        b.scorched.connect(&foo);
        b.scorched.disconnect(&connectFoo);
    }

    b.scorched.connect(&connectFoo, ConnectionFlags.NoObject);
    b.scorched.emit(1);
    assert(scCons.getSlotList!(SlotListId.Func).length == 1);
    assert(scCons.getSlotList!(SlotListId.Strong).length == 0);
    assert(!fooSum);

    auto r = new B();
    b.scorched.connect(&r.baz);
    assert(scCons.getSlotList!(SlotListId.Weak).length == 1);
    b.scorched.emit(1);
    assert(r.bazSum == 1);
    assert(fooSum == 1);

    delete(r);
    assert(scCons.getSlotList!(SlotListId.Weak).length == 1);
    b.scorched.emit(1);
    assert(scCons.getSlotList!(SlotListId.Weak).length == 0);
}