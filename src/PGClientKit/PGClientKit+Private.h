
#include <libpq-fe.h>
#import "PGClientParams.h"

typedef enum {
	PGClientErrorConnectionStateMismatch = 1, // state is wrong for this call
	PGClientErrorParameterError,              // parameters are incorrect
	PGClientErrorRejectionError,              // rejected from operation
	PGClientErrorConnectionError,             // connection error
	PGClientErrorExecutionError               // execution error
} PGClientErrorDomainCode;

extern NSString* PGClientErrorDomain;

////////////////////////////////////////////////////////////////////////////////
// cache methods

void _pgresult_cache_init();
void _pgresult_cache_destroy();

id _pgresult_bin2obj(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding);
id _pgresult_text2obj(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding);

////////////////////////////////////////////////////////////////////////////////

@interface PGConnection (Private)
-(NSError* )_raiseError:(PGClientErrorDomainCode)code reason:(NSString* )reason error:(NSError** )error;
@end

@interface PGResult (Private)
-(id)initWithResult:(PGresult* )theResult format:(PGClientTupleFormat)format;
@end
