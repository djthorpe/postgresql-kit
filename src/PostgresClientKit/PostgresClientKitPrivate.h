
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

// convert into NSObjects from received data
-(NSString* )stringFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(NSNumber* )integerFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(NSNumber* )unsignedIntegerFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(NSNumber* )realFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(NSData* )dataFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(NSNumber* )booleanFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(NSDate* )abstimeFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(NSNumber* )timestampFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(NSDate* )dateFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(FLXMacAddr* )macaddrFromBytes:(const void* )theBytes length:(NSUInteger)theLength;

// arrays
-(NSArray* )integerArrayFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
@end

