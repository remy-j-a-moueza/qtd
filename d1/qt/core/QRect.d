module qt.core.QRect;

public import qt.QGlobal;
public import qt.core.Qt;

public import qt.core.QDataStream;
public import qt.core.QSize;
public import qt.core.QPoint;


public struct QRect
{
    public static QRect opCall() {
        QRect rt;
        rt.x1 = rt.y1 = 0;
        rt.x2 = rt.y2 = -1;
        return rt;
    }

    public static QRect opCall(int aleft, int atop, int awidth, int aheight)
    {
        QRect rt;
        rt.x1 = aleft;
        rt.y1 = atop;
        rt.x2 = (aleft + awidth - 1);
        rt.y2 = (atop + aheight - 1);
        return rt;
    }

    public static QRect opCall(in QPoint atopLeft, in QPoint abottomRight)
    {
        QRect rt;
        rt.x1 = atopLeft.x();
        rt.y1 = atopLeft.y();
        rt.x2 = abottomRight.x();
        rt.y2 = abottomRight.y();
        return rt;
    }

    public static QRect opCall(in QPoint atopLeft, in QSize asize)
    {
        QRect rt;
        rt.x1 = atopLeft.x();
        rt.y1 = atopLeft.y();
        rt.x2 = (rt.x1+asize.width() - 1);
        rt.y2 = (rt.y1+asize.height() - 1);
        return rt;
    }

    bool isNull() // const
    { return x2 == x1 - 1 && y2 == y1 - 1; }

    bool isEmpty() // const
    { return x1 > x2 || y1 > y2; }

    bool isValid() // const
    { return x1 <= x2 && y1 <= y2; }

    int left() // const
    { return x1; }

    int top() // const
    { return y1; }

    int right() // const
    { return x2; }

    int bottom() // const
    { return y2; }

    int x() // const
    { return x1; }

    int y() // const
    { return y1; }

    void left(int pos)
    { x1 = pos; }

    void top(int pos)
    { y1 = pos; }

    void right(int pos)
    { x2 = pos; }

    void bottom(int pos)
    { y2 = pos; }

    void setLeft(int pos)
    { x1 = pos; }

    void setTop(int pos)
    { y1 = pos; }

    void setRight(int pos)
    { x2 = pos; }

    void setBottom(int pos)
    { y2 = pos; }

    void setTopLeft(in QPoint p)
    { x1 = p.x(); y1 = p.y(); }

    void setBottomRight(in QPoint p)
    { x2 = p.x(); y2 = p.y(); }

    void setTopRight(in QPoint p)
    { x2 = p.x(); y1 = p.y(); }

    void setBottomLeft(in QPoint p)
    { x1 = p.x(); y2 = p.y(); }

    void setX(int ax)
    { x1 = ax; }

    void setY(int ay)
    { y1 = ay; }

    QPoint topLeft() // const
    { return QPoint(x1, y1); }

    QPoint bottomRight() // const
    { return QPoint(x2, y2); }

    QPoint topRight() // const
    { return QPoint(x2, y1); }

    QPoint bottomLeft() // const
    { return QPoint(x1, y2); }

    QPoint center() // const
    { return QPoint((x1+x2)/2, (y1+y2)/2); }

    int width() // const
    { return  x2 - x1 + 1; }

    int height() // const
    { return  y2 - y1 + 1; }

    QSize size() // const
    { return QSize(width(), height()); }

    void translate(int dx, int dy)
    {
        x1 += dx;
        y1 += dy;
        x2 += dx;
        y2 += dy;
    }

    void translate(in QPoint p)
    {
        x1 += p.x();
        y1 += p.y();
        x2 += p.x();
        y2 += p.y();
    }

    QRect translated(int dx, int dy) // const
    { return QRect(QPoint(x1 + dx, y1 + dy), QPoint(x2 + dx, y2 + dy)); }

    QRect translated(in QPoint p) // const
    { return QRect(QPoint(x1 + p.x(), y1 + p.y()), QPoint(x2 + p.x(), y2 + p.y())); }

    void moveTo(int ax, int ay)
    {
        x2 += ax - x1;
        y2 += ay - y1;
        x1 = ax;
        y1 = ay;
    }

    void moveTo(in QPoint p)
    {
        x2 += p.x() - x1;
        y2 += p.y() - y1;
        x1 = p.x();
        y1 = p.y();
    }

    void moveLeft(int pos)
    { x2 += (pos - x1); x1 = pos; }

    void moveTop(int pos)
    { y2 += (pos - y1); y1 = pos; }

    void moveRight(int pos)
    {
        x1 += (pos - x2);
        x2 = pos;
    }

    void moveBottom(int pos)
    {
        y1 += (pos - y2);
        y2 = pos;
    }

    void moveTopLeft(in QPoint p)
    {
        moveLeft(p.x());
        moveTop(p.y());
    }

    void moveBottomRight(in QPoint p)
    {
        moveRight(p.x());
        moveBottom(p.y());
    }

    void moveTopRight(in QPoint p)
    {
        moveRight(p.x());
        moveTop(p.y());
    }

    void moveBottomLeft(in QPoint p)
    {
        moveLeft(p.x());
        moveBottom(p.y());
    }

    void getRect(int *ax, int *ay, int *aw, int *ah) // const
    {
        *ax = x1;
        *ay = y1;
        *aw = x2 - x1 + 1;
        *ah = y2 - y1 + 1;
    }

    void setRect(int ax, int ay, int aw, int ah)
    {
        x1 = ax;
        y1 = ay;
        x2 = (ax + aw - 1);
        y2 = (ay + ah - 1);
    }

    void getCoords(int *xp1, int *yp1, int *xp2, int *yp2) // const
    {
        *xp1 = x1;
        *yp1 = y1;
        *xp2 = x2;
        *yp2 = y2;
    }

    void setCoords(int xp1, int yp1, int xp2, int yp2)
    {
        x1 = xp1;
        y1 = yp1;
        x2 = xp2;
        y2 = yp2;
    }

    QRect adjusted(int xp1, int yp1, int xp2, int yp2) // const
    { return QRect(QPoint(x1 + xp1, y1 + yp1), QPoint(x2 + xp2, y2 + yp2)); }

    void adjust(int dx1, int dy1, int dx2, int dy2)
    {
        x1 += dx1;
        y1 += dy1;
        x2 += dx2;
        y2 += dy2;
    }

    void setWidth(int w)
    { x2 = (x1 + w - 1); }

    void setHeight(int h)
    { y2 = (y1 + h - 1); }

    void setSize(in QSize s)
    {
        x2 = (s.width()  + x1 - 1);
        y2 = (s.height() + y1 - 1);
    }

    bool contains(int ax, int ay, bool aproper) // const
    {
        return contains(QPoint(ax, ay), aproper);
    }

    bool contains(int ax, int ay) // const
    {
        return contains(QPoint(ax, ay), false);
    }

    QRect opOrAssign(in QRect r)
    {
        *this = *this | r;
        return *this;
    }

    QRect opAndAssign(in QRect r)
    {
        *this = *this & r;
        return *this;
    }

    QRect intersected(in QRect other) // const
    {
        return *this & other;
    }

    QRect united(in QRect r) // const
    {
        return *this | r;
    }

    bool opEquals(in QRect r)
    {
        return x1==r.x1 && x2==r.x2 && y1==r.y1 && y2==r.y2;
    }

    public final void writeTo(QDataStream arg__1) {
        qtd_QRect_writeTo_QDataStream(this, arg__1 is null ? null : arg__1.__nativeId);
    }

    public final void readFrom(QDataStream arg__1) {
        qtd_QRect_readFrom_QDataStream(this, arg__1 is null ? null : arg__1.__nativeId);
    }

    public final QRect opAnd(in QRect r) {
        return qtd_QRect_operator_and_QRect(this, &r);
    }

    public final QRect opOr(in QRect r) {
        return qtd_QRect_operator_or_QRect(this, &r);
    }

    public final bool contains(QPoint p, bool proper = false) {
        return qtd_QRect_contains_QPoint_bool(this, &p, proper);
    }

    public final bool contains(QRect r, bool proper = false) {
        return qtd_QRect_contains_QRect_bool(this, &r, proper);
    }

    public final bool intersects(QRect r) {
        return qtd_QRect_intersects_QRect(this, &r);
    }

    public final QRect normalized() {
        return qtd_QRect_normalized(this);
    }

private:
    version(OSX)
    {
        int y1;
        int x1;
        int y2;
        int x2;
    }
    else
    {
        int x1;
        int y1;
        int x2;
        int y2;
    }
}


// C wrappers
private extern(C) bool  qtd_QRect_contains_QPoint_bool(void* __this_nativeId,
 void* p0,
 bool proper1);
private extern(C) bool  qtd_QRect_contains_QRect_bool(void* __this_nativeId,
 void* r0,
 bool proper1);
private extern(C) bool  qtd_QRect_intersects_QRect(void* __this_nativeId,
 void* r0);
private extern(C) QRect  qtd_QRect_normalized(void* __this_nativeId);
private extern(C) void  qtd_QRect_writeTo_QDataStream(void* __this_nativeId,
 void* arg__1);
private extern(C) void  qtd_QRect_readFrom_QDataStream(void* __this_nativeId,
 void* arg__1);
private extern(C) QRect  qtd_QRect_operator_and_QRect(void* __this_nativeId,
 void* r0);
private extern(C) QRect  qtd_QRect_operator_or_QRect(void* __this_nativeId,
 void* r0);