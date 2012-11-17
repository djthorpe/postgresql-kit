
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"

@implementation FLXPostgresTypes (NetAddr)


////////////////////////////////////////////////////////////////////////////////////////////////
// mac addr

-(FLXMacAddr* )macAddrFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==6);
	return [FLXMacAddr macAddrWithBytes:theBytes];
}

-(NSObject* )boundValueFromMacAddr:(FLXMacAddr* )theMacAddr type:(FLXPostgresOid* )theTypeOid {
	NSParameterAssert(theMacAddr);
	NSParameterAssert(theTypeOid);
	(*theTypeOid) = FLXPostgresTypeMacAddr;
	return [theMacAddr data];
}

-(FLXPostgresOid)boundTypeFromMacAddr:(FLXMacAddr* )theMacAddr {
	NSParameterAssert(theMacAddr);
	return FLXPostgresTypeMacAddr;	
}

@end
