
#import <Foundation/Foundation.h>

@interface FLXPostgresTypes (NSNumber)

-(Float32)floatFromBytes:(const void* )theBytes;
-(Float64)doubleFromBytes:(const void* )theBytes;
-(NSObject* )boundValueFromNumber:(NSNumber* )theNumber type:(FLXPostgresOid* )theType;
-(NSString* )quotedStringFromNumber:(NSNumber* )theNumber;
-(NSNumber* )integerObjectFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(NSNumber* )unsignedIntegerObjectFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(NSNumber* )realObjectFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(NSNumber* )booleanObjectFromBytes:(const void* )theBytes length:(NSUInteger)theLength;

@end
