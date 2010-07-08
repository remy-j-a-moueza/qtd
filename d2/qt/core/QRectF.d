module qt.core.QRectF;

public import qt.QGlobal;
public import qt.core.Qt;
public import qt.core.QPointF;
public import qt.core.QRect;
public import qt.core.QSizeF;
public import qt.core.QDataStream;


public struct QRectF
{
    public static QRectF opCall()
    {
        QRectF rt;
        rt.xp = rt.yp = 0.;
        rt.w = rt.h = 0.;
        return rt;
    }

    public this(qreal aleft, qreal atop, qreal awidth, qreal aheight)
    {
        xp = aleft;
        yp = atop;
        w = awidth;
        h = aheight;
    }

    public this(QPointF atopLeft, QSizeF asize)
    {
        xp = atopLeft.x();
        yp = atopLeft.y();
        w = asize.width();
        h = asize.height();
    }

    public this(QPointF atopLeft, QPointF abottomRight)
    {
        xp = atopLeft.x();
        yp = atopLeft.y();
        w = abottomRight.x() - xp;
        h = abottomRight.y() - yp;
    }

    public this(QRect r)
    {
        xp = r.x();
        yp = r.y();
        w = r.width();
        h = r.height();
    }

    bool isNull() const
    { return qIsNull(w) && qIsNull(h); }

    bool isEmpty() const
    { return w <= 0. || h <= 0.; }

    bool isValid() const
    { return w > 0. && h > 0.; }

    qreal x() const
    { return xp; }

    qreal y() const
    { return yp; }

    qreal left() const
    { return xp; }

    qreal top() const
    { return yp; }

    qreal right() const
    { return xp + w; }

    qreal bottom() const
    { return yp + h; }

    QPointF topLeft() const
    { return QPointF(xp, yp); }

    QPointF bottomRight() const
    { return QPointF(xp+w, yp+h); }

    QPointF topRight() const
    { return QPointF(xp+w, yp); }

    QPointF bottomLeft() const
    { return QPointF(xp, yp+h); }

    void setLeft(qreal pos) { qreal diff = pos - xp; xp += diff; w -= diff; }

    void setRight(qreal pos) { w = pos - xp; }

    void setTop(qreal pos) { qreal diff = pos - yp; yp += diff; h -= diff; }

    void setBottom(qreal pos) { h = pos - yp; }

    void setTopLeft(ref QPointF p) { setLeft(p.x()); setTop(p.y()); }

    void setTopRight(ref QPointF p) { setRight(p.x()); setTop(p.y()); }

    void setBottomLeft(ref QPointF p) { setLeft(p.x()); setBottom(p.y()); }

    void setBottomRight(ref QPointF p) { setRight(p.x()); setBottom(p.y()); }

    QPointF center() const
    { return QPointF(xp + w/2, yp + h/2); }

    void moveLeft(qreal pos) { xp = pos; }

    void moveTop(qreal pos) { yp = pos; }

    void moveRight(qreal pos) { xp = pos - w; }

    void moveBottom(qreal pos) { yp = pos - h; }

    void moveTopLeft(ref QPointF p) { moveLeft(p.x()); moveTop(p.y()); }

    void moveTopRight(ref QPointF p) { moveRight(p.x()); moveTop(p.y()); }

    void moveBottomLeft(ref QPointF p) { moveLeft(p.x()); moveBottom(p.y()); }

    void moveBottomRight(ref QPointF p) { moveRight(p.x()); moveBottom(p.y()); }

    void moveCenter(ref QPointF p) { xp = p.x() - w/2; yp = p.y() - h/2; }

    qreal width() const
    { return w; }

    qreal height() const
    { return h; }

    QSizeF size() const
    { return QSizeF(w, h); }

    void translate(qreal dx, qreal dy)
    {
        xp += dx;
        yp += dy;
    }

    void translate(ref QPointF p)
    {
        xp += p.x();
        yp += p.y();
    }

    void moveTo(qreal ax, qreal ay)
    {
        xp = ax;
        yp = ay;
    }

    void moveTo(ref QPointF p)
    {
        xp = p.x();
        yp = p.y();
    }

    QRectF translated(qreal dx, qreal dy) const
    { return QRectF(xp + dx, yp + dy, w, h); }

    QRectF translated(ref QPointF p) const
    { return QRectF(xp + p.x(), yp + p.y(), w, h); }

    void getRect(qreal *ax, qreal *ay, qreal *aaw, qreal *aah) const
    {
        *ax = this.xp;
        *ay = this.yp;
        *aaw = this.w;
        *aah = this.h;
    }

    void setRect(qreal ax, qreal ay, qreal aaw, qreal aah)
    {
        this.xp = ax;
        this.yp = ay;
        this.w = aaw;
        this.h = aah;
    }

    void getCoords(qreal *xp1, qreal *yp1, qreal *xp2, qreal *yp2) const
    {
        *xp1 = xp;
        *yp1 = yp;
        *xp2 = xp + w;
        *yp2 = yp + h;
    }

    void setCoords(qreal xp1, qreal yp1, qreal xp2, qreal yp2)
    {
        xp = xp1;
        yp = yp1;
        w = xp2 - xp1;
        h = yp2 - yp1;
    }

    void adjust(qreal xp1, qreal yp1, qreal xp2, qreal yp2)
    { xp += xp1; yp += yp1; w += xp2 - xp1; h += yp2 - yp1; }

    QRectF adjusted(qreal xp1, qreal yp1, qreal xp2, qreal yp2) const
    { return QRectF(xp + xp1, yp + yp1, w + xp2 - xp1, h + yp2 - yp1); }

    void setWidth(qreal aw) // for convenience
    { this.w = aw; }

    void setHeight(qreal ah) // for convenience
    { this.h = ah; }

    void setSize(ref QSizeF s) // for convenience
    {
        w = s.width();
        h = s.height();
    }

    void width(qreal aw)
    { this.w = aw; }

    void height(qreal ah)
    { this.h = ah; }

    void size(ref QSizeF s)
    {
        w = s.width();
        h = s.height();
    }

    bool contains(qreal ax, qreal ay) const
    {
        return contains(QPointF(ax, ay));
    }

    QRectF opOrAssign(ref QRectF r)
    {
        this = this | r;
        return this;
    }

    QRectF opAndAssign(ref QRectF r)
    {
        this = this & r;
        return this;
    }

    QRectF intersected(ref QRectF r) const
    {
        return this & r;
    }

    QRectF united(ref QRectF r) const
    {
        return this | r;
    }

    bool opEquals(ref const QRectF r) const
    {
        return qFuzzyCompare(xp, r.xp) && qFuzzyCompare(yp, r.yp)
            && qFuzzyCompare(w, r.w) && qFuzzyCompare(h, r.h);
    }

    QRect toRect() const
    {
        return QRect(qRound(xp), qRound(yp), qRound(w), qRound(h));
    }

    public final bool contains(QPointF p) const {
        return qtd_QRectF_contains_QPointF(cast(void*)&this, &p);
    }

    public final bool contains(QRectF r) const {
        return qtd_QRectF_contains_QRectF(cast(void*)&this, &r);
    }

    public final bool intersects(QRectF r) const {
        return qtd_QRectF_intersects_QRectF(cast(void*)&this, &r);
    }

    public final QRectF normalized() const {
        return qtd_QRectF_normalized(cast(void*)&this);
    }

    public final QRectF opAnd(ref QRectF r) const {
        return qtd_QRectF_operator_and_QRectF(cast(void*)&this, &r);
    }

    public final void writeTo(QDataStream arg__1) {
        qtd_QRectF_writeTo_QDataStream(&this, arg__1 is null ? null : arg__1.qtdNativeId);
    }

    public final void readFrom(QDataStream arg__1) {
        qtd_QRectF_readFrom_QDataStream(&this, arg__1 is null ? null : arg__1.qtdNativeId);
    }

    public final QRectF opOr(ref QRectF r) const {
        return qtd_QRectF_operator_or_QRectF(cast(void*)&this, &r);
    }

    public final QRect toAlignedRect() const
    {
        return qtd_QRectF_toAlignedRect(cast(void*)&this);
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
    qreal xp;
    qreal yp;
    qreal w;
    qreal h;
}


// C wrappers
private extern(C) bool  qtd_QRectF_contains_QPointF(void* __this_nativeId,
 void* p0);
private extern(C) bool  qtd_QRectF_contains_QRectF(void* __this_nativeId,
 void* r0);
private extern(C) bool  qtd_QRectF_intersects_QRectF(void* __this_nativeId,
 void* r0);
private extern(C) QRectF  qtd_QRectF_normalized(void* __this_nativeId);
private extern(C) QRectF  qtd_QRectF_operator_and_QRectF(void* __this_nativeId,
 void* r0);
private extern(C) void  qtd_QRectF_writeTo_QDataStream(void* __this_nativeId,
 void* arg__1);
private extern(C) void  qtd_QRectF_readFrom_QDataStream(void* __this_nativeId,
 void* arg__1);
private extern(C) QRectF  qtd_QRectF_operator_or_QRectF(void* __this_nativeId,
 void* r0);
private extern(C) QRect  qtd_QRectF_toAlignedRect(void* __this_nativeId);
