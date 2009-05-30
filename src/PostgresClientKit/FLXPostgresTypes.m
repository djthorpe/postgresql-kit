
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"

#import "FLXPostgresTypes+NSString.h"
#import "FLXPostgresTypes+NSData.h"

////////////////////////////////////////////////////////////////////////////////

// number of microseconds per second
#define USECS_PER_SEC ((double)1000000)

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

////////////////////////////////////////////////////////////////////////////////
// bound value from object - returns NSNull, NSString or NSData

-(NSData* )_boundFloat:(float)theValue {
	NSParameterAssert(sizeof(float)==4);
	union { Float32 r; UInt32 i; } u32;
	u32.r = theValue;
#if defined(__ppc__) || defined(__ppc64__)
	// don't swap
#else
	u32.i = CFSwapInt32HostToBig(u32.i);			
#endif
	NSData* theData = [NSData dataWithBytes:&u32 length:sizeof(u32)];	
	return theData;
}

-(NSData* )_boundDouble:(double)theValue {
	NSParameterAssert(sizeof(double)==8);
	union { Float64 r; UInt64 i; } u64;
	u64.r = theValue;
#if defined(__ppc__) || defined(__ppc64__)
	// don't swap
#else
	u64.i = CFSwapInt64HostToBig(u64.i);			
#endif
	NSData* theData = [NSData dataWithBytes:&u64 length:sizeof(u64)];	
	return theData;
}

-(NSData* )_boundLongLong:(SInt64)theValue {
	NSParameterAssert(sizeof(SInt64)==8);
#if defined(__ppc__) || defined(__ppc64__)
	// don't swap
#else
	theValue = EndianS64_NtoB(theValue);
#endif	
	return [NSData dataWithBytes:&theValue length:sizeof(theValue)];
}

-(NSData* )_boundInteger:(SInt32)theValue {
	NSParameterAssert(sizeof(SInt32)==4);
#if defined(__ppc__) || defined(__ppc64__)
	// don't swap
#else
	theValue = EndianS32_NtoB(theValue);
#endif	
	return [NSData dataWithBytes:&theValue length:sizeof(theValue)];
}

-(NSData* )_boundPoint:(FLXGeometryPt)point {
	union u { Float64 r; UInt64 i; };
	struct { union u a; union u b; } theValue;
	theValue.a.r = point.x;
	theValue.b.r = point.y;
	NSParameterAssert(sizeof(theValue)==16);
#if defined(__ppc__) || defined(__ppc64__)
	// don't swap
#else
	theValue.a.i = CFSwapInt64HostToBig(theValue.a.i);			
	theValue.b.i = CFSwapInt64HostToBig(theValue.b.i);
#endif
	return [NSData dataWithBytes:&theValue length:sizeof(theValue)];
}

-(NSObject* )_boundValueFromNumber:(NSNumber* )theNumber type:(FLXPostgresOid* )theTypeOid {
	const char* type = [theNumber objCType];
	switch(type[0]) {
		case 'c':
		case 'C':
		case 'B': // boolean
			(*theTypeOid) = FLXPostgresTypeBool;
			return [theNumber boolValue] ? @"true" : @"false";
		case 'i': // integer
		case 'l': // long
		case 'S': // unsigned short
			(*theTypeOid) = FLXPostgresTypeInt4;
			return [theNumber stringValue];
		case 's':
			(*theTypeOid) = FLXPostgresTypeInt2;
			return [theNumber stringValue];
		case 'q': // long long
		case 'Q': // unsigned long long
		case 'I': // unsigned integer
		case 'L': // unsigned long
			(*theTypeOid) = FLXPostgresTypeInt8;
			return [self _boundLongLong:[theNumber longLongValue]];
		case 'f': // float
			(*theTypeOid) = FLXPostgresTypeFloat4;
			return [self _boundFloat:[theNumber floatValue]];
		case 'd': // double
			(*theTypeOid) = FLXPostgresTypeFloat8;
			return [self _boundDouble:[theNumber doubleValue]];
		default:
			// we shouldn't get here
			NSParameterAssert(NO);
	}

	// we shouldn't reach here
	return nil;
}

-(NSObject* )_boundValueFromInterval:(FLXTimeInterval* )theInterval type:(FLXPostgresOid* )theTypeOid {
	NSParameterAssert(theInterval);
	(*theTypeOid) = FLXPostgresTypeInterval;	
	// data = <8 bytes integer or 8 bytes real>
	// then 4 bytes day
	// then 4 bytes month
	NSMutableData* theData = [NSMutableData dataWithCapacity:16];
	NSParameterAssert(theData);
	if([self isIntegerTimestamp]) {
		[theData appendData:[self _boundLongLong:(long long)([theInterval seconds] * USECS_PER_SEC)]];
	} else {
		[theData appendData:[self _boundDouble:[theInterval seconds]]];
	}
	[theData appendData:[self _boundInteger:[theInterval days]]];
	[theData appendData:[self _boundInteger:[theInterval months]]];
	return theData;
}

-(NSObject* )_boundValueFromGeometry:(FLXGeometry* )theGeometry type:(FLXPostgresOid* )theTypeOid {
	NSParameterAssert(theGeometry);
	NSParameterAssert(theTypeOid);
	NSMutableData* theData = nil;
	switch([theGeometry type]) {

		case FLXGeometryTypePoint:
			theData = [NSMutableData dataWithCapacity:(sizeof(Float64) * 2)];
			NSParameterAssert(theData);
			(*theTypeOid) = FLXPostgresTypePoint;
			[theData appendData:[self _boundPoint:[theGeometry origin]]];
			break;
			
		case FLXGeometryTypeLine:
			theData = [NSMutableData dataWithCapacity:(sizeof(Float64) * 4)];
			NSParameterAssert(theData);
			(*theTypeOid) = FLXPostgresTypeLSeg;
			[theData appendData:[self _boundPoint:[theGeometry pointAtIndex:0]]];
			[theData appendData:[self _boundPoint:[theGeometry pointAtIndex:1]]];
			break;

		case FLXGeometryTypeBox:
			theData = [NSMutableData dataWithCapacity:(sizeof(Float64) * 4)];
			NSParameterAssert(theData);
			(*theTypeOid) = FLXPostgresTypeBox;
			[theData appendData:[self _boundPoint:[theGeometry pointAtIndex:0]]];
			[theData appendData:[self _boundPoint:[theGeometry pointAtIndex:1]]];
			break;
			
		case FLXGeometryTypeCircle:
			theData = [NSMutableData dataWithCapacity:(sizeof(Float64) * 3)];
			NSParameterAssert(theData);
			(*theTypeOid) = FLXPostgresTypeCircle;
			[theData appendData:[self _boundPoint:[theGeometry centre]]];
			[theData appendData:[self _boundDouble:[(FLXGeometryCircle* )theGeometry radius]]];
			break;

		default:
			// should never get here
			return nil;
	}			

	return theData;
}

////////////////////////////////////////////////////////////////////////////////
// boundValueFromObject converts from an NSObject to something which can be
// transmitted to the remote postgresql server. Returns NSNull, NSString or NSData
// and sets type. NSString is transmitted as text, and NSData is
// transmitted as binary.

-(NSObject* )boundValueFromObject:(NSObject* )theObject type:(FLXPostgresOid* )theType {
	NSParameterAssert(theObject);
	NSParameterAssert(theType);
	// NSNull
	if([theObject isKindOfClass:[NSNull class]]) {
		return theObject;
	}
	// NSString
	if([theObject isKindOfClass:[NSString class]]) {
		return [self boundValueFromNSString:(NSString* )theObject type:theType];
	}
	// NSData
	if([theObject isKindOfClass:[NSData class]]) {
		return [self boundValueFromNSData:(NSData* )theObject type:theType];
	}
	// NSNumber booleans are converted to strings, floats and doubles are converted to data
	if([theObject isKindOfClass:[NSNumber class]]) {
		return [self _boundValueFromNumber:(NSNumber* )theObject type:theType];
	}
	// FLXTimeInterval
	if([theObject isKindOfClass:[FLXTimeInterval class]]) {
		return [self _boundValueFromInterval:(FLXTimeInterval* )theObject type:theType];		
	}
	// FLXGeometry
	if([theObject isKindOfClass:[FLXGeometry class]]) {
		return [self _boundValueFromGeometry:(FLXGeometry* )theObject type:theType];
	}
	// TODO: we don't support other types yet
	return nil;	
}

////////////////////////////////////////////////////////////////////////////////////////////////
// abstime

-(NSDate* )abstimeFromBytes:(const void* )theBytes length:(NSUInteger)theLength {	
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==4);
	// convert bytes into integer
	NSNumber* theTime = [self integerFromBytes:theBytes length:theLength];
	return [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)[theTime doubleValue]];
}

////////////////////////////////////////////////////////////////////////////////////////////////
// date

-(NSDate* )dateFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==4);
	// this is number of days since 1st January 2000
	NSNumber* theDays = [self integerFromBytes:theBytes length:theLength];
	NSCalendarDate* theEpoch = [NSCalendarDate dateWithYear:2000 month:1 day:1 hour:0 minute:0 second:0 timeZone:nil];
	NSCalendarDate* theDate = [theEpoch dateByAddingYears:0 months:0 days:[theDays integerValue] hours:0 minutes:0 seconds:0];	
	[theDate setCalendarFormat:@"%Y-%m-%d"];
	return theDate;
}

////////////////////////////////////////////////////////////////////////////////////////////////
// timestamp

-(NSDate* )timestampFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==8);
	NSCalendarDate* theEpoch = [NSCalendarDate dateWithYear:2000 month:1 day:1 hour:0 minute:0 second:0 timeZone:nil];
	if([self isIntegerTimestamp]) {
		// this is number of microseconds since 1st January 2000
		NSNumber* theMicroseconds = [self integerFromBytes:theBytes length:theLength];	
		return [theEpoch addTimeInterval:([theMicroseconds doubleValue] / (double)USECS_PER_SEC)];
	} else {
		double theSeconds = [self doubleFromBytes:theBytes];	
		return [theEpoch addTimeInterval:theSeconds];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////
// mac addr

-(FLXMacAddr* )macaddrFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==6);
	return [FLXMacAddr macAddrWithData:[NSData dataWithBytes:theBytes length:theLength]];
}

////////////////////////////////////////////////////////////////////////////////////////////////
// geometry

-(FLXGeometry* )pointFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==16);
	const Float64* theFloats = theBytes;
	double x = [self doubleFromBytes:theFloats];
	double y = [self doubleFromBytes:(theFloats+1)];
	return [FLXGeometry pointWithOrigin:FLXMakePoint(x,y)];
}

-(FLXGeometry* )lineFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==32);
	const Float64* theFloats = theBytes;
	FLXGeometryPt p1 = FLXMakePoint([self doubleFromBytes:theFloats], [self doubleFromBytes:(theFloats+1)]);
	FLXGeometryPt p2 = FLXMakePoint([self doubleFromBytes:(theFloats+2)], [self doubleFromBytes:(theFloats+3)]);
	return [FLXGeometry lineWithOrigin:p1 destination:p2];
}

-(FLXGeometry* )boxFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==32);
	const Float64* theFloats = theBytes;
	FLXGeometryPt p1 = FLXMakePoint([self doubleFromBytes:theFloats], [self doubleFromBytes:(theFloats+1)]);
	FLXGeometryPt p2 = FLXMakePoint([self doubleFromBytes:(theFloats+2)], [self doubleFromBytes:(theFloats+3)]);
	return [FLXGeometry boxWithPoint:p1 point:p2];
}

-(FLXGeometry* )circleFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==24);
	const Float64* theFloats = theBytes;
	FLXGeometryPt centre = FLXMakePoint([self doubleFromBytes:theFloats], [self doubleFromBytes:(theFloats+1)]);
	Float64 radius = [self doubleFromBytes:(theFloats+2)];
	return [FLXGeometry circleWithCentre:centre radius:radius];
}

-(FLXGeometry* )pathFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	// TODO
	return nil;
}

-(FLXGeometry* )polygonFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	// TODO
	return nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////
// time interval

-(FLXTimeInterval* )intervalFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==16);
	NSNumber* interval= nil;
	if([self isIntegerTimestamp]) {
		// int64 interval
		// TODO: I doubt number is seconds, propably microseconds, so need to adjust
		interval = [self integerFromBytes:theBytes length:8];
	} else {
		// float8 interval 
		interval = [self realFromBytes:theBytes length:8];
	}
	const UInt32* thePtr = theBytes;
	NSNumber* day = [self integerFromBytes:(thePtr + 2) length:4];
	NSNumber* month = [self integerFromBytes:(thePtr + 3) length:4];
	return [FLXTimeInterval intervalWithSeconds:[interval doubleValue] days:[day integerValue] months:[month integerValue]];
}

////////////////////////////////////////////////////////////////////////////////////////////////
// arrays

-(NSArray* )arrayFromBytes:(const void* )theBytes length:(NSUInteger)theLength type:(FLXPostgresOid)theType {
	NSParameterAssert(theBytes);
	// use 4 byte alignment
	const UInt32* thePtr = theBytes;
	// get number of dimensions - we allow zero-dimension arrays
	NSInteger dim = [[self integerFromBytes:(thePtr++) length:4] integerValue];
	NSParameterAssert(dim >= 0 && dim <= ARRAY_MAXDIM);
	NSParameterAssert(thePtr <= (const UInt32* )((const UInt8* )theBytes + theLength));
	// return empty array if dim is zero
	if(dim==0) return [NSArray array];	
	// get flags - should be zero or one
	NSInteger flags = [[self integerFromBytes:(thePtr++) length:4] integerValue];
	NSParameterAssert(flags==0 || flags==1);
	NSParameterAssert(thePtr <= (const UInt32* )((const UInt8* )theBytes + theLength));
	// get type of array
	FLXPostgresOid type = [[self unsignedIntegerFromBytes:(thePtr++) length:4] unsignedIntegerValue];
	NSParameterAssert(type==theType);
	NSParameterAssert(thePtr <= (const UInt32* )((const UInt8* )theBytes + theLength));

	// create an array to hold tuples
	FLXPostgresArray* theArray = [FLXPostgresArray arrayWithDimensions:dim type:type];
	
	NSLog(@"data = %@",[NSData dataWithBytes:theBytes length:theLength]);
	
	// for each dimension, retrieve dimension and lower bound
	NSInteger tuples = dim ?  1 : 0;
	for(NSInteger i = 0; i < dim; i++) {
		NSInteger dimsize = [[self integerFromBytes:(thePtr++) length:4] integerValue];
		NSParameterAssert(thePtr <= (const UInt32* )((const UInt8* )theBytes + theLength));
		NSInteger bound =  [[self integerFromBytes:(thePtr++) length:4] integerValue];
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
		NSUInteger length = [[self unsignedIntegerFromBytes:(thePtr++) length:4] unsignedIntegerValue];
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
			return [self integerFromBytes:theBytes length:theLength];
		case FLXPostgresTypeOid:
			return [self unsignedIntegerFromBytes:theBytes length:theLength];			
		case FLXPostgresTypeFloat4:
		case FLXPostgresTypeFloat8:
			return [self realFromBytes:theBytes length:theLength];
		case FLXPostgresTypeBool:
			return [self booleanFromBytes:theBytes length:theLength];
		case FLXPostgresTypeAbsTime:
			return [self abstimeFromBytes:theBytes length:theLength];
		case FLXPostgresTypeDate:
			return [self dateFromBytes:theBytes length:theLength];				
		case FLXPostgresTypeTimestamp:
			return [self timestampFromBytes:theBytes length:theLength];	
		case FLXPostgresTypeInterval:
			return [self intervalFromBytes:theBytes length:theLength];
		case FLXPostgresTypeMacAddr:
			return [self macaddrFromBytes:theBytes length:theLength];
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

