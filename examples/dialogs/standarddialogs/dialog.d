/****************************************************************************
**
** Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies).
** Contact: Qt Software Information (qt-info@nokia.com)
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
** contact the sales department at qt-sales@nokia.com.
** $QT_END_LICENSE$
**
****************************************************************************/
module dialog;

import qt.gui.QDialog;
import qt.gui.QCheckBox;
import qt.gui.QLabel;
import qt.gui.QMessageBox;
import qt.gui.QGridLayout;
import qt.gui.QErrorMessage;
import qt.gui.QFileDialog;
import qt.gui.QLineEdit;
import qt.gui.QInputDialog;
import qt.gui.QColorDialog;
import qt.gui.QFontDialog;
import qt.gui.QFileDialog;
import qt.core.QFile;

import std.string : format, join;

string MESSAGE = tr("<p>Message boxes have a caption, a text, "
               "and any number of buttons, each with standard or custom texts."
               "<p>Click a button to close the message box. Pressing the Esc button "
               "will activate the detected escape button (if any).");


class Dialog : public QDialog
{
public:

	this(QWidget parent = null)
	{
		super(parent);
		errorMessageDialog = new QErrorMessage(this);

		int frameStyle = QFrame.Sunken | QFrame.Panel;

		integerLabel = new QLabel;
		integerLabel.setFrameStyle(frameStyle);
		QPushButton integerButton = new QPushButton(tr("QInputget&Int()"));

		doubleLabel = new QLabel;
		doubleLabel.setFrameStyle(frameStyle);
		QPushButton doubleButton = new QPushButton(tr("QInputget&Double()"));

		itemLabel = new QLabel;
		itemLabel.setFrameStyle(frameStyle);
		QPushButton itemButton = new QPushButton(tr("QInputgetIte&m()"));

		textLabel = new QLabel;
		textLabel.setFrameStyle(frameStyle);
		QPushButton textButton = new QPushButton(tr("QInputget&Text()"));

		colorLabel = new QLabel;
		colorLabel.setFrameStyle(frameStyle);
		QPushButton colorButton = new QPushButton(tr("QColorget&Color()"));

		fontLabel = new QLabel;
		fontLabel.setFrameStyle(frameStyle);
		QPushButton fontButton = new QPushButton(tr("QFontget&Font()"));

		directoryLabel = new QLabel;
		directoryLabel.setFrameStyle(frameStyle);
		QPushButton directoryButton = new QPushButton(tr("QFilegetE&xistingDirectory()"));

		openFileNameLabel = new QLabel;
		openFileNameLabel.setFrameStyle(frameStyle);
		QPushButton openFileNameButton = new QPushButton(tr("QFileget&OpenFileName()"));

		openFileNamesLabel = new QLabel;
		openFileNamesLabel.setFrameStyle(frameStyle);
		QPushButton openFileNamesButton = new QPushButton(tr("QFile&getOpenFileNames()"));

		saveFileNameLabel = new QLabel;
		saveFileNameLabel.setFrameStyle(frameStyle);
		QPushButton saveFileNameButton = new QPushButton(tr("QFileget&SaveFileName()"));

		criticalLabel = new QLabel;
		criticalLabel.setFrameStyle(frameStyle);
		QPushButton criticalButton = new QPushButton(tr("QMessageBox.critica&l()"));

		informationLabel = new QLabel;
		informationLabel.setFrameStyle(frameStyle);
		QPushButton informationButton = new QPushButton(tr("QMessageBox.i&nformation()"));

		questionLabel = new QLabel;
		questionLabel.setFrameStyle(frameStyle);
		QPushButton questionButton = new QPushButton(tr("QMessageBox.&question()"));

		warningLabel = new QLabel;
		warningLabel.setFrameStyle(frameStyle);
		QPushButton warningButton = new QPushButton(tr("QMessageBox.&warning()"));

		errorLabel = new QLabel;
		errorLabel.setFrameStyle(frameStyle);
		QPushButton errorButton = new QPushButton(tr("QErrorMessage.show&M&essage()"));

		connect(integerButton, "clicked", this, "setInteger");
		connect(doubleButton, "clicked", this, "setDouble");
		connect(itemButton, "clicked", this, "setItem");
		connect(textButton, "clicked", this, "setText");
		connect(colorButton, "clicked", this, "setColor");
		connect(fontButton, "clicked", this, "setFont");
		connect(directoryButton, "clicked", this, "setExistingDirectory");
		connect(openFileNameButton, "clicked", this, "setOpenFileName");
		connect(openFileNamesButton, "clicked", this, "setOpenFileNames");
		connect(saveFileNameButton, "clicked", this, "setSaveFileName");
		connect(criticalButton, "clicked", this, "criticalMessage");
		connect(informationButton, "clicked", this, "informationMessage");
		connect(questionButton, "clicked", this, "questionMessage");
		connect(warningButton, "clicked", this, "warningMessage");
		connect(errorButton, "clicked", this, "errorMessage");

		native = new QCheckBox(this);
		native.setText("Use native file dialog.");
		native.setChecked(true);

		version(windows) {} else
		{
			version(mac) {} else
			{
				native.hide();
			}
		}

		QGridLayout layout = new QGridLayout;
		layout.setColumnStretch(1, 1);
		layout.setColumnMinimumWidth(1, 250);
		layout.addWidget(integerButton, 0, 0);
		layout.addWidget(integerLabel, 0, 1);
		layout.addWidget(doubleButton, 1, 0);
		layout.addWidget(doubleLabel, 1, 1);
		layout.addWidget(itemButton, 2, 0);
		layout.addWidget(itemLabel, 2, 1);
		layout.addWidget(textButton, 3, 0);
		layout.addWidget(textLabel, 3, 1);
		layout.addWidget(colorButton, 4, 0);
		layout.addWidget(colorLabel, 4, 1);
		layout.addWidget(fontButton, 5, 0);
		layout.addWidget(fontLabel, 5, 1);
		layout.addWidget(directoryButton, 6, 0);
		layout.addWidget(directoryLabel, 6, 1);
		layout.addWidget(openFileNameButton, 7, 0);
		layout.addWidget(openFileNameLabel, 7, 1);
		layout.addWidget(openFileNamesButton, 8, 0);
		layout.addWidget(openFileNamesLabel, 8, 1);
		layout.addWidget(saveFileNameButton, 9, 0);
		layout.addWidget(saveFileNameLabel, 9, 1);
		layout.addWidget(criticalButton, 10, 0);
		layout.addWidget(criticalLabel, 10, 1);
		layout.addWidget(informationButton, 11, 0);
		layout.addWidget(informationLabel, 11, 1);
		layout.addWidget(questionButton, 12, 0);
		layout.addWidget(questionLabel, 12, 1);
		layout.addWidget(warningButton, 13, 0);
		layout.addWidget(warningLabel, 13, 1);
		layout.addWidget(errorButton, 14, 0);
		layout.addWidget(errorLabel, 14, 1);
		layout.addWidget(native, 15, 0);
		setLayout(layout);

		setWindowTitle(tr("Standard Dialogs"));
	}

private: // slots

	void slot_setInteger()
	{
		bool ok;
		int i = QInputDialog.getInt(this, tr("QInputgetInteger()"), tr("Percentage:"), 25, 0, 100, 1, ok);
		if (ok)
			integerLabel.setText(format("%d", i));
	}

	void slot_setDouble()
	{
		bool ok;
		double d = QInputDialog.getDouble(this, tr("QInputgetDouble()"),
						tr("Amount:"), 37.56, -10000, 10000, 2, ok);
		if (ok)
			doubleLabel.setText(format("%g", d));
	}

	void slot_setItem()
	{
		string[] items =  [tr("Spring"), tr("Summer"), tr("Fall"), tr("Winter")];

		bool ok;
		string item = QInputDialog.getItem(this, tr("QInputgetItem()"),
						tr("Season:"), items.toQList, 0, false, ok);
		if (ok && item.length)
			itemLabel.setText(item);
	}

	void slot_setText()
	{
		bool ok;
		string text = QInputDialog.getText(this, tr("QInputgetText()"),
						tr("User name:"), QLineEdit.EchoMode.Normal,
		QDir.home().dirName(), ok);
		if (ok && text.length)
			textLabel.setText(text);
	}

	void slot_setColor()
	{
		QColor color = QColorDialog.getColor(QColor.Green, this);
		if (color.isValid()) {
			colorLabel.setText(color.name());
			colorLabel.setPalette(new QPalette(color));
			colorLabel.setAutoFillBackground(true);
		}
	}

	void slot_setFont()
	{
		bool ok;
		QFont font = QFontDialog.getFont(&ok, new QFont(fontLabel.text()), this);
		if (ok) {
			fontLabel.setText(font.key());
			fontLabel.setFont(font);
		}
	}

	void slot_setExistingDirectory()
	{
		int options = QFileDialog.Option.DontResolveSymlinks | QFileDialog.Option.ShowDirsOnly;
		if (!native.isChecked())
			options |= QFileDialog.Option.DontUseNativeDialog;
		string directory = QFileDialog.getExistingDirectory(this,
						tr("QFilegetExistingDirectory()"),
						directoryLabel.text(),
						options);
		if (directory.length)
			directoryLabel.setText(directory);
	}

	void slot_setOpenFileName()
	{
		int options;
		if (!native.isChecked())
			options |= QFileDialog.Option.DontUseNativeDialog;
		string selectedFilter;
		string fileName = QFileDialog.getOpenFileName(this,
						tr("QFilegetOpenFileName()"),
						openFileNameLabel.text(),
						tr("All Files (*);;Text Files (*.txt)"),
						selectedFilter,
						options);
		if (fileName.length)
			openFileNameLabel.setText(fileName);
	}

	void slot_setOpenFileNames()
	{
		int options;
		if (!native.isChecked())
			options |= QFileDialog.Option.DontUseNativeDialog;
		string selectedFilter;
		auto files = QFileDialog.getOpenFileNames(
						this, tr("QFilegetOpenFileNames()"),
						openFilesPath,
						tr("All Files (*);;Text Files (*.txt)"),
						selectedFilter,
						options);
		if (files.length) {
			openFilesPath = files[0];
			openFileNamesLabel.setText(join(files.toArray, "; "));
		}
	}

	void slot_setSaveFileName()
	{
		int options;
		if (!native.isChecked())
			options |= QFileDialog.Option.DontUseNativeDialog;
		string selectedFilter;
		string fileName = QFileDialog.getSaveFileName(this,
						tr("QFilegetSaveFileName()"),
						saveFileNameLabel.text(),
						tr("All Files (*);;Text Files (*.txt)"),
						selectedFilter,
						options);
		if (fileName.length)
			saveFileNameLabel.setText(fileName);
	}

	void slot_criticalMessage()
	{
		QMessageBox.StandardButton reply;
		reply = QMessageBox.critical(this, tr("QMessageBox.critical()"),
						MESSAGE,
						QMessageBox.Abort | QMessageBox.Retry | QMessageBox.Ignore);
		if (reply == QMessageBox.Abort)
			criticalLabel.setText(tr("Abort"));
		else if (reply == QMessageBox.Retry)
			criticalLabel.setText(tr("Retry"));
		else
			criticalLabel.setText(tr("Ignore"));
	}

	void slot_informationMessage()
	{
		QMessageBox.StandardButton reply;
		reply = QMessageBox.information(this, tr("QMessageBox.information()"), MESSAGE);
		if (reply == QMessageBox.Ok)
			informationLabel.setText(tr("OK"));
		else
			informationLabel.setText(tr("Escape"));
	}

	void slot_questionMessage()
	{
		QMessageBox.StandardButton reply;
		reply = QMessageBox.question(this, tr("QMessageBox.question()"),
						MESSAGE,
						QMessageBox.Yes | QMessageBox.No | QMessageBox.Cancel);
		if (reply == QMessageBox.Yes)
			questionLabel.setText(tr("Yes"));
		else if (reply == QMessageBox.No)
			questionLabel.setText(tr("No"));
		else
			questionLabel.setText(tr("Cancel"));
	}

	void slot_warningMessage()
	{
		auto msgBox = new QMessageBox(QMessageBox.Warning, tr("QMessageBox.warning()"), MESSAGE, 0, this);
		msgBox.addButton(tr("Save &Again"), QMessageBox.AcceptRole);
		msgBox.addButton(tr("&Continue"), QMessageBox.RejectRole);
		if (msgBox.exec() == QMessageBox.AcceptRole)
			warningLabel.setText(tr("Save Again"));
		else
			warningLabel.setText(tr("Continue"));
	}

	void slot_errorMessage()
	{
		errorMessageDialog.showMessage(
				tr("This dialog shows and remembers error messages. "
				"If the checkbox is checked (as it is by default), "
				"the shown message will be shown again, "
				"but if the user unchecks the box the message "
				"will not appear again if QErrorMessage.showMessage() "
				"is called with the same message."));
		errorLabel.setText(tr("If the box is unchecked, the message won't appear again."));
	}

private:

	QCheckBox native;
	QLabel integerLabel;
	QLabel doubleLabel;
	QLabel itemLabel;
	QLabel textLabel;
	QLabel colorLabel;
	QLabel fontLabel;
	QLabel directoryLabel;
	QLabel openFileNameLabel;
	QLabel openFileNamesLabel;
	QLabel saveFileNameLabel;
	QLabel criticalLabel;
	QLabel informationLabel;
	QLabel questionLabel;
	QLabel warningLabel;
	QLabel errorLabel;
	QErrorMessage errorMessageDialog;

	string openFilesPath;

    mixin Q_OBJECT;
}
