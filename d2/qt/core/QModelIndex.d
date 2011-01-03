module qt.core.QModelIndex;

public import qt.QGlobal;
private import qt.core.QObject;

// automatic imports-------------
//private import qt.core.QVariant;
private import qt.core.QAbstractItemModel;
public import qt.core.Qt;


public struct QModelIndex
{
    public static QModelIndex opCall() {
         QModelIndex mi;
         mi.r = mi.c = -1;
         mi.p = mi.m = null;
         return mi;
    }

    public final QModelIndex child(int row, int column) const {
        return __qtd_QModelIndex_child_int_int(cast(void*)&this, row, column);
    }

    public final int column() const {
        return __qtd_QModelIndex_column(cast(void*)&this);
    }

    public final QVariant data(int role = 0) const {
        void* __qt_return_value = __qtd_QModelIndex_data_int(cast(void*)&this, role);
        return new QVariant(__qt_return_value);
    }

    public final int flags() const {
        return __qtd_QModelIndex_flags(cast(void*)&this);
    }

    public final long internalId() const {
        return __qtd_QModelIndex_internalId(cast(void*)&this);
    }

    public final const(void*) internalPointer() const {
        return p;
    }

    public final const(Object) object() const {
        return cast(const(Object)) p;
    }

    public final bool isValid() const {
        return __qtd_QModelIndex_isValid(cast(void*)&this);
    }

    public final const(QAbstractItemModel) model() const {
        void* __qt_return_value = cast(void*)m;
        if (m is null)
            return null;
        void* d_obj = qtd_get_d_qobject(cast(void*)m);
        return cast(QAbstractItemModel) d_obj;
    }

    private final bool operator_less(QModelIndex other) const {
        return __qtd_QModelIndex_operator_less_QModelIndex(cast(void*)&this, other);
    }

    private final bool operator_equal(QModelIndex other) const {
        return __qtd_QModelIndex_operator_equal_QModelIndex(cast(void*)&this, other);
    }

    public final QModelIndex parent() const {
        return __qtd_QModelIndex_parent(cast(void*)&this);
    }

    public final int row() const {
        return __qtd_QModelIndex_row(cast(void*)&this);
    }

    public final QModelIndex sibling(int row, int column) const {
        return __qtd_QModelIndex_sibling_int_int(cast(void*)&this, row, column);
    }

    public alias void __isNativeValueType;

    struct QTypeInfo
    {
        enum bool isComplex = true;
        enum bool isStatic = false;
        enum bool isLarge = true;
        enum bool isPointer = false;
        enum bool isDummy = false;
    }

private:
    int r;
    int c;
    void *p;
    void *m;
}


alias QModelIndex QModelIndexAccessor;


// C wrappers
private extern(C) void* __qtd_QModelIndex_QModelIndex_QModelIndex(QModelIndex other0);
private extern(C) QModelIndex  __qtd_QModelIndex_child_int_int(void* __this_nativeId,
 int row0,
 int column1);
private extern(C) int  __qtd_QModelIndex_column(void* __this_nativeId);
private extern(C) void*  __qtd_QModelIndex_data_int(void* __this_nativeId,
 int role0);
private extern(C) int  __qtd_QModelIndex_flags(void* __this_nativeId);
private extern(C) long  __qtd_QModelIndex_internalId(void* __this_nativeId);
private extern(C) void*  __qtd_QModelIndex_internalPointer(void* __this_nativeId);
private extern(C) bool  __qtd_QModelIndex_isValid(void* __this_nativeId);
private extern(C) void*  __qtd_QModelIndex_model(void* __this_nativeId);
private extern(C) bool  __qtd_QModelIndex_operator_less_QModelIndex(void* __this_nativeId,
 QModelIndex other0);
private extern(C) bool  __qtd_QModelIndex_operator_equal_QModelIndex(void* __this_nativeId,
 QModelIndex other0);
private extern(C) QModelIndex  __qtd_QModelIndex_parent(void* __this_nativeId);
private extern(C) int  __qtd_QModelIndex_row(void* __this_nativeId);
private extern(C) QModelIndex  __qtd_QModelIndex_sibling_int_int(void* __this_nativeId,
 int row0,
 int column1);
