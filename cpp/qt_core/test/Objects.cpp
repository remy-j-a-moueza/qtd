#include <QObject>
#include <QEvent>

extern "C" void* qtd_test_QObject_create(void* parent)
{
    return new QObject((QObject*)parent);
}

extern "C" void qtd_test_QObject_delete(void* nativeId)
{
    delete (QObject*)nativeId;
}

extern "C" void qtd_test_QObject_event(void* nativeId)
{
     QEvent event(QEvent::None);
    ((QObject*)nativeId)->event(&event);
}