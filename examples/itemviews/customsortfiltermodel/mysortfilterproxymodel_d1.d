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
module mysortfilterproxymodel_d1;

import qt.core.QDate;
import qt.core.QVariant;
import qt.core.QDateTime;
import qt.gui.QSortFilterProxyModel;


class MySortFilterProxyModel : public QSortFilterProxyModel
{
public:

	this(QObject parent = null)
	{
		super(parent);
		minDate = new QDate();
		maxDate = new QDate();
	}

	QDate filterMinimumDate()
	{
		return minDate;
	}
	
	void setFilterMinimumDate(QDate date)
	{
		minDate = date;
		invalidateFilter();
	}

	QDate filterMaximumDate()
	{
		return maxDate;
	}
	
	void setFilterMaximumDate(QDate date)
	{
		maxDate = date;
		invalidateFilter();
	}

protected:

	override bool filterAcceptsRow(int sourceRow, QModelIndex sourceParent)
	{
		QModelIndex index0 = sourceModel().index(sourceRow, 0, sourceParent);
		QModelIndex index1 = sourceModel().index(sourceRow, 1, sourceParent);
		QModelIndex index2 = sourceModel().index(sourceRow, 2, sourceParent);

		static bool contains(string str, QRegExp rx1)
		{
			auto rx2 = new QRegExp(rx1);
			return (rx2.indexIn(str, 0) != -1);
		}
		
		return (contains(sourceModel().data(index0).toString(), filterRegExp())
			|| contains(sourceModel().data(index1).toString(), filterRegExp()))
			&& dateInRange(sourceModel().data(index2).toDate());
	}

	override bool lessThan(QModelIndex left, QModelIndex right)
	{
		QVariant leftData = sourceModel().data(left);
		QVariant rightData = sourceModel().data(right);

		if (leftData.type() == QVariant.Type.DateTime) {
			return leftData.toDateTime() < rightData.toDateTime();
		} else {
			QRegExp emailPattern = new QRegExp("([\\w\\.]*@[\\w\\.]*)");

			string leftString = leftData.toString();
			if(left.column() == 1 && emailPattern.indexIn(leftString) != -1)
				leftString = emailPattern.cap(1);

			string rightString = rightData.toString();
			if(right.column() == 1 && emailPattern.indexIn(rightString) != -1)
				rightString = emailPattern.cap(1);

			return leftString < rightString;
		}
	}

private:

	bool dateInRange(QDate date)
	{
		return (!minDate.isValid() || date > minDate) && (!maxDate.isValid() || date < maxDate);
	}

	QDate minDate;
	QDate maxDate;
}
