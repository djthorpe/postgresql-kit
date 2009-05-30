
#import <Foundation/Foundation.h>

@interface FLXPostgresTypes (DateTime)

-(NSObject* )boundValueFromInterval:(FLXTimeInterval* )theInterval type:(FLXPostgresOid* )theTypeOid;
-(FLXTimeInterval* )intervalFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(NSDate* )abstimeFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(NSDate* )dateFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(NSDate* )timestampFromBytes:(const void* )theBytes length:(NSUInteger)theLength;

@end
