
#include <libpq-fe.h>

typedef struct {
	NSUInteger size;
	const void** values;
	BOOL* freeWhenDone;
	Oid* types;
	int* lengths;
	int* formats;
} PGClientParams;

PGClientParams* _paramAllocForValues(NSArray* values);
void _paramFree(PGClientParams* params);
void _paramSetNull(PGClientParams* params,NSUInteger i);
void _paramSetBinary(PGClientParams* params,NSUInteger i,NSData* data,Oid pgtype);
void _paramSetText(PGClientParams* params,NSUInteger i,NSString* text,NSStringEncoding encoding,Oid pgtype);
