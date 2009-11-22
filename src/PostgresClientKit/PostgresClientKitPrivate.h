
#include <libpq-fe.h>

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
-(void)registerType:(Class)theClass;
-(BOOL)isIntegerTimestamp;
-(NSObject* )remoteDataFromObject:(NSObject* )theObject type:(FLXPostgresOid* )theType;
-(FLXPostgresOid)remoteTypeFromObject:(NSObject* )theObject;
-(NSObject* )objectFromRemoteData:(const void* )theBytes length:(NSUInteger)theLength type:(FLXPostgresOid)theType;
-(NSString* )quotedStringFromObject:(NSObject* )theObject;
@end

////////////////////////////////////////////////////////////////////////////////

@protocol FLXPostgresTypeProtocol

// create a type handler
-(id)initWithConnection:(FLXPostgresConnection* )theConnection;

// return the remote type values handled by this class (terminated by 0)
+(FLXPostgresOid* )remoteTypes;

// return NSObject from data
-(NSObject* )remoteDataFromObject:(NSObject* )theObject type:(FLXPostgresOid* )theType;
-(FLXPostgresOid)remoteTypeFromObject:(NSObject* )theObject;
-(NSObject* )objectFromRemoteData:(const void* )theBytes length:(NSUInteger)theLength type:(FLXPostgresOid)theType;
-(NSString* )quotedStringFromObject:(NSObject* )theObject;

@end


////////////////////////////////////////////////////////////////////////////////
// see postgresql source code
// include/server/catalog/pg_type.h
// http://doxygen.postgresql.org/include_2catalog_2pg__type_8h-source.html
// these are the types we should support
enum {
 FLXPostgresOidBool = 16,
 FLXPostgresOidData = 17,
 FLXPostgresOidName = 19,
 FLXPostgresOidInt8 = 20,
 FLXPostgresOidInt2 = 21,
 FLXPostgresOidInt4 = 23,
 FLXPostgresOidText = 25,
 FLXPostgresOidOid = 26,
 FLXPostgresOidXML = 142,
 FLXPostgresOidPoint = 600,
 FLXPostgresOidLSeg = 601,
 FLXPostgresOidPath = 602,
 FLXPostgresOidBox = 603,
 FLXPostgresOidPolygon = 604,
 FLXPostgresOidFloat4 = 700,
 FLXPostgresOidFloat8 = 701,
 FLXPostgresOidAbsTime = 702,
 FLXPostgresOidUnknown = 705,
 FLXPostgresOidCircle = 718,
 FLXPostgresOidMoney = 790,
 FLXPostgresOidMacAddr = 829,
 FLXPostgresOidIPAddr = 869,
 FLXPostgresOidNetAddr = 869,
 FLXPostgresOidArrayBool = 1000,
 FLXPostgresOidArrayData = 1001,
 FLXPostgresOidArrayChar = 1002,
 FLXPostgresOidArrayName = 1003,
 FLXPostgresOidArrayInt2 = 1005,
 FLXPostgresOidArrayInt4 = 1007,
 FLXPostgresOidArrayText = 1009,
 FLXPostgresOidArrayVarchar = 1015,
 FLXPostgresOidArrayInt8 = 1016,
 FLXPostgresOidArrayFloat4 = 1021,
 FLXPostgresOidArrayFloat8 = 1022,
 FLXPostgresOidArrayMacAddr = 1040,
 FLXPostgresOidArrayIPAddr = 1041,
 FLXPostgresOidChar = 1042,
 FLXPostgresOidVarchar = 1043,
 FLXPostgresOidDate = 1082,
 FLXPostgresOidTime = 1083,
 FLXPostgresOidTimestamp = 1114,
 FLXPostgresOidTimestampTZ = 1184,
 FLXPostgresOidInterval = 1186,
 FLXPostgresOidTimeTZ = 1266,
 FLXPostgresOidBit = 1560,
 FLXPostgresOidVarbit = 1562,
 FLXPostgresOidNumeric = 1700
};
