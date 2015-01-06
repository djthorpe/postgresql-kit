
#import <Foundation/Foundation.h>
#import "PGFoundationServer.h"

////////////////////////////////////////////////////////////////////////////////

@interface PGFoundationServer (Private)
-(void)setStopFlag:(BOOL)value;
-(BOOL)stopFlag;
@end

////////////////////////////////////////////////////////////////////////////////

@implementation PGFoundationServer

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	self = [super init];
	if(self) {
		_server = [PGServer serverWithDataPath:[PGFoundationServer defaultDataPath]];
		_stop = NO;
	}
	return self;
}

-(id)initWithServer:(PGServer* )server {
	NSParameterAssert(server);
	self = [super init];
	if(self) {
		_server = server;
		_stop = NO;
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic isStarted;
@dynamic isStopped;
@dynamic isError;
@dynamic dataPath;

-(BOOL)isStarted {
	return ([_server state]==PGServerStateRunning || [_server state]==PGServerStateAlreadyRunning);
}

-(BOOL)isStopped {
	return ([_server state]==PGServerStateStopped || [_server state]==PGServerStateUnknown);
}

-(BOOL)isError {
	return ([_server state]==PGServerStateError);
}

-(NSString* )dataPath {
	return [_server dataPath];
}

////////////////////////////////////////////////////////////////////////////////
// class methods

+(NSString* )defaultDataPath {
	NSString* theIdent = @"PGFoundationServer";
	NSArray* theAppFolder = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask,YES);
	NSParameterAssert([theAppFolder count]);
	return [[theAppFolder objectAtIndex:0] stringByAppendingPathComponent:theIdent];
}

////////////////////////////////////////////////////////////////////////////////
// object methods

-(BOOL)deleteData {
	if([self isStopped]==NO) {
		NSLog(@"ERROR: stopped");
		return NO;
	}
	NSError* error = nil;
	BOOL isDir;
	NSParameterAssert([self dataPath]);
	if([[NSFileManager defaultManager] fileExistsAtPath:[self dataPath] isDirectory:&isDir]==NO) {
		// nothing exists at this path
		return YES;
	}
	if(isDir==NO) {
		// not a folder
		NSLog(@"ERROR: not a folder");
		return NO;
	}
	BOOL isSuccess = [[NSFileManager defaultManager] removeItemAtPath:[self dataPath] error:&error];
	if(isSuccess==NO) {
		[self pgserver:_server message:[error localizedDescription]];
		return NO;
	}
	return YES;
}

-(BOOL)start {
	return [self startWithPort:PGServerDefaultPort];
}

-(BOOL)startWithPort:(NSUInteger)port {
	// set stop signal
	[self setStopFlag:NO];
	// start background thread
	[NSThread detachNewThreadSelector:@selector(_backgroundRunLoop:) toTarget:self withObject:[NSNumber numberWithUnsignedInteger:port]];
	// waiting for server to start...
	while([self isStarted]==NO) {
		[NSThread sleepForTimeInterval:0.1];
		// check for error condition
		if([self isError]) {
			[self pgserver:_server message:@"Server start returned error"];
			return NO;
		}
	}
	return YES;
}

-(BOOL)stop {
	[self setStopFlag:YES];
	// wait for server to stop
	while([self isStopped]==NO) {
		[NSThread sleepForTimeInterval:0.1];
	}
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(void)setStopFlag:(BOOL)value {
	@synchronized(self) {
		_stop = value;
	}
}

-(BOOL)stopFlag {
	return _stop;
}

////////////////////////////////////////////////////////////////////////////////
// background runloop implementation

-(void)_backgroundRunLoop:(NSNumber* )port {
	NSParameterAssert(port && [port isKindOfClass:[NSNumber class]]);
	@autoreleasepool {
		[_server setDelegate:self];
		[_server startWithPort:[port unsignedIntegerValue]];
		[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(_timerFired:) userInfo:nil repeats:YES];
		BOOL isRunning = YES;
		NSTimeInterval resolution = 60.0;
		do {
			NSDate* theNextDate = [NSDate dateWithTimeIntervalSinceNow:resolution];
			isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:theNextDate];
		} while(isRunning==YES);
	}
	[self pgserver:_server message:@"Terminated background run loop"];
}

-(void)_timerFired:(id)sender {
	// check for server stop signal
	if([self stopFlag]==YES) {
		[self pgserver:_server message:@"Terminating server...."];
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

////////////////////////////////////////////////////////////////////////////////

@end
