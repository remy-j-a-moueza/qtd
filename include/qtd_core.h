/**
    Copyright: Copyright QtD Team, 2008-2010
    License: Boost License 1.0
 */

#ifndef QTD_CORE_H
#define QTD_CORE_H

#include <QAbstractItemModel>

#define QTD_EXTERN extern "C"

QTD_EXTERN typedef void (*VoidFunc)();

#ifdef WIN32
    #define QTD_EXPORT __declspec(dllexport)
    #define QTD_IMPORT __declspec(dllimport)
#else
    #define QTD_EXPORT
    #define QTD_IMPORT
#endif

#ifdef CPP_SHARED
    #define QTD_FUNC_DECL(MODULE, TYPE, NAME, ARGS) \
        QTD_EXTERN typedef TYPE (*qtd_##NAME##_t)ARGS; \
        QTD_EXTERN { extern QTD_##MODULE##_PUBLIC qtd_##NAME##_t qtd_##NAME; }
    #define QTD_FUNC(MODULE, NAME) \
        QTD_EXTERN { QTD_##MODULE##_PUBLIC qtd_##NAME##_t qtd_##NAME; } \
        QTD_EXTERN QTD_EXPORT void qtd_set_##NAME(VoidFunc func) { qtd_##NAME = (qtd_##NAME##_t)func; }
#else
    #define QTD_FUNC_DECL(MODULE, TYPE, NAME, ARGS) \
        QTD_EXTERN TYPE qtd_##NAME ARGS;
    #define QTD_FUNC(MODULE, NAME)
#endif

//TODO: these should be moved to module-specific includes
#ifdef QTD_CORE
    #define QTD_CORE_PUBLIC QTD_EXPORT
#else
    #define QTD_CORE_PUBLIC QTD_IMPORT
#endif

#ifdef QTD_GUI
    #define QTD_GUI_PUBLIC QTD_EXPORT
#else
    #define QTD_GUI_PUBLIC QTD_IMPORT
#endif

#ifdef QTD_OPENGL
    #define QTD_OPENGL_PUBLIC QTD_EXPORT
#else
    #define QTD_OPENGL_PUBLIC QTD_IMPORT
#endif

#ifdef QTD_NETWORK
    #define QTD_NETWORK_PUBLIC QTD_EXPORT
#else
    #define QTD_NETWORK_PUBLIC QTD_IMPORT
#endif

#ifdef QTD_SVG
    #define QTD_SVG_PUBLIC QTD_EXPORT
#else
    #define QTD_SVG_PUBLIC QTD_IMPORT
#endif

#ifdef QTD_XML
    #define QTD_XML_PUBLIC QTD_EXPORT
#else
    #define QTD_XML_PUBLIC QTD_IMPORT
#endif

#ifdef QTD_WEBKIT
    #define QTD_WEBKIT_PUBLIC QTD_EXPORT
#else
    #define QTD_WEBKIT_PUBLIC QTD_IMPORT
#endif

#ifdef QTD_QWT
    #define QTD_QWT_PUBLIC QTD_EXPORT
#else
    #define QTD_QWT_PUBLIC QTD_IMPORT
#endif

//TODO: ditch
struct QModelIndexAccessor {
	int row;
	int col;
	void *ptr;
	QAbstractItemModel *model;
};

struct DArray {
    size_t length;
    void* ptr;
};

class QTD_CORE_PUBLIC QtdObjectLink
{
public:
    void* dId;

    QtdObjectLink(void* id) : dId(id) {}

    template<typename T>
    static QtdObjectLink* getLink(const T* object)
    {
        return dynamic_cast<QtdObjectLink*>((T*)object);
    }

    template<typename T>
    static void* getDId(const T* object)
    {
        QtdObjectLink *link = getLink((T*)object);
        return link ? link->dId : NULL;
    }
};

class QTD_CORE_PUBLIC QObjectLink : public QtdObjectLink, public QObjectUserData
{
public:
    enum Flags
    {
        None,
        CreatedByD = 0x1
    };

    Flags flags;
    static uint userDataId;

    QObjectLink(QObject* qObject, void* dId);
    bool createdByD();
    virtual ~QObjectLink();
    void destroyLink(QObject* qObject = NULL);
    static QObjectLink* getLink(const QObject* qObject);
    static void* getDId(const QObject* qObject);
};

#define Array DArray

QTD_FUNC_DECL(CORE, void, toUtf8, (const unsigned short* arr, uint size, void* str))
QTD_FUNC_DECL(CORE, void, QtdObject_delete, (void* dId))

QTD_EXTERN QModelIndex qtd_to_QModelIndex(QModelIndexAccessor mia);
QTD_EXTERN QModelIndexAccessor qtd_from_QModelIndex(const QModelIndex &index);

QTD_EXTERN typedef void (*EmitCallback)(void*, void**);
QTD_EXTERN typedef int (*QtMetacallCallback)(void *d_entity, QMetaObject::Call _c, int _id, void **_a);
QTD_EXTERN typedef const QMetaObject* (*MetaObjectCallback)(void *d_entity);

template <class T>
void call_destructor(T *a)
{
    a->~T();
}

#endif // QTD_CORE_H
