
#import "ClientConnection.h"
#import <PostgresClientKit/PostgresClientKit.h>

@implementation ClientConnection
@synthesize server;

////////////////////////////////////////////////////////////////////////////////

-(void)setUp {
    // Run before ALL test methods
	FLXServer* theServer = [FLXServer sharedServer];
	[self setServer:theServer];
}	

+(void)tearDown {
    // Run after ALL test method
	NSLog(@"TOTAL tearDown");
}	

////////////////////////////////////////////////////////////////////////////////

-(void)testCreateConnectionObject {
	FLXPostgresConnection* theConnection = [[FLXPostgresConnection alloc] init];

	STAssertNotNil([self server],@"Shared server should not be nil");

	
	
	[theConnection release];
}

-(void)testCreateConnectionObject2 {
	FLXPostgresConnection* theConnection = [[FLXPostgresConnection alloc] init];
	
	
	
	
	[theConnection release];
}

@end
