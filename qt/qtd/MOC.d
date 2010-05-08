module qt.qtd.MOC;

import qt.qtd.ctfe.Format;

import std.typetuple;

import qt.QGlobal;
import qt.Signal;
import qt.qtd.MetaMarshall;
import qt.qtd.Meta;

public import qt.core.QString;

public import std.traits;
/**
   Utils.
  */

bool is_digit_char(const char s)
{
    return (s >= '0' && s <= '9');
}

bool is_octal_char(const char s)
{
    return (s >= '0' && s <= '7');
}

bool is_hex_char(const char s)
{
    return ((s >= 'a' && s <= 'f')
            || (s >= 'A' && s <= 'F')
            || (s >= '0' && s <= '9')
       );
}

int lastIndexOf(T)(T[] haystack, T[] needle, int from = -1)
{
    auto l = haystack.length;
    auto ol = needle.length;
    int delta = l - ol;
    if (from < 0)
        from = delta;
    if (from < 0 || from > l)
        return -1;
    if (from > delta)
        from = delta;
    
    while(from >= 0)
    {
        if (haystack[from..from+ol] == needle)
            return from;
        from--;
    }
    return -1;
}


T[] newArray(T)(size_t len, T[] from = [])
{
    if (len == from.length)
        return from;

    if (!from.length)
        from = [T.init];

    if (from.length < len)
        return newArray!T(len, from ~ from);

    return from[0..len];
}

string replicate(int n, char value)
{
    char[] ret = "".dup;
    if (n > 0)
    {
//        ret = newArray!char(n);
        for(int i = 0; i < n; i++)
            ret ~= value;
    }
    return cast(string)ret;
}

/**
   CTFE MOC port.
  */

enum MethodFlags {
    AccessPrivate = 0x00,
    AccessProtected = 0x01,
    AccessPublic = 0x02,
    MethodMethod = 0x00,
    MethodSignal = 0x04,
    MethodSlot = 0x08,
    MethodConstructor = 0x0c,
    MethodCompatibility = 0x10,
    MethodCloned = 0x20,
    MethodScriptable = 0x40
}

enum Access { Private, Protected, Public }

struct FunctionDef
{
/*    FunctionDef(): returnTypeIsVolatile(false), access(Private), isConst(false), isVirtual(false),
                   inlineCode(false), wasCloned(false), isCompat(false), isInvokable(false),
                   isScriptable(false), isSlot(false), isSignal(false),
                   isConstructor(false), isDestructor(false), isAbstract(false) {}
                   */
//    Type type;
//    string normalizedType;
//    string tag;
//    string name;
    string sig;
    string arguments;
    Access access;    
/*    bool returnTypeIsVolatile;

    QList<ArgumentDef> arguments;

    enum Access { Private, Protected, Public };
    bool isConst;
    bool isVirtual;
    bool inlineCode;
    bool wasCloned;

    QByteArray inPrivateClass;
    bool isCompat;
    bool isInvokable;
    bool isScriptable;
    bool isSlot;
    bool isSignal;
    bool isConstructor;
    bool isDestructor;
    bool isAbstract;
    */
}

FunctionDef newSlot(string sig, string args)
{
    return FunctionDef(sig, args, Access.Public);
}

FunctionDef newSignal(string sig, string args)
{
    return FunctionDef(sig, args, Access.Protected);
}

struct Generator
{
    string output;
    string[] strings;
//    QByteArray purestSuperClass;
//    QList<QByteArray> metaTypes;
}

int lengthOfEscapeSequence(string s, uint i)
{
    if (s[i] != '\\' || i >= s.length - 1)
        return 1;
    const int startPos = i;
    ++i;
    auto ch = s[i];
    if (ch == 'x') {
        ++i;
        while (i < s.length && is_hex_char(s[i]))
            ++i;
    } else if (is_octal_char(ch)) {
        while (i < startPos + 4
               && i < s.length
               && is_octal_char(s[i])) {
            ++i;
        }
    } else { // single character escape sequence
        i = qMin(i + 1, s.length);
    }
    return i - startPos;
}

int strreg(ref Generator gen, string s)
{
    int idx = 0;
    foreach (str; gen.strings) {
        if (str == s)
            return idx;
        idx += str.length + 1;
        foreach (i, c; str) {
            if (c == '\\') {
                int cnt = lengthOfEscapeSequence(str, i) - 1;
                idx -= cnt;
                i += cnt;
            }
        }
    }
    gen.strings ~= s;
    return idx;
}

void generateFunctions(ref Generator gen, FunctionDef[] list, string functype, byte type)
{
    if (!list.length)
        return;
    gen.output ~= format_ctfe("\n // ${}s: signature, parameters, type, tag, flags\n", functype);

    foreach (i, f; list) {
        byte flags = type;

        if (f.access == Access.Private)
            flags |= MethodFlags.AccessPrivate;
        else if (f.access == Access.Public)
            flags |= MethodFlags.AccessPublic;
        else if (f.access == Access.Protected)
            flags |= MethodFlags.AccessProtected;

        gen.output ~= format_ctfe("    ${}, ${}, ${}, ${}, 0x${:x},\n", strreg(gen, f.sig),
                strreg(gen, f.arguments), strreg(gen, ""/*f.normalizedType*/), strreg(gen, ""/*f.tag*/), flags);
    }
}

string generateCode(string className, FunctionDef[] signalList, FunctionDef[] slotList)
{
    auto gen = Generator("", []);

/*    bool isQt = (cdef->classname == "Qt");
    bool isQObject = (cdef->classname == "QObject");
    bool isConstructible = !cdef->constructorList.isEmpty();

//
// build the data array
//
    int i = 0;


    // filter out undeclared enumerators and sets
    {
        QList<EnumDef> enumList;
        for (i = 0; i < cdef->enumList.count(); ++i) {
            EnumDef def = cdef->enumList.at(i);
            if (cdef->enumDeclarations.contains(def.name)) {
                enumList += def;
            }
            QByteArray alias = cdef->flagAliases.value(def.name);
            if (cdef->enumDeclarations.contains(alias)) {
                def.name = alias;
                enumList += def;
            }
        }
        cdef->enumList = enumList;
    }


    QByteArray qualifiedClassNameIdentifier = cdef->qualified;
    qualifiedClassNameIdentifier.replace(':', '_');
*/
    bool isConstructible = false;
    
    FunctionDef[] propertyList, enumList, constructorList;
    int index = 12;
    gen.output ~= format_ctfe("static const uint[] qt_meta_data_${} = [\n", className);
    gen.output ~= format_ctfe("\n // content:\n");
    gen.output ~= format_ctfe("    ${},       // revision\n", 2);
    gen.output ~= format_ctfe("    ${},       // classname\n", strreg(gen, className));
    gen.output ~= format_ctfe("    ${}, ${}, // classinfo\n", 0, 0);
//    index += cdef->classInfoList.count() * 2;

    int methodCount = signalList.length + slotList.length;// + cdef->methodList.count();
    gen.output ~= format_ctfe("    ${}, ${}, // methods\n", methodCount, methodCount ? index : 0);
    index += methodCount * 5;
    gen.output ~= format_ctfe("    ${}, ${}, // properties\n", propertyList.length, propertyList.length ? index : 0);
    index += propertyList.length * 3;
//    if(cdef->notifyableProperties)
//        index += cdef->propertyList.count();
    gen.output ~= format_ctfe("    ${}, ${}, // enums/sets\n", enumList.length, enumList.length ? index : 0);

//    int enumsIndex = index;
//    for (i = 0; i < cdef->enumList.count(); ++i)
//        index += 4 + (cdef->enumList.at(i).values.count() * 2);
    gen.output ~= format_ctfe("    ${}, ${}, // constructors\n", isConstructible ? constructorList.length : 0,
            isConstructible ? index : 0);

//
// Build classinfo array
//
//    generateClassInfos();

//
// Build signals array first, otherwise the signal indices would be wrong
//
    generateFunctions(gen, signalList, "signal", MethodFlags.MethodSignal);

//
// Build slots array
//
    generateFunctions(gen, slotList, "slot", MethodFlags.MethodSlot);

//
// Build method array
//
//    generateFunctions(cdef->methodList, "method", MethodMethod);


//
// Build property array
//
//    generateProperties();

//
// Build enums array
//
//    generateEnums(enumsIndex);

//
// Build constructors array
//
//    if (isConstructible)
//        generateFunctions(cdef->constructorList, "constructor", MethodConstructor);

//
// Terminate data array
//
    gen.output ~= format_ctfe("\n       0        // eod\n];\n\n");

//
// Build stringdata array
//
    gen.output ~= format_ctfe("static const string qt_meta_stringdata_${} = \n", className);
    gen.output ~= format_ctfe("    \"");
    int col = 0;
    int len = 0;
    foreach (i, s; gen.strings) {
        len = s.length;
        if (col && col + len >= 72) {
            gen.output ~= format_ctfe("\"\n    \"");
            col = 0;
        } else if (len && s[0] >= '0' && s[0] <= '9') {
            gen.output ~= format_ctfe("\"\"");
            len += 2;
        }
        int idx = 0;
        while (idx < s.length) {
            if (idx > 0) {
                col = 0;
                gen.output ~= format_ctfe("\"\n    \"");
            }
            int spanLen = qMin(cast(uint)70, s.length - idx);
            // don't cut escape sequences at the end of a line
            int backSlashPos = s.lastIndexOf("\\", idx + spanLen - 1);
            if (backSlashPos >= idx) {
                int escapeLen = lengthOfEscapeSequence(s, backSlashPos);
                spanLen = qBound(spanLen, backSlashPos + escapeLen - idx, cast(int)(s.length - idx));
            }
            gen.output ~= s[idx..idx+spanLen];
            idx += spanLen;
            col += spanLen;
        }

        gen.output ~= "\\0";
        col += len + 2;
    }
    gen.output ~=  "\";\n\n";
    
    return gen.output;
}

string metaCallArgs(Args...)()
{
    string res;
    foreach(i, _; Args) {
        if (i > 0)
            res ~= ",";
        res ~= metaCallArgument!(Args[i])("_a[" ~ __toString(i+1) ~ "]");
    }
    return res;
}

string qtDeclArgs(Args...)()
{
    string ret;
    foreach(i, _; Args)
    {
        if(i > 0)
            ret ~= ",";
        ret ~= qtDeclArg!(Args[i]);
    }
    return ret;
}

string generate_qt_metacall(alias Signals, alias Slots)()
{
    string res = "
protected int qt_metacall(QMetaObject.Call _c, int _id, void **_a)
    {
        _id = super.qt_metacall(_c, _id, _a);
        if (_id < 0)
            return _id;\n";

    alias TypeTuple!(Signals.at, Slots.at) Methods;
    enum methodCount = Methods.length;
    if(methodCount)
    {
        res ~= "
        if (_c == QMetaObject.Call.InvokeMetaMethod) {
            switch (_id) {";
        foreach(i, _; Repeat!(void, methodCount)) {
            res ~= "
            case " ~ __toString(i) ~ ": " ~ MetaEntryName!(Methods[i].at) ~ "(" ~ metaCallArgs!(MetaEntryArgs!(Methods[i].at))() ~ "); break;";
        }
        res ~= "\n            default: ;\n            }\n";
        res ~= "            _id -= " ~ __toString(methodCount) ~ ";";
        res ~= "\n        }";
    }
    
    res ~= "\n        return _id;
    }";
    return res;
}

string dDeclArgs(Args...)()
{
    string ret;
    foreach(i, _; Args)
    {
        if (i > 0)
            ret ~= ", ";
        ret ~= fullDName!(Args[i]);
    }
    return ret;
}
string genMetaMethodsConstr(alias Funcs)(string className)
{
    string res;
    enum funcsCount = Funcs.at.length;
    foreach(i, bogus; Repeat!(void, funcsCount))
    {
        res ~= "        index++;\n" ~
               "        _staticMetaObject.addMethod(new " ~ className ~ "(signature!(" ~ dDeclArgs!(MetaEntryArgs!(Funcs.at[i].at))()~ ")(\"" ~ MetaEntryName!(Funcs.at[i].at) ~ "\"), index));\n\n";
    }
    return res;
}
string generateMetaObjectConstruction(alias Signals, alias Slots)()
{
    string res;
    res ~= "\n
    private static void _populateMetaInfo() {
        alias BaseClassesTuple!(typeof(this))[0] BaseClass;
        int index = BaseClass.staticMetaObject().methodCount() - 1;\n\n";
    
    res ~= genMetaMethodsConstr!(Signals)("QMetaSignal");
    res ~= genMetaMethodsConstr!(Slots)("QMetaSlot");
    
    res ~= "
    }\n";
    return res;
}

string generateQMetaObject(string className)
{
    string res;
    res ~= "
    public QMetaObject metaObject() { return staticMetaObject(); }
    private static __gshared QMetaObject _staticMetaObject;
    private static __gshared QMetaObjectNative _nativeStaticMetaObject;
    public static QMetaObject staticMetaObject()
    {
        if(!_staticMetaObject)
            createStaticMetaObject();
        return _staticMetaObject;
    }
    protected static void createStaticMetaObject() {
        assert(!_staticMetaObject);
        alias BaseClassesTuple!(typeof(this))[0] BaseClass;
        if (!BaseClass._staticMetaObject)
            BaseClass.createStaticMetaObject;
        auto base = BaseClass._staticMetaObject;
        _nativeStaticMetaObject = QMetaObjectNative(base.nativeId, qt_meta_stringdata_" ~ className ~ ".ptr,
                                                    qt_meta_data_" ~ className ~ ".ptr, null );
        
        _staticMetaObject = new QMetaObject(&_nativeStaticMetaObject, base);
//        _staticMetaObject.construct!(typeof(this));
        _populateMetaInfo();
    }\n\n";
    return res;
}

size_t commaCount(int argCount)
{
    size_t ret = 0;
    if(argCount > 1)
        ret = argCount - 1;
    return ret;
}

FunctionDef[] genFuncDefs(alias Funcs, alias newFunc)()
{
    typeof(return) res;
    enum funcsCount = Funcs.at.length;
    foreach(i, bogus; Repeat!(void, funcsCount))
    {
        string args = replicate(commaCount((MetaEntryArgs!(Funcs.at[i].at)).length), ',');
        string funcSig = MetaEntryName!(Funcs.at[i].at) ~ "(" ~ qtDeclArgs!(MetaEntryArgs!(Funcs.at[i].at))() ~ ")";
        res ~= newFunc(funcSig, args);
    }
    return res;
}

template Q_OBJECT_BIND()
{
}

// ------------------------------------------------------------------------------------------

string generateSignalEmitters(alias Funcs)()
{
    string res;
    enum funcsCount = Funcs.at.length;
    foreach(i, bogus; Repeat!(void, funcsCount))
    {
        res ~= SignalEmitter!(MetaEntryArgs!(Funcs.at[i].at))(SignalType.NewSignal, MetaEntryName!(Funcs.at[i].at), cast(string[])[], i);
    }
    return res;
}

string generateSlotAliases(alias Funcs)()
{
    string res;
    enum funcsCount = Funcs.at.length;
    foreach(i, bogus; Repeat!(void, funcsCount))
    {
        string name = MetaEntryName!(Funcs.at[i].at);
        res ~= format_ctfe("    alias slot_${} ${};\n", name, name);
    }
    return res;
}


string generateMetaInfo(T, alias Signals, alias Slots)()
{
    string res = "";
    auto signalList = genFuncDefs!(Signals, newSignal)();
    auto slotList = genFuncDefs!(Slots, newSlot)();
    res ~= generateSignalEmitters!(Signals)();
    res ~= generateSlotAliases!(Slots)();
    res ~= generateCode(T.stringof, signalList, slotList);
    res ~= generate_qt_metacall!(Signals, Slots);
    res ~= generateMetaObjectConstruction!(Signals, Slots);
    res ~= generateQMetaObject(T.stringof);
    return res;
}

template Q_OBJECT()
{
    alias findSignals!(typeof(this)) SignalFuncs;
    alias toMetaEntries!(SignalFuncs) SignalMetaEntries;
    alias findSlots!(typeof(this)) SlotFuncs;
    alias toMetaEntries!(SlotFuncs) SlotMetaEntries;

    mixin(generateMetaInfo!(typeof(this), SignalMetaEntries, SlotMetaEntries)());
    // debug output
//    pragma(msg, generateMetaInfo!(typeof(this), SignalMetaEntries, SlotMetaEntries)());
}
