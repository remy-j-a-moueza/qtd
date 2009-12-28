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
module window;


import qt.core.QAbstractItemModel;
import qt.gui.QWidget;
import qt.gui.QCheckBox;
import qt.gui.QComboBox;
import qt.gui.QDateEdit;
import qt.gui.QGroupBox;
import qt.gui.QLabel;
import qt.gui.QLineEdit;
import qt.gui.QTreeView;
import qt.gui.QHBoxLayout;
import qt.gui.QVBoxLayout;
import qt.gui.QGridLayout;

version(D_Version2)
    import mysortfilterproxymodel;
else
    import mysortfilterproxymodel_d1;

class Window : public QWidget
{
public:

	this()
	{
		proxyModel = new MySortFilterProxyModel(this);
		proxyModel.setDynamicSortFilter(true);

		sourceView = new QTreeView;
		sourceView.setRootIsDecorated(false);
		sourceView.setAlternatingRowColors(true);

		QHBoxLayout sourceLayout = new QHBoxLayout;

		sourceLayout.addWidget(sourceView);
		sourceGroupBox = new QGroupBox(tr("Original Model"));
		sourceGroupBox.setLayout(sourceLayout);

		filterCaseSensitivityCheckBox = new QCheckBox(tr("Case sensitive filter"));
		filterCaseSensitivityCheckBox.setChecked(true);

		filterPatternLineEdit = new QLineEdit;
		filterPatternLineEdit.setText("Grace|Sports");

		filterPatternLabel = new QLabel(tr("&Filter pattern:"));
		filterPatternLabel.setBuddy(filterPatternLineEdit);

		filterSyntaxComboBox = new QComboBox;
		filterSyntaxComboBox.addItem(tr("Regular expression"), new QVariant(cast(ulong) QRegExp.RegExp));
		filterSyntaxComboBox.addItem(tr("Wildcard"), new QVariant(cast(ulong) QRegExp.Wildcard));
		filterSyntaxComboBox.addItem(tr("Fixed string"), new QVariant(cast(ulong) QRegExp.FixedString));

		fromDateEdit = new QDateEdit;
		fromDateEdit.setDate(new QDate(1970, 01, 01));
		fromLabel = new QLabel(tr("F&rom:"));
		fromLabel.setBuddy(fromDateEdit);

		toDateEdit = new QDateEdit;
		toDateEdit.setDate(new QDate(2099, 12, 31));
		toLabel = new QLabel(tr("&To:"));
		toLabel.setBuddy(toDateEdit);

		connect(filterPatternLineEdit, "textChanged", this, "textFilterChanged");
		connect(filterSyntaxComboBox, "currentIndexChanged", this, "textFilterChanged");
		connect(filterCaseSensitivityCheckBox, "toggled", this, "textFilterChanged");
		connect(fromDateEdit, "dateChanged", this, "dateFilterChanged");
		connect(toDateEdit, "dateChanged", this, "dateFilterChanged");

		proxyView = new QTreeView;
		proxyView.setRootIsDecorated(false);
		proxyView.setAlternatingRowColors(true);
		proxyView.setModel(proxyModel);
		proxyView.setSortingEnabled(true);
		proxyView.sortByColumn(1, Qt.AscendingOrder);

		QGridLayout proxyLayout = new QGridLayout;
		proxyLayout.addWidget(proxyView, 0, 0, 1, 3);
		proxyLayout.addWidget(filterPatternLabel, 1, 0);
		proxyLayout.addWidget(filterPatternLineEdit, 1, 1);
		proxyLayout.addWidget(filterSyntaxComboBox, 1, 2);
		proxyLayout.addWidget(filterCaseSensitivityCheckBox, 2, 0, 1, 3);
		proxyLayout.addWidget(fromLabel, 3, 0);
		proxyLayout.addWidget(fromDateEdit, 3, 1, 1, 2);
		proxyLayout.addWidget(toLabel, 4, 0);
		proxyLayout.addWidget(toDateEdit, 4, 1, 1, 2);

		proxyGroupBox = new QGroupBox(tr("Sorted/Filtered Model"));
		proxyGroupBox.setLayout(proxyLayout);

		QVBoxLayout mainLayout = new QVBoxLayout;
		mainLayout.addWidget(sourceGroupBox);
		mainLayout.addWidget(proxyGroupBox);
		setLayout(mainLayout);

		setWindowTitle(tr("Custom Sort/Filter Model"));
		resize(500, 450);
	}

	void setSourceModel(QAbstractItemModel model)
	{
		proxyModel.setSourceModel(model);
		sourceView.setModel(model);
	}

private: // slots

	void slot_textFilterChanged()
	{
		QRegExp.PatternSyntax syntax = cast(QRegExp.PatternSyntax) filterSyntaxComboBox.itemData(
			filterSyntaxComboBox.currentIndex()).toInt();
		Qt.CaseSensitivity caseSensitivity =
			filterCaseSensitivityCheckBox.isChecked() ? Qt.CaseSensitive
				: Qt.CaseInsensitive;

		auto regExp = new QRegExp(filterPatternLineEdit.text(), caseSensitivity, syntax);
		proxyModel.setFilterRegExp(regExp);
	}

	void slot_dateFilterChanged()
	{
		proxyModel.setFilterMinimumDate(fromDateEdit.date());
		proxyModel.setFilterMaximumDate(toDateEdit.date());
	}
    
    mixin Q_OBJECT;

private:

	MySortFilterProxyModel proxyModel;

	QGroupBox sourceGroupBox;
	QGroupBox proxyGroupBox;
	QTreeView sourceView;
	QTreeView proxyView;
	QCheckBox filterCaseSensitivityCheckBox;
	QLabel filterPatternLabel;
	QLabel fromLabel;
	QLabel toLabel;
	QLineEdit filterPatternLineEdit;
	QComboBox filterSyntaxComboBox;
	QDateEdit fromDateEdit;
	QDateEdit toDateEdit;
}
