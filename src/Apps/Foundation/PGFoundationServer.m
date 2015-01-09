#import "PGFoundationServer.h"

////////////////////////////////////////////////////////////////////////////////
// This example shows how to use the PGServerKit to create a server, as
// a foundation shell tool. When the server is started, any signal (TERM or KILL)
// is handled to stop the server gracefully

@implementation PGFoundationServer

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic dataPath;
@dynamic port;
@dynamic hostname;

-(NSString* )dataPath {
	NSString* theIdent = [[NSProcessInfo processInfo] processName];
	NSArray* theAppFolder = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask, YES);
	NSParameterAssert([theAppFolder count]);
	return [[theAppFolder objectAtIndex:0] stringByAppendingPathComponent:theIdent];
}

-(NSUInteger)port {
	// retrieve port from NSUserDefaults
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"port"]) {
		return [[NSUserDefaults standardUserDefaults] integerForKey:@"port"];
	} else {
		return PGServerDefaultPort;
	}
}

-(NSString* )hostname {
	// retrieve hostname from NSUserDefaults
	return [[NSUserDefaults standardUserDefaults] stringForKey:@"hostname"];
}

////////////////////////////////////////////////////////////////////////////////
// delegate methods

-(void)pgserver:(PGServer* )server message:(NSString* )message {
	printf("%s\n",[message UTF8String]);
}

-(void)pgserver:(PGServer* )server stateChange:(PGServerState)state {
	switch(state) {
		case PGServerStateAlreadyRunning:
		case PGServerStateRunning:
			printf("Server is ready to accept connections\n\n");
			printf("  Version = %s\n",[[[self server] version] UTF8String]);
			printf("  Data Path = %s\n",[[[self server] dataPath] UTF8String]);
			printf("  PID = %d\n",[server pid]);
			printf("  Port = %lu\n",[server port]);
			printf("  Hostname = %s\n",[[server hostname] UTF8String]);
			printf("  Socket path = %s\n",[[server socketPath] UTF8String]);
			printf("  Uptime = %lf seconds\n",[server uptime]);
			break;
		case PGServerStateError:
			// error occured, so program should quit with -1 return value
			printf("Server error, quitting\n");
			[super stop];
			[super stoppedWithReturnValue:-1];
			break;
		case PGServerStateStopped:
			// quit the application
			printf("Server stopped, ending application\n");
			[super stop];
			[super stoppedWithReturnValue:0];
			break;
		default:
			printf("Server state: %s\n",[[PGServer stateAsString:state] UTF8String]);
	}
}

////////////////////////////////////////////////////////////////////////////////
// methods

-(void)setup {
	// create a server
	PGServer* server = [PGServer serverWithDataPath:[self dataPath]];
	// bind to server
	[self setServer:server];
	[[self server] setDelegate:self];
	// start server
	[[self server] startWithNetworkBinding:[self hostname] port:[self port]];
}

-(void)stop {
	[super stop];
	[[self server] stop];
}

@end

////////////////////////////////////////////////////////////////////////////////
// main()

int main (int argc, const char* argv[]) {
	int returnValue = 0;
	@autoreleasepool {
		returnValue = [(PGFoundationApp* )[PGFoundationServer sharedApp] run];
	}
    return returnValue;
}
