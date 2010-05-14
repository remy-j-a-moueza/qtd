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
public import tango.core.Tuple;
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

void append(T)(ref T[] a, T element)
{
    auto newLen = a.length + 1;
    a = (cast(T*)crealloc(a.ptr, newLen * T.sizeof))[0..newLen];
    if (!a.ptr)
        new OutOfMemoryException(__FILE__, __LINE__);
    a[newLen - 1] = element;
}

void move(T)(ref T[] a, size_t src, size_t dest, size_t length)
{
    if (a.length > 1)
        memmove(a.ptr + dest, a.ptr + src, length * T.sizeof);
}

// COMPILER BUG: Though this is private cannot name it 'remove' because of conflicts
// with Array.remove
void erase(T)(ref T[] a, size_t i) 
{
    auto newLen = a.length - 1;
    move(a, i + 1, i, newLen);
    realloc(a, newLen);
}

version (QtdUnittest)
{
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
    ConnectionFlags flags;

    static if (is(Receiver == Dg))
    {
        static const isDelegate = true;
                
        bool isDisposed()
        {
            return !receiver.funcptr;
        }
        
        void dispose()
        {
            receiver.funcptr = null;
            receiver.context = null;
        }

        Object getObject()
        {           
            return flags & ConnectionFlags.NoObject || !receiver.context
                ? null : _d_toObject(receiver.context);
        }
    }
    else
        static const isDelegate = false;
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
public enum ConnectionFlags : ubyte
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
        static if (!strong)
            cfree(data.ptr);
    }
}

public alias void delegate(int signalId, SignalEventId event) SignalEvent;

struct Receivers
{
    struct Data
    {
        Object object;
        int refs;
    }
    
    Data[] data;
    void add(Object receiver, DEvent disposeEvent)
    {        
        foreach (ref d; data)
        {
            if (d.object is receiver)
            {               
                d.refs++;              
                return;
            }
        }
        
        append(data, Data(receiver, 1));
        rt_attachDisposeEvent(receiver, disposeEvent);
    }
    
    void remove(Object receiver, DEvent disposeEvent)
    {
        foreach (i, ref d; data)
        {
            if (d.object is receiver)
            {
                assert (d.refs);
                d.refs--;
                if (!d.refs)
                {
                    .erase(data, i);                    
                    rt_detachDisposeEvent(receiver, disposeEvent);
                }
                return;
            }
        }
        
        assert (false);
    }
    
    // remove all refarences for receiver, receiver has been disposed
    void removeAll(Object receiver)
    {
        foreach (i, ref d; data)
        {
            if (d.object is receiver) 
            {
                .erase(data, i);
                return;
            }
        }
    }
    
    // remove all references for all receivers, detaching dispose events
    void free(DEvent disposeEvent)
    {
        foreach (i, ref d; data)
            rt_detachDisposeEvent(d.object, disposeEvent);
        cfree(data.ptr);
        data = null;
    }
}

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
    
    void onReceiverDisposed(Object receiver)
    {
        foreach (i, e; slotLists.tupleof)
        {
            static if (slotLists.at!(i).SlotType.isDelegate)
            {
                foreach (ref slot; slotLists.at!(i).data)
                {
                    if (slot.getObject is receiver)
                        slot.dispose;
                }
            }
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

public final class SignalHandler
{
    SignalConnections[] connections;
    Receivers receivers;
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
        Dg invoker, ConnectionFlags flags)
    {
        if (signalId >= connections.length)
            connections.length = signalId + 1;
        auto slot = connections[signalId].addSlot!(slotListId)(SlotType!(slotListId)(receiver, invoker, flags));
        
        static if (slot.isDelegate)
        {
            if (!(flags & ConnectionFlags.NoObject))
                receivers.add(_d_toObject(receiver.context), &onReceiverDisposed);
        }

        if (signalEvent && connections[signalId].slotCount == 1)
            signalEvent(signalId, SignalEventId.firstSlotConnected);
       
        return slot;
    }
    
    void onReceiverDisposed(Object receiver)
    {
        synchronized(this)
        {
            foreach(ref c; connections)
                c.onReceiverDisposed(receiver);
            receivers.removeAll(receiver);
        }
    }
    
    private void removeSlot(int slotListId)(int signalId, int slotId)
    {
        auto slot = connections[signalId].getSlotList!(slotListId).get(slotId);
        static if (slot.isDelegate)
        {
            if (auto obj = slot.getObject)
                receivers.remove(obj, &onReceiverDisposed);
        }
        
        connections[signalId].removeSlot!(slotListId)(slotId);

        if (signalEvent && !connections[signalId].slotCount)
            signalEvent(signalId, SignalEventId.lastSlotDisconnected);
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

    void connect(Receiver)(int signalId, Receiver receiver,
        Dg invoker, ConnectionFlags flags)
    {
        synchronized(this)
        {
            static if (is(typeof(receiver.context)))
            {
                Object obj;
                if ((flags & ConnectionFlags.NoObject))
                {
                    // strong by default
                    if (flags & ConnectionFlags.Weak)
                        addSlot!(SlotListId.Weak)(signalId, receiver, invoker, flags);
                    else
                        addSlot!(SlotListId.Strong)(signalId, receiver, invoker, flags);
                }
                else
                {
                    // weak by default
                    if (flags & ConnectionFlags.Strong)
                        addSlot!(SlotListId.Strong)(signalId, receiver, invoker, flags);
                    else
                        addSlot!(SlotListId.Weak)(signalId, receiver, invoker, flags);
                }
            }
            else
            {
                flags |= ConnectionFlags.NoObject;
                addSlot!(SlotListId.Func)(signalId, receiver, invoker, flags);
            }
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
        receivers.free(&onReceiverDisposed);
        foreach(ref c; connections)
            c.free;
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
    
    template connect(string signalName, A...)
    {
        static void connect(T, Func)(T sender, Func func, ConnectionFlags flags = ConnectionFlags.None)
        {
            static if (isFnOrDg!(Func)) // D1 has no constraints
        {
            alias findSignal!(T, signalName, Func, A).result sig;
            auto sh = sender.signalHandler();
            static if (isFn!(Func))
                alias Fn Callable;
            else
                alias Dg Callable;
            auto invoker = Dg(&sh.invokeSlot!(typeof(func), Callable, sig[2..$]));
            sh.connect(sig[1], Callable(func), invoker, flags);
        }
        else
        {
            static assert(false, "The slot must be a function or delegate type.");
        }
        }
    }

    template disconnect(string signalName, A...)
    {
        static void connect(T, Func)(T sender, Func func, ConnectionFlags flags = ConnectionFlags.None)
        {
            static if (isFnOrDg!(Func)) // D1 has no constraints
        {
            alias findSignal!(T, signalName, Func, A).result sig;
            auto sh = sender.signalHandler();
            static if (isFn!(Func))
                alias Fn Callable;
            else
                alias Dg Callable;
            sh.disconnect(sig[1], Callable(func));
        }
        else
        {
            static assert(false, "The slot must be a function or delegate type.");
        }
        }
    }
/*
    template slotCount(string signalName, A...)
    {
        debug static void slotCount(T)(T sender)
        {
            alias findSignal!(T, signalName, Func, A).result sig;
            auto sh = sender.signalHandler();
            return sh.slotCount(sig[1]);
        }
    }
    */
}

/**
    New implementation.
*/

const string signalPrefix = "__signal";

template TupleWrapper(A...) { alias A at; }

template isDg(Dg)
{
    enum { isDg = is(Dg == delegate) }
}

template isFn(Fn)
{
    enum { isFn = is(typeof(*Fn.init) == function) }
}

template isFnOrDg(Dg)
{
    enum { isFnOrDg = isFn!(Dg) || isDg!(Dg) }
}

string joinArgs(A...)()
{
    string res = "";
    static if(A.length)
    {
        res = A[0].stringof;
        foreach(k; A[1..$])
            res ~= "," ~ k.stringof;
    }
    return res;
}

template SlotPred(T1, T2)
{
    enum { SlotPred = is(T1 : T2) }
}

template CheckSlot(alias Needle, alias Source)
{
    static if(Needle.at.length <= Source.at.length)
        enum { CheckSlot = CheckArgs!(Needle, Source, SlotPred, 0).value }
    else
        enum { CheckSlot = false }
}

template SignalPred(T1, T2)
{
    enum { SignalPred = is(T1 == T2) }
}

template CheckSignal(alias Needle, alias Source)
{
    static if(Needle.at.length == Source.at.length)
        enum { CheckSignal = CheckArgs!(Needle, Source, SignalPred, 0).value }
    else
        enum { CheckSignal = false }
}

template CheckArgs(alias Needle, alias Source, alias pred, int i)
{
    static if (i < Needle.at.length)
    {
        static if (pred!(Needle.at[i], Source.at[i]))
            enum { value = CheckArgs!(Needle, Source, pred, i + 1).value }
        else
            enum { value = false }
    }
    else
    {
        enum { value = true }
    }
}

template SigByNamePred(string name, SlotArgs...)
{
    template SigByNamePred(source...)
    {
        static if (source[0] == name) // only instantiate CheckSlot if names match
            enum { SigByNamePred = CheckSlot!(TupleWrapper!(SlotArgs), TupleWrapper!(source[2 .. $])) }
        else
            enum { SigByNamePred = false }
    }
}

template SigBySignPred(string name, SigArgs...)
{
    template SigBySignPred(source...)
    {
        static if (source[0] == name) // only instantiate CheckSignal if names match
            enum { SigBySignPred = CheckSignal!(TupleWrapper!(SigArgs), TupleWrapper!(source[2 .. $])) }
        else
            enum { SigBySignPred = false }
    }
}

template staticSymbolName(string prefix, int id)
{
    const string staticSymbolName = prefix ~ ToString!(id);
}

template signatureString(string name, A...)
{
    const string signatureString = name ~ "(" ~ joinArgs!(A) ~ ")";
}

template findSymbolImpl(string prefix, C, int id, alias pred)
{
    static if ( is(typeof(mixin("C." ~ staticSymbolName!(prefix, id)))) )
    {
        mixin ("alias C." ~ staticSymbolName!(prefix, id) ~ " current;");
        static if (pred!(current))
            alias current result;
        else
            alias findSymbolImpl!(prefix, C, id + 1, pred).result result;
    }
    else
    {
        alias void result;
    }
}

template findSymbol(string prefix, C, alias pred)
{
    alias findSymbolImpl!(prefix, C, 0, pred).result findSymbol;
}

template findSignal(C, string name, Receiver, SigArgs...)
{
    alias TupleWrapper!(ParameterTupleOf!(Receiver)) SlotArgsWr;
    static if (SigArgs.length > 0)
    {
        alias findSymbol!(signalPrefix, C, SigBySignPred!(name, SigArgs)) result;
        static if (is(result == void))
            static assert(0, "Signal " ~ name ~ "(" ~ joinArgs!(SigArgs)() ~ ") was not found.");
        else
            static if (!CheckSlot!(SlotArgsWr, TupleWrapper!(result[2 .. $])))
                static assert(0, "Signature of slot is incompatible with signal " ~ name ~ ".");
    }
    else
    {
        alias findSymbol!(signalPrefix, C, SigByNamePred!(name, SlotArgsWr.at)) result;
        static if (is(result == void))
            static assert(0, "Signal " ~ name ~ " was not found.");
    }
}


public string SignalEmitter(A...)(SignalType signalType, string name, int index)
{
    string fullArgs, args;
    static if (A.length)
    {
        fullArgs = A[0].stringof ~ " a0";
        args = ", a0";
        foreach(i, _; A[1..$])
        {
            fullArgs ~= ", " ~ A[i+1].stringof ~ " a" ~ __toString(i+1);
            args ~= ", a" ~ __toString(i+1);
        }
    }
    string attribute;
    string sigName = name;
    if (signalType == SignalType.BindQtSignal)
        name ~= "_emit";
    else
        attribute = "protected ";
    string str = attribute ~ "void " ~ name ~ "(" ~ fullArgs ~ ")" ~
                 "{ this.signalHandler.emit(" ~ __toString(index) ~ args ~ "); }";
    return str;
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

enum SignalType
{
    BindQtSignal,
    NewSignal
}

template BindQtSignal(string name, A...)
{
    mixin SignalImpl!(0, name, SignalType.BindQtSignal, A);
}

template Signal(string name, A...)
{
    mixin SignalImpl!(0, name, SignalType.NewSignal, A);
}

template SignalImpl(int index, string name, SignalType signalType, A...)
{
    static if (is(typeof(mixin(typeof(this).stringof ~ ".__signal" ~ ToString!(index)))))
        mixin SignalImpl!(index + 1, name, signalType, A);
    else
    {
        // mixed-in once
        static if (!is(typeof(this.signalHandler)))
            mixin SignalHandlerOps;

        mixin (SignalEmitter!(A)(signalType, name, index));
        mixin("public alias Tuple!(\"" ~ name ~ "\", index, A) __signal" ~ ToString!(index) ~ ";");
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