#include "UrlHandler_shell.h"

#include "qtd_core.h"

UrlHandler::UrlHandler(void *d_ptr, QObject*  parent0)
    : QObject(parent0),
      Qtd_QObjectEntity(d_ptr)
{
}

#ifdef CPP_SHARED
extern "C" typedef void (*pfqtd_UrlHandler_handleUrl_QUrl_dispatch)(void *d_entity, void* arg__1);
pfqtd_UrlHandler_handleUrl_QUrl_dispatch qtd_UrlHandler_handleUrl_QUrl_dispatch;
#else
extern "C" void qtd_UrlHandler_handleUrl_QUrl_dispatch(void *d_entity, void* name1);
#endif
void UrlHandler::handleUrl(const QUrl &url)
{
    qtd_UrlHandler_handleUrl_QUrl_dispatch(this->d_entity(), &(QUrl& )url);
}

extern "C" DLL_PUBLIC void qtd_UrlHandler_destructor(void *ptr)
{
    delete (UrlHandler *)ptr;
}

extern "C" DLL_PUBLIC void* qtd_UrlHandler_UrlHandler_QObject
(void *d_ptr,
 void* parent0)
{
    QObject*  __qt_parent0 = (QObject* ) parent0;
    UrlHandler *__qt_this = new UrlHandler(d_ptr, (QObject* )__qt_parent0);
    return (void *) __qt_this;
}

#ifdef CPP_SHARED
extern "C" DLL_PUBLIC void qtd_UrlHandler_initCallBacks(pfunc_abstr *virts, pfunc_abstr qobj_del) {
    qtd_UrlHandler_handleUrl_QUrl_dispatch = (pfqtd_UrlHandler_handleUrl_QUrl_dispatch) virts[0];
//    qtd_D_QWidget_delete = (qtd_pf_D_QWidget_delete)qobj_del;
}
#endif
/* ---------------------------------------- */

#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'urlhandler.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 61
#error "This file was generated using the moc from 4.5.0. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

QT_BEGIN_MOC_NAMESPACE
static const uint qt_meta_data_UrlHandler[] = {

 // content:
       2,       // revision
       0,       // classname
       0,    0, // classinfo
       1,   12, // methods
       0,    0, // properties
       0,    0, // enums/sets
       0,    0, // constructors

 // slots: signature, parameters, type, tag, flags
      16,   12,   11,   11, 0x0a,

       0        // eod
};

static const char qt_meta_stringdata_UrlHandler[] = {
    "UrlHandler\0\0url\0handleUrl(QUrl)\0"
};

const QMetaObject UrlHandler::staticMetaObject = {
    { &QObject::staticMetaObject, qt_meta_stringdata_UrlHandler,
      qt_meta_data_UrlHandler, 0 }
};

const QMetaObject *UrlHandler::metaObject() const
{
    return &staticMetaObject;
}

void *UrlHandler::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_UrlHandler))
        return static_cast<void*>(const_cast< UrlHandler*>(this));
    if (!strcmp(_clname, "Qtd_QObjectEntity"))
        return static_cast< Qtd_QObjectEntity*>(const_cast< UrlHandler*>(this));
    return QObject::qt_metacast(_clname);
}

int UrlHandler::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: handleUrl((*reinterpret_cast< const QUrl(*)>(_a[1]))); break;
        default: ;
        }
        _id -= 1;
    }
    return _id;
}
QT_END_MOC_NAMESPACE
