
#import "ClientConnection.h"

@implementation ClientConnection
@synthesize server;
@synthesize client;

////////////////////////////////////////////////////////////////////////////////

+(void)stopServer:(FLXServer* )theServer {	
	// stop the server
	BOOL isSuccess = YES;
	isSuccess = [theServer stop];
	if(isSuccess==NO) NSLog(@"Unable to initiate server stop");
//	NSParameterAssert(isSuccess);
	
	NSUInteger theClock = 0;
	while([theServer state] != FLXServerStateStopped && theClock < 5) {
		NSLog(@"server state = %@",[theServer stateAsString]);
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
		theClock++;
	}
	
	if([theServer state] != FLXServerStateStopped) {
		NSLog(@"Unable to stop server: %@",[theServer stateAsString]);
		//NSParameterAssert(NO);
	}	
}

+(void)startServer:(FLXServer* )theServer {
	NSLog(@"starting server....");
	
	// Path should be home directory
	NSString* theTempDirectory = NSTemporaryDirectory();
	NSString* theDataDirectory = [theTempDirectory stringByAppendingString:@"postgres-kit-test"];

	NSError* theError = nil;
	BOOL isSuccess = YES;

	NSLog(@"data directory = %@",theDataDirectory);
	
	// remove data directory
	if([[NSFileManager defaultManager] fileExistsAtPath:theDataDirectory]==YES) {	
		NSLog(@"stopping server....");
		[self stopServer:theServer];		
		NSLog(@"removing path %@",theDataDirectory);
		isSuccess = [[NSFileManager defaultManager] removeItemAtPath:theDataDirectory error:&theError];
		if(theError) NSLog(@"%@: %@",theDataDirectory,[theError localizedDescription]);
	}
	NSParameterAssert(isSuccess);

	// create data directory
	isSuccess = [[NSFileManager defaultManager] createDirectoryAtPath:theDataDirectory attributes:nil];
	if(isSuccess==NO) NSLog(@"%@: Unable to create directory",theDataDirectory);
	NSParameterAssert(isSuccess);

	NSLog(@"created directory = %@",theDataDirectory);
		
	// start the server
	isSuccess = [theServer startWithDataPath:theDataDirectory];
	if(isSuccess==NO) NSLog(@"Unable to initiate startWithDataPath");
	NSParameterAssert(isSuccess);

	NSUInteger theClock = 0;
	while([theServer state] != FLXServerStateStarted && theClock < 60) {
		
		NSLog(@"server state = %@",[theServer stateAsString]);
		
		if([theServer state]==FLXServerStateStopped || [theServer state]==FLXServerStateStartingError) {
			NSLog(@"Unable to start server: %@",[theServer stateAsString]);
			NSParameterAssert(NO);
		}
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
		theClock++;
	}

	if([theServer isRunning]==NO) {
		NSLog(@"Server could not be started");
		NSParameterAssert(NO);
	}			
}

+(void)tearDown {
	NSLog(@"doing teardown");
	
	[self stopServer:[FLXServer sharedServer]];
	
	// remove the data directory
	NSString* theDataDirectory = [[FLXServer sharedServer] dataPath];
	BOOL isSuccess = YES;
	NSError* theError = nil;	
	if([[NSFileManager defaultManager] fileExistsAtPath:theDataDirectory]==YES) {
		isSuccess = [[NSFileManager defaultManager] removeItemAtPath:theDataDirectory error:&theError];
		if(theError) NSLog(@"%@: %@",theDataDirectory,[theError localizedDescription]);
	}
	NSParameterAssert(isSuccess);
}	

-(void)setUp {
	
	//////// server
	[self setServer:[FLXServer sharedServer]];		
	if([[self server] isRunning]==NO) {
		[[self class] startServer:[self server]];
	}
	
	//////// client
	FLXPostgresConnection* theConnection = [[[FLXPostgresConnection alloc] init] autorelease];
	@try {
		[theConnection setDatabase:@"postgres"];
		[theConnection setUser:[FLXServer superUsername]];
		[theConnection connect];
	} @catch(NSException* theException) {
		NSLog(@"%@",theException);
	}	
	STAssertTrue([theConnection connected],@"Connection not made");	
	[self setClient:theConnection];
}	

-(void)tearDown {
	@try {
		[[self client] disconnect];
	} @catch(NSException* theException) {
		NSLog(@"%@",theException);		
	}
	STAssertTrue([[self client] connected]==NO,@"Connection still active");	
	[self setClient:nil];
}

////////////////////////////////////////////////////////////////////////////////

-(void)testPing {
	FLXPostgresResult* theResult = [[self client] execute:@"SELECT 1"];
	STAssertNotNil(theResult,@"No result");	
	STAssertTrue([theResult isDataReturned],@"No data returned");	
	STAssertEquals([theResult affectedRows],((NSUInteger)1),@"Requires one row returned");
	NSLog(@"data returned = %@",[theResult fetchRowAsArray]);
}

@end
