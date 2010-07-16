#include <QVariant>
#include <qabstractitemmodel.h>
#include <qvariant.h>

#include <qabstractitemmodel.h>

#include "qtd_core.h"

QTD_EXTERN QTD_EXPORT void __qtd_QModelIndex_destructor(void *ptr)
{
    delete (QModelIndex *)ptr;
}

// ---externC---
// QModelIndex::QModelIndex()
QTD_EXTERN QTD_EXPORT void* __qtd_QModelIndex_QModelIndex
()
{
    QModelIndex *__qt_this = new QModelIndex();
    return (void *) __qt_this;

}

// QModelIndex::QModelIndex(const QModelIndex & other)
QTD_EXTERN QTD_EXPORT void* __qtd_QModelIndex_QModelIndex_QModelIndex
(QModelIndex other0)
{
    QModelIndex *__qt_this = new QModelIndex((const QModelIndex& )other0);
    return (void *) __qt_this;

}

// QModelIndex::child(int row, int column) const
QTD_EXTERN QTD_EXPORT QModelIndex __qtd_QModelIndex_child_int_int
(void* __this_nativeId,
 int row0,
 int column1)
{
    QModelIndex *__qt_this = (QModelIndex *) __this_nativeId;
    QModelIndex  __qt_return_value = __qt_this->child((int )row0, (int )column1);


    return __qt_return_value;
}

// QModelIndex::column() const
QTD_EXTERN QTD_EXPORT int __qtd_QModelIndex_column
(void* __this_nativeId)
{
    QModelIndex *__qt_this = (QModelIndex *) __this_nativeId;
    int  __qt_return_value = __qt_this->column();

    int __java_return_value = __qt_return_value;

    return __java_return_value;
}

// QModelIndex::data(int role) const
QTD_EXTERN QTD_EXPORT void* __qtd_QModelIndex_data_int
(void* __this_nativeId,
 int role0)
{
    QModelIndex *__qt_this = (QModelIndex *) __this_nativeId;
    QVariant  __qt_return_value = __qt_this->data((int )role0);

    QVariant *__java_return_value = new QVariant(__qt_return_value);

    return __java_return_value;
}

// QModelIndex::flags() const
QTD_EXTERN QTD_EXPORT int __qtd_QModelIndex_flags
(void* __this_nativeId)
{
    QModelIndex *__qt_this = (QModelIndex *) __this_nativeId;
    int  __qt_return_value = __qt_this->flags();

    int __java_return_value = __qt_return_value;

    return __java_return_value;
}

// QModelIndex::internalId() const
QTD_EXTERN QTD_EXPORT qint64 __qtd_QModelIndex_internalId
(void* __this_nativeId)
{
    QModelIndex *__qt_this = (QModelIndex *) __this_nativeId;
    qint64  __qt_return_value = __qt_this->internalId();

    qint64 __java_return_value = __qt_return_value;

    return __java_return_value;
}

// QModelIndex::internalPointer() const
QTD_EXTERN QTD_EXPORT void* __qtd_QModelIndex_internalPointer
(void* __this_nativeId)
{
    QModelIndex *__qt_this = (QModelIndex *) __this_nativeId;
    void*  __qt_return_value = __qt_this->internalPointer();

    void* __java_return_value = (void*) __qt_return_value;// qtjambi_from_cpointer

    return __java_return_value;
}

// QModelIndex::isValid() const
QTD_EXTERN QTD_EXPORT bool __qtd_QModelIndex_isValid
(void* __this_nativeId)
{
    QModelIndex *__qt_this = (QModelIndex *) __this_nativeId;
    bool  __qt_return_value = __qt_this->isValid();

    bool __java_return_value = __qt_return_value;

    return __java_return_value;
}

// QModelIndex::model() const
QTD_EXTERN QTD_EXPORT void* __qtd_QModelIndex_model
(void* __this_nativeId)
{
    QModelIndex *__qt_this = (QModelIndex *) __this_nativeId;
    const QAbstractItemModel*  __qt_return_value = __qt_this->model();

    void* __java_return_value = (void*) __qt_return_value;

    return __java_return_value;
}

// QModelIndex::operator<(const QModelIndex & other) const
QTD_EXTERN QTD_EXPORT bool __qtd_QModelIndex_operator_less_QModelIndex
(void* __this_nativeId,
 QModelIndex other0)
{
    QModelIndex *__qt_this = (QModelIndex *) __this_nativeId;
    bool  __qt_return_value = __qt_this->operator<((const QModelIndex& )other0);

    bool __java_return_value = __qt_return_value;

    return __java_return_value;
}

// QModelIndex::operator==(const QModelIndex & other) const
QTD_EXTERN QTD_EXPORT bool __qtd_QModelIndex_operator_equal_QModelIndex
(void* __this_nativeId,
 QModelIndex other0)
{
    QModelIndex *__qt_this = (QModelIndex *) __this_nativeId;
    bool  __qt_return_value = __qt_this->operator==((const QModelIndex& )other0);

    bool __java_return_value = __qt_return_value;

    return __java_return_value;
}

// QModelIndex::parent() const
QTD_EXTERN QTD_EXPORT QModelIndex __qtd_QModelIndex_parent
(void* __this_nativeId)
{
    QModelIndex *__qt_this = (QModelIndex *) __this_nativeId;
    QModelIndex  __qt_return_value = __qt_this->parent();


    return __qt_return_value;
}

// QModelIndex::row() const
QTD_EXTERN QTD_EXPORT int __qtd_QModelIndex_row
(void* __this_nativeId)
{
    QModelIndex *__qt_this = (QModelIndex *) __this_nativeId;
    int  __qt_return_value = __qt_this->row();

    int __java_return_value = __qt_return_value;

    return __java_return_value;
}

// QModelIndex::sibling(int row, int column) const
QTD_EXTERN QTD_EXPORT QModelIndex __qtd_QModelIndex_sibling_int_int
(void* __this_nativeId,
 int row0,
 int column1)
{
    QModelIndex *__qt_this = (QModelIndex *) __this_nativeId;
    QModelIndex  __qt_return_value = __qt_this->sibling((int )row0, (int )column1);


    return __qt_return_value;
}

// ---externC---end
// Field accessors


