
#include <libpq-fe.h>
#include <libpq/libpq-fs.h> // for large object support


//#include <pgtypes_date.h>
//#include <pgtypes_numeric.h>
//#include <pgtypes_timestamp.h>
//#include <pgtypes_interval.h>

typedef Oid FLXPostgresOid;

@interface FLXPostgresConnection (Private)
-(PGconn* )connection;
-(void)_noticeProcessorWithMessage:(NSString* )theMessage;
@end

@interface FLXPostgresResult (Private)
-(id)initWithResult:(PGresult* )theResult;
-(PGresult* )result;
@end

@interface FLXPostgresStatement (Private)
-(id)initWithStatement:(NSString* )theStatement;
@end

@interface FLXPostgresTypes (Private)
+(NSObject* )boundValueFromObject:(NSObject* )theObject type:(FLXPostgresOid* )theType;
+(NSObject* )objectForResult:(PGresult* )theResult row:(NSUInteger)theRow column:(NSUInteger)theColumn;

// convert into NSObjects from received data
+(NSString* )stringFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
+(NSNumber* )integerFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
+(NSNumber* )unsignedIntegerFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
+(NSNumber* )realFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
+(NSData* )dataFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
+(NSNumber* )booleanFromBytes:(const void* )theBytes length:(NSUInteger)theLength;

// date, time types
+(NSDate* )abstimeFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
+(NSDate* )timestampFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
+(FLXTimeInterval* )intervalFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
+(NSDate* )dateFromBytes:(const void* )theBytes length:(NSUInteger)theLength;

// network addresses
+(FLXMacAddr* )macaddrFromBytes:(const void* )theBytes length:(NSUInteger)theLength;

// geometry
+(FLXGeometry* )pointFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
+(FLXGeometry* )lineFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
+(FLXGeometry* )boxFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
+(FLXGeometry* )circleFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
+(FLXGeometry* )pathFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
+(FLXGeometry* )polygonFromBytes:(const void* )theBytes length:(NSUInteger)theLength;

// arrays
+(NSArray* )arrayFromBytes:(const void* )theBytes length:(NSUInteger)theLength type:(FLXPostgresOid)theType;

@end

