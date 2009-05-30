
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"
#import "FLXPostgresTypes+Geometry.h"
#import "FLXPostgresTypes+NSNumber.h"

@implementation FLXPostgresTypes (Geometry)

////////////////////////////////////////////////////////////////////////////////
// bound value from geometry object

-(NSData* )boundDataFromPoint:(FLXGeometryPt)point {
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

-(NSObject* )boundValueFromGeometry:(FLXGeometry* )theGeometry type:(FLXPostgresOid* )theTypeOid {
	NSParameterAssert(theGeometry);
	NSParameterAssert(theTypeOid);
	NSMutableData* theData = nil;
	switch([theGeometry type]) {
			
		case FLXGeometryTypePoint:
			theData = [NSMutableData dataWithCapacity:(sizeof(Float64) * 2)];
			NSParameterAssert(theData);
			(*theTypeOid) = FLXPostgresTypePoint;
			[theData appendData:[self boundDataFromPoint:[theGeometry origin]]];
			break;
			
		case FLXGeometryTypeLine:
			theData = [NSMutableData dataWithCapacity:(sizeof(Float64) * 4)];
			NSParameterAssert(theData);
			(*theTypeOid) = FLXPostgresTypeLSeg;
			[theData appendData:[self boundDataFromPoint:[theGeometry pointAtIndex:0]]];
			[theData appendData:[self boundDataFromPoint:[theGeometry pointAtIndex:1]]];
			break;
			
		case FLXGeometryTypeBox:
			theData = [NSMutableData dataWithCapacity:(sizeof(Float64) * 4)];
			NSParameterAssert(theData);
			(*theTypeOid) = FLXPostgresTypeBox;
			[theData appendData:[self boundDataFromPoint:[theGeometry pointAtIndex:0]]];
			[theData appendData:[self boundDataFromPoint:[theGeometry pointAtIndex:1]]];
			break;
			
		case FLXGeometryTypeCircle:
			theData = [NSMutableData dataWithCapacity:(sizeof(Float64) * 3)];
			NSParameterAssert(theData);
			(*theTypeOid) = FLXPostgresTypeCircle;
			[theData appendData:[self boundDataFromPoint:[theGeometry centre]]];
			[theData appendData:[self boundDataFromFloat64:[(FLXGeometryCircle* )theGeometry radius]]];
			break;
			
		default:
			// should never get here
			return nil;
	}			
	
	return theData;
}

////////////////////////////////////////////////////////////////////////////////////////////////
// convert to geometry object from bytes

-(FLXGeometry* )pointFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==16);
	const Float64* theFloats = theBytes;
	double x = [self float64FromBytes:theFloats];
	double y = [self float64FromBytes:(theFloats+1)];
	return [FLXGeometry pointWithOrigin:FLXMakePoint(x,y)];
}

-(FLXGeometry* )lineFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==32);
	const Float64* theFloats = theBytes;
	FLXGeometryPt p1 = FLXMakePoint([self float64FromBytes:theFloats], [self float64FromBytes:(theFloats+1)]);
	FLXGeometryPt p2 = FLXMakePoint([self float64FromBytes:(theFloats+2)], [self float64FromBytes:(theFloats+3)]);
	return [FLXGeometry lineWithOrigin:p1 destination:p2];
}

-(FLXGeometry* )boxFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==32);
	const Float64* theFloats = theBytes;
	FLXGeometryPt p1 = FLXMakePoint([self float64FromBytes:theFloats], [self float64FromBytes:(theFloats+1)]);
	FLXGeometryPt p2 = FLXMakePoint([self float64FromBytes:(theFloats+2)], [self float64FromBytes:(theFloats+3)]);
	return [FLXGeometry boxWithPoint:p1 point:p2];
}

-(FLXGeometry* )circleFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==24);
	const Float64* theFloats = theBytes;
	FLXGeometryPt centre = FLXMakePoint([self float64FromBytes:theFloats], [self float64FromBytes:(theFloats+1)]);
	Float64 radius = [self float64FromBytes:(theFloats+2)];
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

@end
