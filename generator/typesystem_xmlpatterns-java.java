/****************************************************************************
**
** Copyright (C) 1992-2008 Nokia. All rights reserved.
**
** This file is part of Qt Jambi.
**
** * Commercial Usage
* Licensees holding valid Qt Commercial licenses may use this file in
* accordance with the Qt Commercial License Agreement provided with the
* Software or, alternatively, in accordance with the terms contained in
* a written agreement between you and Nokia.
*
*
* GNU General Public License Usage
* Alternatively, this file may be used under the terms of the GNU
* General Public License versions 2.0 or 3.0 as published by the Free
* Software Foundation and appearing in the file LICENSE.GPL included in
* the packaging of this file.  Please review the following information
* to ensure GNU General Public Licensing requirements will be met:
* http://www.fsf.org/licensing/licenses/info/GPLv2.html and
* http://www.gnu.org/copyleft/gpl.html.  In addition, as a special
* exception, Nokia gives you certain additional rights. These rights
* are described in the Nokia Qt GPL Exception version 1.2, included in
* the file GPL_EXCEPTION.txt in this package.
* 
* Qt for Windows(R) Licensees
* As a special exception, Nokia, as the sole copyright holder for Qt
* Designer, grants users of the Qt/Eclipse Integration plug-in the
* right for the Qt/Eclipse Integration to link to functionality
* provided by Qt Designer and its related libraries.
*
*
* If you are unsure which license is appropriate for your use, please
* contact the sales department at qt-sales@nokia.com.

**
** This file is provided AS IS with NO WARRANTY OF ANY KIND, INCLUDING THE
** WARRANTY OF DESIGN, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
**
****************************************************************************/

package generator;

import qt.QtBlockedSlot;
import qt.xmlpatterns.QAbstractXmlNodeModel;
import qt.xmlpatterns.QXmlNodeModelIndex;

class QXmlNodeModelIndex___ extends QXmlNodeModelIndex {
    @QtBlockedSlot
    public final QAbstractXmlNodeModel model() {
        return QAbstractXmlNodeModel.fromNativePointer(model_private());
    }
}// class

class QXmlName___ extends QXmlName {

      /**
       * Constructs a <code>QXmlName</code> instance that inserts <code>localName</code>,
       * <code>namespaceURI</code> and <code>prefix</code> into <code>namePool</code> if they aren't
       * already there. The accessor functions <code>namespaceUri()</code>, <code>prefix()</code>,
       * <code>localName()</code>, and <code>toClarkName()</code> must be passed the <code>namePool</code>
       * used here, so the <code>namePool</code> must remain in scope while the
       * accessor functions might be used. However, two instances can
       * be compared with <code>==</code> or <code>!=</code> and copied without the
       * <code>namePool</code>.
       *
       * The user guarantees that the string components are valid for a
       * <code>QName</code>. In particular, the local name, and the prefix (if present),
       * must be valid {@link <a href="http://www.w3.org/TR/REC-xml-names/#NT-NCName">NCNames</a>}
       * The function <code>isNCName()</code> can be used to test validity
       * of these names. The namespace URI should be an absolute URI.
       * <code>QUrl.isRelative()</code> can be used to test whether the namespace URI
       * is relative or absolute. Finally, providing a prefix is not valid
       * when no namespace URI is provided.
       *
       * <code>namePool</code> is not copied. Nor is the reference to it retained
       * in this instance. This constructor inserts the three strings
       * into <code>namePool</code>.
       */
      public QXmlName(QXmlNamePool namePool, String localName, String namespaceURI, String prefix) {
          this(namePool.nativePointer(), localName, namespaceURI, prefix);
      }

      /**
       * Equivalent to calling QXmlName(namePool, localName, namespaceURI, null);
       */
      public QXmlName(QXmlNamePool namePool, String localName, String namespaceURI) {
          this(namePool, localName, namespaceURI, null);
      }

      /**
       * Equivalent to calling QXmlName(namePool, localName, null, null)
       */
      public QXmlName(QXmlNamePool namePool, String localName) {
          this(namePool, localName, null);
      }


}// class

class QSimpleXmlNodeModel___ extends QSimpleXmlNodeModel {

    /**
     * Returns the name pool that is associated with this model. The implementation of <code>name()</code>
     * would use this to create names.
     */
    public final QXmlNamePool namePool() {
        return QXmlNamePool.fromNativePointer(namePool_private());
    }
}// class
