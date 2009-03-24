
#include <libpq-fe.h>

//#include <pgtypes_date.h>
//#include <pgtypes_numeric.h>
//#include <pgtypes_timestamp.h>
//#include <pgtypes_interval.h>

@interface FLXPostgresResult (Private)
-(id)initWithResult:(PGresult* )theResult types:(FLXPostgresTypes* )theTypes;
-(PGresult* )result;
@end

@interface FLXPostgresTypes (Private)
-(NSObject* )objectForResult:(PGresult* )theResult row:(NSUInteger)theRow column:(NSUInteger)theColumn;
-(NSString* )stringFromBytes:(const char* )theBytes length:(NSUInteger)theLength;
-(NSNumber* )integerFromBytes:(const char* )theBytes length:(NSUInteger)theLength;
-(NSNumber* )realFromBytes:(const char* )theBytes length:(NSUInteger)theLength;
-(NSData* )dataFromBytes:(const char* )theBytes length:(NSUInteger)theLength;
-(NSNumber* )booleanFromBytes:(const char* )theBytes length:(NSUInteger)theLength;
@end

