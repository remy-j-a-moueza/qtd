#ifndef QQOBJECTENTITY_H
#define QQOBJECTENTITY_H

#include <cstdlib>

class Qtd_QObjectEntity
{
public:
	Qtd_QObjectEntity(void *d_ptr) { _d_ptr = d_ptr; }
	void *d_entity() const { return _d_ptr; }

private:
	void *_d_ptr;
};

#endif // QQOBJECTENTITY_H
