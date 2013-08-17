
#import "PGFoundationServer.h"

@implementation PGFoundationServer

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	self = [super init];
	if(self) {
		_server = [PGServer serverWithDataPath:[self dataPath]];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic isStarted;
@dynamic isStopped;
@dynamic isError;
@synthesize stopServer;
@dynamic dataPath;

-(BOOL)isStarted {
	return ([_server state]==PGServerStateRunning);
}

-(BOOL)isStopped {
	return ([_server state]==PGServerStateStopped);
}

-(BOOL)isError {
	return ([_server state]==PGServerStateError);
}

-(NSString* )dataPath {
	NSString* theIdent = @"PGFoundationServer";
	NSArray* theAppFolder = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask, YES);
	NSParameterAssert([theAppFolder count]);
	return [[theAppFolder objectAtIndex:0] stringByAppendingPathComponent:theIdent];
}

////////////////////////////////////////////////////////////////////////////////
// methods

-(BOOL)start {
	return [self startWithPort:PGServerDefaultPort];
}

-(BOOL)startWithPort:(NSUInteger)port {
	// set stop server to NO
	[self setStopServer:NO];
	// start background thread
	[NSThread detachNewThreadSelector:@selector(_backgroundRunLoop:) toTarget:self withObject:[NSNumber numberWithUnsignedInteger:port]];
	// waiting for server to start...
	while([self isStarted]==NO) {
		[NSThread sleepForTimeInterval:0.1];
		// check for error condition
		if([self isError]) {
			NSLog(@"Server start returned error");
			return NO;
		}
	}
	return YES;
}

-(BOOL)stop {
	// signal server to stop
	[self setStopServer:YES];
	// wait for server to stop
	while([self isStopped]==NO) {
		[NSThread sleepForTimeInterval:0.1];
	}
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// background runloop implementation

-(void)_backgroundRunLoop:(NSNumber* )port {
	NSParameterAssert(port && [port isKindOfClass:[NSNumber class]]);
	@autoreleasepool {
		[_server setDelegate:self];
		[_server startWithPort:[port unsignedIntegerValue]];
		[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_timerFired:) userInfo:nil repeats:YES];
		BOOL isRunning = YES;
		NSTimeInterval resolution = 5.0;
		do {
			NSDate* theNextDate = [NSDate dateWithTimeIntervalSinceNow:resolution];
			isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:theNextDate];
		} while(isRunning==YES);
	}
	NSLog(@"Terminated background run loop");
}

-(void)_timerFired:(id)sender {
	// check for server stop signal
	if([self stopServer]==YES) {
		NSLog(@"Terminating server....");
		[_server stop];
	}
}

////////////////////////////////////////////////////////////////////////////////
// delegate implementation

-(void)pgserver:(PGServer* )server stateChange:(PGServerState)state {
	switch(state) {
		case PGServerStateAlreadyRunning:
		case PGServerStateRunning:
			break;
		case PGServerStateError:
			break;
		case PGServerStateStopped:
			CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
			break;
		default:
			break;
	}
}

-(void)pgserver:(PGServer* )server message:(NSString* )message {
	NSLog(@"%@\n",message);
}


@end
