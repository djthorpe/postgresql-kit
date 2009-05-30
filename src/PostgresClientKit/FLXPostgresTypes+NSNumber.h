
#import <Foundation/Foundation.h>

@interface FLXPostgresTypes (NSNumber)

-(Float32)float32FromBytes:(const void* )theBytes;
-(Float64)float64FromBytes:(const void* )theBytes;
-(NSData* )boundDataFromFloat32:(Float32)theValue;
-(NSData* )boundDataFromFloat64:(Float64)theValue;
-(NSData* )boundDataFromInt32:(SInt32)theValue;
-(NSData* )boundDataFromInt64:(SInt64)theValue;

-(NSObject* )boundValueFromNumber:(NSNumber* )theNumber type:(FLXPostgresOid* )theType;
-(NSString* )quotedStringFromNumber:(NSNumber* )theNumber;
-(NSNumber* )integerObjectFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(NSNumber* )unsignedIntegerObjectFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(NSNumber* )realObjectFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(NSNumber* )booleanObjectFromBytes:(const void* )theBytes length:(NSUInteger)theLength;

@end
