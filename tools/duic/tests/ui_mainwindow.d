/********************************************************************************
** Form generated from reading ui file 'mainwindow.ui'
**
** Created: Sat May 30 11:51:12 2009
**      by: QtD User Interface Compiler version 4.5.0
**
** WARNING! All changes made in this file will be lost when recompiling ui file!
********************************************************************************/

module ui_mainwindow;

public import qt.core.QString;
public import qt.core.QVariant;
public import qt.gui.QAction;
public import qt.gui.QApplication;
public import qt.gui.QButtonGroup;
public import qt.gui.QDockWidget;
public import qt.gui.QDoubleSpinBox;
public import qt.gui.QFontComboBox;
public import qt.gui.QFrame;
public import qt.gui.QGroupBox;
public import qt.gui.QHBoxLayout;
public import qt.gui.QListView;
public import qt.gui.QMainWindow;
public import qt.gui.QMenu;
public import qt.gui.QMenuBar;
public import qt.gui.QRadioButton;
public import qt.gui.QStatusBar;
public import qt.gui.QToolBar;
public import qt.gui.QTreeView;
public import qt.gui.QVBoxLayout;
public import qt.gui.QWidget;

mixin QT_BEGIN_NAMESPACE;

template Ui_MainWindow()
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

    void setupUi(QMainWindow MainWindow)
    {
    if (MainWindow.objectName().length == 0)
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
    frame.setFrameShape(QFrame.StyledPanel);
    frame.setFrameShadow(QFrame.Raised);
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
    menubar.setGeometry(QRect(0, 0, 800, 24));
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
    actionQuit.triggered.connect(&MainWindow.close);

    // QMetaObject.connectSlotsByName(MainWindow);
    } // setupUi

    void retranslateUi(QMainWindow MainWindow)
    {
    MainWindow.setWindowTitle(QApplication.translate("MainWindow", "MainWindow", null, QApplication.UnicodeUTF8));
    actionOpen.setText(QApplication.translate("MainWindow", "Open", null, QApplication.UnicodeUTF8));
    actionClose.setText(QApplication.translate("MainWindow", "Close", null, QApplication.UnicodeUTF8));
    actionQuit.setText(QApplication.translate("MainWindow", "Quit", null, QApplication.UnicodeUTF8));
    actionCopy.setText(QApplication.translate("MainWindow", "Copy", null, QApplication.UnicodeUTF8));
    actionPaste.setText(QApplication.translate("MainWindow", "Paste", null, QApplication.UnicodeUTF8));
    actionCut.setText(QApplication.translate("MainWindow", "Cut", null, QApplication.UnicodeUTF8));
    menuFile.setTitle(QApplication.translate("MainWindow", "File", null, QApplication.UnicodeUTF8));
    menuEdit.setTitle(QApplication.translate("MainWindow", "Edit", null, QApplication.UnicodeUTF8));
    toolBar.setWindowTitle(QApplication.translate("MainWindow", "toolBar", null, QApplication.UnicodeUTF8));
    groupBox.setTitle(QApplication.translate("MainWindow", "Some options", null, QApplication.UnicodeUTF8));
    radioButton.setText(QApplication.translate("MainWindow", "Option 1", null, QApplication.UnicodeUTF8));
    radioButton_2.setText(QApplication.translate("MainWindow", "Option 2", null, QApplication.UnicodeUTF8));
    radioButton_3.setText(QApplication.translate("MainWindow", "Option 3", null, QApplication.UnicodeUTF8));
    } // retranslateUi

}

struct MainWindow {
    mixin Ui_MainWindow;
}

mixin QT_END_NAMESPACE;

