
#import "PostgresServerApp.h"
#import "PostgresPrefPaneShared.h"

@implementation PostgresServerApp

@synthesize server;
@synthesize connection;
@synthesize dataPath;

-(void)dealloc {
	[self setDataPath:nil];
	[self setConnection:nil];
	[self setServer:nil];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////

-(BOOL)awakeThread {

	// set up shared postgres object
	[self setServer:[FLXServer sharedServer]];
	if([self server]==nil) {
		return NO;
	}
	
	// set postgres delegate
	[[self server] setDelegate:self];

	// NSConnection object
	[self setConnection:[NSConnection defaultConnection]];
	[[self connection] setRootObject:self];
	if([[self connection] registerName:PostgresServerAppIdentifier]==NO) {
		return NO;
	}
	
	// indicate
	[self serverStateDidChange:[self serverState]];
	
	// success
	return YES;
}

////////////////////////////////////////////////////////////////////////////////

-(void)startServer {
	// start the server
	
	// create application support path
	BOOL isDirectory = NO;
	if([[NSFileManager defaultManager] fileExistsAtPath:[self dataPath] isDirectory:&isDirectory]==NO) {
		[[NSFileManager defaultManager] createDirectoryAtPath:[self dataPath] attributes:nil];
	}
	
	// initialize the data directory if nesessary
	NSString* theDataDirectory = [[self dataPath] stringByAppendingPathComponent:@"data"];
	if([[self server] startWithDataPath:theDataDirectory]==NO) {
		// starting failed, possibly because a server is already running
		if([[self server] state]==FLXServerStateAlreadyRunning) {
			[[self server] stop];
		}
	}    	
}

-(void)stopServer {
	[[self server] stop];
}

-(NSString* )serverVersion {
	return [[self server] serverVersion];
}

-(NSString* )serverState {
	return [[self server] stateAsString];
}

////////////////////////////////////////////////////////////////////////////////

-(void)serverMessage:(NSString* )theMessage {
	NSLog(@"server message: %@",theMessage);
}

-(void)serverStateDidChange:(NSString* )theMessage {
	NSLog(@"server state did change: %@",theMessage);	
}

@end
