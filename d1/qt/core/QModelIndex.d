module qt.core.QModelIndex;

public import qt.QGlobal;
private import qt.QtdObject;

// automatic imports-------------
private import qt.core.QVariant;
private import qt.core.QAbstractItemModel;
public import qt.core.Qt;

version (Tango)
{
    import tango.core.Array;
    import tango.stdc.stringz;
    import tango.text.convert.Utf;
}


public struct QModelIndex
{

    public static QModelIndex opCall() {
         QModelIndex mi;
	     mi.r = mi.c = -1;
         mi.p = mi.m = null;
         return mi;
    }
    public final QModelIndex child(int row, int column) {
        return __qtd_QModelIndex_child_int_int(this, row, column);
    }

    public final int column() {
        return __qtd_QModelIndex_column(this);
    }

    public final QVariant data(int role = 0) {
        void* __qt_return_value = __qtd_QModelIndex_data_int(this, role);
        return new QVariant(__qt_return_value);
    }

    public final int flags() {
        return __qtd_QModelIndex_flags(this);
    }

    public final long internalId() {
        return __qtd_QModelIndex_internalId(this);
    }

    public final void* internalPointer() {
        //return __qtd_QModelIndex_internalPointer(this);
		return p;
    }

	public final Object object() {
	    return cast(Object) p;
	}

    public final bool isValid() {
        return __qtd_QModelIndex_isValid(this);
    }

    public final QAbstractItemModel model() {
//        void* __qt_return_value = __qtd_QModelIndex_model(this);
        void* __qt_return_value = m;
        if (__qt_return_value is null)
            return null;
        void* d_obj = qtd_get_d_qobject(__qt_return_value);
        return cast(QAbstractItemModel) d_obj;
    }

    private final bool operator_less(QModelIndex other) {
        return __qtd_QModelIndex_operator_less_QModelIndex(this, other);
    }

    private final bool operator_equal(QModelIndex other) {
        return __qtd_QModelIndex_operator_equal_QModelIndex(this, other);
    }

    public final QModelIndex parent() {
        return __qtd_QModelIndex_parent(this);
    }

    public final int row() {
        return __qtd_QModelIndex_row(this);
    }

    public final QModelIndex sibling(int row, int column) {
        return __qtd_QModelIndex_sibling_int_int(this, row, column);
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
// Just the private functions for abstract functions implemeneted in superclasses



// Virtual Dispatch functions
