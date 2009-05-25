
#import <Foundation/Foundation.h>

// these are the geometric types
typedef enum {
	FLXGeometryTypePoint = FLXPostgresTypePoint,
	FLXGeometryTypeLine = FLXPostgresTypeLine,
	FLXGeometryTypePath = FLXPostgresTypePath,
	FLXGeometryTypeBox = FLXPostgresTypeBox,
	FLXGeometryTypePolygon = FLXPostgresTypePolygon,
	FLXGeometryTypeCircle = FLXPostgresTypeCircle
} FLXGeometryType;

typedef struct {
	Float64 x;
	Float64 y;
} FLXGeometryPoint;

// methods
FLXGeometryPoint FLXMakePoint(Float64 x,Float64 y);
NSString* NSStringFromFLXPoint(FLXGeometryPoint p);
NSString* NSStringFromFLXPointArray(const FLXGeometryPoint* points,NSUInteger size);

////////////////////////////////////////////////////////////////////////////////
// class

@interface FLXGeometry : NSObject {
	FLXGeometryType type;
	NSData* data;
	Float64 radius; // for FLXGeometryTypeCircle
	NSUInteger size;
}

// constructors
+(FLXGeometry* )pointWithOrigin:(FLXGeometryPoint)thePoint;
+(FLXGeometry* )circleWithCentre:(FLXGeometryPoint)thePoint radius:(Float64)theRadius;
+(FLXGeometry* )lineWithOrigin:(FLXGeometryPoint)theOrigin destination:(FLXGeometryPoint)theDestination;
+(FLXGeometry* )boxWithPoint:(FLXGeometryPoint)theOrigin point:(FLXGeometryPoint)theDestination;

// methods
-(FLXGeometryType)type;
-(FLXGeometryPoint)pointAtIndex:(NSUInteger)theIndex;
-(FLXGeometryPoint)origin;
-(FLXGeometryPoint)centre;
-(Float64)radius;
-(NSUInteger)count;

@end
