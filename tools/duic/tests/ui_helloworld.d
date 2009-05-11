/********************************************************************************
** Form generated from reading ui file 'helloworld.ui'
**
** Created: Wed Dec 17 23:20:28 2008
**      by: QtD User Interface Compiler version 4.4.3
**
** WARNING! All changes made in this file will be lost when recompiling ui file!
********************************************************************************/

module ui.HelloWorldForm

import qt.core.QVariant;
import qt.gui.QAction;
import qt.gui.QApplication;
import qt.gui.QButtonGroup;
import qt.gui.QLabel;
import qt.gui.QVBoxLayout;
import qt.gui.QWidget;

mixin QT_BEGIN_NAMESPACE;

class Ui_HelloWorldForm
{
public:
    QVBoxLayout *verticalLayout;
    QLabel *label;

    void setupUi(QWidget *HelloWorldForm)
    {
    if (HelloWorldForm.objectName().isEmpty())
        HelloWorldForm.setObjectName(qt.core.QString.fromUtf8("HelloWorldForm"));
    HelloWorldForm.resize(96, 48);
    verticalLayout = new QVBoxLayout(HelloWorldForm);
    verticalLayout.setObjectName(qt.core.QString.fromUtf8("verticalLayout"));
    label = new QLabel(HelloWorldForm);
    label.setObjectName(qt.core.QString.fromUtf8("label"));

    verticalLayout.addWidget(label);


    retranslateUi(HelloWorldForm);

    QMetaObject.connectSlotsByName(HelloWorldForm);
    } // setupUi

    void retranslateUi(QWidget *HelloWorldForm)
    {
    HelloWorldForm.setWindowTitle(qt.gui.QApplication.translate("HelloWorldForm", "Form", 0, qt.gui.QApplication.UnicodeUTF8));
    label.setText(qt.gui.QApplication.translate("HelloWorldForm", "Hello World!", 0, qt.gui.QApplication.UnicodeUTF8));
    Q_UNUSED(HelloWorldForm);
    } // retranslateUi

};

mixin QT_END_NAMESPACE;

