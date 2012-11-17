
#import <Foundation/Foundation.h>

// these are the geometric types
typedef enum {
	FLXGeometryTypePoint = FLXPostgresTypePoint,
	FLXGeometryTypeLine = FLXPostgresTypeLSeg,
	FLXGeometryTypePath = FLXPostgresTypePath,
	FLXGeometryTypeBox = FLXPostgresTypeBox,
	FLXGeometryTypePolygon = FLXPostgresTypePolygon,
	FLXGeometryTypeCircle = FLXPostgresTypeCircle
} FLXGeometryType;

typedef struct {
	Float64 x;
	Float64 y;
} FLXGeometryPt;

// methods
FLXGeometryPt FLXMakePoint(Float64 x,Float64 y);
NSString* NSStringFromFLXPoint(FLXGeometryPt p);
NSString* NSStringFromFLXPointArray(const FLXGeometryPt* points,NSUInteger size);

////////////////////////////////////////////////////////////////////////////////
// base class

@interface FLXGeometry : NSObject {
	FLXGeometryType type;
	NSData* data;
	Float64 radius; // for FLXGeometryTypeCircle
	NSUInteger size;
	BOOL closed; // for FLXGeometryTypePath
}

// constructors
+(FLXGeometry* )pointWithOrigin:(FLXGeometryPt)thePoint;
+(FLXGeometry* )circleWithCentre:(FLXGeometryPt)thePoint radius:(Float64)theRadius;
+(FLXGeometry* )lineWithOrigin:(FLXGeometryPt)theOrigin destination:(FLXGeometryPt)theDestination;
+(FLXGeometry* )boxWithPoint:(FLXGeometryPt)theOrigin point:(FLXGeometryPt)theDestination;
+(FLXGeometry* )polygonWithPoints:(const FLXGeometryPt* )thePoints count:(NSUInteger)theCount;
+(FLXGeometry* )pathWithPoints:(const FLXGeometryPt* )thePoints count:(NSUInteger)theCount closed:(BOOL)isClosedPath;

// methods
-(FLXGeometryType)type;
-(FLXGeometryPt)pointAtIndex:(NSUInteger)theIndex;
-(FLXGeometryPt)origin;
-(FLXGeometryPt)centre;
-(NSUInteger)count;

@end

////////////////////////////////////////////////////////////////////////////////
// point class

@interface FLXGeometryPoint : FLXGeometry {
	
}

@end

////////////////////////////////////////////////////////////////////////////////
// line class

@interface FLXGeometryLine : FLXGeometry {
	
}

@end

////////////////////////////////////////////////////////////////////////////////
// box class

@interface FLXGeometryBox : FLXGeometry {
	
}

@end

////////////////////////////////////////////////////////////////////////////////
// circle class

@interface FLXGeometryCircle : FLXGeometry {
	
}

-(Float64)radius;

@end

////////////////////////////////////////////////////////////////////////////////
// polygon class

@interface FLXGeometryPolygon : FLXGeometry {
	
}

@end

////////////////////////////////////////////////////////////////////////////////
// path class

@interface FLXGeometryPath : FLXGeometry {
	
}

-(BOOL)closed;

@end




