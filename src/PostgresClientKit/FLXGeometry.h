
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

////////////////////////////////////////////////////////////////////////////////
// class

@interface FLXGeometry : NSObject {
	FLXGeometryType type;
	NSData* data;
	Float64 radius; // for FLXGeometryTypeCircle
	NSUInteger size;
}

+(FLXGeometry* )pointWithPoint:(FLXGeometryPoint)point;

@end
