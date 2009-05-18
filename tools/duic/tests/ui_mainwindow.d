/********************************************************************************
** Form generated from reading ui file 'mainwindow.ui'
**
** Created: Mon May 18 06:21:12 2009
**      by: QtD User Interface Compiler version 4.5.0
**
** WARNING! All changes made in this file will be lost when recompiling ui file!
********************************************************************************/

module ui.MainWindow;

import qt.core.QVariant;
import qt.gui.QAction;
import qt.gui.QApplication;
import qt.gui.QButtonGroup;
import qt.gui.QDockWidget;
import qt.gui.QDoubleSpinBox;
import qt.gui.QFontComboBox;
import qt.gui.QFrame;
import qt.gui.QGroupBox;
import qt.gui.QHBoxLayout;
import qt.gui.QListView;
import qt.gui.QMainWindow;
import qt.gui.QMenu;
import qt.gui.QMenuBar;
import qt.gui.QRadioButton;
import qt.gui.QStatusBar;
import qt.gui.QToolBar;
import qt.gui.QTreeView;
import qt.gui.QVBoxLayout;
import qt.gui.QWidget;

mixin QT_BEGIN_NAMESPACE;

template Ui_MainWindow
{
public:
    QAction actionOpen;
    QAction actionClose;
    QAction actionQuit;
    QAction actionCopy;
    QAction actionPaste;
    QAction actionCut;
    QWidget centralwidget;
    QVBoxLayout verticalLayout_3;
    QWidget widget;
    QHBoxLayout horizontalLayout_2;
    QFontComboBox fontComboBox;
    QDoubleSpinBox doubleSpinBox;
    QFrame frame;
    QVBoxLayout verticalLayout_2;
    QListView listView;
    QTreeView treeView;
    QMenuBar menubar;
    QMenu menuFile;
    QMenu menuEdit;
    QStatusBar statusbar;
    QToolBar toolBar;
    QDockWidget dockWidget;
    QWidget dockWidgetContents;
    QHBoxLayout horizontalLayout;
    QGroupBox groupBox;
    QVBoxLayout verticalLayout;
    QRadioButton radioButton;
    QRadioButton radioButton_2;
    QRadioButton radioButton_3;

    void setupUi(QMainWindow *MainWindow)
    {
    if (MainWindow.objectName().isEmpty())
        MainWindow.setObjectName(QString.fromUtf8("MainWindow"));
    MainWindow.resize(800, 600);
    actionOpen = new QAction(MainWindow);
    actionOpen.setObjectName(QString.fromUtf8("actionOpen"));
    actionClose = new QAction(MainWindow);
    actionClose.setObjectName(QString.fromUtf8("actionClose"));
    actionQuit = new QAction(MainWindow);
    actionQuit.setObjectName(QString.fromUtf8("actionQuit"));
    actionCopy = new QAction(MainWindow);
    actionCopy.setObjectName(QString.fromUtf8("actionCopy"));
    actionPaste = new QAction(MainWindow);
    actionPaste.setObjectName(QString.fromUtf8("actionPaste"));
    actionCut = new QAction(MainWindow);
    actionCut.setObjectName(QString.fromUtf8("actionCut"));
    centralwidget = new QWidget(MainWindow);
    centralwidget.setObjectName(QString.fromUtf8("centralwidget"));
    verticalLayout_3 = new QVBoxLayout(centralwidget);
    verticalLayout_3.setObjectName(QString.fromUtf8("verticalLayout_3"));
    widget = new QWidget(centralwidget);
    widget.setObjectName(QString.fromUtf8("widget"));
    horizontalLayout_2 = new QHBoxLayout(widget);
    horizontalLayout_2.setObjectName(QString.fromUtf8("horizontalLayout_2"));
    fontComboBox = new QFontComboBox(widget);
    fontComboBox.setObjectName(QString.fromUtf8("fontComboBox"));

    horizontalLayout_2.addWidget(fontComboBox);

    doubleSpinBox = new QDoubleSpinBox(widget);
    doubleSpinBox.setObjectName(QString.fromUtf8("doubleSpinBox"));

    horizontalLayout_2.addWidget(doubleSpinBox);


    verticalLayout_3.addWidget(widget);

    frame = new QFrame(centralwidget);
    frame.setObjectName(QString.fromUtf8("frame"));
    frame.setFrameShape(QFrame.QFrame::StyledPanel);
    frame.setFrameShadow(QFrame.QFrame::Raised);
    verticalLayout_2 = new QVBoxLayout(frame);
    verticalLayout_2.setObjectName(QString.fromUtf8("verticalLayout_2"));
    listView = new QListView(frame);
    listView.setObjectName(QString.fromUtf8("listView"));

    verticalLayout_2.addWidget(listView);

    treeView = new QTreeView(frame);
    treeView.setObjectName(QString.fromUtf8("treeView"));

    verticalLayout_2.addWidget(treeView);


    verticalLayout_3.addWidget(frame);

    MainWindow.setCentralWidget(centralwidget);
    menubar = new QMenuBar(MainWindow);
    menubar.setObjectName(QString.fromUtf8("menubar"));
    menubar.setGeometry(QRect(0, 0, 800, 27));
    menuFile = new QMenu(menubar);
    menuFile.setObjectName(QString.fromUtf8("menuFile"));
    menuEdit = new QMenu(menubar);
    menuEdit.setObjectName(QString.fromUtf8("menuEdit"));
    MainWindow.setMenuBar(menubar);
    statusbar = new QStatusBar(MainWindow);
    statusbar.setObjectName(QString.fromUtf8("statusbar"));
    MainWindow.setStatusBar(statusbar);
    toolBar = new QToolBar(MainWindow);
    toolBar.setObjectName(QString.fromUtf8("toolBar"));
    MainWindow.addToolBar(Qt.TopToolBarArea, toolBar);
    dockWidget = new QDockWidget(MainWindow);
    dockWidget.setObjectName(QString.fromUtf8("dockWidget"));
    dockWidgetContents = new QWidget();
    dockWidgetContents.setObjectName(QString.fromUtf8("dockWidgetContents"));
    horizontalLayout = new QHBoxLayout(dockWidgetContents);
    horizontalLayout.setObjectName(QString.fromUtf8("horizontalLayout"));
    groupBox = new QGroupBox(dockWidgetContents);
    groupBox.setObjectName(QString.fromUtf8("groupBox"));
    verticalLayout = new QVBoxLayout(groupBox);
    verticalLayout.setObjectName(QString.fromUtf8("verticalLayout"));
    radioButton = new QRadioButton(groupBox);
    radioButton.setObjectName(QString.fromUtf8("radioButton"));

    verticalLayout.addWidget(radioButton);

    radioButton_2 = new QRadioButton(groupBox);
    radioButton_2.setObjectName(QString.fromUtf8("radioButton_2"));

    verticalLayout.addWidget(radioButton_2);

    radioButton_3 = new QRadioButton(groupBox);
    radioButton_3.setObjectName(QString.fromUtf8("radioButton_3"));

    verticalLayout.addWidget(radioButton_3);


    horizontalLayout.addWidget(groupBox);

    dockWidget.setWidget(dockWidgetContents);
    MainWindow.addDockWidget((cast(Qt.DockWidgetArea)(2)), dockWidget);

    menubar.addAction(menuFile.menuAction());
    menubar.addAction(menuEdit.menuAction());
    menuFile.addAction(actionOpen);
    menuFile.addAction(actionClose);
    menuFile.addAction(actionQuit);
    menuEdit.addAction(actionCopy);
    menuEdit.addAction(actionPaste);
    menuEdit.addAction(actionCut);
    toolBar.addAction(actionOpen);
    toolBar.addAction(actionQuit);

    retranslateUi(MainWindow);
    QObject.connect(actionQuit, SIGNAL(activated(int)), MainWindow, SLOT(close()));

    QMetaObject.connectSlotsByName(MainWindow);
    } // setupUi

    void retranslateUi(QMainWindow *MainWindow)
    {
    MainWindow.setWindowTitle(QApplication.translate("MainWindow", "MainWindow", 0, QApplication.UnicodeUTF8));
    actionOpen.setText(QApplication.translate("MainWindow", "Open", 0, QApplication.UnicodeUTF8));
    actionClose.setText(QApplication.translate("MainWindow", "Close", 0, QApplication.UnicodeUTF8));
    actionQuit.setText(QApplication.translate("MainWindow", "Quit", 0, QApplication.UnicodeUTF8));
    actionCopy.setText(QApplication.translate("MainWindow", "Copy", 0, QApplication.UnicodeUTF8));
    actionPaste.setText(QApplication.translate("MainWindow", "Paste", 0, QApplication.UnicodeUTF8));
    actionCut.setText(QApplication.translate("MainWindow", "Cut", 0, QApplication.UnicodeUTF8));
    menuFile.setTitle(QApplication.translate("MainWindow", "File", 0, QApplication.UnicodeUTF8));
    menuEdit.setTitle(QApplication.translate("MainWindow", "Edit", 0, QApplication.UnicodeUTF8));
    toolBar.setWindowTitle(QApplication.translate("MainWindow", "toolBar", 0, QApplication.UnicodeUTF8));
    groupBox.setTitle(QApplication.translate("MainWindow", "Some options", 0, QApplication.UnicodeUTF8));
    radioButton.setText(QApplication.translate("MainWindow", "Option 1", 0, QApplication.UnicodeUTF8));
    radioButton_2.setText(QApplication.translate("MainWindow", "Option 2", 0, QApplication.UnicodeUTF8));
    radioButton_3.setText(QApplication.translate("MainWindow", "Option 3", 0, QApplication.UnicodeUTF8));
    } // retranslateUi

}

struct MainWindow {
    mixin Ui_MainWindow;
}
mixin QT_END_NAMESPACE;

