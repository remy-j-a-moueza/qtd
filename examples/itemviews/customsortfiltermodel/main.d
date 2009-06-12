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
module main;


import qt.core.QAbstractItemModel;
import qt.core.QDateTime;
import qt.gui.QStandardItemModel;

import window;


void addMail(QAbstractItemModel model, string subject, string sender, QDateTime date)
{
	model.insertRow(0);
	model.setData(model.index(0, 0), new QVariant(subject));
	model.setData(model.index(0, 1), new QVariant(sender));
	model.setData(model.index(0, 2), new QVariant(date));
}

QAbstractItemModel createMailModel(QObject parent)
{
	QStandardItemModel model = new QStandardItemModel(0, 3, parent);

	model.setHeaderData(0, Qt.Horizontal, new QVariant(tr("Subject")));
	model.setHeaderData(1, Qt.Horizontal, new QVariant(tr("Sender")));
	model.setHeaderData(2, Qt.Horizontal, new QVariant(tr("Date")));

	addMail(model, "Happy New Year!", "Grace K. <grace@software-inc.com>",
		new QDateTime(new QDate(2006, 12, 31), new QTime(17, 03)));
	addMail(model, "Radically new concept", "Grace K. <grace@software-inc.com>",
		new QDateTime(new QDate(2006, 12, 22), new QTime(9, 44)));
	addMail(model, "Accounts", "pascale@nospam.com",
		new QDateTime(new QDate(2006, 12, 31), new QTime(12, 50)));
	addMail(model, "Expenses", "Joe Bloggs <joe@bloggs.com>",
		new QDateTime(new QDate(2006, 12, 25), new QTime(11, 39)));
	addMail(model, "Re: Expenses", "Andy <andy@nospam.com>",
		new QDateTime(new QDate(2007, 01, 02), new QTime(16, 05)));
	addMail(model, "Re: Accounts", "Joe Bloggs <joe@bloggs.com>",
		new QDateTime(new QDate(2007, 01, 03), new QTime(14, 18)));
	addMail(model, "Re: Accounts", "Andy <andy@nospam.com>",
		new QDateTime(new QDate(2007, 01, 03), new QTime(14, 26)));
	addMail(model, "Sports", "Linda Smith <linda.smith@nospam.com>",
		new QDateTime(new QDate(2007, 01, 05), new QTime(11, 33)));
	addMail(model, "AW: Sports", "Rolf Newschweinstein <rolfn@nospam.com>",
		new QDateTime(new QDate(2007, 01, 05), new QTime(12, 00)));
	addMail(model, "RE: Sports", "Petra Schmidt <petras@nospam.com>",
		new QDateTime(new QDate(2007, 01, 05), new QTime(12, 01)));

	return model;
}


int main(string[] args)
{
	scope app = new QApplication(args);
	scope window = new Window;
	window.setSourceModel(createMailModel(window));
	window.show();
	return app.exec();
}
