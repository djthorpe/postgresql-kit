
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"
#import "FLXPostgresTypes+NSString.h"
#import "FLXPostgresTypes+NSData.h"

@implementation FLXPostgresTypes (NSString)

-(NSObject* )boundValueFromString:(NSString* )theString type:(FLXPostgresOid* )theType {
	NSParameterAssert(theString);
	NSParameterAssert(theType);
	(*theType) = FLXPostgresTypeText;
	// return a UTF8 string as data
	return [theString dataUsingEncoding:NSUTF8StringEncoding];
}

-(FLXPostgresOid)boundTypeFromString:(NSString* )theString {
	NSParameterAssert(theString);
	return FLXPostgresTypeText;
}

-(NSString* )quotedStringFromString:(NSString* )theString {
	NSParameterAssert(theString);
	return [self quotedStringFromData:[theString dataUsingEncoding:NSUTF8StringEncoding]];
}

-(NSObject* )stringObjectFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);	
	return [[[NSString alloc] initWithBytes:theBytes length:theLength encoding:NSUTF8StringEncoding] autorelease];
}

@end
