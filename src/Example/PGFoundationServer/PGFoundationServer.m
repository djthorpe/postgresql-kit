#import "PGFoundationServer.h"

@implementation PGFoundationServer

@synthesize signal;
@synthesize returnValue;
@dynamic dataPath;

////////////////////////////////////////////////////////////////////////////////
// properties

-(NSString* )dataPath {
	NSString* theIdent = @"PostgreSQL";
	NSArray* theApplicationSupportDirectory = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask, YES);
	NSParameterAssert([theApplicationSupportDirectory count]);
	return [[theApplicationSupportDirectory objectAtIndex:0] stringByAppendingPathComponent:theIdent];
}

////////////////////////////////////////////////////////////////////////////////
// delegate methods

-(void)pgserver:(PGServer* )server message:(NSString* )message {
	printf("%s\n",[message UTF8String]);
}

-(void)pgserverStateChange:(PGServer* )sender {
	switch([sender state]) {
		case PGServerStateAlreadyRunning:
			// need to reload the server
			printf("Server is already running, restarting\n");
			[[self server] restart];
			break;
		case PGServerStateStopped:
		case PGServerStateError:
			// quit the application
			[self setSignal:-1];
			CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
			break;
		default:
			printf("Server state: %s\n",[[PGServer stateAsString:[sender state]] UTF8String]);
	}
}

-(void)stop {
	[[self server] stop];
}

-(int)start {
	// create a server
	[self setServer:[PGServer serverWithDataPath:[self dataPath]]];
	// set server delegate
	[[self server] setDelegate:self];	
	// set success return value
	[self setReturnValue:0];
	
	// Report server version
	NSLog(@"Version: %@",[[self server] version]);
	
	// create a timer to fire once run loop is started
	[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerFired:) userInfo:nil repeats:NO];
	
	// start the run loop
	double resolution = 300.0;
	BOOL isRunning;
	do {
		NSDate* theNextDate = [NSDate dateWithTimeIntervalSinceNow:resolution];
		isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:theNextDate];
	} while(isRunning==YES && [self signal] >= 0);

	// return the code
	return [self returnValue];
}

-(void)timerFired:(id)theTimer {
	PGServerState state = [[self server] state];
	if(state==PGServerStateUnknown) {
		[[self server] start];
	}
}


/*
 // if server is stopped, then make signal minus 1, and stop the run loop now
 if([[self server] state]==PGServerStateStopped) {
 [self setSignal:-1];
 CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
 return;
 }
 
 // stop server if signal is greater than 0
 if([self signal] > 0) {
 [[self server] stop];
 }
 */
/*
 -(NSString* )hostname {
 return [[NSUserDefaults standardUserDefaults] stringForKey:@"hostname"];
 }
 
 -(NSUInteger)port {
 NSInteger port = [[NSUserDefaults standardUserDefaults] integerForKey:@"port"];
 if(port > 0) {
 return (NSUInteger)port;
 } else {
 return (NSUInteger)0;
 }
 }
 */


@end
