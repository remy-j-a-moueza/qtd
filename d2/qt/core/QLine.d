module qt.core.QLine;

public import qt.QGlobal;
public import qt.core.Qt;
public import qt.core.QPoint;
public import qt.core.QDataStream;


public struct QLine
{
    public static QLine opCall() {
        QLine ln;
        ln.pt1 = QPoint();
        ln.pt2 = QPoint();
        return ln;
    }

    public this(QPoint pt1_, QPoint pt2_) {
        pt1 = pt1_;
        pt2 = pt2_;
    }

    public this(int x1pos, int y1pos, int x2pos, int y2pos) {
        pt1 = QPoint(x1pos, y1pos);
        pt2 = QPoint(x2pos, y2pos);
    }

    bool isNull() // const
    {
        return pt1 == pt2;
    }

    int x1() // const
    {
        return pt1.x();
    }

    int y1() // const
    {
        return pt1.y();
    }

    int x2() // const
    {
        return pt2.x();
    }

    int y2() // const
    {
        return pt2.y();
    }

    QPoint p1() // const
    {
        return pt1;
    }

    QPoint p2() // const
    {
        return pt2;
    }

    int dx() // const
    {
        return pt2.x() - pt1.x();
    }

    int dy() // const
    {
        return pt2.y() - pt1.y();
    }

    void translate(ref QPoint point)
    {
        pt1 += point;
        pt2 += point;
    }

    void translate(int adx, int ady)
    {
        translate(QPoint(adx, ady));
    }

    QLine translated(ref QPoint p) // const
    {
        return QLine(pt1 + p, pt2 + p);
    }

    QLine translated(int adx, int ady) // const
    {
        return translated(QPoint(adx, ady));
    }

    void p1(ref QPoint aP1)
    {
        pt1 = aP1;
    }

    void p2(ref QPoint aP2)
    {
        pt2 = aP2;
    }

    void setP1(ref QPoint aP1) // for convenience
    {
        pt1 = aP1;
    }

    void setP2(ref QPoint aP2) // for convenience
    {
        pt2 = aP2;
    }

    void setPoints(ref QPoint aP1, ref QPoint aP2)
    {
        pt1 = aP1;
        pt2 = aP2;
    }

    void setLine(int aX1, int aY1, int aX2, int aY2)
    {
        pt1 = QPoint(aX1, aY1);
        pt2 = QPoint(aX2, aY2);
    }

    bool opEquals(ref const QLine d) const
    {
        return pt1 == d.pt1 && pt2 == d.pt2;
    }

    public final void writeTo(QDataStream arg__1) {
        qtd_QLine_writeTo_QDataStream(&this, arg__1 is null ? null : arg__1.qtdNativeId);
    }

    public final void readFrom(QDataStream arg__1) {
        qtd_QLine_readFrom_QDataStream(&this, arg__1 is null ? null : arg__1.qtdNativeId);
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
    QPoint pt1, pt2;
}


public enum QLineF_IntersectType {
    NoIntersection = 0,
    BoundedIntersection = 1,
    UnboundedIntersection = 2
}

public struct QLineF
{

    alias QLineF_IntersectType IntersectType;

    alias QLineF_IntersectType.NoIntersection NoIntersection;
    alias QLineF_IntersectType.BoundedIntersection BoundedIntersection;
    alias QLineF_IntersectType.UnboundedIntersection UnboundedIntersection;

    public static QLineF opCall() {
        QLineF ln;
        ln.pt1 = QPointF();
        ln.pt2 = QPointF();
        return ln;
    }

    public this(QPointF apt1, QPointF apt2) {
        pt1 = apt1;
        pt2 = apt2;
    }

    public this(qreal x1pos, qreal y1pos, qreal x2pos, qreal y2pos) {
        pt1 = QPointF(x1pos, y1pos);
        pt2 = QPointF(x2pos, y2pos);
    }

    public this(QLine line){
        pt1 = QPointF(line.p1());
        pt2 = QPointF(line.p2());
    }

    public final bool isNull() // const
    {
        return qtd_QLineF_isNull(&this);
    }

    qreal x1() // const
    {
        return pt1.x();
    }

    qreal y1() // const
    {
        return pt1.y();
    }

    qreal x2() // const
    {
        return pt2.x();
    }

    qreal y2() // const
    {
        return pt2.y();
    }

    QPointF p1() // const
    {
        return pt1;
    }

    QPointF p2() // const
    {
        return pt2;
    }

    qreal dx() // const
    {
        return pt2.x() - pt1.x();
    }

    qreal dy() // const
    {
        return pt2.y() - pt1.y();
    }

    QLineF normalVector() // const
    {
        return QLineF(p1(), p1() + QPointF(dy(), -dx()));
    }

    void translate(ref QPointF point)
    {
        pt1 += point;
        pt2 += point;
    }

    void translate(qreal adx, qreal ady)
    {
        this.translate(QPointF(adx, ady));
    }

    QLineF translated(ref QPointF p) // const
    {
        return QLineF(pt1 + p, pt2 + p);
    }

    QLineF translated(qreal adx, qreal ady) // const
    {
        return translated(QPointF(adx, ady));
    }

    void setLength(qreal len)
    {
        if (isNull())
            return;
        QLineF v = unitVector();
        pt2 = QPointF(pt1.x() + v.dx() * len, pt1.y() + v.dy() * len);
    }

    void length(qreal len)
    {
        if (isNull())
            return;
        QLineF v = unitVector();
        pt2 = QPointF(pt1.x() + v.dx() * len, pt1.y() + v.dy() * len);
    }

    QPointF pointAt(qreal t) // const
    {
        qreal vx = pt2.x() - pt1.x();
        qreal vy = pt2.y() - pt1.y();
        return QPointF(pt1.x() + vx * t, pt1.y() + vy * t);
    }

    QLine toLine() // const
    {
        return QLine(pt1.toPoint(), pt2.toPoint());
    }

    void setP1(ref QPointF aP1)
    {
        pt1 = aP1;
    }

    void setP2(ref QPointF aP2)
    {
        pt2 = aP2;
    }

    void p1(ref QPointF aP1)
    {
        pt1 = aP1;
    }

    void p2(ref QPointF aP2)
    {
        pt2 = aP2;
    }

    void setPoints(ref QPointF aP1, ref QPointF aP2)
    {
        pt1 = aP1;
        pt2 = aP2;
    }

    void setLine(qreal aX1, qreal aY1, qreal aX2, qreal aY2)
    {
        pt1 = QPointF(aX1, aY1);
        pt2 = QPointF(aX2, aY2);
    }

    bool opEquals(ref const QLineF d) const
    {
        return pt1 == d.pt1 && pt2 == d.pt2;
    }

    public final double angle() {
        return qtd_QLineF_angle(&this);
    }

    public final double angle(ref QLineF l) {
        return qtd_QLineF_angle_QLineF(&this, &l);
    }

    public final double angleTo(ref QLineF l) {
        return qtd_QLineF_angleTo_QLineF(&this, &l);
    }

    // ### Qt 5: rename intersects() or intersection() and rename IntersectType IntersectionType
    private final QLineF_IntersectType intersect(ref QLineF l, QPointF* intersectionPoint) {
        return cast(QLineF_IntersectType) qtd_QLineF_intersect_QLineF_nativepointerQPointF(&this, &l, intersectionPoint);
    }

    public final double length() {
        return qtd_QLineF_length(&this);
    }

    public final void writeTo(QDataStream arg__1) {
        qtd_QLineF_writeTo_QDataStream(&this, arg__1 is null ? null : arg__1.qtdNativeId);
    }

    public final void readFrom(QDataStream arg__1) {
        qtd_QLineF_readFrom_QDataStream(&this, arg__1 is null ? null : arg__1.qtdNativeId);
    }

    public final void setAngle(double angle) {
        qtd_QLineF_setAngle_double(&this, angle);
    }

    public final QLineF unitVector() {
        return qtd_QLineF_unitVector(&this);
    }

    public static QLineF fromPolar(double length, double angle) {
        return qtd_QLineF_fromPolar_double_double(length, angle);
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
        QPointF pt1, pt2;
}


// C wrappers
// QLine
private extern(C) void  qtd_QLine_writeTo_QDataStream(void* __this_nativeId,
 void* arg__1);
private extern(C) void  qtd_QLine_readFrom_QDataStream(void* __this_nativeId,
 void* arg__1);

// QLineF
private extern(C) bool  qtd_QLineF_isNull(void* __this_nativeId);
private extern(C) double  qtd_QLineF_angle(void* __this_nativeId);
private extern(C) double  qtd_QLineF_angle_QLineF(void* __this_nativeId,
 void* l0);
private extern(C) double  qtd_QLineF_angleTo_QLineF(void* __this_nativeId,
 void* l0);
private extern(C) int  qtd_QLineF_intersect_QLineF_nativepointerQPointF(void* __this_nativeId,
 void* l0,
 void* intersectionPoint1);
private extern(C) double  qtd_QLineF_length(void* __this_nativeId);
private extern(C) void  qtd_QLineF_writeTo_QDataStream(void* __this_nativeId,
 void* arg__1);
private extern(C) void  qtd_QLineF_readFrom_QDataStream(void* __this_nativeId,
 void* arg__1);
private extern(C) void  qtd_QLineF_setAngle_double(void* __this_nativeId,
 double angle0);

private extern(C) QLineF  qtd_QLineF_unitVector(void* __this_nativeId);
private extern(C) QLineF  qtd_QLineF_fromPolar_double_double(double length0,
 double angle1);
