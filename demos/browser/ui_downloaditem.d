/********************************************************************************
** Form generated from reading ui file 'downloaditem.ui'
**
** Created: Mon May 18 01:52:16 2009
**      by: Qt User Interface Compiler version 4.5.0
**
** WARNING! All changes made in this file will be lost when recompiling ui file!
********************************************************************************/

import qt.core.QVariant;
import qt.gui.QAction;
import qt.gui.QApplication;
import qt.gui.QButtonGroup;
import qt.gui.QHBoxLayout;
import qt.gui.QHeaderView;
import qt.gui.QLabel;
import qt.gui.QProgressBar;
import qt.gui.QPushButton;
import qt.gui.QSpacerItem;
import qt.gui.QVBoxLayout;
import qt.gui.QWidget;
import squeezelabel;


class Ui_DownloadItem
{
public:
    QHBoxLayout horizontalLayout;
    QLabel fileIcon;
    QVBoxLayout verticalLayout_2;
    SqueezeLabel fileNameLabel;
    QProgressBar progressBar;
    SqueezeLabel downloadInfoLabel;
    QVBoxLayout verticalLayout;
    QSpacerItem verticalSpacer;
    QPushButton tryAgainButton;
    QPushButton stopButton;
    QPushButton openButton;
    QSpacerItem verticalSpacer_2;

    void setupUi(QWidget DownloadItem)
    {
        if (DownloadItem.objectName().isEmpty())
            DownloadItem.setObjectName("DownloadItem");
        DownloadItem.resize(423, 110);
        horizontalLayout = new QHBoxLayout(DownloadItem);
        horizontalLayout.setMargin(0);
        horizontalLayout.setObjectName("horizontalLayout");
        fileIcon = new QLabel(DownloadItem);
        fileIcon.setObjectName("fileIcon");
        QSizePolicy sizePolicy(QSizePolicy.Minimum, QSizePolicy.Minimum);
        sizePolicy.setHorizontalStretch(0);
        sizePolicy.setVerticalStretch(0);
        sizePolicy.setHeightForWidth(fileIcon.sizePolicy().hasHeightForWidth());
        fileIcon.setSizePolicy(sizePolicy);

        horizontalLayout.addWidget(fileIcon);

        verticalLayout_2 = new QVBoxLayout();
        verticalLayout_2.setObjectName("verticalLayout_2"));
        fileNameLabel = new SqueezeLabel(DownloadItem);
        fileNameLabel.setObjectName("fileNameLabel"));
        QSizePolicy sizePolicy1(QSizePolicy.Expanding, QSizePolicy.Preferred);
        sizePolicy1.setHorizontalStretch(0);
        sizePolicy1.setVerticalStretch(0);
        sizePolicy1.setHeightForWidth(fileNameLabel.sizePolicy().hasHeightForWidth());
        fileNameLabel.setSizePolicy(sizePolicy1);

        verticalLayout_2.addWidget(fileNameLabel);

        progressBar = new QProgressBar(DownloadItem);
        progressBar.setObjectName("progressBar");
        progressBar.setValue(0);

        verticalLayout_2.addWidget(progressBar);

        downloadInfoLabel = new SqueezeLabel(DownloadItem);
        downloadInfoLabel.setObjectName("downloadInfoLabel"));
        QSizePolicy sizePolicy2(QSizePolicy.Minimum, QSizePolicy.Preferred);
        sizePolicy2.setHorizontalStretch(0);
        sizePolicy2.setVerticalStretch(0);
        sizePolicy2.setHeightForWidth(downloadInfoLabel.sizePolicy().hasHeightForWidth());
        downloadInfoLabel.setSizePolicy(sizePolicy2);

        verticalLayout_2.addWidget(downloadInfoLabel);


        horizontalLayout.addLayout(verticalLayout_2);

        verticalLayout = new QVBoxLayout();
        verticalLayout.setObjectName("verticalLayout"));
        verticalSpacer = new QSpacerItem(17, 1, QSizePolicy.Minimum, QSizePolicy.Expanding);

        verticalLayout.addItem(verticalSpacer);

        tryAgainButton = new QPushButton(DownloadItem);
        tryAgainButton.setObjectName("tryAgainButton");
        tryAgainButton.setEnabled(false);

        verticalLayout.addWidget(tryAgainButton);

        stopButton = new QPushButton(DownloadItem);
        stopButton.setObjectName("stopButton");

        verticalLayout.addWidget(stopButton);

        openButton = new QPushButton(DownloadItem);
        openButton.setObjectName("openButton");

        verticalLayout.addWidget(openButton);

        verticalSpacer_2 = new QSpacerItem(17, 5, QSizePolicy.Minimum, QSizePolicy.Expanding);

        verticalLayout.addItem(verticalSpacer_2);


        horizontalLayout.addLayout(verticalLayout);


        retranslateUi(DownloadItem);

        QMetaObject.connectSlotsByName(DownloadItem);
    } // setupUi

    void retranslateUi(QWidget DownloadItem)
    {
        DownloadItem.setWindowTitle(QApplication.translate("DownloadItem", "Form", 0, QApplication.UnicodeUTF8));
        fileIcon.setText(QApplication.translate("DownloadItem", "Ico", 0, QApplication.UnicodeUTF8));
        fileNameLabel.setProperty("text", QVariant(QApplication.translate("DownloadItem", "Filename", 0, QApplication.UnicodeUTF8)));
        downloadInfoLabel.setProperty("text", QVariant(QString()));
        tryAgainButton.setText(QApplication.translate("DownloadItem", "Try Again", 0, QApplication.UnicodeUTF8));
        stopButton.setText(QApplication.translate("DownloadItem", "Stop", 0, QApplication.UnicodeUTF8));
        openButton.setText(QApplication.translate("DownloadItem", "Open", 0, QApplication.UnicodeUTF8));
        Q_UNUSED(DownloadItem);
    } // retranslateUi

}


class DownloadItem: public Ui_DownloadItem {}
