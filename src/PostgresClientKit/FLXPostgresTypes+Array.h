
#import <Foundation/Foundation.h>

@interface FLXPostgresTypes (Array)
-(NSArray* )arrayFromBytes:(const void* )theBytes length:(NSUInteger)theLength type:(FLXPostgresOid)theType;
@end
