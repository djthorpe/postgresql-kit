
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"
#import "FLXPostgresTypeNSString.h"

////////////////////////////////////////////////////////////////////////////////

FLXPostgresOid FLXPostgresTypeNSStringTypes[] = { 
	FLXPostgresOidText,FLXPostgresOidChar,FLXPostgresOidVarchar,FLXPostgresOidUnknown,0 
};

////////////////////////////////////////////////////////////////////////////////

@implementation FLXPostgresTypeNSString

-(id)initWithConnection:(FLXPostgresConnection* )theConnection {
	NSParameterAssert(theConnection);
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

////////////////////////////////////////////////////////////////////////////////

-(FLXPostgresOid* )remoteTypes {
	return FLXPostgresTypeNSStringTypes;
}

-(Class)nativeClass {
	return [NSString class];
}

////////////////////////////////////////////////////////////////////////////////
// TODO: fix encoding to match whatever database is expecting

-(NSData* )remoteDataFromObject:(id)theObject type:(FLXPostgresOid* )theType {
	NSParameterAssert(theObject);
	NSParameterAssert([theObject isKindOfClass:[NSString class]]);	
	NSParameterAssert(theType);
	(*theType) = FLXPostgresOidText;
	// return a string as data (we assume UTF-8 right now)
	return [(NSString* )theObject dataUsingEncoding:NSUTF8StringEncoding];		
}

-(id)objectFromRemoteData:(const void* )theBytes length:(NSUInteger)theLength type:(FLXPostgresOid)theType {
	NSParameterAssert(theBytes);
	return [[[NSString alloc] initWithBytes:theBytes length:theLength encoding:NSUTF8StringEncoding] autorelease];
}

-(NSString* )quotedStringFromObject:(id)theObject {
	NSParameterAssert(theObject);
	NSParameterAssert([theObject isKindOfClass:[NSString class]]);
	return nil;
}

@end
