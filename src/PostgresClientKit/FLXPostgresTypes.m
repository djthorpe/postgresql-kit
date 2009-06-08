
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"

#import "FLXPostgresTypes+NSString.h"
#import "FLXPostgresTypes+NSData.h"
#import "FLXPostgresTypes+NSNumber.h"
#import "FLXPostgresTypes+Geometry.h"
#import "FLXPostgresTypes+DateTime.h"
#import "FLXPostgresTypes+NetAddr.h"
#import "FLXPostgresTypes+Array.h"

////////////////////////////////////////////////////////////////////////////////

@implementation FLXPostgresTypes
@synthesize connection = m_theConnection;

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)initWithConnection:(FLXPostgresConnection* )theConnection {
	self = [super init];
	if (self != nil) {
		m_theConnection = [theConnection retain];
	}
	return self;	
}

-(void)dealloc {
	[m_theConnection release];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// properties from the server which affect how types are interpreted

-(NSObject* )boundValueFromObject:(NSObject* )theObject type:(FLXPostgresOid* )theType {
	NSParameterAssert(theObject);
	NSParameterAssert(theType);
	
	// NSNull
	if([theObject isKindOfClass:[NSNull class]]) {
		return theObject;
	}
	// NSString
	if([theObject isKindOfClass:[NSString class]]) {
		return [self boundValueFromString:(NSString* )theObject type:theType];
	}
	// NSData
	if([theObject isKindOfClass:[NSData class]]) {
		return [self boundValueFromData:(NSData* )theObject type:theType];
	}
	// NSNumber booleans are converted to strings, floats and doubles are converted to data
	if([theObject isKindOfClass:[NSNumber class]]) {
		return [self boundValueFromNumber:(NSNumber* )theObject type:theType];
	}
	// FLXTimeInterval
	if([theObject isKindOfClass:[FLXTimeInterval class]]) {
		return [self boundValueFromInterval:(FLXTimeInterval* )theObject type:theType];		
	}
	// FLXGeometry
	if([theObject isKindOfClass:[FLXGeometry class]]) {
		return [self boundValueFromGeometry:(FLXGeometry* )theObject type:theType];
	}
	// FLXMacAddr
	if([theObject isKindOfClass:[FLXMacAddr class]]) {
		return [self boundValueFromMacAddr:(FLXMacAddr* )theObject type:theType];
	}

	// Unsupported type: we don't support other types yet
	return nil;	
}

////////////////////////////////////////////////////////////////////////////////
// returns the NSObject from a data buffer, which is received from the
// postgresql server if the type is not recognized, then NSData object is
// returned instead.

-(NSObject* )objectFromBytes:(const void* )theBytes length:(NSUInteger)theLength type:(FLXPostgresOid)theType {
	switch(theType) {
		case FLXPostgresTypeChar:
		case FLXPostgresTypeName:
		case FLXPostgresTypeText:
		case FLXPostgresTypeVarchar:
		case FLXPostgresTypeUnknown:
			return [self stringObjectFromBytes:theBytes length:theLength];			
		case FLXPostgresTypeInt8:
		case FLXPostgresTypeInt2:
		case FLXPostgresTypeInt4:
			return [self integerObjectFromBytes:theBytes length:theLength];
		case FLXPostgresTypeOid:
			return [self unsignedIntegerObjectFromBytes:theBytes length:theLength];			
		case FLXPostgresTypeFloat4:
		case FLXPostgresTypeFloat8:
			return [self realObjectFromBytes:theBytes length:theLength];
		case FLXPostgresTypeBool:
			return [self booleanObjectFromBytes:theBytes length:theLength];
		case FLXPostgresTypeAbsTime:
			return [self abstimeFromBytes:theBytes length:theLength];
		case FLXPostgresTypeDate:
			return [self dateFromBytes:theBytes length:theLength];				
		case FLXPostgresTypeTimestamp:
			return [self timestampFromBytes:theBytes length:theLength];	
		case FLXPostgresTypeInterval:
			return [self intervalFromBytes:theBytes length:theLength];
		case FLXPostgresTypeMacAddr:
			return [self macAddrFromBytes:theBytes length:theLength];
		case FLXPostgresTypePoint:
			return [self pointFromBytes:theBytes length:theLength];
		case FLXPostgresTypeLSeg:
			return [self lineFromBytes:theBytes length:theLength];
		case FLXPostgresTypeBox:
			return [self boxFromBytes:theBytes length:theLength];
		case FLXPostgresTypePath:
			return [self pathFromBytes:theBytes length:theLength];
		case FLXPostgresTypePolygon:
			return [self polygonFromBytes:theBytes length:theLength];
		case FLXPostgresTypeCircle:
			return [self circleFromBytes:theBytes length:theLength];
		case FLXPostgresTypeArrayInt4:
			return [self arrayFromBytes:theBytes length:theLength type:FLXPostgresTypeInt4];	
		case FLXPostgresTypeArrayText:
			return [self arrayFromBytes:theBytes length:theLength type:FLXPostgresTypeText];	
		case FLXPostgresTypeData:
			return [self dataObjectFromBytes:theBytes length:theLength];
		default:
			[[self connection] _noticeProcessorWithMessage:[NSString stringWithFormat:@"Unknown type, %d, returning data object",theType]];
			return [self dataObjectFromBytes:theBytes length:theLength];
	}
}

@end

