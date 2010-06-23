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

    #define QTD_DLL_EXPORT __declspec(dllexport)
    #define QTD_DLL_IMPORT __declspec(dllimport)

    #ifdef CPP_SHARED

        #define QTD_EXPORT_DECL(MODULE, TYPE, NAME, ARGS) \
            QTD_EXTERN typedef TYPE (*qtd_##NAME##_t)ARGS; \
            QTD_EXTERN { extern QTD_##MODULE##_DLL_PUBLIC qtd_##NAME##_t qtd_##NAME; }

        #define QTD_EXPORT(MODULE, NAME) \
            QTD_EXTERN { QTD_##MODULE##_DLL_PUBLIC qtd_##NAME##_t qtd_##NAME; } \
            QTD_EXTERN QTD_DLL_EXPORT void qtd_set_##NAME(VoidFunc func) { qtd_##NAME = (qtd_##NAME##_t)func; }

    #endif

#else

    #define QTD_DLL_EXPORT
    #define QTD_DLL_IMPORT

    #define QTD_EXPORT_DECL(MODULE, TYPE, NAME, ARGS) \
        QTD_EXTERN TYPE qtd_##NAME ARGS;

    #define QTD_EXPORT(MODULE, NAME)

#endif

#define QTD_DLL_PUBLIC QTD_DLL_EXPORT

#ifdef QTD_CORE
    #define QTD_CORE_DLL_PUBLIC QTD_DLL_EXPORT
#else
    #define QTD_CORE_DLL_PUBLIC QTD_DLL_IMPORT
#endif

#ifdef QTD_GUI
    #define QTD_GUI_DLL_PUBLIC QTD_DLL_EXPORT
#else
    #define QTD_GUI_DLL_PUBLIC QTD_DLL_IMPORT
#endif

#ifdef QTD_OPENGL
    #define QTD_OPENGL_DLL_PUBLIC QTD_DLL_EXPORT
#else
    #define QTD_OPENGL_DLL_PUBLIC QTD_DLL_IMPORT
#endif

#ifdef QTD_NETWORK
    #define QTD_NETWORK_DLL_PUBLIC QTD_DLL_EXPORT
#else
    #define QTD_NETWORK_DLL_PUBLIC QTD_DLL_IMPORT
#endif

#ifdef QTD_SVG
    #define QTD_SVG_DLL_PUBLIC QTD_DLL_EXPORT
#else
    #define QTD_SVG_DLL_PUBLIC QTD_DLL_IMPORT
#endif

#ifdef QTD_XML
    #define QTD_XML_DLL_PUBLIC QTD_DLL_EXPORT
#else
    #define QTD_XML_DLL_PUBLIC QTD_DLL_IMPORT
#endif

#ifdef QTD_WEBKIT
    #define QTD_WEBKIT_DLL_PUBLIC QTD_DLL_EXPORT
#else
    #define QTD_WEBKIT_DLL_PUBLIC QTD_DLL_IMPORT
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

enum QtdObjectFlags
{
    qNone,
    qNativeOwnership            = 0x01,
    qDOwnership                 = 0x02
    //gcManaged                 = 0x04
};

class QTD_CORE_DLL_PUBLIC QtdObjectLink
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

class QTD_CORE_DLL_PUBLIC QObjectLink : public QtdObjectLink, public QObjectUserData
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

QTD_EXPORT_DECL(CORE, void, toUtf8, (const unsigned short* arr, uint size, void* str))
QTD_EXPORT_DECL(CORE, void, QtdObject_delete, (void* dId))

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
