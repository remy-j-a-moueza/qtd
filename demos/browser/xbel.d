/****************************************************************************
**
** Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies).
** Contact: Qt Software Information (qt-info@nokia.com)
**
** This file is part of the demonstration applications of the Qt Toolkit.
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

module xbel;


import qt.xml.QXmlStreamReader;

import qt.core.QDateTime;
import qt.core.QFile;


class BookmarkNode
{
public:

	enum Type {
		Root,
		Folder,
		Bookmark,
		Separator
	};

	this(Type type = Type.Root, BookmarkNode parent = null)
	{
		expanded = false;
		m_parent = parent;
		m_type = type;

		if (parent)
			parent.add(this);
	}

	~this()
	{
		if (m_parent)
			m_parent.remove(this);
		qDeleteAll(m_children);
		m_parent = 0;
		m_type = BookmarkNode.Root;
	}

	int opEquals(BookmarkNode other)
	{
		if (url != other.url || title != other.title || desc != other.desc || expanded != other.expanded
			|| m_type != other.m_type || m_children.length != other.m_children.length)
			return cast(int) false;

		for (int i = 0; i < m_children.length; ++i)
			if (!((*(m_children[i])) == (*(other.m_children[i]))))
				return cast(int) false;
		return cast(int) true;
	}

	Type type()
	{
		return m_type;
	}

	void setType(Type type)
	{
		m_type = type;
	}

	BookmarkNode[] children()
	{
		return m_children;
	}

	BookmarkNode parent()
	{
		return m_parent;
	}

	void add(BookmarkNode child, int offset = -1)
	{
		assert(child.m_type != Root);
		if (child.m_parent)
			child.m_parent.remove(child);
		child.m_parent = this;
		if (-1 == offset)
			offset = m_children.length;
		m_children.insert(offset, child);
	}

	void remove(BookmarkNode child)
	{
		child.m_parent = 0;
		m_children.removeAll(child);
	}

	string url;
	string title;
	string desc;
	bool expanded;

private:

	BookmarkNode m_parent;
	Type m_type;
	BookmarkNode[] m_children;
}

class XbelReader : public QXmlStreamReader
{
public:

	this()
	{
	}

	BookmarkNode read(string fileName)
	{
		auto file = new QFile(fileName);
		if (!file.exists()) {
			return new BookmarkNode(BookmarkNode.Root);
		}
		file.open(QFile.ReadOnly);
		return read(&file);
	}

	BookmarkNode read(QIODevice device)
	{
		BookmarkNode root = new BookmarkNode(BookmarkNode.Root);
		setDevice(device);
		while (!atEnd()) {
			readNext();
			if (isStartElement()) {
				string version_ = attributes().value("version").toString();
				if (name() == "xbel" && (version_.isEmpty() || version_ == "1.0")) {
					readXBEL(root);
				} else {
					raiseError(QObject.tr("The file is not an XBEL version 1.0 file."));
				}
			}
		}
		return root;
	}

private:

	void skipUnknownElement()
	{
		assert(isStartElement());

		while (!atEnd()) {
			readNext();

			if (isEndElement())
				break;

			if (isStartElement())
				skipUnknownElement();
		}
	}

	void readXBEL(BookmarkNode parent)
	{
		assert(isStartElement() && name() == "xbel");

		while (!atEnd()) {
			readNext();
			if (isEndElement())
				break;

			if (isStartElement()) {
				if (name() == "folder")
					readFolder(parent);
				else if (name() == "bookmark")
					readBookmarkNode(parent);
				else if (name() == "separator")
					readSeparator(parent);
				else
					skipUnknownElement();
			}
		}
	}

	void readTitle(BookmarkNode parent)
	{
		assert(isStartElement() && name() == "title");
		parent.title = readElementText();
	}

	void readDescription(BookmarkNode parent)
	{
		assert(isStartElement() && name() == "desc");
		parent.desc = readElementText();
	}

	void readSeparator(BookmarkNode parent)
	{
		new BookmarkNode(BookmarkNode.Separator, parent);
		// empty elements have a start and end element
		readNext();
	}


	void readFolder(BookmarkNode parent)
	{
		assert(isStartElement() && name() == "folder");

		BookmarkNode folder = new BookmarkNode(BookmarkNode.Folder, parent);
		folder.expanded = (attributes().value("folded") == "no");

		while (!atEnd()) {
			readNext();

			if (isEndElement())
				break;

			if (isStartElement()) {
				if (name() == "title")
					readTitle(folder);
				else if (name() == "desc")
					readDescription(folder);
				else if (name() == "folder")
					readFolder(folder);
				else if (name() == "bookmark")
					readBookmarkNode(folder);
				else if (name() == "separator")
					readSeparator(folder);
				else
					skipUnknownElement();
			}
		}
	}

	void readBookmarkNode(BookmarkNode parent)
	{
		assert(isStartElement() && name() == "bookmark");
		BookmarkNode bookmark = new BookmarkNode(BookmarkNode.Bookmark, parent);
		bookmark.url = attributes().value("href").toString();
		while (!atEnd()) {
			readNext();
			if (isEndElement())
				break;

			if (isStartElement()) {
				if (name() == "title")
					readTitle(bookmark);
				else if (name() == "desc")
					readDescription(bookmark);
				else
					skipUnknownElement();
			}
		}
		if (bookmark.title.isEmpty())
			bookmark.title = QObject.tr("Unknown title");
	}
}

import qt.xml.QXmlStreamWriter;

class XbelWriter : public QXmlStreamWriter
{
public:

	this()
	{
		setAutoFormatting(true);
	}
	
	bool write(string fileName, BookmarkNode root)
	{
		auto file = new QFile(fileName);
		if (!root || !file.open(QFile.WriteOnly))
			return false;
		return write(&file, root);
	}

	bool write(QIODevice device, BookmarkNode root)
	{
		setDevice(device);

		writeStartDocument();
		writeDTD("<!DOCTYPE xbel>");
		writeStartElement("xbel");
		writeAttribute("version", "1.0");
		if (root.type() == BookmarkNode.Root) {
			for (int i = 0; i < root.children().length; ++i)
				writeItem(root.children()[i]);
		} else {
			writeItem(root);
		}

		writeEndDocument();
		return true;
	}

private:

	void writeItem(BookmarkNode parent)
	{
		switch (parent.type()) {
			case BookmarkNode.Folder:
				writeStartElement("folder");
				writeAttribute("folded", parent.expanded ? "no" : "yes");
				writeTextElement("title", parent.title);
				for (int i = 0; i < parent.children().count(); ++i)
					writeItem(parent.children()[i]);
				writeEndElement();
				break;
			case BookmarkNode.Bookmark:
				writeStartElement("bookmark");
				if (!parent.url.isEmpty())
					writeAttribute("href", parent.url);
				writeTextElement("title", parent.title);
				if (!parent.desc.isEmpty())
					writeAttribute("desc", parent.desc);
				writeEndElement();
				break;
			case BookmarkNode.Separator:
				writeEmptyElement("separator");
				break;
			default:
				break;
		}
	}
}
