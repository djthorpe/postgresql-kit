
#import "ClientConnection.h"
#import <PostgresClientKit/PostgresClientKit.h>

@implementation ClientConnection

-(void)testCreateConnectionObject {
	FLXPostgresConnection* theConnection = [[FLXPostgresConnection alloc] init];

	// do stuff
	
	[theConnection release];
}

@end
