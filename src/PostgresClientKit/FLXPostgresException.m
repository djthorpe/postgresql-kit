
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"

@implementation FLXPostgresException

+(void)raise:(NSString* )theName connection:(void* )theConnection {
  const char* theErrorMessage = theConnection ? PQerrorMessage(theConnection) : "Unknown error";
  FLXPostgresException* theException = [[[FLXPostgresException alloc] initWithName:theName reason:[NSString stringWithUTF8String:theErrorMessage] userInfo:nil] autorelease];
  [theException raise];
}

+(void)raise:(NSString* )theName reason:(NSString* )theReason {
  FLXPostgresException* theException = [[[FLXPostgresException alloc] initWithName:theName reason:theReason userInfo:nil] autorelease];
  [theException raise];  
}

@end
