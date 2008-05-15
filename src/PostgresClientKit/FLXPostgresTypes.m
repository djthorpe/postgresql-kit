
#import "PostgresClientKit.h"
#include <pgtypes_date.h>

@implementation FLXPostgresTypes

-(id)init {
	self = [super init];
	if (self != nil) {
		m_theDictionary = [[NSMutableDictionary alloc] init];
		m_theReverseDictionary = [[NSMutableDictionary alloc] init];
	}
	return self;
}

-(void)dealloc {
	[m_theReverseDictionary release];
	[m_theDictionary release];
	[super dealloc];
}

+(FLXPostgresTypes* )array {
	return [[[FLXPostgresTypes alloc] init] autorelease];
}

-(NSString* )stringAtIndex:(NSUInteger)theIndex {
	NSArray* theType = [m_theDictionary objectForKey:[NSNumber numberWithUnsignedInteger:theIndex]];
	return theType ? [theType objectAtIndex:0] : nil;
}

-(FLXPostgresType)typeAtIndex:(NSUInteger)theIndex {
	NSArray* theType = [m_theDictionary objectForKey:[NSNumber numberWithUnsignedInteger:theIndex]];
	if(theType==nil) return FLXPostgresTypeUnknown;
	NSParameterAssert([theType isKindOfClass:[NSArray class]] && [theType count] >= 2);
	return (FLXPostgresType)[[theType objectAtIndex:1] integerValue];
}

-(NSUInteger)indexForType:(FLXPostgresType)theType {
	NSNumber* theIndex = [m_theReverseDictionary objectForKey:[NSNumber numberWithInteger:theType]];
	return ((theIndex==nil) ? 0 : [theIndex unsignedIntegerValue]);  
}

-(void)insertString:(NSString* )theType atIndex:(NSUInteger)theIndex {
	NSInteger theInternalType = FLXPostgresTypeUnknown;
	if([theType isEqual:@"bool"]) {
		theInternalType = FLXPostgresTypeBool;
	} else if([theType isEqual:@"bytea"]) {
		theInternalType = FLXPostgresTypeData;    
	} else if([theType isEqual:@"char"] || [theType isEqual:@"text"] || [theType isEqual:@"varchar"] || [theType isEqual:@"name"]) {
		theInternalType = FLXPostgresTypeString;
	} else if([theType isEqual:@"int8"] || [theType isEqual:@"int4"] || [theType isEqual:@"int2"]) {
		theInternalType = FLXPostgresTypeInteger;    
	} else if([theType isEqual:@"float4"] || [theType isEqual:@"float8"] || [theType isEqual:@"money"]) {
		theInternalType = FLXPostgresTypeReal;    
	} else if([theType isEqual:@"date"]) {
		theInternalType = FLXPostgresTypeDate;        
	} else if([theType isEqual:@"timestamp"] || [theType isEqual:@"timestamptz"]) {
		theInternalType = FLXPostgresTypeDatetime;            
	}	
	[m_theDictionary setObject:[NSArray arrayWithObjects:theType,[NSNumber numberWithInteger:theInternalType],nil] forKey:[NSNumber numberWithUnsignedInteger:theIndex]];
	[m_theReverseDictionary setObject:[NSNumber numberWithUnsignedInteger:theIndex] forKey:[NSNumber numberWithInteger:theInternalType]];
}

////////////////////////////////////////////////////////////////////////////////////////////////
// support for conversion from postgresql binary representations to NSObjects

+(NSString* )stringFromBytes:(const char* )theBytes length:(NSUInteger)theLength {
	// note that the string is always terminated with NULL so we don't need the length field
	return [NSString stringWithUTF8String:theBytes];
}

+(NSNumber* )integerFromBytes:(const char* )theBytes length:(NSUInteger)theLength {
	switch(theLength) {
	case 2:
		return [NSNumber numberWithInteger:*((SInt16* )theBytes)];
	case 4:
		return [NSNumber numberWithInteger:*((SInt32* )theBytes)];
	case 8:
		return [NSNumber numberWithLong:*((SInt64* )theBytes)];
	}
	// we shouldn't get here - we only support int2, int4 and int8
	NSParameterAssert(FALSE);
	return nil;				
}

+(NSNumber* )realFromBytes:(const char* )theBytes length:(NSUInteger)theLength {
	switch(theLength) {
	case 4:
		return [NSNumber numberWithFloat:*((Float32* )theBytes)];
	case 8:
		return [NSNumber numberWithDouble:*((Float64* )theBytes)];
	}
	// we shouldn't get here unless the integer is some strange type
	NSParameterAssert(FALSE);
	return nil;				
}

+(NSNumber* )booleanFromBytes:(const char* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theLength==1);
	return [NSNumber numberWithBool:(*theBytes ? YES : NO)];	
}

+(NSData* )dataFromBytes:(const char* )theBytes length:(NSUInteger)theLength {	
	return [NSData dataWithBytes:theBytes length:theLength];	
}

+(NSDate* )dateFromBytes:(const char* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theLength==4);
	SInt32 theDate = *((SInt32* )theBytes);
	NSString* theString = [NSString stringWithUTF8String:PGTYPESdate_to_asc(theDate)];
	NSParameterAssert([theString length]==10);
	return [NSCalendarDate dateWithString:theString calendarFormat:@"%Y-%m-%d"];
}

+(NSDate* )datetimeFromBytes:(const char* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theLength==4);
	SInt32 theDate = *((SInt32* )theBytes);
	NSString* theString = [NSString stringWithUTF8String:PGTYPESdate_to_asc(theDate)];
	NSLog(@"datetime = %@",theString);
	return [NSCalendarDate calendarDate];
}

@end

/*
 2007-10-22 12:47:54.824 PostgresServerTool[2438] 16 => bool
 2007-10-22 12:47:54.824 PostgresServerTool[2438] 17 => bytea
 2007-10-22 12:47:54.824 PostgresServerTool[2438] 18 => char
 2007-10-22 12:47:54.824 PostgresServerTool[2438] 19 => name
 2007-10-22 12:47:54.825 PostgresServerTool[2438] 20 => int8
 2007-10-22 12:47:54.825 PostgresServerTool[2438] 21 => int2
 2007-10-22 12:47:54.825 PostgresServerTool[2438] 22 => int2vector
 2007-10-22 12:47:54.825 PostgresServerTool[2438] 23 => int4
 2007-10-22 12:47:54.825 PostgresServerTool[2438] 24 => regproc
 2007-10-22 12:47:54.825 PostgresServerTool[2438] 25 => text
 2007-10-22 12:47:54.825 PostgresServerTool[2438] 26 => oid
 2007-10-22 12:47:54.825 PostgresServerTool[2438] 27 => tid
 2007-10-22 12:47:54.826 PostgresServerTool[2438] 28 => xid
 2007-10-22 12:47:54.826 PostgresServerTool[2438] 29 => cid
 2007-10-22 12:47:54.826 PostgresServerTool[2438] 30 => oidvector
 2007-10-22 12:47:54.826 PostgresServerTool[2438] 71 => pg_type
 2007-10-22 12:47:54.826 PostgresServerTool[2438] 75 => pg_attribute
 2007-10-22 12:47:54.826 PostgresServerTool[2438] 81 => pg_proc
 2007-10-22 12:47:54.826 PostgresServerTool[2438] 83 => pg_class
 2007-10-22 12:47:54.826 PostgresServerTool[2438] 210 => smgr
 2007-10-22 12:47:54.826 PostgresServerTool[2438] 600 => point
 2007-10-22 12:47:54.826 PostgresServerTool[2438] 601 => lseg
 2007-10-22 12:47:54.826 PostgresServerTool[2438] 602 => path
 2007-10-22 12:47:54.827 PostgresServerTool[2438] 603 => box
 2007-10-22 12:47:54.827 PostgresServerTool[2438] 604 => polygon
 2007-10-22 12:47:54.827 PostgresServerTool[2438] 628 => line
 2007-10-22 12:47:54.827 PostgresServerTool[2438] 700 => float4
 2007-10-22 12:47:54.827 PostgresServerTool[2438] 701 => float8
 2007-10-22 12:47:54.827 PostgresServerTool[2438] 702 => abstime
 2007-10-22 12:47:54.827 PostgresServerTool[2438] 703 => reltime
 2007-10-22 12:47:54.827 PostgresServerTool[2438] 704 => tinterval
 2007-10-22 12:47:54.827 PostgresServerTool[2438] 705 => unknown
 2007-10-22 12:47:54.827 PostgresServerTool[2438] 718 => circle
 2007-10-22 12:47:54.827 PostgresServerTool[2438] 790 => money
 2007-10-22 12:47:54.827 PostgresServerTool[2438] 829 => macaddr
 2007-10-22 12:47:54.827 PostgresServerTool[2438] 869 => inet
 2007-10-22 12:47:54.827 PostgresServerTool[2438] 650 => cidr
 2007-10-22 12:47:54.828 PostgresServerTool[2438] 1033 => aclitem
 2007-10-22 12:47:54.828 PostgresServerTool[2438] 1042 => bpchar
 2007-10-22 12:47:54.828 PostgresServerTool[2438] 1043 => varchar
 2007-10-22 12:47:54.828 PostgresServerTool[2438] 1082 => date
 2007-10-22 12:47:54.828 PostgresServerTool[2438] 1083 => time
 2007-10-22 12:47:54.828 PostgresServerTool[2438] 1114 => timestamp
 2007-10-22 12:47:54.828 PostgresServerTool[2438] 1184 => timestamptz
 2007-10-22 12:47:54.828 PostgresServerTool[2438] 1186 => interval
 2007-10-22 12:47:54.828 PostgresServerTool[2438] 1266 => timetz
 2007-10-22 12:47:54.828 PostgresServerTool[2438] 1560 => bit
 2007-10-22 12:47:54.828 PostgresServerTool[2438] 1562 => varbit
 2007-10-22 12:47:54.828 PostgresServerTool[2438] 1700 => numeric
 2007-10-22 12:47:54.828 PostgresServerTool[2438] 1790 => refcursor
 2007-10-22 12:47:54.828 PostgresServerTool[2438] 2202 => regprocedure
 2007-10-22 12:47:54.829 PostgresServerTool[2438] 2203 => regoper
 2007-10-22 12:47:54.829 PostgresServerTool[2438] 2204 => regoperator
 2007-10-22 12:47:54.829 PostgresServerTool[2438] 2205 => regclass
 2007-10-22 12:47:54.829 PostgresServerTool[2438] 2206 => regtype
 2007-10-22 12:47:54.829 PostgresServerTool[2438] 2249 => record
 2007-10-22 12:47:54.829 PostgresServerTool[2438] 2275 => cstring
 2007-10-22 12:47:54.829 PostgresServerTool[2438] 2276 => any
 2007-10-22 12:47:54.829 PostgresServerTool[2438] 2277 => anyarray
 2007-10-22 12:47:54.829 PostgresServerTool[2438] 2278 => void
 2007-10-22 12:47:54.829 PostgresServerTool[2438] 2279 => trigger
 2007-10-22 12:47:54.829 PostgresServerTool[2438] 2280 => language_handler
 2007-10-22 12:47:54.829 PostgresServerTool[2438] 2281 => internal
 2007-10-22 12:47:54.829 PostgresServerTool[2438] 2282 => opaque
 2007-10-22 12:47:54.829 PostgresServerTool[2438] 2283 => anyelement
 */

