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
module classwizard_d1;

import qt.gui.QWizardPage;
import qt.gui.QCheckBox;
import qt.gui.QGroupBox;
import qt.gui.QLabel;
import qt.gui.QLineEdit;
import qt.gui.QRadioButton;
import qt.gui.QMessageBox;
import qt.gui.QVBoxLayout;
import qt.gui.QGridLayout;
import qt.core.QFile;
import qt.core.QDir;
import qt.core.QRegExp;

import tango.text.convert.Format;
import tango.core.Array;
import tango.text.Ascii;


class ClassWizard : public QWizard
{
public:

	this(QWidget parent = null)
	{
		super(parent);
		addPage(new IntroPage);
		addPage(new ClassInfoPage);
		addPage(new CodeStylePage);
		addPage(new OutputFilesPage);
		addPage(new ConclusionPage);

		setPixmap(QWizard.BannerPixmap, new QPixmap(":/images/banner.png"));
		setPixmap(QWizard.BackgroundPixmap, new QPixmap(":/images/background.png"));

		setWindowTitle(tr("Class Wizard"));
	}

	void accept()
	{
		string className = field("className").toString();
		string baseClass = field("baseClass").toString();
		string macroName = field("macroName").toString();
		string baseInclude = field("baseInclude").toString();

		string outputDir = field("outputDir").toString();
		string header = field("header").toString();
		string implementation = field("implementation").toString();

		string block;

		if (field("comment").toBool()) {
			block ~= "/*\n";
			block ~= "    " ~ header ~ "\n";
			block ~= "*/\n";
			block ~= "\n";
		}
		if (field("protect").toBool()) {
			block ~= "#ifndef " ~ macroName ~ "\n";
			block ~= "#define " ~ macroName ~ "\n";
			block ~= "\n";
		}
		if (field("includeBase").toBool()) {
			block ~= "#include " ~ baseInclude ~ "\n";
			block ~= "\n";
		}

		block ~= "class " ~ className;
		if (baseClass.length)
			block ~= " : public " ~ baseClass;
		block ~= "\n";
		block ~= "{\n";

		/* qmake ignore  */

		if (field("qobjectMacro").toBool()) {
			block ~= "    \n";
			block ~= "\n";
		}
		block ~= "public:\n";

		if (field("qobjectCtor").toBool()) {
			block ~= "    " ~ className ~ "(QObject *parent = 0);\n";
		} else if (field("qwidgetCtor").toBool()) {
			block ~= "    " ~ className ~ "(QWidget *parent = 0);\n";
		} else if (field("defaultCtor").toBool()) {
			block ~= "    " ~ className ~ "();\n";
			if (field("copyCtor").toBool()) {
				block ~= "    " ~ className ~ "(const " ~ className ~ " &other);\n";
				block ~= "\n";
				block ~= "    " ~ className ~ " &operator=" ~ "(const " ~ className ~ " &other);\n";
			}
		}
		block ~= "};\n";

		if (field("protect").toBool()) {
			block ~= "\n";
			block ~= "#endif\n";
		}

        scope headerFile = new QFile(outputDir ~ "/" ~ header);
		if (!headerFile.open(QFile.WriteOnly | QFile.Text)) {
			QMessageBox.warning(null, tr("Simple Wizard"),
					Format(tr("Cannot write file {}:\n{}"),
					headerFile.fileName(),
					headerFile.errorString()));
			return;
		}
		headerFile.write(block);

		block.length = 0;

		if (field("comment").toBool()) {
			block ~= "/*\n";
			block ~= "    " ~ implementation ~ "\n";
			block ~= "*/\n";
			block ~= "\n";
		}
		block ~= "#include \"" ~ header ~ "\"\n";
		block ~= "\n";

		if (field("qobjectCtor").toBool()) {
			block ~= className ~ "." ~ className ~ "(QObject *parent)\n";
			block ~= "    : " ~ baseClass ~ "(parent)\n";
			block ~= "{\n";
			block ~= "}\n";
		} else if (field("qwidgetCtor").toBool()) {
			block ~= className ~ "." ~ className ~ "(QWidget *parent)\n";
			block ~= "    : " ~ baseClass ~ "(parent)\n";
			block ~= "{\n";
			block ~= "}\n";
		} else if (field("defaultCtor").toBool()) {
			block ~= className ~ "." ~ className ~ "()\n";
			block ~= "{\n";
			block ~= "    // missing code\n";
			block ~= "}\n";

			if (field("copyCtor").toBool()) {
				block ~= "\n";
				block ~= className ~ "." ~ className ~ "(const " ~ className ~ " &other)\n";
				block ~= "{\n";
				block ~= "    *this = other;\n";
				block ~= "}\n";
				block ~= "\n";
				block ~= className ~ " &" ~ className ~ ".operator=(const " ~ className ~ " &other)\n";
				block ~= "{\n";
				if (baseClass.length)
					block ~= "    " ~ baseClass ~ ".operator=(other);\n";
				block ~= "    // missing code\n";
				block ~= "    return *this;\n";
				block ~= "}\n";
			}
		}

        scope implementationFile = new QFile(outputDir ~ "/" ~ implementation);
		if (!implementationFile.open(QFile.WriteOnly | QFile.Text)) {
			QMessageBox.warning(null, tr("Simple Wizard"),
					Format(tr("Cannot write file {}:\n{}"),
					implementationFile.fileName(),
					implementationFile.errorString()));
			return;
		}
		implementationFile.write(block);

		QDialog.accept();
	}
}


class IntroPage : public QWizardPage
{
public:

	this(QWidget parent = null)
	{
		super(parent);
		setTitle(tr("Introduction"));
		setPixmap(QWizard.WatermarkPixmap, new QPixmap(":/images/watermark1.png"));

		label = new QLabel(tr("This wizard will generate a skeleton C++ class "
				"definition, including a few functions. You simply "
				"need to specify the class name and set a few "
				"options to produce a header file and an "
				"implementation file for your new C++ class."));
		label.setWordWrap(true);

		QVBoxLayout layout = new QVBoxLayout;
		layout.addWidget(label);
		setLayout(layout);
	}

private:

	QLabel label;
}
	
class ClassInfoPage : public QWizardPage
{
public:

	this(QWidget parent = null)
	{
		super(parent);
		setTitle(tr("Class Information"));
		setSubTitle(tr("Specify basic information about the class for which you want to generate skeleton source code files."));
		setPixmap(QWizard.LogoPixmap, new QPixmap(":/images/logo1.png"));

		classNameLabel = new QLabel(tr("&Class name:"));
		classNameLineEdit = new QLineEdit;
		classNameLabel.setBuddy(classNameLineEdit);

		baseClassLabel = new QLabel(tr("B&ase class:"));
		baseClassLineEdit = new QLineEdit;
		baseClassLabel.setBuddy(baseClassLineEdit);

		qobjectMacroCheckBox = new QCheckBox(tr("Generate  &macro"));

		groupBox = new QGroupBox(tr("C&onstructor"));

		qobjectCtorRadioButton = new QRadioButton(tr("&QObject-style constructor"));
		qwidgetCtorRadioButton = new QRadioButton(tr("Q&Widget-style constructor"));
		defaultCtorRadioButton = new QRadioButton(tr("&Default constructor"));
		copyCtorCheckBox = new QCheckBox(tr("&Generate copy constructor and operator="));

		defaultCtorRadioButton.setChecked(true);
        connect!("toggled")(defaultCtorRadioButton, &copyCtorCheckBox.setEnabled);

		registerField("className*", classNameLineEdit);
		registerField("baseClass", baseClassLineEdit);
		registerField("qobjectMacro", qobjectMacroCheckBox);
		registerField("qobjectCtor", qobjectCtorRadioButton);
		registerField("qwidgetCtor", qwidgetCtorRadioButton);
		registerField("defaultCtor", defaultCtorRadioButton);
		registerField("copyCtor", copyCtorCheckBox);

		QVBoxLayout groupBoxLayout = new QVBoxLayout;

		groupBoxLayout.addWidget(qobjectCtorRadioButton);
		groupBoxLayout.addWidget(qwidgetCtorRadioButton);
		groupBoxLayout.addWidget(defaultCtorRadioButton);
		groupBoxLayout.addWidget(copyCtorCheckBox);
		groupBox.setLayout(groupBoxLayout);

		QGridLayout layout = new QGridLayout;
		layout.addWidget(classNameLabel, 0, 0);
		layout.addWidget(classNameLineEdit, 0, 1);
		layout.addWidget(baseClassLabel, 1, 0);
		layout.addWidget(baseClassLineEdit, 1, 1);
		layout.addWidget(qobjectMacroCheckBox, 2, 0, 1, 2);
		layout.addWidget(groupBox, 3, 0, 1, 2);
		setLayout(layout);
	}

private:

	QLabel classNameLabel;
	QLabel baseClassLabel;
	QLineEdit classNameLineEdit;
	QLineEdit baseClassLineEdit;
	QCheckBox qobjectMacroCheckBox;
	QGroupBox groupBox;
	QRadioButton qobjectCtorRadioButton;
	QRadioButton qwidgetCtorRadioButton;
	QRadioButton defaultCtorRadioButton;
	QCheckBox copyCtorCheckBox;
}

class CodeStylePage : public QWizardPage
{
public:

	this(QWidget parent = null)
	{
		super(parent);
		setTitle(tr("Code Style Options"));
		setSubTitle(tr("Choose the formatting of the generated code."));
		setPixmap(QWizard.LogoPixmap, new QPixmap(":/images/logo2.png"));

		commentCheckBox = new QCheckBox(tr("&Start generated files with a comment"));
		commentCheckBox.setChecked(true);

		protectCheckBox = new QCheckBox(tr("&Protect header file against multiple inclusions"));
		protectCheckBox.setChecked(true);

		macroNameLabel = new QLabel(tr("&Macro name:"));
		macroNameLineEdit = new QLineEdit;
		macroNameLabel.setBuddy(macroNameLineEdit);

		includeBaseCheckBox = new QCheckBox(tr("&Include base class definition"));
		baseIncludeLabel = new QLabel(tr("Base class include:"));
		baseIncludeLineEdit = new QLineEdit;
		baseIncludeLabel.setBuddy(baseIncludeLineEdit);

        connect!("toggled")(protectCheckBox, &macroNameLabel.setEnabled);
// ?    connect!("toggled")(protectCheckBox, &macroNameLabel.setEnabled);
        connect!("toggled")(includeBaseCheckBox, &macroNameLabel.setEnabled);
// ?    connect!("toggled")(includeBaseCheckBox, &macroNameLabel.setEnabled);

		registerField("comment", commentCheckBox);
		registerField("protect", protectCheckBox);
		registerField("macroName", macroNameLineEdit);
		registerField("includeBase", includeBaseCheckBox);
		registerField("baseInclude", baseIncludeLineEdit);

		QGridLayout layout = new QGridLayout;
		layout.setColumnMinimumWidth(0, 20);
		layout.addWidget(commentCheckBox, 0, 0, 1, 3);
		layout.addWidget(protectCheckBox, 1, 0, 1, 3);
		layout.addWidget(macroNameLabel, 2, 1);
		layout.addWidget(macroNameLineEdit, 2, 2);
		layout.addWidget(includeBaseCheckBox, 3, 0, 1, 3);
		layout.addWidget(baseIncludeLabel, 4, 1);
		layout.addWidget(baseIncludeLineEdit, 4, 2);

		setLayout(layout);
	}

protected:

	void initializePage()
	{
		string className = field("className").toString();
		macroNameLineEdit.setText(toUpper(className) ~ "_H");

		string baseClass = field("baseClass").toString();

		includeBaseCheckBox.setChecked(baseClass.length != 0);
		includeBaseCheckBox.setEnabled(baseClass.length != 0);
		baseIncludeLabel.setEnabled(baseClass.length != 0);
		baseIncludeLineEdit.setEnabled(baseClass.length != 0);

		if (baseClass.length == 0) {
			baseIncludeLineEdit.clear();
		} else if ((new QRegExp("Q[A-Z].*")).exactMatch(baseClass)) {
			baseIncludeLineEdit.setText("<" ~ baseClass ~ ">");
		} else {
			baseIncludeLineEdit.setText("\"" ~ toLower(baseClass) ~ ".h\"");
		}
	}

private:

	QCheckBox commentCheckBox;
	QCheckBox protectCheckBox;
	QCheckBox includeBaseCheckBox;
	QLabel macroNameLabel;
	QLabel baseIncludeLabel;
	QLineEdit macroNameLineEdit;
	QLineEdit baseIncludeLineEdit;
}

class OutputFilesPage : public QWizardPage
{
public:    

	this(QWidget parent = null)
	{
		super(parent);
		setTitle(tr("Output Files"));
		setSubTitle(tr("Specify where you want the wizard to put the generated skeleton code."));
		setPixmap(QWizard.LogoPixmap, new QPixmap(":/images/logo3.png"));

		outputDirLabel = new QLabel(tr("&Output directory:"));
		outputDirLineEdit = new QLineEdit;
		outputDirLabel.setBuddy(outputDirLineEdit);

		headerLabel = new QLabel(tr("&Header file name:"));
		headerLineEdit = new QLineEdit;
		headerLabel.setBuddy(headerLineEdit);

		implementationLabel = new QLabel(tr("&Implementation file name:"));
		implementationLineEdit = new QLineEdit;
		implementationLabel.setBuddy(implementationLineEdit);

		registerField("outputDir*", outputDirLineEdit);
		registerField("header*", headerLineEdit);
		registerField("implementation*", implementationLineEdit);

		QGridLayout layout = new QGridLayout;
		layout.addWidget(outputDirLabel, 0, 0);
		layout.addWidget(outputDirLineEdit, 0, 1);
		layout.addWidget(headerLabel, 1, 0);
		layout.addWidget(headerLineEdit, 1, 1);
		layout.addWidget(implementationLabel, 2, 0);
		layout.addWidget(implementationLineEdit, 2, 1);
		setLayout(layout);
	}

protected:

	void initializePage()
	{
		string className = field("className").toString();
		headerLineEdit.setText(toLower(className) ~ ".h");
		implementationLineEdit.setText(toLower(className) ~ ".cpp");
		outputDirLineEdit.setText(QDir.convertSeparators(QDir.tempPath()));
	}

private:

	QLabel outputDirLabel;
	QLabel headerLabel;
	QLabel implementationLabel;
	QLineEdit outputDirLineEdit;
	QLineEdit headerLineEdit;
	QLineEdit implementationLineEdit;
}

class ConclusionPage : public QWizardPage
{
public:

	this(QWidget parent = null)
	{
		super(parent);
		setTitle(tr("Conclusion"));
		setPixmap(QWizard.WatermarkPixmap, new QPixmap(":/images/watermark2.png"));

		label = new QLabel;
		label.setWordWrap(true);

		QVBoxLayout layout = new QVBoxLayout;
		layout.addWidget(label);
		setLayout(layout);
	}

protected:

	void initializePage()
	{
		string finishText = wizard().buttonText(QWizard.FinishButton).dup;	
		label.setText(Format(tr("Click {} to generate the class skeleton."), finishText));
	}

private:

	QLabel label;
}
