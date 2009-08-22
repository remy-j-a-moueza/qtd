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
