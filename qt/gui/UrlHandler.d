module qt.gui.UrlHandler;

import qt.core.QUrl;

alias void delegate(QUrl) UrlHandlerDg;

package class UrlHandler : QObject {
    public this(UrlHandlerDg dg) {
        if (!init_flag_UrlHandler)
            static_init_UrlHandler();

        _dg = dg;
        void* __qt_return_value = qtd_UrlHandler_UrlHandler_QObject(cast(void*) this, null);
        this(__qt_return_value, true);
    }
    
    void handleUrl(QUrl url) {
        _dg(url);
    }
    
    private UrlHandlerDg _dg;
    
    public this(void* native_id, bool gc_managed) {
        super(native_id, gc_managed);
    }


    protected void __free_native_resources() {
        qtd_UrlHandler_destructor(nativeId());
    }

    void __set_native_ownership(bool ownership_) {
        __no_real_delete = ownership_;
    }
}
extern (C) void qtd_UrlHandler_destructor(void *ptr);

private extern(C) void* qtd_UrlHandler_UrlHandler_QObject(void *d_ptr,
 void* parent0);

private extern(C) void qtd_UrlHandler_handleUrl_QUrl_dispatch(void *d_entity, void* name1)
{
    auto d_object = cast(UrlHandler) d_entity;
    scope name1_d_ref = new QUrl(name1, true);
    d_object.handleUrl(name1_d_ref);
}

private extern (C) void qtd_UrlHandler_initCallBacks(void* virtuals, void* qobj_del);

private bool init_flag_UrlHandler = false;
void static_init_UrlHandler() {
    init_flag_UrlHandler = true;

    void*[1] virt_arr;
    virt_arr[0] = &qtd_UrlHandler_handleUrl_QUrl_dispatch;

//    void *qobj_del;
//    qobj_del = &qtd_D_QWidget_delete;
    qtd_UrlHandler_initCallBacks(virt_arr.ptr, null);
}
