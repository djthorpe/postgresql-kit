
#import <Foundation/Foundation.h>

@interface FLXPostgresTypes (Geometry)

-(NSObject* )boundValueFromGeometry:(FLXGeometry* )theGeometry type:(FLXPostgresOid* )theTypeOid;
-(FLXGeometry* )pointFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(FLXGeometry* )lineFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(FLXGeometry* )boxFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(FLXGeometry* )circleFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(FLXGeometry* )pathFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(FLXGeometry* )polygonFromBytes:(const void* )theBytes length:(NSUInteger)theLength;

@end
