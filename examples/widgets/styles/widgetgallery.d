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
module widgetgallery;


import qt.gui.QDialog;
import qt.gui.QCheckBox;
import qt.gui.QComboBox;
import qt.gui.QDateTimeEdit;
import qt.gui.QDial;
import qt.gui.QGroupBox;
import qt.gui.QLabel;
import qt.gui.QLineEdit;
import qt.gui.QProgressBar;
import qt.gui.QPushButton;
import qt.gui.QRadioButton;
import qt.gui.QScrollBar;
import qt.gui.QSlider;
import qt.gui.QSpinBox;
import qt.gui.QTabWidget;
import qt.gui.QTableWidget;
import qt.gui.QTextEdit;
import qt.gui.QStyleFactory;
import qt.gui.QHBoxLayout;
import qt.gui.QGridLayout;
import qt.gui.QVBoxLayout;
import qt.core.QTimer;

import norwegianwoodstyle;


class WidgetGallery : public QDialog
{
public:

	this(QWidget parent = null)
	{
		super(parent);
		originalPalette = QApplication.palette();

		styleComboBox = new QComboBox;
		styleComboBox.addItem("NorwegianWood");
		styleComboBox.addItems(QStyleFactory.keys());

		styleLabel = new QLabel(tr("&Style:"));
		styleLabel.setBuddy(styleComboBox);

		useStylePaletteCheckBox = new QCheckBox(tr("&Use style's standard palette"));
		useStylePaletteCheckBox.setChecked(true);

		disableWidgetsCheckBox = new QCheckBox(tr("&Disable widgets"));

		createTopLeftGroupBox();
		createTopRightGroupBox();
		createBottomLeftTabWidget();
		createBottomRightGroupBox();
		createProgressBar();

		styleComboBox.activated.connect(&this.changeStyle);
		useStylePaletteCheckBox.toggled.connect(&this.changePalette);
		disableWidgetsCheckBox.toggled.connect(&topLeftGroupBox.setDisabled);
		disableWidgetsCheckBox.toggled.connect(&topRightGroupBox.setDisabled);
		disableWidgetsCheckBox.toggled.connect(&bottomLeftTabWidget.setDisabled);
		disableWidgetsCheckBox.toggled.connect(&bottomRightGroupBox.setDisabled);

		QHBoxLayout topLayout = new QHBoxLayout;

		topLayout.addWidget(styleLabel);
		topLayout.addWidget(styleComboBox);
		topLayout.addStretch(1);
		topLayout.addWidget(useStylePaletteCheckBox);
		topLayout.addWidget(disableWidgetsCheckBox);

		QGridLayout mainLayout = new QGridLayout;
		mainLayout.addLayout(topLayout, 0, 0, 1, 2);
		mainLayout.addWidget(topLeftGroupBox, 1, 0);
		mainLayout.addWidget(topRightGroupBox, 1, 1);
		mainLayout.addWidget(bottomLeftTabWidget, 2, 0);
		mainLayout.addWidget(bottomRightGroupBox, 2, 1);
		mainLayout.addWidget(progressBar, 3, 0, 1, 2);
		mainLayout.setRowStretch(1, 1);
		mainLayout.setRowStretch(2, 1);
		mainLayout.setColumnStretch(0, 1);
		mainLayout.setColumnStretch(1, 1);
		setLayout(mainLayout);

		setWindowTitle(tr("Styles"));
		changeStyle("NorwegianWood");
	}

	private:

	void changeStyle(string styleName)
	{
		if (styleName == "NorwegianWood") {
			QApplication.setStyle(new NorwegianWoodStyle);
		} else {
			QApplication.setStyle(QStyleFactory.create(styleName));
		}
		changePalette();
	}

	void changePalette()
	{
		if (useStylePaletteCheckBox.isChecked())
			QApplication.setPalette(QApplication.style().standardPalette());
		else
			QApplication.setPalette(originalPalette);
	}

	void advanceProgressBar()
	{
		int curVal = progressBar.value();
		int maxVal = progressBar.maximum();
		progressBar.setValue(curVal + (maxVal - curVal) / 100);
	}

private:

	void createTopLeftGroupBox()
	{
		topLeftGroupBox = new QGroupBox(tr("Group 1"));

		radioButton1 = new QRadioButton(tr("Radio button 1"));
		radioButton2 = new QRadioButton(tr("Radio button 2"));
		radioButton3 = new QRadioButton(tr("Radio button 3"));
		radioButton1.setChecked(true);

		checkBox = new QCheckBox(tr("Tri-state check box"));
		checkBox.setTristate(true);
		checkBox.setCheckState(Qt.PartiallyChecked);

		QVBoxLayout layout = new QVBoxLayout;
		layout.addWidget(radioButton1);
		layout.addWidget(radioButton2);
		layout.addWidget(radioButton3);
		layout.addWidget(checkBox);
		layout.addStretch(1);
		topLeftGroupBox.setLayout(layout);
	}

	void createTopRightGroupBox()
	{
		topRightGroupBox = new QGroupBox(tr("Group 2"));

		defaultPushButton = new QPushButton(tr("Default Push Button"));
		defaultPushButton.setDefault(true);

		togglePushButton = new QPushButton(tr("Toggle Push Button"));
		togglePushButton.setCheckable(true);
		togglePushButton.setChecked(true);

		flatPushButton = new QPushButton(tr("Flat Push Button"));
		flatPushButton.setFlat(true);

		QVBoxLayout layout = new QVBoxLayout;
		layout.addWidget(defaultPushButton);
		layout.addWidget(togglePushButton);
		layout.addWidget(flatPushButton);
		layout.addStretch(1);
		topRightGroupBox.setLayout(layout);
	}

	void createBottomLeftTabWidget()
	{
		bottomLeftTabWidget = new QTabWidget;
		bottomLeftTabWidget.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Ignored);

		QWidget tab1 = new QWidget;
		tableWidget = new QTableWidget(10, 10);

		QHBoxLayout tab1hbox = new QHBoxLayout;
		tab1hbox.setMargin(5);
		tab1hbox.addWidget(tableWidget);
		tab1.setLayout(tab1hbox);

		QWidget tab2 = new QWidget;
		textEdit = new QTextEdit;

		textEdit.setPlainText(tr("Twinkle, twinkle, little star,\n"
		      "How I wonder what you are.\n"
		      "Up above the world so high,\n"
		      "Like a diamond in the sky.\n"
		      "Twinkle, twinkle, little star,\n"
		      "How I wonder what you are!\n"));

		QHBoxLayout tab2hbox = new QHBoxLayout;
		tab2hbox.setMargin(5);
		tab2hbox.addWidget(textEdit);
		tab2.setLayout(tab2hbox);

		bottomLeftTabWidget.addTab(tab1, tr("&Table"));
		bottomLeftTabWidget.addTab(tab2, tr("Text &Edit"));
	}

	void createBottomRightGroupBox()
	{
		bottomRightGroupBox = new QGroupBox(tr("Group 3"));
		bottomRightGroupBox.setCheckable(true);
		bottomRightGroupBox.setChecked(true);

		lineEdit = new QLineEdit("s3cRe7");
		lineEdit.setEchoMode(QLineEdit.Password);

		spinBox = new QSpinBox(bottomRightGroupBox);
		spinBox.setValue(50);

		dateTimeEdit = new QDateTimeEdit(bottomRightGroupBox);
		dateTimeEdit.setDateTime(QDateTime.currentDateTime());

		slider = new QSlider(Qt.Horizontal, bottomRightGroupBox);
		slider.setValue(40);

		scrollBar = new QScrollBar(Qt.Horizontal, bottomRightGroupBox);
		scrollBar.setValue(60);

		dial = new QDial(bottomRightGroupBox);
		dial.setValue(30);
		dial.setNotchesVisible(true);

		QGridLayout layout = new QGridLayout;
		layout.addWidget(lineEdit, 0, 0, 1, 2);
		layout.addWidget(spinBox, 1, 0, 1, 2);
		layout.addWidget(dateTimeEdit, 2, 0, 1, 2);
		layout.addWidget(slider, 3, 0);
		layout.addWidget(scrollBar, 4, 0);
		layout.addWidget(dial, 3, 1, 2, 1);
		layout.setRowStretch(5, 1);
		bottomRightGroupBox.setLayout(layout);
	}

	void createProgressBar()
	{
		progressBar = new QProgressBar;
		progressBar.setRange(0, 10000);
		progressBar.setValue(0);

		QTimer timer = new QTimer(this);
		timer.timeout.connect(&this.advanceProgressBar);
		timer.start(1000);
	}


	QPalette originalPalette;

	QLabel styleLabel;
	QComboBox styleComboBox;
	QCheckBox useStylePaletteCheckBox;
	QCheckBox disableWidgetsCheckBox;

	QGroupBox topLeftGroupBox;
	QRadioButton radioButton1;
	QRadioButton radioButton2;
	QRadioButton radioButton3;
	QCheckBox checkBox;

	QGroupBox topRightGroupBox;
	QPushButton defaultPushButton;
	QPushButton togglePushButton;
	QPushButton flatPushButton;

	QTabWidget bottomLeftTabWidget;
	QTableWidget tableWidget;
	QTextEdit textEdit;

	QGroupBox bottomRightGroupBox;
	QLineEdit lineEdit;
	QSpinBox spinBox;
	QDateTimeEdit dateTimeEdit;
	QSlider slider;
	QScrollBar scrollBar;
	QDial dial;

	QProgressBar progressBar;
}
