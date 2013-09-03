
#include "libpq-fe.h"
#import "PGClientParams.h"
#import "PGConverters.h"

@interface PGConnection (Private)
+(NSMutableDictionary* )extractParametersFromURL:(NSURL* )theURL;
+(NSError* )createError:(NSError** )error code:(PGClientErrorDomainCode)code url:(NSURL* )url reason:(NSString* )format,...;
@end

@interface PGResult (Private)
-(NSError* )raiseError:(NSError** )error code:(PGClientErrorDomainCode)code url:(NSURL* )url reason:(NSString* )format,...;
-(NSError* )raiseError:(NSError** )error code:(PGClientErrorDomainCode)code reason:(NSString* )format,...;
-(id)initWithResult:(PGresult* )theResult format:(PGClientTupleFormat)format;
@end
