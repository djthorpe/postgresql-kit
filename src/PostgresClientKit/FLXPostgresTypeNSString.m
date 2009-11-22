
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"
#import "FLXPostgresTypeNSString.h"

FLXPostgresOid FLXPostgresTypeNSStringBoundTypes[] = { FLXPostgresOidText, 0 };

@implementation FLXPostgresTypeNSString

-(id)initWithConnection:(FLXPostgresConnection* )theConnection {
	self = [super init];
	if(self != nil) {
		m_theConnection = [theConnection retain];
	}
	return self;
}

-(void)dealloc {
	[m_theConnection release];
	[super dealloc];
}



-(FLXPostgresOid* )boundTypes {
	return FLXPostgresTypeNSStringBoundTypes;
}

-(id)objectFromData:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);	
	return [[[NSString alloc] initWithBytes:theBytes length:theLength encoding:NSUTF8StringEncoding] autorelease];
}

-(NSString* )quotedStringFromObject:(id)theObject {
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

-(NSData* )dataFromObject:(id)theObject type:(FLXPostgresOid* )theBoundType {
	NSParameterAssert(theObject);
	NSParameterAssert(theBoundType);
	(*theType) = FLXPostgresOidText;
	// return a UTF8 string as data
	return [theString dataUsingEncoding:NSUTF8StringEncoding];	
}

/*


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

 */

@end
