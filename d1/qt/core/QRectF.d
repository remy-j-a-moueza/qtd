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

    public static QRectF opCall(qreal aleft, qreal atop, qreal awidth, qreal aheight)
    {
        QRectF rt;
        rt.xp = aleft;
        rt.yp = atop;
        rt.w = awidth;
        rt.h = aheight;
        return rt;
    }

    public static QRectF opCall(in QPointF atopLeft, in QSizeF asize)
    {
        QRectF rt;
        rt.xp = atopLeft.x();
        rt.yp = atopLeft.y();
        rt.w = asize.width();
        rt.h = asize.height();
        return rt;
    }

    public static QRectF opCall(in QPointF atopLeft, in QPointF abottomRight)
    {
        QRectF rt;
        rt.xp = atopLeft.x();
        rt.yp = atopLeft.y();
        rt.w = abottomRight.x() - rt.xp;
        rt.h = abottomRight.y() - rt.yp;
        return rt;
    }

    public static QRectF opCall(in QRect r)
    {
        QRectF rt;
        rt.xp = r.x();
        rt.yp = r.y();
        rt.w = r.width();
        rt.h = r.height();
        return rt;
    }

    bool isNull() // conts
    { return qIsNull(w) && qIsNull(h); }

    bool isEmpty() // conts
    { return w <= 0. || h <= 0.; }

    bool isValid() // conts
    { return w > 0. && h > 0.; }

    qreal x() // conts
    { return xp; }

    qreal y() // conts
    { return yp; }

    qreal left() // const
    { return xp; }

    qreal top() // const
    { return yp; }

    qreal right() // const
    { return xp + w; }

    qreal bottom() // const
    { return yp + h; }

    QPointF topLeft() // const
    { return QPointF(xp, yp); }

    QPointF bottomRight() // const
    { return QPointF(xp+w, yp+h); }

    QPointF topRight() // const
    { return QPointF(xp+w, yp); }

    QPointF bottomLeft() // const
    { return QPointF(xp, yp+h); }

    void setLeft(qreal pos) { qreal diff = pos - xp; xp += diff; w -= diff; }

    void setRight(qreal pos) { w = pos - xp; }

    void setTop(qreal pos) { qreal diff = pos - yp; yp += diff; h -= diff; }

    void setBottom(qreal pos) { h = pos - yp; }

    void setTopLeft(in QPointF p) { setLeft(p.x()); setTop(p.y()); }

    void setTopRight(in QPointF p) { setRight(p.x()); setTop(p.y()); }

    void setBottomLeft(in QPointF p) { setLeft(p.x()); setBottom(p.y()); }

    void setBottomRight(in QPointF p) { setRight(p.x()); setBottom(p.y()); }

    QPointF center() // conts
    { return QPointF(xp + w/2, yp + h/2); }

    void moveLeft(qreal pos) { xp = pos; }

    void moveTop(qreal pos) { yp = pos; }

    void moveRight(qreal pos) { xp = pos - w; }

    void moveBottom(qreal pos) { yp = pos - h; }

    void moveTopLeft(in QPointF p) { moveLeft(p.x()); moveTop(p.y()); }

    void moveTopRight(in QPointF p) { moveRight(p.x()); moveTop(p.y()); }

    void moveBottomLeft(in QPointF p) { moveLeft(p.x()); moveBottom(p.y()); }

    void moveBottomRight(in QPointF p) { moveRight(p.x()); moveBottom(p.y()); }

    void moveCenter(in QPointF p) { xp = p.x() - w/2; yp = p.y() - h/2; }

    qreal width() // conts
    { return w; }

    qreal height() // conts
    { return h; }

    QSizeF size() // conts
    { return QSizeF(w, h); }

    void translate(qreal dx, qreal dy)
    {
        xp += dx;
        yp += dy;
    }

    void translate(in QPointF p)
    {
        xp += p.x();
        yp += p.y();
    }

    void moveTo(qreal ax, qreal ay)
    {
        xp = ax;
        yp = ay;
    }

    void moveTo(in QPointF p)
    {
        xp = p.x();
        yp = p.y();
    }

    QRectF translated(qreal dx, qreal dy) // conts
    { return QRectF(xp + dx, yp + dy, w, h); }

    QRectF translated(in QPointF p) // conts
    { return QRectF(xp + p.x(), yp + p.y(), w, h); }

    void getRect(qreal *ax, qreal *ay, qreal *aaw, qreal *aah) // conts
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

    void getCoords(qreal *xp1, qreal *yp1, qreal *xp2, qreal *yp2) // conts
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

    QRectF adjusted(qreal xp1, qreal yp1, qreal xp2, qreal yp2) // conts
    { return QRectF(xp + xp1, yp + yp1, w + xp2 - xp1, h + yp2 - yp1); }

    void setWidth(qreal aw) // for convenience
    { this.w = aw; }

    void setHeight(qreal ah) // for convenience
    { this.h = ah; }

    void setSize(in QSizeF s) // for convenience
    {
        w = s.width();
        h = s.height();
    }

    void width(qreal aw)
    { this.w = aw; }

    void height(qreal ah)
    { this.h = ah; }

    void size(in QSizeF s)
    {
        w = s.width();
        h = s.height();
    }

    bool contains(qreal ax, qreal ay) // conts
    {
        return contains(QPointF(ax, ay));
    }

    QRectF opOrAssign(in QRectF r)
    {
        *this = *this | r;
        return *this;
    }

    QRectF opAndAssign(in QRectF r)
    {
        *this = *this & r;
        return *this;
    }

    QRectF intersected(in QRectF r) // conts
    {
        return *this & r;
    }

    QRectF united(in QRectF r) // conts
    {
        return *this | r;
    }

    bool opEquals(in QRectF r)
    {
        return qFuzzyCompare(xp, r.xp) && qFuzzyCompare(yp, r.yp)
            && qFuzzyCompare(w, r.w) && qFuzzyCompare(h, r.h);
    }

    QRect toRect() // conts
    {
        return QRect(qRound(xp), qRound(yp), qRound(w), qRound(h));
    }

    public final bool contains(QPointF p) {
        return qtd_QRectF_contains_QPointF(this, &p);
    }

    public final bool contains(QRectF r) {
        return qtd_QRectF_contains_QRectF(this, &r);
    }

    public final bool intersects(QRectF r) {
        return qtd_QRectF_intersects_QRectF(this, &r);
    }

    public final QRectF normalized() {
        return qtd_QRectF_normalized(this);
    }

    public final QRectF opAnd(in QRectF r) {
        return qtd_QRectF_operator_and_QRectF(this, &r);
    }

    public final void writeTo(QDataStream arg__1) {
        qtd_QRectF_writeTo_QDataStream(this, arg__1 is null ? null : arg__1.__nativeId);
    }

    public final void readFrom(QDataStream arg__1) {
        qtd_QRectF_readFrom_QDataStream(this, arg__1 is null ? null : arg__1.__nativeId);
    }

    public final QRectF opOr(in QRectF r) {
        return qtd_QRectF_operator_or_QRectF(this, &r);
    }

    public final QRect toAlignedRect() // const
    {
        return qtd_QRectF_toAlignedRect(this);
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