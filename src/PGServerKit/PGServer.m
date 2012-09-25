
#include <sys/sysctl.h>
#include <pg_config.h>
#import "PGServerKit.h"
#import "PGServer+Private.h"

NSUInteger PGServerDefaultPort = DEF_PGPORT;

@implementation PGServer

@dynamic state;
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
		[self setState:PGServerStateUnknown];
		[self setTask:[[NSTask alloc] init]];
		[self setTaskOutput:[[NSPipe alloc] init]];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// private methods to return paths to things within the framework

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
// private method to return the PID of the running postgresql process

-(int)_pidFromDataPath {
	NSString* thePath = [[self dataPath] stringByAppendingPathComponent:@"postmaster.pid"];
	if([[NSFileManager defaultManager] fileExistsAtPath:thePath]==NO) {
		// no postmaster.pid file found, therefore no process
		return 0;
	}
	if([[NSFileManager defaultManager] isReadableFileAtPath:thePath]==NO) {
		// if postmaster.pid is not readable, return error
		return -1;
	}
	NSDictionary* theAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:thePath error:nil];
	if(theAttributes==nil || [theAttributes fileSize] > 1024) {
		// if postmaster.pid file is too large, return error
		return -1;
	}
	NSError* theError = nil;
	NSString* thePidString = [NSString stringWithContentsOfFile:thePath encoding:NSUTF8StringEncoding error:&theError];
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
// determine if process is still running
// see: http://www.cocoadev.com/index.pl?HowToDetermineIfAProcessIsRunning

-(int)_doesProcessExist:(int)thePid {
	int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, thePid };
	int returnValue = 1;
	size_t count;
	if(sysctl(mib,4,0,&count,0,0) < 0 ) {
		return 0;
	}
	struct kinfo_proc* kp = (struct kinfo_proc* )malloc(count);
	if(kp==nil) return -1;
	if(sysctl(mib,4,kp,&count,0,0) < 0) {
		returnValue = -1;
	} else {
		int nentries = count / sizeof(struct kinfo_proc);
		if(nentries < 1) {
			returnValue = 0;
		}
	}
	free(kp);
	return returnValue;
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
// set state and emit messages

-(PGServerState)state {
	return _state;
}

-(void)setState:(PGServerState)state {
	PGServerState oldState = _state;
	_state = state;
	if(_state != oldState && [[self delegate] respondsToSelector:@selector(pgserverStateChange:)]) {
		[[self delegate] performSelectorOnMainThread:@selector(pgserverStateChange:) withObject:self waitUntilDone:YES];
	}
}

-(void)_delegateMessage:(NSString* )message {
	
	NSLog(@"message = %@",message);
	
	if([[self delegate] respondsToSelector:@selector(pgserverMessage:)] && [message length]) {
		[[self delegate] performSelectorOnMainThread:@selector(pgserverMessage:) withObject:message waitUntilDone:YES];
	}
	// if message is "database system is ready" and server in state PGServerStateStarting
	// then advance state to PGServerStateRunning.
	// For 8.3 upwards, the message is "database system is ready to accept connections"
	if([message hasSuffix:@"database system is ready"] && [self state]==PGServerStateStarting) {
		[self setState:PGServerStateRunning];
	} else if([message hasSuffix:@"database system is ready to accept connections"] && [self state]==PGServerStateStarting) {
		[self setState:PGServerStateRunning];
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
		 
-(void)_setState:(PGServerState)theState message:(NSString* )theMessage {
 [self setState:theState];
 [self _delegateMessage:theMessage];
}

////////////////////////////////////////////////////////////////////////////////
// initialize the database data

-(BOOL)_shouldInitialize {
	// check for postgresql.conf file
	if([[NSFileManager defaultManager] fileExistsAtPath:[[self dataPath] stringByAppendingPathComponent:@"postgresql.conf"]]==YES) {
		return NO;
	} else {
		return YES;
	}
}

-(BOOL)_initialize {
	NSPipe* theOutPipe = [[NSPipe alloc] init];
	NSTask* theTask = [[NSTask alloc] init];
	
	[theTask setStandardOutput:theOutPipe];
	[theTask setStandardError:theOutPipe];
	[theTask setLaunchPath:[[self class] _initBinary]];
	[theTask setArguments:[NSArray arrayWithObjects:@"-D",[self dataPath],@"--encoding=UTF8",@"--no-locale",@"-U",[[self class] _superUsername],nil]];
	[theTask setEnvironment:[NSDictionary dictionaryWithObject:[[self class] _libraryPath] forKey:@"DYLD_LIBRARY_PATH"]];

	// launch the init method
	[theTask launch];
	
	NSData* theData = nil;
	while((theData = [[theOutPipe fileHandleForReading] availableData]) && [theData length]) {
		[self _delegateMessageFromData:theData];
	}
	// wait until task is actually completed
	[theTask waitUntilExit];
	int theReturnCode = [theTask terminationStatus];
	// if return code is non-zero report error
	if(theReturnCode) {
		[self _setState:PGServerStateError message:[NSString stringWithFormat:@"_initialize method returned status %d",theReturnCode]];
		return NO;
	}
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// get server version and port

-(NSString* )version {
	NSPipe* theOutPipe = [[NSPipe alloc] init];
	NSTask* theTask = [[NSTask alloc] init];
	[theTask setStandardOutput:theOutPipe];
	[theTask setStandardError:theOutPipe];
	[theTask setLaunchPath:[[self class] _serverBinary]];
	[theTask setArguments:[NSArray arrayWithObject:@"--version"]];
	[theTask setEnvironment:[NSDictionary dictionaryWithObject:[[self class] _libraryPath] forKey:@"DYLD_LIBRARY_PATH"]];
	
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

+(NSUInteger)defaultPort {
	return PGServerDefaultPort;
}

////////////////////////////////////////////////////////////////////////////////
// start the server

-(BOOL)_run {
	NSTask* theTask = [self task];

	if([theTask isRunning]) {
		NSLog(@"task already running, returning NO");
		return NO;
	}

	// set output
	[[self task] setStandardOutput:[self taskOutput]];
	[[self task] setStandardError:[self taskOutput]];
	[[self task] setLaunchPath:[PGServer _serverBinary]];
	[[self task] setEnvironment:[NSDictionary dictionaryWithObject:[PGServer _libraryPath] forKey:@"DYLD_LIBRARY_PATH"]];
	
	// set arguments
	NSMutableArray* theArguments = [NSMutableArray arrayWithObjects:@"-D",[self dataPath],nil];
	if([[self hostname] length]) {
		[theArguments addObject:@"-h"];
		[theArguments addObject:[self hostname]];
	} else {
		[theArguments addObject:@"-h"];
		[theArguments addObject:@""];
	}	
	if([self port] > 0 && [self port] != PGServerDefaultPort) {
		[theArguments addObject:@"-p"];
		[theArguments addObject:[NSString stringWithFormat:@"%ld",[self port]]];
	} else {
		[self setPort:PGServerDefaultPort];
	}
	[theTask setArguments:theArguments];
	
	// add notification for messages coming back from the task
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_readMessages:) name:NSFileHandleReadCompletionNotification object:[[self taskOutput] fileHandleForReading]];
	[[[self taskOutput] fileHandleForReading] readInBackgroundAndNotify];
	
	// launch the postgres database, set the pid
	[theTask launch];
	[self setPid:[theTask processIdentifier]];
	NSLog(@"task started with PID %d",[self pid]);
	return YES;
}

-(void)_readMessages:(NSNotification* )theNotification {
	NSFileHandle* theFileHandle = [theNotification object];
	NSData* theData = [[theNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	if([theData length]) {
		[theFileHandle readInBackgroundAndNotify];
		NSLog(@"Message: %@",theData);
	}
}
	// get output from the task
	// NSData* theData = nil;
	//NSPipe* theOutPipe = [[self task] standardOutput];
	//if ((theData = [[theOutPipe fileHandleForReading] availableData]) && [theData length]) {
	//	[self _delegateMessageFromData:theData];
	//}

////////////////////////////////////////////////////////////////////////////////
// reload the server

-(BOOL)reload {
	if([self state] != PGServerStateRunning && [self state] != PGServerStateAlreadyRunning) {
		return NO;
	}
	if([self pid] <= 0) {
		return NO;
	}
	
	// send HUP
	kill([self pid],SIGHUP);

	// return success
	return YES;
}


////////////////////////////////////////////////////////////////////////////////
// background server thread

-(void)_backgroundThread:(id)anObject {
	NSLog(@"backgroundThreadStarted");
	@autoreleasepool {
		BOOL isSuccess = NO;
		do {
			NSLog(@"backgroundThread state = %@",[PGServer stateAsString:[self state]]);
			// wait until task is actually completed
			// [theTask waitUntilExit];
			// int theReturnCode = [theTask terminationStatus];
			// if return code is non-zero report error
			// if(theReturnCode) {
			// [self _setState:PGServerStateError message:[NSString stringWithFormat:@"_start method returned status %d",theReturnCode]];
			// return NO;
			//}
			// return YES;

			switch([self state]) {
				case PGServerStateIgnition:
					// determine if we need to initialize the data directory
					if([self _shouldInitialize]) {
						[self setState:PGServerStateInitialize];
					} else {
						[self setState:PGServerStateStarting];
						[self _run];
					}
					break;
				case PGServerStateInitialize:
					// initialize the data directory
					isSuccess = [self _initialize];
					if(isSuccess==NO) {
						[self _setState:PGServerStateError message:@"Error initializing server data"];
					} else {
						[self setState:PGServerStateStarting];
						[self _run];
					}
					break;
				case PGServerStateStarting:
					// wait for server to start
					break;
				case PGServerStateError:
					// an error occurred when starting the server
					// in this state, we need to quit the runloop and close down everything
					[self _setState:PGServerStateError message:@"Stopping run loop"];
					[self setPid:-1];
					break;
				case PGServerStateStopping:
					if([[self task] isRunning]==NO) {
						[self _setState:PGServerStateStopped message:@"Stopped"];
					}
					break;
				case PGServerStateStopped:
					// do nothing in these states
					break;
				default:
					NSAssert(NO,@"Don't know what to do for that state (%@) in _backgroundThreadFire",[PGServer stateAsString:[self state]]);
					break;
			}
		} while([self pid] >= 0);
		[self setState:PGServerStateStopped];
	}
	NSLog(@"backgroundThreadStopped");
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(BOOL)startWithDataPath:(NSString* )thePath {
	NSParameterAssert(thePath);
	
	if([self state]==PGServerStateRunning || [self state]==PGServerStateStarting) {
		return NO;
	}
	
	// set the data path and the pid
	[self setDataPath:thePath];
	[self setPid:-1];
	
	// if database process is already running, then set this as the state and return NO
	int thePid = [self _pidFromDataPath];
	if(thePid > 0) {
		[self setPid:thePid];
		[self _setState:PGServerStateAlreadyRunning message:@"Server already started"];
		return NO;
	}
	
	// if we received a minus one, an error occurred doing this step
	if(thePid < 0) {
		[self _setState:PGServerStateError message:@"Internal error"];
		return NO;
	}
	
	// create the data path if nesessary
	if([self _createDataPath:[self dataPath]]==NO) {
		[self _setState:PGServerStateError message:[NSString stringWithFormat:@"Unable to create data path: %@",[self dataPath]]];
		return NO;
	}
	
	// set the pid to zero and state to ignition
	[self setPid:0];
	[self _setState:PGServerStateIgnition message:@"Server starting"];

	// start the background thread to start the server
	[NSThread detachNewThreadSelector:@selector(_backgroundThread:) toTarget:self withObject:nil];
	
	// immediate return
	return YES;
}

-(BOOL)stop {
	if([self state] != PGServerStateRunning && [self state] != PGServerStateAlreadyRunning) {
		return NO;
	}
	if([self pid] <= 0) {
		return NO;
	}	
	// set counter and state
	int count = 0;
	[self _setState:PGServerStateStopping message:@"Stopping server"];

	// wait until process identifier is minus one
	do {
		if(count==0) {
			kill([self pid],SIGTERM);
		} else if(count==100) {
			kill([self pid],SIGINT);
		} else if(count==300) {
			kill([self pid],SIGKILL);
		}
		// sleep for 100ms
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		count++;
	} while([self _doesProcessExist:[self pid]]);
	
	// set process identifier to minus one to indicate the background thread should end
	[self setPid:-1];

	count = 0;
	do {
		NSLog(@"state = %@ count = %d",[PGServer stateAsString:[self state]],count);
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		count++;
	} while([self state]==PGServerStateStopping && count < 10);
	
	// return success
	return YES;
}


////////////////////////////////////////////////////////////////////////////////
// private method to return English language version of PGServerState

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
