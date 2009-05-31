
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

-(NSObject* )boundValueFromPolygon:(FLXGeometry* )theGeometry type:(FLXPostgresOid* )theType {
	NSParameterAssert(theGeometry);
	NSParameterAssert([theGeometry type]==FLXGeometryTypePolygon);
	NSParameterAssert(theType);
	(*theType) = FLXPostgresTypePolygon;
	NSMutableData* theData = [NSMutableData dataWithCapacity:((sizeof(Float32) * [theGeometry count]) + sizeof(SInt64))];
	NSParameterAssert(theData);
	[theData appendData:[self boundDataFromInt32:[theGeometry count]]];
	for(NSUInteger i = 0; i < [theGeometry count]; i++) {
		[theData appendData:[self boundDataFromPoint:[theGeometry pointAtIndex:i]]];
	}
	return theData;
}


-(NSObject* )boundValueFromPath:(FLXGeometry* )theGeometry type:(FLXPostgresOid* )theType {
	NSParameterAssert(theGeometry);
	NSParameterAssert([theGeometry type]==FLXGeometryTypePath);
	NSParameterAssert(theType);
	(*theType) = FLXPostgresTypePath;
	NSMutableData* theData = [NSMutableData dataWithCapacity:((sizeof(Float32) * [theGeometry count]) + sizeof(SInt64))];
	NSParameterAssert(theData);
	[theData appendData:[self boundDataFromInt32:[theGeometry count]]];
	for(NSUInteger i = 0; i < [theGeometry count]; i++) {
		[theData appendData:[self boundDataFromPoint:[theGeometry pointAtIndex:i]]];
	}
	return theData;
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

		case FLXGeometryTypePolygon:
			return [self boundValueFromPolygon:theGeometry type:theTypeOid];

		case FLXGeometryTypePath:
			return [self boundValueFromPath:theGeometry type:theTypeOid];
			
		default:
			// should never get here
			return nil;
	}			
	
	return theData;
}

////////////////////////////////////////////////////////////////////////////////////////////////
// convert to geometry object from bytes

-(FLXGeometryPt)pointFromBytes:(const void* )theBytes {
	NSParameterAssert(theBytes);
	const Float64* theFloats = theBytes;
	return FLXMakePoint([self float64FromBytes:theFloats],[self float64FromBytes:(theFloats+1)]);	
}

-(FLXGeometry* )pointFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==16);
	return [FLXGeometry pointWithOrigin:[self pointFromBytes:theBytes]];
}

-(FLXGeometry* )lineFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==32);
	const Float64* theFloats = theBytes;
	FLXGeometryPt p1 = [self pointFromBytes:theFloats];
	FLXGeometryPt p2 = [self pointFromBytes:(theFloats+2)];
	return [FLXGeometry lineWithOrigin:p1 destination:p2];
}

-(FLXGeometry* )boxFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==32);
	const Float64* theFloats = theBytes;
	FLXGeometryPt p1 = [self pointFromBytes:theFloats];
	FLXGeometryPt p2 = [self pointFromBytes:(theFloats+2)];
	return [FLXGeometry boxWithPoint:p1 point:p2];
}

-(FLXGeometry* )circleFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==24);
	const Float64* theFloats = theBytes;
	FLXGeometryPt centre = [self pointFromBytes:theFloats];
	Float64 radius = [self float64FromBytes:(theFloats+2)];
	return [FLXGeometry circleWithCentre:centre radius:radius];
}

-(FLXGeometry* )polygonFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength >= 4);
	const SInt32* theBytes2 = theBytes;
	// read the count
	NSUInteger theCount = [self int32FromBytes:theBytes];	
	// ensure data length is correct
	NSParameterAssert(theLength==((theCount * sizeof(FLXGeometryPt)) + sizeof(SInt32)));

	// read in the points
	const FLXGeometryPt* thePointsIn = (const FLXGeometryPt* )((const SInt32* )theBytes2 + 1);
	FLXGeometryPt* thePointsOut = malloc(sizeof(FLXGeometryPt) * theCount);
	if(thePointsOut==nil) {
		return nil;
	}
	
	NSParameterAssert(thePointsOut);
	for(NSUInteger i = 0; i < theCount; i++) {
		thePointsOut[i] = [self pointFromBytes:(thePointsIn + i)];
	}

	// create polygon object
	FLXGeometry* thePolygon = [FLXGeometry polygonWithPoints:thePointsOut count:theCount];
	// free the temporary data structure
	free(thePointsOut);
	// return the polygon
	return thePolygon;
}

-(FLXGeometry* )pathFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	// TODO
	NSLog(@"TO BE IMPLEMENTED: pathFromBytes");
	return nil;
}
@end
