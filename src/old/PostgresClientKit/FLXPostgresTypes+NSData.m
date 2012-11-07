
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"
#import "FLXPostgresTypes+NSData.h"

@implementation FLXPostgresTypes (NSData)

-(NSObject* )boundValueFromData:(NSData* )theData type:(FLXPostgresOid* )theType {
	NSParameterAssert(theData);
	NSParameterAssert(theType);
	(*theType) = FLXPostgresTypeData;		
	return theData;
}

-(FLXPostgresOid)boundTypeFromData:(NSData* )theData {
	NSParameterAssert(theData);
	return FLXPostgresTypeData;		
}

-(NSString* )quotedStringFromData:(NSData* )theData {
	size_t theLength = 0;
	unsigned char* theBuffer = PQescapeByteaConn([[self connection] PGconn],[theData bytes],[theData length],&theLength);
	if(theBuffer==nil) {
		return nil;
	}
	NSMutableString* theNewString = [[NSMutableString alloc] initWithBytesNoCopy:theBuffer length:(theLength-1) encoding:NSUTF8StringEncoding freeWhenDone:YES];
	// add quotes
	[theNewString appendString:@"'"];
	[theNewString insertString:@"'" atIndex:0];
	// return the string
	return [theNewString autorelease];  
}

-(NSObject* )dataObjectFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	return [NSData dataWithBytes:theBytes length:theLength];	
}

@end
