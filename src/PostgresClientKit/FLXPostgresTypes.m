
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"

#import "FLXPostgresTypes+NSString.h"
#import "FLXPostgresTypes+NSData.h"
#import "FLXPostgresTypes+NSNumber.h"
#import "FLXPostgresTypes+Geometry.h"
#import "FLXPostgresTypes+DateTime.h"
#import "FLXPostgresTypes+NetAddr.h"

// maximum number of dimensions for arrays
#define ARRAY_MAXDIM   6

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

-(BOOL)isIntegerTimestamp {
	NSDictionary* parameters = [[self connection] parameters];
	NSParameterAssert(parameters);
	NSNumber* propertyValue = [parameters objectForKey:FLXPostgresParameterIntegerDateTimes];
	NSParameterAssert([propertyValue isKindOfClass:[NSNumber class]]);
	return [propertyValue boolValue];
}

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

////////////////////////////////////////////////////////////////////////////////////////////////
// arrays

-(NSArray* )arrayFromBytes:(const void* )theBytes length:(NSUInteger)theLength type:(FLXPostgresOid)theType {
	NSParameterAssert(theBytes);
	// use 4 byte alignment
	const UInt32* thePtr = theBytes;
	// get number of dimensions - we allow zero-dimension arrays
	NSInteger dim = [[self integerObjectFromBytes:(thePtr++) length:4] integerValue];
	NSParameterAssert(dim >= 0 && dim <= ARRAY_MAXDIM);
	NSParameterAssert(thePtr <= (const UInt32* )((const UInt8* )theBytes + theLength));
	// return empty array if dim is zero
	if(dim==0) return [NSArray array];	
	// get flags - should be zero or one
	NSInteger flags = [[self integerObjectFromBytes:(thePtr++) length:4] integerValue];
	NSParameterAssert(flags==0 || flags==1);
	NSParameterAssert(thePtr <= (const UInt32* )((const UInt8* )theBytes + theLength));
	// get type of array
	FLXPostgresOid type = [[self unsignedIntegerObjectFromBytes:(thePtr++) length:4] unsignedIntegerValue];
	NSParameterAssert(type==theType);
	NSParameterAssert(thePtr <= (const UInt32* )((const UInt8* )theBytes + theLength));

	// create an array to hold tuples
	FLXPostgresArray* theArray = [FLXPostgresArray arrayWithDimensions:dim type:type];
	
	NSLog(@"data = %@",[NSData dataWithBytes:theBytes length:theLength]);
	
	// for each dimension, retrieve dimension and lower bound
	NSInteger tuples = dim ?  1 : 0;
	for(NSInteger i = 0; i < dim; i++) {
		NSInteger dimsize = [[self integerObjectFromBytes:(thePtr++) length:4] integerValue];
		NSParameterAssert(thePtr <= (const UInt32* )((const UInt8* )theBytes + theLength));
		NSInteger bound =  [[self integerObjectFromBytes:(thePtr++) length:4] integerValue];
		NSParameterAssert(thePtr <= (const UInt32* )((const UInt8* )theBytes + theLength));
		NSParameterAssert(dimsize > 0);
		NSParameterAssert(bound >= 0);		
		// set dim-n size and lower bound
		[theArray setDimension:i size:dimsize lowerBound:bound];
		// calculate number of tuples
		tuples = tuples * dimsize;
	}	
	// iterate through the tuples
	for(NSInteger i = 0; i < tuples; i++) {
		NSUInteger length = [[self unsignedIntegerObjectFromBytes:(thePtr++) length:4] unsignedIntegerValue];
		NSParameterAssert(thePtr <= (const UInt32* )((const UInt8* )theBytes + theLength));
		NSObject* theObject = nil;
		if(length==((NSUInteger)0xFFFFFFFF)) {
			theObject = [NSNull null];
			length = 0;
		} else {
			theObject = [self objectFromBytes:thePtr length:length type:theType];
		}
		NSParameterAssert(theObject);
		// add tuple
		[theArray addTuple:theObject];
		// increment ptr by bytes
		thePtr = (const UInt32* )((const UInt8* )thePtr + length);
		NSParameterAssert(thePtr <= (const UInt32* )((const UInt8* )theBytes + theLength));
	}
	
	return [theArray array];
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

