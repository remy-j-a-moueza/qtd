
#include <QMetaType>
#include "qtd_core.h"

typedef void * Ctor (const void *copy);
typedef void Dtor(void *obj);

extern "C" DLL_PUBLIC int qtd_registerType(char* namePtr, Ctor ctor, Dtor dtor)
{   
    return QMetaType::registerType(namePtr, dtor, ctor);
}

typedef void (*SaveOperator)(void *, void *);
typedef void (*LoadOperator)(void *, void *);


extern "C" DLL_PUBLIC void qtd_registerStreamOperators(const char *typeName, SaveOperator saveOp,
                                        LoadOperator loadOp)
{   
    QMetaType::registerStreamOperators(typeName, reinterpret_cast<QMetaType::SaveOperator>(saveOp),
                                       reinterpret_cast<QMetaType::LoadOperator>(loadOp));
}
    

extern "C" DLL_PUBLIC int qtd_MetatypeId(char *id)
{
    return QMetaType::type(id);
}
