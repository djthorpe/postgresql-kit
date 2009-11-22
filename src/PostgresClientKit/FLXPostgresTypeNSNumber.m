#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"
#import "FLXPostgresTypeNSNumber.h"

////////////////////////////////////////////////////////////////////////////////

FLXPostgresOid FLXPostgresTypeNSNumberTypes[] = { 
	FLXPostgresOidInt8,FLXPostgresOidInt2,FLXPostgresOidInt4,
	FLXPostgresOidFloat4,FLXPostgresOidFloat8,FLXPostgresOidBool,0 
};

////////////////////////////////////////////////////////////////////////////////

@implementation FLXPostgresTypeNSNumber

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
	return FLXPostgresTypeNSNumberTypes;
}

-(Class)nativeClass {
	return [NSNumber class];
}

////////////////////////////////////////////////////////////////////////////////

-(NSData* )remoteDataFromObject:(id)theObject type:(FLXPostgresOid* )theType {
	NSParameterAssert(theObject);
	NSParameterAssert([theObject isKindOfClass:[NSNumber class]]);	
	NSParameterAssert(theType);
}

-(id)objectFromRemoteData:(const void* )theBytes length:(NSUInteger)theLength type:(FLXPostgresOid)theType {
	NSParameterAssert(theBytes);
}

-(NSString* )quotedStringFromObject:(id)theObject {
	NSParameterAssert(theObject);
	NSParameterAssert([theObject isKindOfClass:[NSNumber class]]);
	return [(NSNumber* )theObject stringValue];
}

@end
