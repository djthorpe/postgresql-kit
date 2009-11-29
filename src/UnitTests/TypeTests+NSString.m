
#import "TypeTests+NSString.h"

@implementation TypeTests
@synthesize server;

////////////////////////////////////////////////////////////////////////////////

-(void)setUp {
	NSURL* theURL = [NSURL URLWithString:@"psql://localhost/test"];
	FLXPostgresConnection* theConnection = [FLXPostgresConnection connectionWithURL:theURL];
	STAssertNoThrow([theConnection connect],@"Connect to database");
	STAssertTrue([theConnection connected],@"Connection not made");	
	[self setServer:theConnection];
}	

-(void)tearDown {
	STAssertNoThrow([[self server] disconnect],@"Connect to database");
	STAssertTrue([[self server] connected]==NO,@"Connection still active");	
	[self setServer:nil];
}

////////////////////////////////////////////////////////////////////////////////

-(void)test001_Ping {
	FLXPostgresResult* theResult = [[self server] execute:@"SELECT 'ping'"];
	STAssertNotNil(theResult,@"No result");	
	STAssertTrue([theResult isDataReturned],@"No data returned");	
	STAssertEquals((NSUInteger)1,[theResult affectedRows],@"Requires one row returned");
	STAssertEquals((NSUInteger)1,[theResult numberOfColumns],@"Requires one column returned");
	
	NSString* theValue = [[theResult fetchRowAsArray] objectAtIndex:0];
	STAssertNotNil(theValue,@"Cell should not be nil");	
	STAssertEqualObjects([NSString stringWithString:@"ping"],theValue,@"String should be 'ping' but is %@",theValue);	
}


@end
