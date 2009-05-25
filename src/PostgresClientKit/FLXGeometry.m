
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"

@implementation FLXGeometry

////////////////////////////////////////////////////////////////////////////////

-(id)initWithType:(FLXGeometryType)theType points:(const FLXGeometryPoint* )thePoints size:(NSUInteger)theSize radius:(Float64)theRadius {
	NSParameterAssert(theSize > 0);
	NSParameterAssert(thePoints);
	self = [super init];
	if (self != nil) {
		type = theType;
		radius = theRadius;
		size = theSize;
		data = [[NSMutableData alloc] initWithCapacity:(sizeof(FLXGeometryPoint) * size)];
		NSParameterAssert(data);
		memcpy([(NSMutableData* )data mutableBytes],thePoints,sizeof(FLXGeometryPoint) * size);
	}
	return self;
}

-(void)dealloc {
	[data release];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// NSCopying

-(id)copyWithZone:(NSZone* )zone {
	return [[FLXGeometry allocWithZone:zone] initWithType:type points:[data bytes] size:size radius:radius];
}

////////////////////////////////////////////////////////////////////////////////

+(FLXGeometry* )pointWithOrigin:(FLXGeometryPoint)thePoint {
	return [[[FLXGeometry alloc] initWithType:FLXGeometryTypePoint points:&thePoint size:1 radius:0.0] autorelease];	
}

+(FLXGeometry* )circleWithCentre:(FLXGeometryPoint)thePoint radius:(Float64)theRadius {
	return [[[FLXGeometry alloc] initWithType:FLXGeometryTypeCircle points:&thePoint size:1 radius:theRadius] autorelease];	
}

+(FLXGeometry* )lineWithOrigin:(FLXGeometryPoint)theOrigin destination:(FLXGeometryPoint)theDestination {
	FLXGeometryPoint thePoints[2] = { theOrigin, theDestination };
	return [[[FLXGeometry alloc] initWithType:FLXGeometryTypeLine points:thePoints size:2 radius:0.0] autorelease];	
}

+(FLXGeometry* )boxWithPoint:(FLXGeometryPoint)theOrigin point:(FLXGeometryPoint)theDestination {
	// for boxes, the origin is always top right, and the destination is bottom left
	// swap x values
	if(theOrigin.x < theDestination.x) {
		Float64 swap = theOrigin.x;
		theOrigin.x = theDestination.x;
		theDestination.x = swap;
	}
	// swap y values
	if(theOrigin.y < theDestination.y) {
		Float64 swap = theOrigin.y;
		theOrigin.y = theDestination.y;
		theDestination.y = swap;
	}
	// make points
	FLXGeometryPoint thePoints[2] = { theOrigin, theDestination };
	return [[[FLXGeometry alloc] initWithType:FLXGeometryTypeBox points:thePoints size:2 radius:0.0] autorelease];	
}

// TODO: path and polygon TBD

////////////////////////////////////////////////////////////////////////////////

-(FLXGeometryType)type {
	return type;
}

-(FLXGeometryPoint)pointAtIndex:(NSUInteger)theIndex {
	NSParameterAssert(theIndex < size);
	FLXGeometryPoint* thePoints = (FLXGeometryPoint* )[data bytes];
	return thePoints[theIndex];
}

-(FLXGeometryPoint)origin {
	return [self pointAtIndex:0];
}

-(FLXGeometryPoint)centre {
	NSParameterAssert(type == FLXGeometryTypeCircle || type == FLXGeometryTypePoint);
	// TODO: centre point is different for boxes, lines, etc.
	return [self pointAtIndex:0];
}

-(Float64)radius {
	NSParameterAssert(type == FLXGeometryTypeCircle); // radius is only relevant for circles
	return radius;
}

-(NSUInteger)count {
	return size;
}

////////////////////////////////////////////////////////////////////////////////
// NSObject

-(BOOL)isEqual:(id)anObject {
	if([anObject isKindOfClass:[FLXGeometry class]]==NO) return NO;
	if([(FLXGeometry* )anObject type] != [self type]) return NO;
	if([anObject count] != size) return NO;
	if(type==FLXGeometryTypeCircle) {
		if([anObject radius] != radius) return NO;
	}
	for(NSUInteger i = 0; i < size; i++) {
		FLXGeometryPoint a = [self pointAtIndex:i];
		FLXGeometryPoint b = [anObject pointAtIndex:i];
		if(a.x != b.x) return NO;
		if(a.y != b.y) return NO;
	}
	return YES;
}

-(NSString* )description {
	switch(type) {
		case FLXGeometryTypePoint:
			return [NSString stringWithFormat:@"<FLXGeometry point=%@>",NSStringFromFLXPoint([self origin])];
		case FLXGeometryTypeLine:
			return [NSString stringWithFormat:@"<FLXGeometry line=%@>",NSStringFromFLXPointArray([data bytes],size)];
		case FLXGeometryTypePath:
			return [NSString stringWithFormat:@"<FLXGeometry path=%@>",NSStringFromFLXPointArray([data bytes],size)];
		case FLXGeometryTypeBox:
			return [NSString stringWithFormat:@"<FLXGeometry box=%@>",NSStringFromFLXPointArray([data bytes],size)];
		case FLXGeometryTypePolygon:
			return [NSString stringWithFormat:@"<FLXGeometry polygon=%@>",NSStringFromFLXPointArray([data bytes],size)];
		case FLXGeometryTypeCircle:
			return [NSString stringWithFormat:@"<FLXGeometry circle center=%@, radius=%f>",NSStringFromFLXPoint([self centre]),[self radius]];
	}
	return [super description];
}

@end

////////////////////////////////////////////////////////////////////////////////

FLXGeometryPoint FLXMakePoint(Float64 x,Float64 y) {
	FLXGeometryPoint p;
	p.x = x; p.y = y;
	return p;
}

NSString* NSStringFromFLXPoint(FLXGeometryPoint p) {
	return [NSString stringWithFormat:@"{ %f,%f }",p.x,p.y];
}

NSString* NSStringFromFLXPointArray(const FLXGeometryPoint* points,NSUInteger size) {
	NSMutableString* theString = [NSMutableString string];
	for(NSUInteger i = 0; i < size; i++) {
		if(i > 0) {
			[theString appendString:@","];
		}
		[theString appendString:NSStringFromFLXPoint(points[i])];
	}
	return theString;
}
