
#import <Foundation/Foundation.h>

@interface FLXPostgresTypes (Array)
-(NSObject* )arrayFromBytes:(const void* )theBytes length:(NSUInteger)theLength type:(FLXPostgresOid)theType;
-(NSObject* )boundValueFromArray:(NSArray* )theArray type:(FLXPostgresOid* )theTypeOid;
@end
