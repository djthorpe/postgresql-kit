
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"

@implementation FLXGeometry

////////////////////////////////////////////////////////////////////////////////

-(id)initWithPoint:(FLXGeometryPoint)point {
	self = [super init];
	if (self != nil) {
		type = FLXGeometryTypePoint;
		size = 1;
		data = [[NSMutableData alloc] initWithCapacity:(sizeof(FLXGeometryPoint) * size)];
		if(data==nil) {
			[self release];
			return nil;
		}
		memcpy([(NSMutableData* )data mutableBytes],&point,sizeof(point) * size);
	}
	return self;
}

-(void)dealloc {
	[data release];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////

+(FLXGeometry* )pointWithPoint:(FLXGeometryPoint)point {
	return [[[FLXGeometry alloc] initWithPoint:point] autorelease];	
}

+(FLXGeometry* )pointWithNSPoint:(NSPoint)point {
	return [[[FLXGeometry alloc] initWithPoint:FLXMakePoint(point.x,point.y)] autorelease];	
}


////////////////////////////////////////////////////////////////////////////////

-(NSString* )typeAsString {
	switch(type) {
	case FLXGeometryTypePoint:
		return @"point";
	case FLXGeometryTypeLine:
		return @"line";
	case FLXGeometryTypePath:
		return @"path";
	case FLXGeometryTypeBox:
		return @"box";
	case FLXGeometryTypePolygon:
		return @"polygon";
	case FLXGeometryTypeCircle:
		return @"circle";
	default:
		return @"unknown";
	}			
}

/*
+(FLXGeometry* )lineWithPoint:(FLXGeometryPoint)a point:(FLXGeometryPoint)b {
	
}

+(FLXGeometry* )circleWithCentre:(FLXGeometryPoint)c radius:(Float64)radius {
	
}

+(FLXGeometry* )boxWithPoint:(FLXGeometryPoint)a point:(FLXGeometryPoint)b {
	
}
*/

@end

////////////////////////////////////////////////////////////////////////////////

FLXGeometryPoint FLXMakePoint(Float64 x,Float64 y) {
	FLXGeometryPoint p;
	p.x = x; p.y = y;
	return p;
}

	
