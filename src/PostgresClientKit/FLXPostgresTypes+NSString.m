
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"
#import "FLXPostgresTypes+NSString.h"
#import "FLXPostgresTypes+NSData.h"

@implementation FLXPostgresTypes (NSString)

-(NSObject* )boundValueFromString:(NSString* )theString type:(FLXPostgresOid* )theType {
	NSParameterAssert(theString);
	NSParameterAssert(theType);
	(*theType) = FLXPostgresTypeText;
	return theString;
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
	// string is always terminated with NULL so we don't need the length field
	return [NSString stringWithUTF8String:theBytes];	
}

@end
