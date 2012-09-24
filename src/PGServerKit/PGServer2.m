
#include <sys/sysctl.h>
#include <pg_config.h>
#import "PGServerKit.h"
#import "PGServer+Private.h"

NSUInteger PGServer2DefaultPort = DEF_PGPORT;

@implementation PGServer2

@dynamic version;

////////////////////////////////////////////////////////////////////////////////
// initialization methods

+(PGServer* )sharedServer {
    static dispatch_once_t pred = 0;
    __strong static id _sharedServer = nil;
    dispatch_once(&pred, ^{
        _sharedServer = [[self alloc] init];
    });
    return _sharedServer;
}

-(id)init {
	self = [super init];
	if(self) {
		[self setDelegate:nil];
		_state = PGServerStateUnknown;
		_hostname = nil;
		_port = 0;
		_pid = -1;
		_dataPath = nil;
		_currentTask = nil;
		_timer = nil;
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// private methods for returning information

+(NSString* )_bundlePath {
	return [[NSBundle bundleForClass:[self class]] bundlePath];
}

+(NSString* )_serverBinary {
	return [[self _bundlePath] stringByAppendingPathComponent:@"Resources/postgresql-current/bin/postgres"];
}

+(NSString* )_initBinary {
	return [[self _bundlePath] stringByAppendingPathComponent:@"Resources/postgresql-current/bin/initdb"];
}

+(NSString* )_libraryPath {
	return [[self _bundlePath] stringByAppendingPathComponent:@"Resources/postgresql-current/lib"];
}

+(NSString* )_dumpBinary {
	return [[self _bundlePath] stringByAppendingPathComponent:@"Resources/postgresql-current/bin/pg_dumpall"];
}

+(NSString* )_superUsername {
	return @"postgres";
}

////////////////////////////////////////////////////////////////////////////////
// set state and send messages to delegate where necessary

-(void)_setState:(PGServerState)state {
	PGServerState oldState = _state;
	_state = state;
	if(_state != oldState && [[self delegate] respondsToSelector:@selector(pgserverStateChange:)]) {
		[[self delegate] performSelectorOnMainThread:@selector(pgserverStateChange:) withObject:self waitUntilDone:YES];
	}
}

////////////////////////////////////////////////////////////////////////////////
// send messages to the delegate

-(void)_delegateMessage:(NSString* )message {
	if([[self delegate] respondsToSelector:@selector(pgserverMessage:)] && [message length]) {
		[[self delegate] performSelectorOnMainThread:@selector(pgserverMessage:) withObject:message waitUntilDone:YES];
	}
}

-(void)_delegateMessageFromData:(NSData* )theData {
	NSString* theMessage = [[NSString alloc] initWithData:theData encoding:NSUTF8StringEncoding];
	NSArray* theArray = [theMessage componentsSeparatedByString:@"\n"];
	NSEnumerator* theEnumerator = [theArray objectEnumerator];
	NSString* theLine = nil;
	while(theLine = [theEnumerator nextObject]) {
		[self _delegateMessage:[theLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	}
}

////////////////////////////////////////////////////////////////////////////////
// private method to return the PID of the running postgresql process

-(int)_pidFromPath:(NSString* )thePath {
	NSString* thePidPath = [thePath stringByAppendingPathComponent:@"postmaster.pid"];
	if([[NSFileManager defaultManager] fileExistsAtPath:thePidPath]==NO) {
		// no postmaster.pid file found, therefore no process
		return 0;
	}
	if([[NSFileManager defaultManager] isReadableFileAtPath:thePidPath]==NO) {
		// if postmaster.pid is not readable, return error
		return -1;
	}
	NSDictionary* theAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:thePidPath error:nil];
	if(theAttributes==nil || [theAttributes fileSize] > 1024) {
		// if postmaster.pid file is too large, return error
		return -1;
	}
	NSError* theError = nil;
	NSString* thePidString = [NSString stringWithContentsOfFile:thePidPath encoding:NSUTF8StringEncoding error:&theError];
	if(thePidString==nil) {
		// if postmaster.pid file could not be read, return error
		return -1;
	}
	
	// return the PID as a decimal number
	NSDecimalNumber* thePid = [NSDecimalNumber decimalNumberWithString:thePidString];
	if(thePid==nil) {
		// if postmaster.pid file does not contain a valid decimal number, return
		return -1;
	}
	
	// success - return decimal number
	return [thePid intValue];
}

////////////////////////////////////////////////////////////////////////////////
// private method to create data path if it doesn't exist

-(BOOL)_createDataPath:(NSString* )thePath {
	// if directory already exists
	BOOL isDirectory = NO;
	if([[NSFileManager defaultManager] fileExistsAtPath:thePath isDirectory:&isDirectory]==NO) {
		// create the directory
		if([[NSFileManager defaultManager] createDirectoryAtPath:thePath withIntermediateDirectories:YES attributes:nil error:nil]==NO) {
			return NO;
		}
	} else if(isDirectory==NO) {
		return NO;
	}
	
	// success - return yes
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// run a task

-(BOOL)_startTask:(NSString* )theBinary arguments:(NSArray* )theArguments {
	NSParameterAssert(theBinary && [theBinary isKindOfClass:[NSString class]]);
	NSParameterAssert(theArguments && [theArguments isKindOfClass:[NSArray class]]);

	// check for currently running task
	if(_currentTask != nil) {
		return NO;
	}
	
	// set up the task
	NSTask* theTask = [[NSTask alloc] init];
	[theTask setLaunchPath:theBinary];
	[theTask setArguments:theArguments];

	// add dynamic library path
	[theTask setEnvironment:[NSDictionary dictionaryWithObject:[PGServer2 _libraryPath] forKey:@"DYLD_LIBRARY_PATH"]];

	// create a pipe
	NSPipe* thePipe = [[NSPipe alloc] init];
	[theTask setStandardOutput:thePipe];
	[theTask setStandardError:thePipe];

	// add a notification for the pipe's standard out
	NSFileHandle* theFileHandle = [thePipe fileHandleForReading];
	NSNotificationCenter* theNotificationCenter = [NSNotificationCenter defaultCenter];
    [theNotificationCenter addObserver:self
                           selector:@selector(_getTaskData:)
                               name:NSFileHandleReadCompletionNotification
                             object:nil];
	[theFileHandle readInBackgroundAndNotify];

	// now launch the task
	_currentTask = theTask;
	NSLog(@"Launching %@ with args %@",theBinary,theArguments);
	[theTask launch];
	return YES;
	
}

-(void)_getTaskData:(NSNotification* )theNotification {
	NSData* theData = [[theNotification userInfo] objectForKey:@"NSFileHandleNotificationDataItem"];

	[self _delegateMessageFromData:theData];

	if([theData length]) {
		// get more data
		[[theNotification object] readInBackgroundAndNotify];
	}
}

////////////////////////////////////////////////////////////////////////////////
// run a timer

-(void)_startTimer {
	if(_timer) {
		[_timer invalidate];
	}
	_timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_firedTimer:) userInfo:nil repeats:YES];
}

-(void)_firedTimer:(id)sender {
	BOOL isSuccess;
	switch(_state) {
		case PGServerStateIgnition:
			isSuccess = [self _startTask:[PGServer2 _serverBinary] arguments:[NSArray array]];
			if(isSuccess==NO) {
				[self _setState:PGServerStateError];
			} else {
				[self _setState:PGServerStateStarting];
			}
			break;
		default:
			break;
	}
	NSLog(@"timer fired");
}

////////////////////////////////////////////////////////////////////////////////
// property implementation

-(NSString* )version {
	NSPipe* theOutPipe = [[NSPipe alloc] init];
	NSTask* theTask = [[NSTask alloc] init];
	[theTask setStandardOutput:theOutPipe];
	[theTask setStandardError:theOutPipe];
	[theTask setLaunchPath:[PGServer2 _serverBinary]];
	[theTask setArguments:[NSArray arrayWithObject:@"--version"]];
	[theTask setEnvironment:[NSDictionary dictionaryWithObject:[PGServer2 _libraryPath] forKey:@"DYLD_LIBRARY_PATH"]];
	
	// get the version number
	[theTask launch];
	
	NSMutableData* theVersion = [NSMutableData data];
	NSData* theData = nil;
	while((theData = [[theOutPipe fileHandleForReading] availableData]) && [theData length]) {
		[theVersion appendData:theData];
	}
	
	// wait until task is actually completed
	[theTask waitUntilExit];
	int theReturnCode = [theTask terminationStatus];
	if(theReturnCode==0 && [theVersion length]) {
		return [[NSString alloc] initWithData:theVersion encoding:NSUTF8StringEncoding];
	} else {
		return nil;
	}
}

////////////////////////////////////////////////////////////////////////////////
// start server method

-(BOOL)startWithDataPath:(NSString* )thePath {
	return [self startWithDataPath:thePath hostname:nil port:0];
}

-(BOOL)startWithDataPath:(NSString* )thePath hostname:(NSString* )hostname port:(NSUInteger)port {
	NSParameterAssert(thePath);

	if([self state]==PGServerStateRunning || [self state]==PGServerStateStarting) {
		return NO;
	}
	
	// if database process is already running, then set this as the state and return NO
	int thePid = [self _pidFromPath:thePath];
	if(thePid > 0) {
		_pid = thePid;
		[self _setState:PGServerStateAlreadyRunning];
		return NO;
	}

	// create the data path if nesessary
	if([self _createDataPath:thePath]==NO) {
		[self _setState:PGServerStateError];
		[self _delegateMessage:[NSString stringWithFormat:@"Unable to create data path: %@",thePath]];
		return NO;
	}
	
	// set the pid to zero and state to ignition
	_pid = 0;
	[self _setState:PGServerStateIgnition];
	
	// start the timer
	[self _startTimer];
	
	// return YES
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// stop, reload and restart server

-(BOOL)stop {
	return NO;
}

-(BOOL)restart {
	return NO;
}

-(BOOL)reload {
	return NO;
}

////////////////////////////////////////////////////////////////////////////////
// utility methods

+(NSString* )stateAsString:(PGServerState)theState {
	switch(theState) {
		case PGServerStateStopped:
			return @"PGServerStateStopped";
		case PGServerStateStopping:
			return @"PGServerStateStopping";
		case PGServerStateStarting:
		case PGServerStateIgnition:
			return @"PGServerStateStarting";
		case PGServerStateInitialize:
			return @"PGServerStateInitialize";
		case PGServerStateRunning:
		case PGServerStateAlreadyRunning:
			return @"PGServerStateRunning";
		case PGServerStateUnknown:
			return @"PGServerStateUnknown";
		case PGServerStateError:
			return @"PGServerStateError";
		default:
			return @"????";
	}
}

@end
