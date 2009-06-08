#import <Foundation/Foundation.h>

@interface FLXPostgresTypes (NetAddr)
-(FLXMacAddr* )macAddrFromBytes:(const void* )theBytes length:(NSUInteger)theLength;
-(NSObject* )boundValueFromMacAddr:(FLXMacAddr* )theMacAddr type:(FLXPostgresOid* )theTypeOid;
@end
