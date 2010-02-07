module qt.core.QSize;

public import qt.QGlobal;
public import qt.core.Qt;


public struct QSize
{
/* ctors, reserved for D2
    public this()
    { wd = ht = -1; }

    public this(int w, int h)
    { wd = w; ht = h; }
*/

    public static QSize opCall() {
    	QSize sz;
    	sz.wd = sz.ht = -1;
    	return sz;
    }

    public this(int w, int h) {
    	wd = w;
    	ht = h;
    }

    final bool isNull()
    { return wd==0 && ht==0; }
    
    final bool isEmpty()
    { return wd<1 || ht<1; }
    
    final bool isValid()
    { return wd>=0 && ht>=0; }

    final int width() const
    { return wd; }
    
    final int height() const
    { return ht; }
    
    final void width(int w)
    { wd = w; }
    
    final void height(int h)
    { ht = h; }
    
    final void setWidth(int w) // for convenience
    { wd = w; }
    
    final void setHeight(int h) // for convenience
    { ht = h; }
    
    void transpose() {
		int tmp = wd;
		wd = ht;
		ht = tmp;
	}

    void scale(int w, int h, Qt.AspectRatioMode mode) {
    	scale(QSize(w, h), mode);
    }
    
    void scale(ref QSize s, Qt.AspectRatioMode mode) {
    	__qtd_QSize_scale_QSize_AspectRatioMode(&this, &s, mode);
    }

    QSize expandedTo(ref QSize otherSize) {
        return QSize(qMax(wd,otherSize.wd), qMax(ht,otherSize.ht));
	}

    QSize boundedTo(ref QSize otherSize) {
    	return QSize(qMin(wd,otherSize.wd), qMin(ht,otherSize.ht));
	}
/*
    public final void writeTo(QDataStream arg__1)    {
        __qtd_QSize_writeTo_QDataStream(&this, arg__1 is null ? null : arg__1.nativeId);
    }

    public final void readFrom(QDataStream arg__1)    {
        __qtd_QSize_readFrom_QDataStream(&this, arg__1 is null ? null : arg__1.nativeId);
    }
*/
	QSize opAddAssign(ref QSize s)
	{ wd+=s.wd; ht+=s.ht; return this; }

	QSize opSubAssign(ref QSize s)
	{ wd-=s.wd; ht-=s.ht; return this; }

	QSize opMulAssign(qreal c)
	{ wd = qRound(wd*c); ht = qRound(ht*c); return this; }

	bool opEquals(ref const QSize s) const
	{ return wd == s.wd && ht == s.ht; }

	QSize opAdd(ref QSize s)
	{ return QSize(this.wd+s.wd, this.ht+s.ht); }

	QSize opSub(ref QSize s)
	{ return QSize(this.wd-s.wd, this.ht-s.ht); }

	QSize opMul(qreal c)
	{ return QSize(qRound(this.wd*c), qRound(this.ht*c)); }

	QSize opDivAssign(qreal c) {
    	assert(!qFuzzyCompare(c + 1, 1.));
    	wd = qRound(wd/c); ht = qRound(ht/c);
    	return this;
	}

	QSize opDiv(qreal c) {
    	assert(!qFuzzyCompare(c + 1, 1.));
    	return QSize(qRound(this.wd/c), qRound(this.ht/c));
	}
    
    // service stuff
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
    int wd;
    int ht;
}


public struct QSizeF
{
/* ctors, reserved for D2
	this()
	{ wd = ht = -1.; }

	this(ref QSize sz)
	{ wd = sz.width(); ht = sz.height(); }

	this(qreal w, qreal h)
	{ wd = w; ht = h; }
*/
	public static QSizeF opCall() {
    	QSizeF sz;
		sz.wd = sz.ht = -1.;
		return sz;
	}

	public static QSizeF opCall(ref QSizeF s) {
		QSizeF sz;
		sz.wd = s.width(); sz.ht = s.height();
		return sz;
	}

	public static QSizeF opCall(qreal w, qreal h) {
		QSizeF sz;
		sz.wd = w; sz.ht = h;
		return sz;
	}

	bool isNull()
	{ return qIsNull(wd) && qIsNull(ht); }

	bool isEmpty()
	{ return wd <= 0. || ht <= 0.; }

	bool isValid()
	{ return wd >= 0. && ht >= 0.; }

	qreal width()
	{ return wd; }

	qreal height()
	{ return ht; }

	void width(qreal w)
	{ wd = w; }

	void height(qreal h)
	{ ht = h; }

	void setWidth(qreal w)
	{ wd = w; }

	void setHeight(qreal h)
	{ ht = h; }

	void scale(qreal w, qreal h, Qt.AspectRatioMode mode)
	{ scale(QSizeF(w, h), mode); }

    public final void scale(QSizeF s, Qt.AspectRatioMode mode)
    { __qtd_QSizeF_scale_QSizeF_AspectRatioMode(&this, &s, mode); }

	void transpose() {
    	qreal tmp = wd;
    	wd = ht;
    	ht = tmp;
	}

	QSizeF expandedTo(ref QSizeF otherSize)
	{ return QSizeF(qMax(wd,otherSize.wd), qMax(ht,otherSize.ht)); }

	QSizeF boundedTo(ref QSizeF otherSize)
	{ return QSizeF(qMin(wd,otherSize.wd), qMin(ht,otherSize.ht)); }

	QSize toSize()
	{ return QSize(qRound(wd), qRound(ht));	}
/*
    public final void writeTo(QDataStream arg__1) {
        __qtd_QSizeF_writeTo_QDataStream(&this, arg__1 is null ? null : arg__1.nativeId);
    }

    public final void readFrom(QDataStream arg__1) {
        __qtd_QSizeF_readFrom_QDataStream(&this, arg__1 is null ? null : arg__1.nativeId);
*/
	QSizeF opAddAssign(ref QSizeF s)
	{ wd += s.wd; ht += s.ht; return this; }

	QSizeF opSubAssign(ref QSizeF s)
	{ wd -= s.wd; ht -= s.ht; return this; }

	QSizeF opMulAssign(qreal c)
	{ wd *= c; ht *= c; return this; }

	bool opEquals(ref const QSizeF s) const
	{ return qFuzzyCompare(wd, s.wd) && qFuzzyCompare(ht, s.ht); }

	QSizeF opAdd(ref QSizeF s)
	{ return QSizeF(this.wd+s.wd, this.ht+s.ht); }

	QSizeF opSub(ref QSizeF s)
	{ return QSizeF(this.wd-s.wd, this.ht-s.ht); }

	QSizeF opMul(qreal c)
	{ return QSizeF(this.wd*c, this.ht*c); }

	QSizeF opDivAssign(qreal c)
	{
	    assert(!qFuzzyCompare(c + 1, 1.));
	    wd = wd/c; ht = ht/c;
	    return this;
	}

	QSizeF opDiv(qreal c)
	{
	    assert(!qFuzzyCompare(c + 1, 1.));
	    return QSizeF(this.wd/c, this.ht/c);
	}
    
    // service stuff
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
    qreal wd;
    qreal ht;
}


extern (C) void qtd_append_array_QSize(QSize[]* arr, QSize arg)
{
    *arr ~= arg;
}

extern (C) void qtd_append_array_QSizeF(QSizeF[]* arr, QSizeF arg)
{
    *arr ~= arg;
}

// C wrappers
// QSize
private extern(C) void  __qtd_QSize_scale_QSize_AspectRatioMode(void* __this_nativeId,
 void* s0,
 int mode1);
private extern(C) void  __qtd_QSize_writeTo_QDataStream(void* __this_nativeId,
 void* arg__1);
private extern(C) void  __qtd_QSize_readFrom_QDataStream(void* __this_nativeId,
 void* arg__1);

// QSizeF
private extern(C) void  __qtd_QSizeF_writeTo_QDataStream(void* __this_nativeId,
 void* arg__1);
private extern(C) void  __qtd_QSizeF_readFrom_QDataStream(void* __this_nativeId,
 void* arg__1);
private extern(C) void  __qtd_QSizeF_scale_QSizeF_AspectRatioMode(void* __this_nativeId,
 void* s0,
 int mode1);