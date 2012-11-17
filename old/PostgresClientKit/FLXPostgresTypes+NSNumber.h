
#import <Foundation/Foundation.h>

@interface FLXPostgresTypes (NSNumber)

-(Float32)float32FromBytes:(const void* )theBytes;
-(Float64)float64FromBytes:(const void* )theBytes;
-(SInt16)int16FromBytes:(const void* )theBytes;
-(SInt32)int32FromBytes:(const void* )theBytes;
-(SInt64)int64FromBytes:(const void* )theBytes;
-(UInt16)unsignedInt16FromBytes:(const void* )theBytes;
-(UInt32)unsignedInt32FromBytes:(const void* )theBytes;
-(UInt64)unsignedInt64FromBytes:(const void* )theBytes;
-(BOOL)booleanFromBytes:(const void* )theBytes;

-(NSData* )boundDataFromFloat32:(Float32)theValue;
-(NSData* )boundDataFromFloat64:(Float64)theValue;
-(NSData* )boundDataFromInt32:(SInt32)theValue;
-(NSData* )boundDataFromInt64:(SInt64)theValue;
-(NSData* )boundDataFromBoolean:(BOOL)theValue;

-(NSObject* )boundValueFromNumber:(NSNumber* )theNumber type:(FLXPostgresOid* )theType;
-(FLXPostgresOid)boundTypeFromNumber:(NSNumber* )theNumber;

-(NSString* )quotedStringFromNumber:(NSNumber* )theNumber;
-(NSNumber* )integerObjectFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(NSNumber* )unsignedIntegerObjectFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(NSNumber* )realObjectFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(NSNumber* )booleanObjectFromBytes:(const void* )theBytes length:(NSUInteger)theLength;

@end
