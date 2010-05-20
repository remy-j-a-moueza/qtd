module qtd.MOC;

import
    std.typetuple,
    std.traits,
    std.typetuple,
    std.conv,
    qt.QGlobal,
    qtd.Signal,
    qtd.Marshal,
    qtd.Array,
    qtd.Str,
    qtd.meta.Compiletime,
    qtd.ctfe.Format;

import qt.core.QString;

/**
   Utils.
 */
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
        while (i < s.length && isHexChar(s[i]))
            ++i;
    } else if (isOctalChar(ch)) {
        while (i < startPos + 4
               && i < s.length
               && isOctalChar(s[i])) {
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
    gen.output ~= "private static const uint[] qt_meta_data = [\n";
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
    gen.output ~= "private static const string qt_meta_stringdata = \n";
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

string dDeclArgs(Args...)()
{
    string ret;
    foreach(i, _; Args)
    {
        if (i > 0)
            ret ~= ", ";
        ret ~= fullName!(Args[i]);
    }
    return ret;
}

size_t commaCount(int argCount)
{
    size_t ret = 0;
    if(argCount > 1)
        ret = argCount - 1;
    return ret;
}

FunctionDef[] generateFuncDefs(alias newFunc, Funcs...)()
{
    typeof(return) res;
    enum funcsCount = Funcs.length;
    foreach(i, bogus; Repeat!(void, funcsCount))
    {
        alias ParameterTypeTuple!(Funcs[i]) Args;
        string args = replicate(commaCount(Args.length), ',');
        string funcSig = methodName!(Funcs[i]) ~ "(" ~ qtDeclArgs!(Args)() ~ ")";
        res ~= newFunc(funcSig, args);
    }
    return res;
}

template Q_OBJECT_BIND()
{
}

// ------------------------------------------------------------------------------------------

string generateSignalEmitters(uint signalCount)
{
    string res = "";
    foreach (i; 0..signalCount)
    {
        auto iStr = to!string(i);
        res ~= "mixin SignalEmitter!(SignalKind.NewSignal, " ~ iStr ~ ");\n";
    }
    return res;
}

private mixin template SlotAlias(alias slot)
{
    mixin ("alias slot " ~ methodName!slot ~ ";");
}

string generateSlotAliases(uint slotCount)
{
    string res = "";
    foreach(i; 0..slotCount)
    {
        auto iStr = to!string(i);
        res ~= "mixin SlotAlias!(slots[" ~ iStr ~ "]);\n";
    }
    return res;
}

string generateMetaCall(string methodName, size_t argCount)
{
    string res = "";
    foreach (i; 1..argCount)
        res ~= generateConvToD(i);

    res ~= methodName ~ "(";
    foreach (i; 1..argCount)
    {
        if (i > 1)
            res ~= ", ";
        res ~= "_out" ~ to!string(i);
    }
    return res ~ ");\n";
}

string generateDispatchSwitch(size_t methodCount)
{
    string res = "switch(_id) {\n";

    foreach(i; 0..methodCount)
    {
        string iStr = to!string(i);
        res ~= "    case " ~ iStr ~ ":\n";
        res ~= "        alias methods[" ~ iStr ~ "] method;\n";
        res ~= "        alias TypeTuple!(void, ParameterTypeTuple!method) Args;\n";
        res ~= "        mixin(generateMetaCall(methodName!method, Args.length));\n";
        res ~= "        break;\n";
    }

    res ~= "    default:\n";

    return res ~ "}\n";
}

mixin template Q_OBJECT()
{
    import std.typetuple;
    import qtd.Marshal;
    import qt.core.QString; // for QStringUtil.toNative

public: // required to override the outside scope protection.

    alias typeof(this) This;

    alias findSignals!(This) signals;
    alias findSlots!(This) slots;
    alias TypeTuple!(signals, slots) methods;

 
    mixin (generateSignalEmitters(signals.length));
    mixin (generateSlotAliases(slots.length));

    auto signalList = generateFuncDefs!(newSignal, signals)();
    auto slotList = generateFuncDefs!(newSlot, slots)();
    mixin (generateCode(typeof(this).stringof, signalList, slotList));

    protected int qt_metacall(QMetaObject.Call _c, int _id, void **_a)
    {
        _id = super.qt_metacall(_c, _id, _a);

        static if (methods.length)
        {
            if (_id < 0)
                return _id;

            if (_c == QMetaObject.Call.InvokeMetaMethod) {
                //pragma(msg, generateDispatchSwitch(methods.length));
                mixin (generateDispatchSwitch(methods.length));
            }
            _id -= methods.length;
        }

        return _id;
    }

    @property
    override QMetaObject metaObject() const { return staticMetaObject(); }

    private static __gshared QMetaObject _staticMetaObject;
    private static __gshared QMetaObjectNative _nativeStaticMetaObject;

    @property
    static QMetaObject staticMetaObject()
    {
        // TODO: synchronize or enable static constructors in circular modules
        if(!_staticMetaObject)
        {
            alias BaseClassesTuple!(This)[0] Base;

            _nativeStaticMetaObject = QMetaObjectNative(
                Base.staticMetaObject.nativeId,
                qt_meta_stringdata.ptr,
                qt_meta_data.ptr, null);

            QMetaObject.create!This(&_nativeStaticMetaObject);
        }
        return _staticMetaObject;
    }

    /*internal*/ static void setStaticMetaObject(QMetaObject m)
    {
        _staticMetaObject = m;
    }
}

