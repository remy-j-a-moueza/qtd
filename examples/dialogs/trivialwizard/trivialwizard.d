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
module trivialwizard;


import qt.core.QTranslator;
import qt.core.QLocale;
import qt.core.QLibraryInfo;
import qt.gui.QGridLayout;
import qt.gui.QWizardPage;
import qt.gui.QLabel;
import qt.gui.QVBoxLayout;
import qt.gui.QLineEdit;

QWizardPage createIntroPage()
{
	QWizardPage page = new QWizardPage;
	page.setTitle("Introduction");

	QLabel label = new QLabel("This wizard will help you register your copy of Super Product Two.");
	label.setWordWrap(true);

	QVBoxLayout layout = new QVBoxLayout;
	layout.addWidget(label);
	page.setLayout(layout);

	return page;
}

QWizardPage createRegistrationPage()
{
	QWizardPage page = new QWizardPage;
	page.setTitle("Registration");
	page.setSubTitle("Please fill both fields.");

	QLabel nameLabel = new QLabel("Name:");
	QLineEdit nameLineEdit = new QLineEdit;

	QLabel emailLabel = new QLabel("Email address:");
	QLineEdit emailLineEdit = new QLineEdit;

	QGridLayout layout = new QGridLayout;
	layout.addWidget(nameLabel, 0, 0);
	layout.addWidget(nameLineEdit, 0, 1);
	layout.addWidget(emailLabel, 1, 0);
	layout.addWidget(emailLineEdit, 1, 1);
	page.setLayout(layout);

	return page;
}

QWizardPage createConclusionPage()
{
	QWizardPage page = new QWizardPage;
	page.setTitle("Conclusion");

	QLabel label = new QLabel("You are now successfully registered. Have a nice day!");
	label.setWordWrap(true);

	QVBoxLayout layout = new QVBoxLayout;
	layout.addWidget(label);
	page.setLayout(layout);

	return page;
}

int main(string[] args)
{
	scope app = new QApplication(args);

	string translatorFileName = "qt_";
	translatorFileName ~= QLocale.system().name();
	scope translator = new QTranslator(app);
	if (translator.load(translatorFileName, QLibraryInfo.location(QLibraryInfo.TranslationsPath)))
		app.installTranslator(translator);


	scope wizard = new QWizard;
	wizard.addPage(createIntroPage());
	wizard.addPage(createRegistrationPage());
	wizard.addPage(createConclusionPage());

	wizard.setWindowTitle("Trivial Wizard");
	wizard.show();

	return app.exec();
}
