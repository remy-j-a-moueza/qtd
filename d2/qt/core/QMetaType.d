module qt.core.QMetaType;
public import qt.core.Qt;
private import qt.core.QDataStream;

version (Tango)
{
    import tango.core.Array;
    import tango.stdc.stringz;
    import tango.core.Traits;
}

alias extern(C) void *function(void *copy) Ctor;
alias extern(C) void function(void *obj) Dtor;
alias extern(C) void function(void *stream, void * object) StreamOp;

struct DArrayToC
{
    void[] array;
}

public template MetaTypeOps(T)
{
   // TODO:
   // static assert(typeof(new T), "Type " ~ T.stringof ~ " has no default constructor");
   // static assert(typeof(new T(T.init))), "Type " ~ T.stringof ~ " has no default copy constructor");

    extern(C) void* ctor(void* copy)
    {
	static if (is(T == class) || is(T == interface))
	{
	    return cast(void*)(copy ? new T(cast(T)copy) : new T);
	}
	else static if (isDynamicArrayType!(T) || isStaticArrayType!(T) )
	{
	    auto darray = new DArrayToC;
	    if(copy)
		darray.array = (cast(DArrayToC*)copy).array.dup;
	    return cast(void*)darray;
	}
	else
	{
	    auto data = new T;
	    if(copy)
		*data = *cast(T*)copy;
	    return cast(void*)data;
	}
    }
    

    extern(C) void dtor(void* obj)
    {
        static if (is(T == class) || is(T == interface))
	{
	    auto tmp = cast(T)obj;
            delete tmp;
	}
	else
	{
	    auto tmp = cast(T*)obj;
            delete tmp;
	}
    }
}

public int qRegisterMetaType(T)(string name = null)
{
    if (!name.length)
	name = typeid(T).toString; 

    return qtd_registerType(toStringz(name), &MetaTypeOps!(T).ctor, &MetaTypeOps!(T).dtor);
}

/* Not work....
private class DataStreamPriv: QDataStream
{
    this(void * cobj)
    {
	super(cobj);
    }
}
*/
/*
public void qRegisterMetaTypeStreamOperators(T)(void function(ref QDataStream, T ) saveOp, void function (ref QDataStream, ref T) loadOp, string name = null)
{
    static void function(ref QDataStream, T ) SaveOp;
    static void function (ref QDataStream, ref T)  LoadOp;
    SaveOp = saveOp;
    LoadOp = loadOp;
    
    if (!name.length)
	name = typeid(T).toString; 
    
    extern(C) void saveOpC(void *stream, void *object)
    {
	QDataStream dstream = new DataStreamPriv(stream);
	Stdout(object).newline;
	static if (is(T == class) || is(T == interface))
	    SaveOp(dstream, cast(T)object);	
	else 
	    SaveOp(dstream, *cast(T*)object);
    }
    
    extern(C) void loadOpC(void *stream, void *object)
    {
	//return stream;
    }

    qtd_registerStreamOperators(toStringz(name), cast(StreamOp)&saveOpC, cast(StreamOp)&loadOpC);
}
*/
private extern(C) void qtd_registerStreamOperators(char *typeName, StreamOp saveOp, StreamOp loadOp);
private extern(C) int qtd_registerType(in char* namePtr, Ctor ctor, Dtor dtor);
extern(C) int qtd_MetatypeId(in char *id); // TODO: wrap to D.