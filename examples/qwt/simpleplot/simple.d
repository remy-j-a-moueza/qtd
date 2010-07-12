module simple;

import std.math;

import qt.gui.QApplication;
import qt.qwt.QwtPlot;
import qt.qwt.QwtPlotMarker;
import qt.qwt.QwtPlotCurve;
import qt.qwt.QwtLegend;
import qt.qwt.QwtData;
import qt.qwt.QwtText;

//-----------------------------------------------------------------
//              simple.d
//
//      A simple example which shows how to use QwtPlot and QwtData
//-----------------------------------------------------------------

// hack to avoid linker error (undefined symbols), possibly a compiler bug
real mysin(real arg)
{
    return sin(arg);
}

real mycos(real arg)
{
    return cos(arg);
}

alias real function(real) double_func;

class SimpleData: QwtData
{
    // The x values depend on its index and the y values
    // can be calculated from the corresponding x value.
    // So we don't need to store the values.
    // Such an implementation is slower because every point
    // has to be recalculated for every replot, but it demonstrates how
    // QwtData can be used.

public:
    this(const double_func y, size_t size)
    {
        d_size = size;
        d_y = y;
    }

    QwtData copy() const
    {
        return new SimpleData(d_y, d_size);
    }

    size_t size() const
    {
        return d_size;
    }

    double x(size_t i) const
    {
        return 0.1 * i;
    }

    double y(size_t i) const
    {
        return d_y(x(i));
    }
private:
    size_t d_size;
    const double_func d_y;
};

class Plot : QwtPlot
{
public:
    this()
    {
        setTitle("A Simple QwtPlot Demonstration");
        insertLegend(new QwtLegend(), QwtPlot.RightLegend);

        // Set axis titles
        setAxisTitle(xBottom, "x -->");
        setAxisTitle(yLeft, "y -->");

        // Insert new curves
        auto cSin = new QwtPlotCurve("y = sin(x)");
        cSin.setRenderHint(QwtPlotItem.RenderAntialiased);
        cSin.setPen(new QPen(new QColor(Qt.red)));
        cSin.attach(this);

        auto cCos = new QwtPlotCurve("y = cos(x)");
        cCos.setRenderHint(QwtPlotItem.RenderAntialiased);
        cCos.setPen(new QPen(new QColor(Qt.blue)));
        cCos.attach(this);

        // Create sin and cos data
        const int nPoints = 100;
        cSin.setData(new SimpleData(&mysin, nPoints));
        cCos.setData(new SimpleData(&mycos, nPoints));

        // Insert markers

        //  ...a horizontal line at y = 0...
        auto mY = new QwtPlotMarker();
        mY.setLabel(new QwtText("y = 0"));
        mY.setLabelAlignment(Qt.AlignRight | Qt.AlignTop);
        mY.setLineStyle(QwtPlotMarker.HLine);
        mY.setYValue(0.0);
        mY.attach(this);

        //  ...a vertical line at x = 2 * pi
        auto mX = new QwtPlotMarker();
        mX.setLabel(new QwtText("x = 2 pi"));
        mX.setLabelAlignment(Qt.AlignLeft | Qt.AlignBottom);
        mX.setLabelOrientation(Qt.Vertical);
        mX.setLineStyle(QwtPlotMarker.VLine);
        mX.setLinePen(new QPen(new QBrush(Qt.black), 0, Qt.DashDotLine));
        mX.setXValue(2.0 * PI);
        mX.attach(this);
    }

};

int main(string[] args)
{
    auto a = new QApplication(args);

    scope plot = new Plot;
    plot.resize(600,400);
    plot.show();
    return a.exec();
}
