module qt.core.QPoint;

public import qt.QGlobal;
public import qt.core.Qt;
public import qt.core.QDataStream;


public struct QPoint
{

// Functions
    public static QPoint opCall() {
        QPoint pt;
        pt.xp = pt.yp = 0;
        return pt;
    }

    public this(int xpos, int ypos) {
        xp = xpos;
        yp = ypos;
    }

    bool isNull() // const
    { return xp == 0 && yp == 0; }

    int x() const
    { return xp; }

    int y() const
    { return yp; }

    void x(int xpos)
    { xp = xpos; }

    void y(int ypos)
    { yp = ypos; }

    void setX(int xpos) // for convenience
        { xp = xpos; }

    void setY(int ypos) // for convenience
        { yp = ypos; }

    public final int manhattanLength() {
        return qtd_QPoint_manhattanLength(&this);
    }
/*
inline int &rx()
{ return xp; }

inline int &ry()
{ return yp; }
*/

    QPoint opAddAssign(ref QPoint p)
    { xp+=p.xp; yp+=p.yp; return this; }

    QPoint opSubAssign(ref QPoint p)
    { xp-=p.xp; yp-=p.yp; return this; }

    QPoint opMulAssign(qreal c)
    { xp = qRound(xp*c); yp = qRound(yp*c); return this; }

    bool opEquals(ref const QPoint p) const
    { return xp == p.xp && yp == p.yp; }

    QPoint opAdd(ref QPoint p)
    { return QPoint(this.xp+p.xp, this.yp+p.yp); }

    QPoint opSub(ref QPoint p)
    { return QPoint(this.xp-p.xp, this.yp-p.yp); }

    QPoint opMul(qreal c)
    { return QPoint(qRound(this.xp*c), qRound(this.yp*c)); }

    QPoint opDivAssign(qreal c)
    {
        xp = qRound(xp/c);
        yp = qRound(yp/c);
        return this;
    }

    QPoint opDiv(qreal c)
    {
        return QPoint(qRound(this.xp/c), qRound(this.yp/c));
    }

    public final void writeTo(QDataStream arg__1) {
        qtd_QPoint_writeTo_QDataStream(&this, arg__1 is null ? null : arg__1.qtdNativeId);
    }

    public final void readFrom(QDataStream arg__1) {
        qtd_QPoint_readFrom_QDataStream(&this, arg__1 is null ? null : arg__1.qtdNativeId);
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
    // ### Qt 5;  remove the ifdef and just have the same order on all platforms.
    version(OSX)
    {
        int yp;
        int xp;
    }
    else
    {
        int xp;
        int yp;
    }
}


public struct QPointF
{
    public static QPointF opCall() {
        QPointF pt;
        pt.xp = pt.yp = 0;
        return pt;
    }

    public this(qreal xpos, qreal ypos) {
        xp = xpos;
        yp = ypos;
    }

    public this(QPoint p) {
        xp = p.x();
        yp = p.y();
    }

    bool isNull() const
    {
        return qIsNull(xp) && qIsNull(yp);
    }

    qreal x() const
    {
        return xp;
    }

    qreal y() const
    {
        return yp;
    }

    void x(qreal xpos)
    {
        xp = xpos;
    }

    void y(qreal ypos)
    {
        yp = ypos;
    }
/*
ref qreal rx()
{
        return xp;
}

ref qreal ry()
{
    return yp;
}
*/

    QPointF opAddAssign(ref QPointF p)
    { xp+=p.xp; yp+=p.yp; return this; }

    QPointF opSubAssign(ref QPointF p)
    { xp-=p.xp; yp-=p.yp; return this; }

    QPointF opMulAssign(qreal c)
    { xp*=c; yp*=c; return this; }

    bool opEquals(ref const QPointF p) const
    { return qFuzzyCompare(xp, p.xp) && qFuzzyCompare(yp, p.yp); }

    QPointF opAdd(ref QPointF p)
    { return QPointF(this.xp+p.xp, this.yp+p.yp); }

    QPointF opSub(ref QPointF p)
    { return QPointF(this.xp-p.xp, this.yp-p.yp); }

    QPointF opMul(qreal c)
    { return QPointF(this.xp*c, this.yp*c); }

    QPointF opDivAssign(qreal c)
    {
        xp/=c;
        yp/=c;
        return this;
    }

    QPointF opDiv(qreal c)
    {
        return QPointF(xp/c, yp/c);
    }

    QPoint toPoint() const
    {
        return QPoint(qRound(xp), qRound(yp));
    }

    public final void writeTo(QDataStream arg__1) {
        qtd_QPointF_writeTo_QDataStream(&this, arg__1 is null ? null : arg__1.qtdNativeId);
    }

    public final void readFrom(QDataStream arg__1) {
        qtd_QPointF_readFrom_QDataStream(&this, arg__1 is null ? null : arg__1.qtdNativeId);
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
}


// C wrappers
// QPoint
private extern(C) int  qtd_QPoint_manhattanLength(void* __this_nativeId);
private extern(C) void  qtd_QPoint_writeTo_QDataStream(void* __this_nativeId,
 void* arg__1);
private extern(C) void  qtd_QPoint_readFrom_QDataStream(void* __this_nativeId,
 void* arg__1);

// QPointF
private extern(C) void  qtd_QPointF_writeTo_QDataStream(void* __this_nativeId,
 void* arg__1);
private extern(C) void  qtd_QPointF_readFrom_QDataStream(void* __this_nativeId,
 void* arg__1);
