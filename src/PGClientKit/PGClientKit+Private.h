
#include <libpq-fe.h>
#import "PGConnectionPool.h"

typedef enum {
	PGClientErrorConnectionStateMismatch = 1, // state is wrong for this call
	PGClientErrorParameterError,              // parameters are incorrect
	PGClientErrorRejectionError,              // rejected from operation
	PGClientErrorConnectionError,             // connection error
	PGClientErrorExecutionError               // execution error
} PGClientErrorDomainCode;

extern NSString* PGClientErrorDomain;

@interface PGResult (Private)
-(id)initWithResult:(PGresult* )theResult format:(PGClientTupleFormat)format;
@end
