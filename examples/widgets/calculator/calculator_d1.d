/****************************************************************************
**
** Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies).
** Contact: Qt Software Information (qt-info@nokia.com)
**
** This file is part of the example classes of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:LGPL$
** Commercial Usage
** Licensees holding valid Qt Commercial licenses may use this file in
** accordance with the Qt Commercial License Agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and Nokia.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 2.1 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPL included in the
** packaging of this file.  Please review the following information to
** ensure the GNU Lesser General Public License version 2.1 requirements
** will be met: http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
**
** In addition, as a special exception, Nokia gives you certain
** additional rights. These rights are described in the Nokia Qt LGPL
** Exception version 1.0, included in the file LGPL_EXCEPTION.txt in this
** package.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3.0 as published by the Free Software
** Foundation and appearing in the file LICENSE.GPL included in the
** packaging of this file.  Please review the following information to
** ensure the GNU General Public License version 3.0 requirements will be
** met: http://www.gnu.org/copyleft/gpl.html.
**
** If you are unsure which license is appropriate for your use, please
** contact the sales department at qt-sales@nokia.com.
** $QT_END_LICENSE$
**
****************************************************************************/

module calculator_d1;

import button;
import qt.gui.QDialog;
import qt.gui.QGridLayout;
import qt.gui.QLineEdit;
import qt.gui.QFont;

import tango.math.Math;     
import tango.math.Math : pow, sqrt;
import Float = tango.text.convert.Float;
import Integer = tango.text.convert.Integer;
import tango.core.Array;    

class Calculator : public QDialog
{
        
public:
        
        this(QWidget parent = null)
        {
                super(parent);

                sumInMemory = 0.0;
                sumSoFar = 0.0;
                factorSoFar = 0.0;
                waitingForOperand = true;

                display = new QLineEdit("0");
                display.setReadOnly(true);
                display.setAlignment(Qt.AlignRight);
                display.setMaxLength(15);

		auto font = new QFont(display.font());
                font.setPointSize(font.pointSize() + 8);
                display.setFont(font);

                for (int i = 0; i < NumDigitButtons; ++i) {
                        digitButtons[i] = createButton(Integer.toString(i), &digitClicked);
                }

                Button pointButton = createButton(tr("."), &pointClicked);
                Button changeSignButton = createButton(tr("+/-"), &changeSignClicked);

                Button backspaceButton = createButton(tr("Backspace"), &backspaceClicked);
                Button clearButton = createButton(tr("Clear"), &clear);
                Button clearAllButton = createButton(tr("Clear All"), &clearAll);

                Button clearMemoryButton = createButton(tr("MC"), &clearMemory);
                Button readMemoryButton = createButton(tr("MR"), &readMemory);
                Button setMemoryButton = createButton(tr("MS"), &setMemory);
                Button addToMemoryButton = createButton(tr("M+"), &addToMemory);

                Button divisionButton = createButton(tr("/"), &multiplicativeOperatorClicked);
                Button timesButton = createButton(tr("*"), &multiplicativeOperatorClicked);
                Button minusButton = createButton(tr("-"), &additiveOperatorClicked);
                Button plusButton = createButton(tr("+"), &additiveOperatorClicked);

                Button squareRootButton = createButton(tr("Sqrt"), &unaryOperatorClicked);
                Button powerButton = createButton(tr("x^2"), &unaryOperatorClicked);
                Button reciprocalButton = createButton(tr("1/x"), &unaryOperatorClicked);
                Button equalButton = createButton(tr("="), &equalClicked);

                QGridLayout mainLayout = new QGridLayout();

                mainLayout.setSizeConstraint(QLayout.SetFixedSize);

                mainLayout.addWidget(display, 0, 0, 1, 6);
                mainLayout.addWidget(backspaceButton, 1, 0, 1, 2);
                mainLayout.addWidget(clearButton, 1, 2, 1, 2);
                mainLayout.addWidget(clearAllButton, 1, 4, 1, 2);

                mainLayout.addWidget(clearMemoryButton, 2, 0);
                mainLayout.addWidget(readMemoryButton, 3, 0);
                mainLayout.addWidget(setMemoryButton, 4, 0);
                mainLayout.addWidget(addToMemoryButton, 5, 0);

                for (int i = 1; i < NumDigitButtons; ++i) {
                        int row = ((9 - i) / 3) + 2;
                        int column = ((i - 1) % 3) + 1;
                        mainLayout.addWidget(digitButtons[i], row, column);
                }

                mainLayout.addWidget(digitButtons[0], 5, 1);
                mainLayout.addWidget(pointButton, 5, 2);
                mainLayout.addWidget(changeSignButton, 5, 3);

                mainLayout.addWidget(divisionButton, 2, 4);
                mainLayout.addWidget(timesButton, 3, 4);
                mainLayout.addWidget(minusButton, 4, 4);
                mainLayout.addWidget(plusButton, 5, 4);

                mainLayout.addWidget(squareRootButton, 2, 5);
                mainLayout.addWidget(powerButton, 3, 5);
                mainLayout.addWidget(reciprocalButton, 4, 5);
                mainLayout.addWidget(equalButton, 5, 5);
                setLayout(mainLayout);

                setWindowTitle(tr("Calculator"));
        }

//private slots:
        void digitClicked()
        {
                Button clickedButton = cast(Button) signalSender();
                int digitValue = Integer.toInt(clickedButton.text);
                if (display.text() == "0" && digitValue == 0.0)
                        return;

                if (waitingForOperand) {
                        display.clear();
                        waitingForOperand = false;
                }
                display.setText(display.text() ~ Integer.toString(digitValue));
        }

        void unaryOperatorClicked()
        {
                Button clickedButton = cast(Button) signalSender();
                string clickedOperator = clickedButton.text();
                double operand = Float.toFloat(display.text);
                double result = 0.0;

                if (clickedOperator == tr("Sqrt")) {
                        if (operand < 0.0) {
                                abortOperation();
                                return;
                        }
                        result = sqrt(operand);
                } else if (clickedOperator == tr("x^2")) {
                        result = pow(operand, 2.0);
                } else if (clickedOperator == tr("1/x")) {
                        if (operand == 0.0) {
                                abortOperation();
                                return;
                        }
                        result = 1.0 / operand;
                }
                display.setText(Float.toString(result, 4));
                waitingForOperand = true;
        }

        void additiveOperatorClicked()
        {
                Button clickedButton = cast(Button) signalSender();
                string clickedOperator = clickedButton.text();
                double operand = Float.toFloat(display.text);

                if (pendingMultiplicativeOperator.length) {
                        if (!calculate(operand, pendingMultiplicativeOperator)) {
                                abortOperation();
                                return;
                        }
                        display.setText(Float.toString(factorSoFar, 4));
                        operand = factorSoFar;
                        factorSoFar = 0.0;
                        pendingMultiplicativeOperator = null;
                }

                if (pendingAdditiveOperator.length) {
                        if (!calculate(operand, pendingAdditiveOperator)) {
                                abortOperation();
                                return;
                        }
                        display.setText(Float.toString(sumSoFar, 4));
                } else {
                        sumSoFar = operand;
                }

                pendingAdditiveOperator = clickedOperator;
                waitingForOperand = true;
        }

        void multiplicativeOperatorClicked()
        {
                Button clickedButton = cast(Button) signalSender();
                string clickedOperator = clickedButton.text();
                double operand = Float.toFloat(display.text);

                if (pendingMultiplicativeOperator.length) {
                        if (!calculate(operand, pendingMultiplicativeOperator)) {
                                abortOperation();
                                return;
                        }
                        display.setText(Float.toString(factorSoFar, 4));
                } else {
                        factorSoFar = operand;
                }

                pendingMultiplicativeOperator = clickedOperator;
                waitingForOperand = true;
        }

        void equalClicked()
        {
                double operand = Float.toFloat(display.text);

                if (pendingMultiplicativeOperator.length) {
                        if (!calculate(operand, pendingMultiplicativeOperator)) {
                                abortOperation();
                                return;
                        }
                        operand = factorSoFar;
                        factorSoFar = 0.0;
                        pendingMultiplicativeOperator = null;
                }
                if (pendingAdditiveOperator.length) {
                        if (!calculate(operand, pendingAdditiveOperator)) {
                                abortOperation();
                                return;
                        }
                        pendingAdditiveOperator = null;
                } else {
                        sumSoFar = operand;
                }

                display.setText(Float.toString(sumSoFar, 4));
                sumSoFar = 0.0;
                waitingForOperand = true;
        }

        void pointClicked()
        {
                string text = display.text;

                if (waitingForOperand)
                        display.setText("0");

                if (find(text, '.') >= text.length)
                        display.setText(text ~ tr("."));
                
                waitingForOperand = false;
        }

        void changeSignClicked()
        {
                string text = display.text();
                double value = Float.toFloat(text);

                if (value > 0.0) {
                        text = "-" ~ text;
                } else if (value < 0.0) {
                        text = text[1..$];
                }
                display.setText(text);
        }

        void backspaceClicked()
        {
                if (waitingForOperand)
                        return;

                string text = display.text();
                text = text[0..$-1];
                if (text.length == 0) {
                        text = "0";
                        waitingForOperand = true;
                }
                display.setText(text);
        }


        void clear()
        {
                if (waitingForOperand)
                        return;

                display.setText("0");
                waitingForOperand = true;
        }

        void clearAll()
        {
                sumSoFar = 0.0;
                factorSoFar = 0.0;
                pendingAdditiveOperator = null;
                pendingMultiplicativeOperator = null;
                display.setText("0");
                waitingForOperand = true;
        }

        void clearMemory()
        {
                sumInMemory = 0.0;
        }

        void readMemory()
        {
                display.setText(Float.toString(sumInMemory, 4));
                waitingForOperand = true;
        }

        void setMemory()
        {
                equalClicked();
                sumInMemory = Float.toFloat(display.text);
        }

        void addToMemory()
        {
                equalClicked();
                sumInMemory += Float.toFloat(display.text);
        }

private:

        Button createButton(string text, void delegate() member)
        {
                Button button = new Button(text);
                connect!("clicked")(button, member);
                return button;
        }

        void abortOperation()
        {
                clearAll();
                display.setText(tr("####"));
        }

        bool calculate(double rightOperand, string pendingOperator)
        {
                if (pendingOperator == tr("+")) {
                        sumSoFar += rightOperand;
                } else if (pendingOperator == tr("-")) {
                        sumSoFar -= rightOperand;
                } else if (pendingOperator == tr("*")) {
                        factorSoFar *= rightOperand;
                } else if (pendingOperator == tr("/")) {
                        if (rightOperand == 0.0)
                                return false;
                        factorSoFar /= rightOperand;
                }
                return true;
        }

        double sumInMemory;
        double sumSoFar;
        double factorSoFar;
        string pendingAdditiveOperator;
        string pendingMultiplicativeOperator;
        bool waitingForOperand;

        QLineEdit display;

        enum { NumDigitButtons = 10 };
        Button[NumDigitButtons] digitButtons;
}
