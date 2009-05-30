
#include <libpq-fe.h>
#include <libpq/libpq-fs.h> // for large object support

//#include <pgtypes_date.h>
//#include <pgtypes_numeric.h>
//#include <pgtypes_timestamp.h>
//#include <pgtypes_interval.h>

typedef Oid FLXPostgresOid;

@interface FLXPostgresConnection (Private)
-(PGconn* )PGconn;
-(void)_noticeProcessorWithMessage:(NSString* )theMessage;
@end

@interface FLXPostgresResult (Private)
-(id)initWithTypes:(FLXPostgresTypes* )theTypes result:(PGresult* )theResult;
-(PGresult* )result;
@end

@interface FLXPostgresStatement (Private)
-(id)initWithStatement:(NSString* )theStatement;
@end

@interface FLXPostgresTypes (Private)
-(id)initWithConnection:(FLXPostgresConnection* )theConnection;
-(BOOL)isIntegerTimestamp;
-(NSObject* )boundValueFromObject:(NSObject* )theObject type:(FLXPostgresOid* )theType;
-(NSObject* )objectFromBytes:(const void* )theBytes length:(NSUInteger)theLength type:(FLXPostgresOid)theType;
-(NSString* )quotedStringFromObject:(NSObject* )theObject;
@end

