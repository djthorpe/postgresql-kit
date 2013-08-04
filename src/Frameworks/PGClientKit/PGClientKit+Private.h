
#include "libpq-fe.h"
#import "PGClientParams.h"
#import "PGConverters.h"

typedef enum {
	PGClientErrorConnectionStateMismatch = 1, // state is wrong for this call
	PGClientErrorParameterError,              // parameters are incorrect
	PGClientErrorRejectionError,              // rejected from operation
	PGClientErrorConnectionError,             // connection error
	PGClientErrorExecutionError               // execution error
} PGClientErrorDomainCode;

extern NSString* PGClientErrorDomain;

////////////////////////////////////////////////////////////////////////////////

@interface PGConnection (Private)
-(NSError* )_raiseError:(PGClientErrorDomainCode)code reason:(NSString* )reason error:(NSError** )error;
@end

@interface PGResult (Private)
-(id)initWithResult:(PGresult* )theResult format:(PGClientTupleFormat)format;
@end
