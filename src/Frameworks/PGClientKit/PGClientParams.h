
#include <libpq-fe.h>

typedef struct {
	NSUInteger size;
	const char** values;
	Oid* types;
	int* lengths;
	int* formats;
} PGClientParams;

PGClientParams* _paramAllocForValues(NSArray* values);
void _paramFree(PGClientParams* params);
void _paramSetNull(PGClientParams* params,NSUInteger i);
void _paramSetData(PGClientParams* params,NSUInteger i,NSData* data,Oid pgtype,int format);