
#import <Foundation/Foundation.h>

@interface FLXPostgresTypes (NSData)

-(NSObject* )boundValueFromData:(NSData* )theData type:(FLXPostgresOid* )theType;
-(NSString* )quotedStringFromData:(NSData* )theData;
-(NSObject* )dataObjectFromBytes:(const void* )theBytes length:(NSUInteger)theLength;

@end
