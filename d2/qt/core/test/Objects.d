module qt.core.test.Objects;

// make sure QtdUnittest is defined
version (QtdUnittest) {} else { static assert(false); }

import
    core.memory,
    qtd.Debug,
    qtd.meta.Runtime,
    qt.core.QObject,
    qt.core.QMetaObject;

extern (C) void* qtd_test_QObject_create(void* parent);
extern (C) void qtd_test_QObject_delete(void* nativeId);
extern (C) void qtd_test_QObject_event(void* nativeId);

class C1 : QObject
{
    mixin Q_CLASSINFO!("author", "Sabrina Schweinsteiger");
    mixin Q_CLASSINFO!("url", "http://doc.moosesoft.co.uk/1.0/");

    static int slot1Called;
    static ClassInfo eventReceived;

    this(QObject parent = null)
    {
        super(parent);
    }

    final
    {
        void signal_signal1();
        void signal_signal2(int);
    }

    override bool event(QEvent event)
    {
        eventReceived = event.classinfo;
        return false;
    }

    void slot_slot1()
    {
        slot1Called++;
    }

    static void reset()
    {
        slot1Called = 0;
        eventReceived = null;
    }

    mixin Q_OBJECT;
}

void test1()
{
    auto c1 = new C1;
}

void test2()
{
    scope c1 = new C1;
}

void test3()
{
    auto ptr = qtd_test_QObject_create(null);
    scope obj = meta!(QObject).getWrapper(ptr);
    assert (qtdDebug.wrapperCount == 1);
}

void test4()
{
    scope c1 = new C1;
    qtd_test_QObject_event(c1.qtdNativeId);
    assert (c1.eventReceived !is null);
    assert (c1.eventReceived.classinfo == QEvent.classinfo);
}

void test5()
{
    scope c1 = new C1;

    QObject.connect(c1, "signal1", c1, "slot1");
    c1.signal1();
    assert(c1.slot1Called == 1);

    QObject.connect(c1, "signal2", c1, "slot1");
    c1.signal2(42);
    assert(C1.slot1Called == 2);
}

unittest
{
    static void reset()
    {
        qtdDebug.reset();
        C1.reset();
    }

    qtdDebug.info("Running unittests (" ~ __FILE__ ~")");

    //test1
    reset();
    test1();
    GC.collect();
    assert(qtdDebug.wrapperCount == 1);


    //test2
    reset();
    test2();
    assert(qtdDebug.wrapperCount == 0);
    assert(qtdDebug.nativeDeletedCount == 1);

    //test3
    reset();
    test3();
    assert(qtdDebug.wrapperCount == 0);
    assert(qtdDebug.nativeDeletedCount == 1);

    //test4
    reset();
    test4();
    GC.collect();
    assert(qtdDebug.wrapperCount == 0);
    assert(qtdDebug.nativeDeletedCount == 1);

    //test5
    qtdDebug.reset();
    test5();
    assert(qtdDebug.wrapperCount == 0);

    qtdDebug.info("Unittests completed (" ~ __FILE__ ~")");
}
