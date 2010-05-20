/****************************************************************************
**
** Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies).
** Contact: Nokia Corporation (qt-info@nokia.com)
**
** This file is part of the examples of the Qt Toolkit.
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
** contact the sales department at http://www.qtsoftware.com/contact.
** $QT_END_LICENSE$
**
****************************************************************************/

/****************************************************************************
**
** Translated from Qt/C++ to QtD/D by Jason Addison
** Date: 2009 09 13
** Contact: jraddison@gmail.com
**
****************************************************************************/


import qt.gui.QMainWindow;
import qt.gui.QAction;
import qt.gui.QMenu;
import qt.gui.QTextEdit;
import qt.gui.QFileDialog;
import qt.gui.QMessageBox;
import qt.core.QSettings;
import qt.core.QTextStream;

//import std.string;
import std.conv;

class MainWindow : public QMainWindow
{
  //    Q_OBJECT

 public:
  this()
    {
      init();
      setCurrentFile("");
    }

  this(string fileName)
    {
      init();
      loadFile(fileName);
    }

 protected:

  void closeEvent(QCloseEvent event)
  {
    if (maybeSave()) {
      writeSettings();
      event.accept();
    } else {
      event.ignore();
    }
  }

 private: // slots

  void slot_newFile()
  {
    MainWindow other = new MainWindow;
    other.move(x() + 40, y() + 40);
    other.show();
  }

  void slot_open()
  {
    scope fileName = QFileDialog.getOpenFileName(this);
    if (fileName) {
      MainWindow existing = findMainWindow(fileName);
      if (existing) {
        existing.show();
        existing.raise();
        existing.activateWindow();
        return;
      }
      if (isUntitled && textEdit.document().isEmpty()
          && !isWindowModified()) {
        loadFile(fileName);
      } else {
        MainWindow other = new MainWindow(fileName);
        if (other.isUntitled) {
          delete other;
          return;
        }
        other.move(x() + 40, y() + 40);
        other.show();
      }
    }
  }

  bool slot_save()
  {
    if (isUntitled) {
      return saveAs();
    } else {
      return saveFile(curFile);
    }
  }

  bool slot_saveAs()
  {
    string fileName = QFileDialog.getSaveFileName(this, tr("Save As"),
                                                  curFile);
    if (!fileName)
      return false;

    return saveFile(fileName);
  }

  void slot_about()
  {
    QMessageBox.about(this, tr("About SDI"),
                      tr("The <b>SDI</b> example demonstrates how to write single " ~
                         "document interface applications using Qt."));
  }

  void slot_documentWasModified()
  {
    setWindowModified(true);
  }

 private:

  void init()
  {
    setAttribute(Qt.WA_DeleteOnClose);

    isUntitled = true;

    textEdit = new QTextEdit;
    setCentralWidget(textEdit);

    createActions();
    createMenus();
    createToolBars();
    createStatusBar();

    readSettings();

    connect(textEdit.document(), "contentsChanged", this, "documentWasModified");

    setUnifiedTitleAndToolBarOnMac(true);
  }

  void createActions()
  {
    newAct = new QAction(new QIcon(":/images/new.png"), tr("&New"), this);
    newAct.setShortcuts(QKeySequence.New);
    newAct.setStatusTip(tr("Create a new file"));
    connect(newAct, "triggered", this, "newFile");

    openAct = new QAction(new QIcon(":/images/open.png"), tr("&Open..."), this);
    openAct.setShortcuts(QKeySequence.Open);
    openAct.setStatusTip(tr("Open an existing file"));
    connect(openAct, "triggered", this, "open");

    saveAct = new QAction(new QIcon(":/images/save.png"), tr("&Save"), this);
    saveAct.setShortcuts(QKeySequence.Save);
    saveAct.setStatusTip(tr("Save the document to disk"));
    connect(saveAct, "triggered", this, "save");

    saveAsAct = new QAction(tr("Save &As..."), this);
    saveAsAct.setShortcuts(QKeySequence.SaveAs);
    saveAsAct.setStatusTip(tr("Save the document under a new name"));
    connect(saveAsAct, "triggered", this, "saveAs");

    closeAct = new QAction(tr("&Close"), this);
    closeAct.setShortcut(tr("Ctrl+W"));
    closeAct.setStatusTip(tr("Close this window"));
    connect(closeAct, "triggered", this, "close");

    exitAct = new QAction(tr("E&xit"), this);
    exitAct.setShortcut(tr("Ctrl+Q"));
    exitAct.setStatusTip(tr("Exit the application"));
    connect(exitAct, "triggered", qApp(), "closeAllWindows");

    cutAct = new QAction(new QIcon(":/images/cut.png"), tr("Cu&t"), this);
    cutAct.setShortcuts(QKeySequence.Cut);
    cutAct.setStatusTip(tr("Cut the current selection's contents to the " ~
                           "clipboard"));
    connect(cutAct, "triggered", textEdit, "cut");

    copyAct = new QAction(new QIcon(":/images/copy.png"), tr("&Copy"), this);
    copyAct.setShortcuts(QKeySequence.Copy);
    copyAct.setStatusTip(tr("Copy the current selection's contents to the " ~
                            "clipboard"));
    connect(copyAct, "triggered", textEdit, "copy");

    pasteAct = new QAction(new QIcon(":/images/paste.png"), tr("&Paste"), this);
    pasteAct.setShortcuts(QKeySequence.Paste);
    pasteAct.setStatusTip(tr("Paste the clipboard's contents into the current " ~
                             "selection"));
    connect(pasteAct, "triggered", textEdit, "paste");

    aboutAct = new QAction(tr("&About"), this);
    aboutAct.setStatusTip(tr("Show the application's About box"));
    connect(aboutAct, "triggered", this, "about");

    aboutQtAct = new QAction(tr("About &Qt"), this);
    aboutQtAct.setStatusTip(tr("Show the Qt library's About box"));
    connect(aboutQtAct, "triggered", qApp, "aboutQt");

    cutAct.setEnabled(false);
    copyAct.setEnabled(false);

    connect(textEdit, "copyAvailable", cutAct, "setEnabled");
    connect(textEdit, "copyAvailable", copyAct, "setEnabled");
  }

  void createMenus()
  {
    fileMenu = menuBar.addMenu(tr("&File"));
    fileMenu.addAction(newAct);
    fileMenu.addAction(openAct);
    fileMenu.addAction(saveAct);
    fileMenu.addAction(saveAsAct);
    fileMenu.addSeparator();
    fileMenu.addAction(closeAct);
    fileMenu.addAction(exitAct);

    editMenu = menuBar.addMenu(tr("&Edit"));
    editMenu.addAction(cutAct);
    editMenu.addAction(copyAct);
    editMenu.addAction(pasteAct);

    menuBar().addSeparator();

    helpMenu = menuBar.addMenu(tr("&Help"));
    helpMenu.addAction(aboutAct);
    helpMenu.addAction(aboutQtAct);
  }

  void createToolBars()
  {
    fileToolBar = addToolBar(tr("File"));
    fileToolBar.addAction(newAct);
    fileToolBar.addAction(openAct);
    fileToolBar.addAction(saveAct);

    editToolBar = addToolBar(tr("Edit"));
    editToolBar.addAction(cutAct);
    editToolBar.addAction(copyAct);
    editToolBar.addAction(pasteAct);
  }

  void createStatusBar()
  {
    statusBar.showMessage(tr("Ready"));
  }

  void readSettings()
  {
    scope QSettings settings = new QSettings("Trolltech", "SDI Example");
    scope QPoint pos = settings.value("pos", new QVariant(QPoint(200, 200))).toPoint();
    scope QSize size = settings.value("size", new QVariant(QSize(400, 400))).toSize();
    move(pos);
    resize(size);
  }

  void writeSettings()
  {
    QSettings settings = new QSettings("Trolltech", "SDI Example");
    settings.setValue("pos", new QVariant(pos()));
    settings.setValue("size", new QVariant(size()));
  }

  bool maybeSave()
  {
    if (textEdit.document().isModified()) {
      QMessageBox.StandardButton ret;
      ret = QMessageBox.warning(this, tr("SDI"),
                                tr("The document has been modified.\n" ~
                                   "Do you want to save your changes?"),
                                QMessageBox.Save | QMessageBox.Discard
                                | QMessageBox.Cancel);
      if (ret == QMessageBox.Save)
        return save();
      else if (ret == QMessageBox.Cancel)
        return false;
    }
    return true;
  }

  void loadFile(string fileName)
  {
    scope file = new QFile(fileName);
    if (!file.open(QFile.ReadOnly | QFile.Text)) {
      QMessageBox.warning(this, tr("SDI"),
                          tr("Cannot read file " ~
                             fileName ~ ":\n" ~
                             file.errorString ~ "."));
      return;
    }

    scope inStream = new QTextStream(file);
    QApplication.setOverrideCursor(new QCursor(Qt.WaitCursor));
    textEdit.setPlainText(inStream.readAll());
    QApplication.restoreOverrideCursor();

    setCurrentFile(fileName);
    statusBar.showMessage(tr("File loaded"), 2000);
  }

  bool saveFile(string fileName)
  {
    scope file = new QFile(fileName);
    if (!file.open(QFile.WriteOnly | QFile.Text)) {
      QMessageBox.warning(this, tr("SDI"),
                          tr("Cannot write file " ~
                             fileName ~ ":\n" ~
                             file.errorString ~ "."));
      return false;
    }

    scope outStream = new QTextStream(file);
    QApplication.setOverrideCursor(new QCursor(Qt.WaitCursor));
    outStream.writeString(textEdit.toPlainText());
    QApplication.restoreOverrideCursor();

    setCurrentFile(fileName);
    statusBar.showMessage("Saved '" ~ fileName ~ "'", 2000);
    return true;
  }

  void setCurrentFile(string fileName)
  {
    static int sequenceNumber = 1;

    isUntitled = fileName == null;
    if (isUntitled) {
        curFile = tr("document" ~ to!(string)(sequenceNumber++) ~ ".txt");
    } else {
      scope qfi = new QFileInfo(fileName);
      curFile = qfi.canonicalFilePath;
    }

    textEdit.document().setModified(false);
    setWindowModified(false);

    setWindowTitle(strippedName(curFile) ~ "[*] - " ~ tr("SDI"));
  }

  string strippedName(string fullFileName)
  {
    scope qfi = new QFileInfo(fullFileName);
    return qfi.fileName();
  }

  MainWindow findMainWindow(string fileName)
  {
    scope qfi = new QFileInfo(fileName);
    string canonicalFilePath = qfi.canonicalFilePath();

    foreach (QWidget widget; QApplication.topLevelWidgets) {
      MainWindow mainWin = cast(MainWindow)(widget);
      if (mainWin && mainWin.curFile == canonicalFilePath)
        return mainWin;
    }
    return null;
  }

  QTextEdit textEdit;
  string curFile;
  bool isUntitled;

  QMenu fileMenu;
  QMenu editMenu;
  QMenu helpMenu;
  QToolBar fileToolBar;
  QToolBar editToolBar;

  QAction newAct;
  QAction openAct;
  QAction saveAct;
  QAction saveAsAct;
  QAction closeAct;
  QAction exitAct;
  QAction cutAct;
  QAction copyAct;
  QAction pasteAct;
  QAction aboutAct;
  QAction aboutQtAct;

  mixin Q_OBJECT;
};
