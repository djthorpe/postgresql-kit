
#import <Foundation/Foundation.h>

@interface FLXPostgresTypes (NSString)

-(NSObject* )boundValueFromString:(NSString* )theString type:(FLXPostgresOid* )theType;
-(NSString* )quotedStringFromString:(NSString* )theString;
-(NSObject* )stringObjectFromBytes:(const void* )theBytes length:(NSUInteger)theLength;

@end
