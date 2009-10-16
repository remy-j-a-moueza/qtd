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
module screenshot;


import qt.gui.QPixmap;
import qt.gui.QWidget;
import qt.gui.QCheckBox;
import qt.gui.QGridLayout;
import qt.gui.QGroupBox;
import qt.gui.QHBoxLayout;
import qt.gui.QLabel;
import qt.gui.QPushButton;
import qt.gui.QSpinBox;
import qt.gui.QVBoxLayout;
import qt.gui.QFileDialog;
import qt.core.QDir;
import qt.core.QTimer;

import tango.text.convert.Format;
import tango.text.Ascii;


class Screenshot : public QWidget
{
public:
	
	this()
	{
		screenshotLabel = new QLabel;
		screenshotLabel.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding);
		screenshotLabel.setAlignment(Qt.AlignCenter);
		screenshotLabel.setMinimumSize(240, 160);

		createOptionsGroupBox();
		createButtonsLayout();

		mainLayout = new QVBoxLayout;
		mainLayout.addWidget(screenshotLabel);
		mainLayout.addWidget(optionsGroupBox);
		mainLayout.addLayout(buttonsLayout);
		setLayout(mainLayout);

		shootScreen();
		delaySpinBox.setValue(5);

		setWindowTitle(tr("Screenshot"));
		resize(300, 200);
	}

protected:

	void resizeEvent(QResizeEvent  /* event */)
	{
		QSize scaledSize = originalPixmap.size();
		scaledSize.scale(screenshotLabel.size(), Qt.KeepAspectRatio);
		if (!screenshotLabel.pixmap() || scaledSize != screenshotLabel.pixmap().size())
			updateScreenshotLabel();
	}

	private:

	void newScreenshot()
	{
		if (hideThisWindowCheckBox.isChecked())
			hide();
		newScreenshotButton.setDisabled(true);

		QTimer.singleShot(delaySpinBox.value() * 1000, this, SLOT(shootScreen()));
	}

	void saveScreenshot()
	{
		string format = "png";
		string initialPath = QDir.currentPath() + tr("/untitled.") + format;

		string fileName = QFileDialog.getSaveFileName(this, tr("Save As"), initialPath,
			Format(tr("{} Files (*.{});;All Files (*)"), toUpper(format), format));
		if (fileName.length)
			originalPixmap.save(fileName, format);
	}

	void shootScreen()
	{
		if (delaySpinBox.value() != 0)
			QApplication.beep();

		originalPixmap = new QPixmap(); // clear image for low memory situations
		
		// on embedded devices.
		originalPixmap = QPixmap.grabWindow(QApplication.desktop().winId());
		updateScreenshotLabel();

		newScreenshotButton.setDisabled(false);
		if (hideThisWindowCheckBox.isChecked())
			show();
	}

	void updateCheckBox()
	{
		if (delaySpinBox.value() == 0) {
			hideThisWindowCheckBox.setDisabled(true);
			hideThisWindowCheckBox.setChecked(false);
		}
		else
			hideThisWindowCheckBox.setDisabled(false);
	}

private:

	void createOptionsGroupBox()
	{
		optionsGroupBox = new QGroupBox(tr("Options"));

		delaySpinBox = new QSpinBox;
		delaySpinBox.setSuffix(tr(" s"));
		delaySpinBox.setMaximum(60);
		connect!("valueChanged")(delaySpinBox, &this.updateCheckBox);
		
		delaySpinBoxLabel = new QLabel(tr("Screenshot Delay:"));

		hideThisWindowCheckBox = new QCheckBox(tr("Hide This Window"));

		optionsGroupBoxLayout = new QGridLayout;
		optionsGroupBoxLayout.addWidget(delaySpinBoxLabel, 0, 0);
		optionsGroupBoxLayout.addWidget(delaySpinBox, 0, 1);
		optionsGroupBoxLayout.addWidget(hideThisWindowCheckBox, 1, 0, 1, 2);
		optionsGroupBox.setLayout(optionsGroupBoxLayout);
	}

	void createButtonsLayout()
	{
		newScreenshotButton = createButton(tr("New Screenshot"), &this.newScreenshot);

		saveScreenshotButton = createButton(tr("Save Screenshot"), &this.saveScreenshot);

		quitScreenshotButton = createButton(tr("Quit"), &this.close);

		buttonsLayout = new QHBoxLayout;
		buttonsLayout.addStretch();
		buttonsLayout.addWidget(newScreenshotButton);
		buttonsLayout.addWidget(saveScreenshotButton);
		buttonsLayout.addWidget(quitScreenshotButton);
	}

	QPushButton createButton(string text, void delegate() slot)
	{
		QPushButton button = new QPushButton(text);
		connect!("clicked")(button, slot);
		return button;
	}

	void updateScreenshotLabel()
	{
		screenshotLabel.setPixmap(originalPixmap.scaled(screenshotLabel.size(), Qt.KeepAspectRatio, Qt.SmoothTransformation));
	}

	QPixmap originalPixmap;

	QLabel screenshotLabel;
	QGroupBox optionsGroupBox;
	QSpinBox delaySpinBox;
	QLabel delaySpinBoxLabel;
	QCheckBox hideThisWindowCheckBox;
	QPushButton newScreenshotButton;
	QPushButton saveScreenshotButton;
	QPushButton quitScreenshotButton;

	QVBoxLayout mainLayout;
	QGridLayout optionsGroupBoxLayout;
	QHBoxLayout buttonsLayout;
}
