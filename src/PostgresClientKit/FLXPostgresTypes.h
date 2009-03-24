
#import <Foundation/Foundation.h>

// see postgresql source code
// include/server/catalog/pg_type.h
// http://doxygen.postgresql.org/include_2catalog_2pg__type_8h-source.html

typedef enum {
	FLXPostgresTypeUnknown = -1,
	FLXPostgresTypeBool = 16,
	FLXPostgresTypeData = 17,
	FLXPostgresTypeChar = 18,
	FLXPostgresTypeName = 19,
	FLXPostgresTypeInt8 = 20,
	FLXPostgresTypeInt2 = 21,
	FLXPostgresTypeInt4 = 23,
	FLXPostgresTypeText = 25,
	FLXPostgresTypeOid = 26,
	FLXPostgresTypeXML = 142,
	FLXPostgresTypePoint = 600,
	FLXPostgresTypeLine = 601,
	FLXPostgresTypePath = 602,
	FLXPostgresTypeBox = 603,
	FLXPostgresTypePolygon = 604,
	FLXPostgresTypeFloat4 = 700,
	FLXPostgresTypeFloat8 = 701,
	FLXPostgresTypeCircle = 718,
	FLXPostgresTypeMoney = 790,
	FLXPostgresTypeMacAddr = 829,
	FLXPostgresTypeIPAddr = 869,
	FLXPostgresTypeNetAddr = 869,
	FLXPostgresTypeArrayBool = 1000,
	FLXPostgresTypeArrayData = 1001,
	FLXPostgresTypeArrayChar = 1002,
	FLXPostgresTypeArrayName = 1003,
	FLXPostgresTypeArrayInt2 = 1005,
	FLXPostgresTypeArrayInt4 = 1007,
	FLXPostgresTypeArrayText = 1009,
	FLXPostgresTypeArrayVarchar = 1015,
	FLXPostgresTypeArrayInt8 = 1016,
	FLXPostgresTypeArrayFloat4 = 1021,
	FLXPostgresTypeArrayFloat8 = 1022,
	FLXPostgresTypeArrayMacAddr = 1040,
	FLXPostgresTypeArrayIPAddr = 1041,
	FLXPostgresTypeArrayNetAddr = 651,
	FLXPostgresTypeVarchar = 1043,
	FLXPostgresTypeDate = 1082,
	FLXPostgresTypeTime = 1083,
	FLXPostgresTypeTimestamp = 1114,
	FLXPostgresTypeTimestampTZ = 1184,
	FLXPostgresTypeInterval = 1186,
	FLXPostgresTypeTimeTZ = 1266,
	FLXPostgresTypeBit = 1560,
	FLXPostgresTypeVarbit = 1562,
	FLXPostgresTypeNumeric = 1700
} FLXPostgresType;

typedef NSInteger FLXPostgresOid;

@interface FLXPostgresTypes : NSObject {
  NSMutableDictionary* m_theDictionary;
  NSMutableDictionary* m_theReverseDictionary;  
}

// constructor
+(FLXPostgresTypes* )array;

/*
// get type properties
-(NSString* )stringAtIndex:(NSUInteger)theIndex;
-(FLXPostgresType)typeAtIndex:(NSUInteger)theIndex;
-(NSUInteger)indexForType:(FLXPostgresType)theType;

// set type properties
-(void)insertString:(NSString* )theType atIndex:(NSUInteger)theIndex;
*/

@end
