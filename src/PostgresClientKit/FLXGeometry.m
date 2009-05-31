
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"

@implementation FLXGeometry

////////////////////////////////////////////////////////////////////////////////

-(id)initWithType:(FLXGeometryType)theType points:(const FLXGeometryPt* )thePoints size:(NSUInteger)theSize radius:(Float64)theRadius closed:(BOOL)isClosedPath {
	NSParameterAssert(thePoints);
	self = [super init];
	if (self != nil) {
		type = theType;
		radius = theRadius;
		closed = isClosedPath;
		size = theSize;
		data = [[NSMutableData alloc] initWithCapacity:(sizeof(FLXGeometryPt) * size)];
		NSParameterAssert(theSize==0 || data);
		if(theSize) {
			memcpy([(NSMutableData* )data mutableBytes],thePoints,sizeof(FLXGeometryPt) * size);
		}
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
	return [[FLXGeometry allocWithZone:zone] initWithType:type points:[data bytes] size:size radius:radius closed:closed];
}

////////////////////////////////////////////////////////////////////////////////

+(FLXGeometry* )pointWithOrigin:(FLXGeometryPt)thePoint {
	return [[[FLXGeometryPoint alloc] initWithType:FLXGeometryTypePoint points:&thePoint size:1 radius:0.0 closed:NO] autorelease];	
}

+(FLXGeometry* )circleWithCentre:(FLXGeometryPt)thePoint radius:(Float64)theRadius {
	return [[[FLXGeometryCircle alloc] initWithType:FLXGeometryTypeCircle points:&thePoint size:1 radius:theRadius closed:NO] autorelease];	
}

+(FLXGeometry* )lineWithOrigin:(FLXGeometryPt)theOrigin destination:(FLXGeometryPt)theDestination {
	FLXGeometryPt thePoints[2] = { theOrigin, theDestination };
	return [[[FLXGeometryLine alloc] initWithType:FLXGeometryTypeLine points:thePoints size:2 radius:0.0 closed:NO] autorelease];	
}

+(FLXGeometry* )boxWithPoint:(FLXGeometryPt)theOrigin point:(FLXGeometryPt)theDestination {
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
	FLXGeometryPt thePoints[2] = { theOrigin, theDestination };
	return [[[FLXGeometryBox alloc] initWithType:FLXGeometryTypeBox points:thePoints size:2 radius:0.0 closed:NO] autorelease];	
}

+(FLXGeometry* )polygonWithPoints:(const FLXGeometryPt* )thePoints count:(NSUInteger)theCount {
	return [[[FLXGeometryPolygon alloc] initWithType:FLXGeometryTypePolygon points:thePoints size:theCount radius:0.0 closed:NO] autorelease];
}

+(FLXGeometry* )pathWithPoints:(const FLXGeometryPt* )thePoints count:(NSUInteger)theCount closed:(BOOL)isClosedPath {
	return [[[FLXGeometryPath alloc] initWithType:FLXGeometryTypePath points:thePoints size:theCount radius:0.0 closed:isClosedPath] autorelease];
}

////////////////////////////////////////////////////////////////////////////////

-(FLXGeometryType)type {
	return type;
}

-(FLXGeometryPt)pointAtIndex:(NSUInteger)theIndex {
	NSParameterAssert(theIndex < size);
	FLXGeometryPt* thePoints = (FLXGeometryPt* )[data bytes];
	return thePoints[theIndex];
}

-(FLXGeometryPt)origin {
	return [self pointAtIndex:0];
}

-(FLXGeometryPt)centre {
	NSParameterAssert(type == FLXGeometryTypeCircle || type == FLXGeometryTypePoint);
	// TODO: centre point is different for boxes, lines, etc.
	return [self pointAtIndex:0];
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
		FLXGeometryPt a = [self pointAtIndex:i];
		FLXGeometryPt b = [anObject pointAtIndex:i];
		if(a.x != b.x) return NO;
		if(a.y != b.y) return NO;
	}
	return YES;
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation FLXGeometryPoint

-(NSString* )description {
	return [NSString stringWithFormat:@"<FLXGeometryPoint %@>",NSStringFromFLXPoint([self origin])];
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation FLXGeometryLine

-(NSString* )description {
	return [NSString stringWithFormat:@"<FLXGeometryLine %@>",NSStringFromFLXPointArray([data bytes],size)];
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation FLXGeometryBox

-(NSString* )description {
	return [NSString stringWithFormat:@"<FLXGeometryBox %@>",NSStringFromFLXPointArray([data bytes],size)];
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation FLXGeometryCircle

-(Float64)radius {
	NSParameterAssert(type == FLXGeometryTypeCircle); // radius is only relevant for circles
	return radius;
}

-(NSString* )description {
	return [NSString stringWithFormat:@"<FLXGeometryCircle %@, %f>",NSStringFromFLXPoint([self centre]),[self radius]];
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation FLXGeometryPolygon

-(NSString* )description {
	return [NSString stringWithFormat:@"<FLXGeometryPolygon %@>",NSStringFromFLXPointArray([data bytes],size)];
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation FLXGeometryPath

-(NSString* )description {
	return [NSString stringWithFormat:@"<FLXGeometryPath %@>",NSStringFromFLXPointArray([data bytes],size)];
}

-(BOOL)closed {
	return closed;
}

@end

////////////////////////////////////////////////////////////////////////////////

FLXGeometryPt FLXMakePoint(Float64 x,Float64 y) {
	FLXGeometryPt p;
	p.x = x; p.y = y;
	return p;
}

NSString* NSStringFromFLXPoint(FLXGeometryPt p) {
	return [NSString stringWithFormat:@"( %f,%f )",p.x,p.y];
}

NSString* NSStringFromFLXPointArray(const FLXGeometryPt* points,NSUInteger size) {
	NSMutableString* theString = [NSMutableString string];
	[theString appendString:@"( "];
	for(NSUInteger i = 0; i < size; i++) {
		if(i > 0) {
			[theString appendString:@","];
		}
		[theString appendString:NSStringFromFLXPoint(points[i])];
	}
	[theString appendString:@" )"];
	return theString;
}
