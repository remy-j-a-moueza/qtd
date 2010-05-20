/****************************************************************************
**
** Copyright (C) 2008 Nokia Corporation and/or its subsidiary(-ies).
** Contact: Qt Software Information (qt-info@nokia.com)
**
** This file is part of the example classes of the Qt Toolkit.
**
** Commercial Usage
** Licensees holding valid Qt Commercial licenses may use this file in
** accordance with the Qt Commercial License Agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and Nokia.
**
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License versions 2.0 or 3.0 as published by the Free
** Software Foundation and appearing in the file LICENSE.GPL included in
** the packaging of this file.  Please review the following information
** to ensure GNU General Public Licensing requirements will be met:
** http://www.fsf.org/licensing/licenses/info/GPLv2.html and
** http://www.gnu.org/copyleft/gpl.html.  In addition, as a special
** exception, Nokia gives you certain additional rights. These rights
** are described in the Nokia Qt GPL Exception version 1.3, included in
** the file GPL_EXCEPTION.txt in this package.
**
** Qt for Windows(R) Licensees
** As a special exception, Nokia, as the sole copyright holder for Qt
** Designer, grants users of the Qt/Eclipse Integration plug-in the
** right for the Qt/Eclipse Integration to link to functionality
** provided by Qt Designer and its related libraries.
**
** If you are unsure which license is appropriate for your use, please
** contact the sales department at qt-sales@nokia.com.
**
****************************************************************************/


import qt.gui.QMainWindow;

import qt.gui.QListWidget;
import qt.gui.QMenu;
import qt.gui.QToolBar;
import qt.gui.QDockWidget;
import qt.gui.QListWidget;
import qt.gui.QMessageBox;
import qt.gui.QTextEdit;
import qt.gui.QTextCursor;
import qt.gui.QTextFrame;
import qt.gui.QTextFrameFormat;
import qt.gui.QTextCharFormat;
import qt.gui.QTextTableFormat;
import qt.gui.QAction;
import qt.gui.QStatusBar;
import qt.gui.QFont;
import qt.gui.QIcon;
import qt.core.QDate;

import std.string : split;

class MainWindow : public QMainWindow
{
//    Q_OBJECT

    public:
        this()
        {
            textEdit = new QTextEdit;
            setCentralWidget(textEdit);

            createActions();
            createMenus();
            createToolBars();
            createStatusBar();
            createDockWindows();

            setWindowTitle(tr("Dock Widgets"));
            newLetter();
        }

    private : //slots:
        void slot_newLetter()
        {
            textEdit.clear();

            scope cursor = textEdit.textCursor;
            cursor.movePosition(QTextCursor.Start);
            QTextFrame topFrame = cursor.currentFrame();
            QTextFrameFormat topFrameFormat = topFrame.frameFormat();
            topFrameFormat.setPadding(16);
            topFrame.setFrameFormat(topFrameFormat);

            scope textFormat = new QTextCharFormat;
            scope boldFormat = new QTextCharFormat;
            scope italicFormat = new QTextCharFormat;
            boldFormat.setFontWeight(QFont.Bold);
            italicFormat.setFontItalic(true);

            scope tableFormat = new QTextTableFormat;
            tableFormat.setBorder(1);
            tableFormat.setCellPadding(16);
            tableFormat.setAlignment(Qt.AlignRight);
            cursor.insertTable(1, 1, tableFormat);
            cursor.insertText("The Firm", boldFormat);
            cursor.insertBlock();
            cursor.insertText("321 City Street", textFormat);
            cursor.insertBlock();
            cursor.insertText("Industry Park");
            cursor.insertBlock();
            cursor.insertText("Some Country");
            cursor.setPosition(topFrame.lastPosition());
            cursor.insertText(QDate.currentDate.toString("d MMMM yyyy"), textFormat);
            cursor.insertBlock();
            cursor.insertBlock();
            cursor.insertText("Dear ", textFormat);
            cursor.insertText("NAME", italicFormat);
            cursor.insertText(",", textFormat);
            for (int i = 0; i < 3; ++i)
                cursor.insertBlock();
            cursor.insertText(tr("Yours sincerely,"), textFormat);
            for (int i = 0; i < 3; ++i)
                cursor.insertBlock();
            cursor.insertText("The Boss", textFormat);
            cursor.insertBlock();
            cursor.insertText("ADDRESS", italicFormat);
        }
/*
        void slot_save()
        {
            char[] fileName = QFileDialog.getSaveFileName(this,
                                                          tr("Choose a file name"), ".",
                                                          tr("HTML (*.html *.htm)"));
            if (fileName.isEmpty())
                return;
            scope file = new QFile(fileName);
            if (!file.open(QFile.WriteOnly | QFile.Text)) {
                QMessageBox.warning(this, tr("Dock Widgets"),
                                    tr(layout("Cannot write file %1:\n%2.", fileName, file.errorString))
                return;
            }

            scope outStream = new QTextStream(file);
            QApplication.setOverrideCursor(Qt.WaitCursor);
            outStream << textEdit.toHtml();
            QApplication.restoreOverrideCursor();

            statusBar.showMessage(layout("Saved '%1'", fileName), 2000);
        }*/

        void slot_print() { }

        void slot_undo() {
            auto document = textEdit.document();
            document.undo();
        }

        void slot_insertCustomer(string customer)
        {
            if (customer == "")
                return;

            string[] customerList = customer.split(", ");
            auto document = textEdit.document();
            QTextCursor cursor = document.find("NAME");
            if (!cursor.isNull) {
                cursor.beginEditBlock();
                cursor.insertText(customerList[0]);
                scope oldcursor = new QTextCursor(cursor);
                cursor = document.find("ADDRESS");
                if (!cursor.isNull) {
                    for (int i = 1; i < customerList.length; ++i) {
                        cursor.insertBlock();
                        cursor.insertText(customerList[i]);
                    }
                    cursor.endEditBlock();
                }
                else
                    oldcursor.endEditBlock();
            }
        }

        void slot_addParagraph(string paragraph)
        {
            if (paragraph == "")
                return;
            auto document = textEdit.document();
            scope cursor = document.find(tr("Yours sincerely,"));
            if (cursor.isNull)
                return;
            cursor.beginEditBlock();
            cursor.movePosition(QTextCursor.PreviousBlock, QTextCursor.MoveAnchor, 2);
            cursor.insertBlock();
            cursor.insertText(paragraph);
            cursor.insertBlock();
            cursor.endEditBlock();

        }

        void slot_about()
        {
            QMessageBox.about(this, "About Dock Widgets",
                               "The <b>Dock Widgets</b> example demonstrates how to "
                               "use Qt's dock widgets. You can enter your own text, "
                               "click a customer to add a customer name and "
                               "address, and click standard paragraphs to add them.");
        }

    private:
        void createActions()
        {
            newLetterAct = new QAction(new QIcon(":images/new.png"), tr("&New Letter"), this);
            newLetterAct.setShortcut(tr("Ctrl+N"));
            newLetterAct.setStatusTip(tr("Create a new form letter"));
            connect(newLetterAct, "triggered", this, "newLetter");

            saveAct = new QAction(new QIcon(":images/save.png"), tr("&Save..."), this);
            saveAct.setShortcut(tr("Ctrl+S"));
            saveAct.setStatusTip(tr("Save the current form letter"));
            // saveAct.triggered.connect(&save);

            printAct = new QAction(new QIcon(":images/print.png"), tr("&Print..."), this);
            printAct.setShortcut(tr("Ctrl+P"));
            printAct.setStatusTip(tr("Print the current form letter"));
            // printAct.triggered.connect(&print);

            undoAct = new QAction(new QIcon(":images/undo.png"), tr("&Undo"), this);
            undoAct.setShortcut(tr("Ctrl+Z"));
            undoAct.setStatusTip(tr("Undo the last editing action"));
            connect(undoAct, "triggered", this, "undo");

            quitAct = new QAction(tr("&Quit"), this);
            quitAct.setShortcut(tr("Ctrl+Q"));
            quitAct.setStatusTip(tr("Quit the application"));
            connect(quitAct, "triggered", this, "close");

            aboutAct = new QAction(tr("&About"), this);
            aboutAct.setStatusTip(tr("Show the application's About box"));
            connect(aboutAct, "triggered", this, "about");

            aboutQtAct = new QAction(tr("About &Qt"), this);
            aboutQtAct.setStatusTip(tr("Show the Qt library's About box"));
            connect(aboutQtAct, "triggered", qApp, "aboutQt");
        }

        void createMenus()
        {
            fileMenu = menuBar.addMenu(tr("&File"));
            fileMenu.addAction(newLetterAct);
            fileMenu.addAction(saveAct);
            fileMenu.addAction(printAct);
            fileMenu.addSeparator();
            fileMenu.addAction(quitAct);

            editMenu = menuBar.addMenu(tr("&Edit"));
            editMenu.addAction(undoAct);

            viewMenu = menuBar.addMenu(tr("&View"));

            menuBar().addSeparator();

            helpMenu = menuBar.addMenu(tr("&Help"));
            helpMenu.addAction(aboutAct);
            helpMenu.addAction(aboutQtAct);
        }

        void createToolBars()
        {
            fileToolBar = addToolBar(tr("File"));
            fileToolBar.addAction(newLetterAct);
            fileToolBar.addAction(saveAct);
            fileToolBar.addAction(printAct);

            editToolBar = addToolBar(tr("Edit"));
            editToolBar.addAction(undoAct);
        }

        void createStatusBar()
        {
            statusBar.showMessage(tr("Ready"));
        }

        void createDockWindows()
        {
            QDockWidget dock = new QDockWidget(tr("Customers"), this);
            dock.setAllowedAreas(Qt.LeftDockWidgetArea | Qt.RightDockWidgetArea);
            customerList = new QListWidget(dock);
            customerList.addItems([
                "John Doe, Harmony Enterprises, 12 Lakeside, Ambleton",
                "Jane Doe, Memorabilia, 23 Watersedge, Beaton",
                "Tammy Shea, Tiblanka, 38 Sea Views, Carlton",
                "Tim Sheen, Caraba Gifts, 48 Ocean Way, Deal",
                "Sol Harvey, Chicos Coffee, 53 New Springs, Eccleston",
                "Sally Hobart, Tiroli Tea, 67 Long River, Fedula"]);
            dock.setWidget(customerList);
            addDockWidget(Qt.RightDockWidgetArea, dock);
            viewMenu.addAction(dock.toggleViewAction());

            dock = new QDockWidget(tr("Paragraphs"), this);
            paragraphsList = new QListWidget(dock);
            paragraphsList.addItems([
                "Thank you for your payment which we have received today.",
                "Your order has been dispatched and should be with you "
                "within 28 days.",

                "We have dispatched those items that were in stock. The "
                "rest of your order will be dispatched once all the "
                "remaining items have arrived at our warehouse. No "
                "additional shipping charges will be made.",

                "You made a small overpayment (less than $5) which we "
                "will keep on account for you, or return at your request.",

                "You made a small underpayment (less than $1), but we have "
                "sent your order anyway. We'll add this underpayment to "
                "your next bill.",

                "Unfortunately you did not send enough money. Please remit "
                "an additional $. Your order will be dispatched as soon as "
                "the complete amount has been received.",

                "You made an overpayment (more than $5). Do you wish to "
                "buy more items, or should we return the excess to you?"]);
            dock.setWidget(paragraphsList);
            addDockWidget(Qt.RightDockWidgetArea, dock);
            viewMenu.addAction(dock.toggleViewAction());

            connect(customerList, "currentTextChanged", this, "insertCustomer");
            connect(paragraphsList, "currentTextChanged", this, "addParagraph");
        }

        QTextEdit textEdit;
        QListWidget customerList;
        QListWidget paragraphsList;

        QMenu fileMenu;
        QMenu editMenu;
        QMenu viewMenu;
        QMenu helpMenu;
        QToolBar fileToolBar;
        QToolBar editToolBar;
        QAction newLetterAct;
        QAction saveAct;
        QAction printAct;
        QAction undoAct;
        QAction aboutAct;
        QAction aboutQtAct;
        QAction quitAct;

        mixin Q_OBJECT;
}
