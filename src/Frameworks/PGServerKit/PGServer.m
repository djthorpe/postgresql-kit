
// Copyright 2009-2015 David Thorpe
// https://github.com/djthorpe/postgresql-kit
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

#include <sys/sysctl.h>
#include <pg_config.h>
#import "PGServerKit.h"
#import "PGServer+Private.h"

NSUInteger PGServerDefaultPort = DEF_PGPORT;
NSString* PGServerSuperuser = @"postgres";

@implementation PGServer

////////////////////////////////////////////////////////////////////////////////
// initialization methods

-(id)init {
	// dont allow init method
	return nil;
}

-(id)initWithDataPath:(NSString* )thePath {
	self = [super init];
	if(self) {
		[self setDelegate:nil];
		_state = PGServerStateUnknown;
		_hostname = nil;
		_port = 0;
		_pid = -1;
		_dataPath = thePath;
		_socketPath = nil;
		_currentTask = nil;
		_timer = nil;
	}
	return self;
}

-(void)dealloc {
	[self _removeNotification];
}

+(PGServer* )serverWithDataPath:(NSString* )thePath {
	return [[PGServer alloc] initWithDataPath:thePath];
}

////////////////////////////////////////////////////////////////////////////////
// private methods for returning information

+(NSString* )_bundlePath {
	return [[NSBundle bundleForClass:[self class]] bundlePath];
}

+(NSString* )_serverBinary {
	return [[self _bundlePath] stringByAppendingPathComponent:@"Resources/postgresql-current-mac_x86_64/bin/postgres"];
}

+(NSString* )_initBinary {
	return [[self _bundlePath] stringByAppendingPathComponent:@"Resources/postgresql-current-mac_x86_64/bin/initdb"];
}

+(NSString* )_libraryPath {
	return [[self _bundlePath] stringByAppendingPathComponent:@"Resources/postgresql-current-mac_x86_64/lib"];
}

+(NSString* )_dumpBinary {
	return [[self _bundlePath] stringByAppendingPathComponent:@"Resources/postgresql-current-mac_x86_64/bin/pg_dumpall"];
}

+(NSString* )_hostAccessRulesFilename {
	return @"pg_hba.conf";
}

+(NSString* )_configurationPreferencesFilename {
	return @"postgresql.conf";
}

+(NSString* )_pidFilename {
	return @"postmaster.pid";
}

////////////////////////////////////////////////////////////////////////////////
// set state and send messages to delegate where necessary

-(void)_setState:(PGServerState)state {
	PGServerState oldState = _state;
	_state = state;
	if(_state != oldState && [[self delegate] respondsToSelector:@selector(pgserver:stateChange:)]) {
		[[self delegate] pgserver:self stateChange:state];
	}
}

////////////////////////////////////////////////////////////////////////////////
// send messages to the delegate

-(void)_delegateMessage:(NSString* )message {
	if([[self delegate] respondsToSelector:@selector(pgserver:message:)] && [message length]) {
		[[self delegate] pgserver:self message:message];
	}
	
	// if message is "database system is ready" and server in state PGServerStateStarting
	// then advance state to PGServerStateRunning0.
	// For 8.3 upwards, the message is "database system is ready to accept connections"
	if([message hasSuffix:@"database system is ready"] && [self state]==PGServerStateStarting) {
		[self _setState:PGServerStateRunning0];
	} else if([message hasSuffix:@"database system is ready to accept connections"] && [self state]==PGServerStateStarting) {
		[self _setState:PGServerStateRunning0];
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
// private method to return the PID and other properties from running postgresql
// process

-(int)_pidFromPath:(NSString* )thePath {
	NSString* thePidPath = [thePath stringByAppendingPathComponent:[PGServer _pidFilename]];
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

-(BOOL)_setPropertiesFromPidFile {
	NSString* thePidPath = [[self dataPath] stringByAppendingPathComponent:[PGServer _pidFilename]];
	if([[NSFileManager defaultManager] fileExistsAtPath:thePidPath]==NO
	   || [[NSFileManager defaultManager] isReadableFileAtPath:thePidPath]==NO) {
		// no postmaster.pid file found, therefore no process
#ifdef DEBUG
		NSLog(@"_setPropertiesFromPath: missing or invalid file: %@",thePidPath);
#endif
		return NO;
	}
	NSDictionary* theAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:thePidPath error:nil];
	if(theAttributes==nil || [theAttributes fileSize] > 1024) {
#ifdef DEBUG
		NSLog(@"_setPropertiesFromPath: missing or invalid file: %@",thePidPath);
#endif
		// if postmaster.pid file is too large, return error
		return NO;
	}
	NSError* theError = nil;
	NSString* thePidString = [NSString stringWithContentsOfFile:thePidPath encoding:NSUTF8StringEncoding error:&theError];
	if(thePidString==nil) {
#ifdef DEBUG
		NSLog(@"_setPropertiesFromPath: missing or invalid file: %@: %@",thePidPath,theError);
#endif		
		// if postmaster.pid file could not be read, return error
		return NO;
	}
	
	// we need to have at least five lines
	NSArray* theLines = [thePidString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	NSParameterAssert([theLines count] >= 6);
	for(NSUInteger i = 0; i < 6; i++) {
		NSString* theLine = [[theLines objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		switch(i) {
			case 0: {
				NSDecimalNumber* thePid = [NSDecimalNumber decimalNumberWithString:theLine];
				NSParameterAssert(thePid && [thePid intValue] > 0);
				if(![self _doesProcessExist:[thePid intValue]]) {
					return NO;
				}
				_pid = [thePid intValue];
				break;
			}
			case 1: {
				// data path
				BOOL isDir = NO;
				NSParameterAssert([[NSFileManager defaultManager] fileExistsAtPath:theLine isDirectory:&isDir] && isDir==YES);
				break;
			}
			case 2: {
				// start time
				NSDecimalNumber* startTime = [NSDecimalNumber decimalNumberWithString:theLine];
				NSParameterAssert(startTime && [startTime integerValue] > 0);
				_startTime = [startTime unsignedIntegerValue];
				break;
			}
			case 3: {
				// port
				NSDecimalNumber* port = [NSDecimalNumber decimalNumberWithString:theLine];
				NSParameterAssert(port && [port integerValue] > 0);
				_port = [port unsignedIntegerValue];
				break;
			}
			case 4: {
				// socket directory
				BOOL isDir = NO;
				NSParameterAssert([[NSFileManager defaultManager] fileExistsAtPath:theLine isDirectory:&isDir] && isDir==YES);
				_socketPath = theLine;
				break;
			}
			case 5: {
				// hostname
				_hostname = theLine;
				break;
			}
			default:
				NSParameterAssert(NO);
		}
	}
	
	return YES;
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
		long nentries = (long)count / (long)sizeof(struct kinfo_proc);
		if(nentries < 1) {
			returnValue = 0;
		}
	}
	free(kp);
	return returnValue;
}

-(void)_stopProcess:(int)thePid {
	// set counter and state
	int count = 0;
	// wait until process identifier is minus one
	do {
		if(count==0) {
#ifdef DEBUG
			NSLog(@"killing PID %d, SIGTERM",thePid);
#endif
			kill(thePid,SIGTERM);
		} else if(count==100) {
#ifdef DEBUG
			NSLog(@"killing PID %d, SIGINT",thePid);
#endif
			kill(thePid,SIGINT);
		} else if(count==300) {
#ifdef DEBUG
			NSLog(@"killing PID %d, SIGKILL",thePid);
#endif
			kill(thePid,SIGKILL);
		}
		// sleep for 100ms
		[NSThread sleepForTimeInterval:0.1];
		count++;
	} while([self _doesProcessExist:thePid]);
}

////////////////////////////////////////////////////////////////////////////////
// create data path if it doesn't exist

-(BOOL)_createDataPath:(NSString* )thePath {
	// if directory already exists
	BOOL isDirectory = NO;
	if([[NSFileManager defaultManager] fileExistsAtPath:thePath isDirectory:&isDirectory]==NO) {
		// create the directory
		if([[NSFileManager defaultManager] createDirectoryAtPath:thePath withIntermediateDirectories:YES attributes:nil error:nil]==NO) {
#ifdef DEBUG
			NSLog(@"Unable to create directory: %@",thePath);
#endif
			return NO;
		}
	} else if(isDirectory==NO) {
#ifdef DEBUG
		NSLog(@"Not a valid directory: %@",thePath);
#endif
		return NO;
	} else if([[NSFileManager defaultManager] isWritableFileAtPath:thePath]==NO) {
#ifdef DEBUG
		NSLog(@"Not a writable directory: %@",thePath);
#endif
		return NO;
	}
	
	// success - return yes
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// initialize the database data

-(BOOL)_shouldInitialize {
	// check for postgresql.conf file
	if([[NSFileManager defaultManager] fileExistsAtPath:[_dataPath stringByAppendingPathComponent:[PGServer _configurationPreferencesFilename]]]==YES) {
		return NO;
	} else {
		return YES;
	}
}

////////////////////////////////////////////////////////////////////////////////
// run a task

-(void)_removeNotification {
	NSNotificationCenter* theNotificationCenter = [NSNotificationCenter defaultCenter];
	[theNotificationCenter removeObserver:self];
}

-(void)_addNotificationForFileHandle:(NSFileHandle* )theFileHandle {
	NSNotificationCenter* theNotificationCenter = [NSNotificationCenter defaultCenter];
    [theNotificationCenter addObserver:self
							  selector:@selector(_getTaskData:)
								  name:NSFileHandleReadCompletionNotification
								object:nil];
	[theFileHandle readInBackgroundAndNotify];
}

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
	[theTask setEnvironment:[NSDictionary dictionaryWithObject:[PGServer _libraryPath] forKey:@"DYLD_LIBRARY_PATH"]];

	// create a pipe
	NSPipe* thePipe = [[NSPipe alloc] init];
	[theTask setStandardOutput:thePipe];
	[theTask setStandardError:thePipe];

	// add a notification for the pipe's standard out
	[self _removeNotification];
	[self _addNotificationForFileHandle:[thePipe fileHandleForReading]];

	// now launch the task
	_currentTask = theTask;
	[theTask launch];
	return YES;
	
}

-(void)_getTaskData:(NSNotification* )theNotification {
	NSData* theData = [[theNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];

	[self _delegateMessageFromData:theData];

	if([theData length]) {
		// get more data
		[[theNotification object] readInBackgroundAndNotify];
	}
}

-(BOOL)_startTaskInitialize {
	NSArray* theArguments = [NSArray arrayWithObjects:@"-D",[self dataPath],@"--encoding=UTF8",@"--no-locale",@"-U",PGServerSuperuser,nil];
	return [self _startTask:[PGServer _initBinary] arguments:theArguments];
}

-(BOOL)_startTaskServer {
	// set arguments
	NSMutableArray* theArguments = [NSMutableArray arrayWithObjects:@"-D",[self dataPath],nil];
	if([[self hostname] length]) {
		[theArguments addObject:@"-h"];
		[theArguments addObject:[self hostname]];
	} else {
		[theArguments addObject:@"-h"];
		[theArguments addObject:@""];
	}
	if(_port > 0 && _port != PGServerDefaultPort) {
		[theArguments addObject:@"-p"];
		[theArguments addObject:[NSString stringWithFormat:@"%ld",_port]];
	} else {
		_port = PGServerDefaultPort;
	}
	if(_socketPath) {
		[theArguments addObject:@"-k"];
		[theArguments addObject:_socketPath];
	}
#ifdef DEBUG
	NSLog(@"Starting server with args: %@",[theArguments componentsJoinedByString:@" "]);
#endif
	return [self _startTask:[PGServer _serverBinary] arguments:theArguments];
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
			// determine if we need to initialize the data directory
			if([self _shouldInitialize]) {
				[self _setState:PGServerStateInitialize];
			} else {
				[self _setState:PGServerStateInitialized];
			}
			break;
		case PGServerStateInitialize:
			NSParameterAssert(_currentTask==nil);
			// initialize the data directory
			isSuccess = [self _startTaskInitialize];
			if(isSuccess==NO) {
				[self _setState:PGServerStateStopped];
			} else {
				[self _setState:PGServerStateInitializing];
			}
			break;
		case PGServerStateInitializing:
			NSParameterAssert(_currentTask);
			// keep going until _currentTask is no longer running
			if([_currentTask isRunning]==NO) {
				if([_currentTask terminationStatus]==0) {
					[self _setState:PGServerStateInitialized];
				} else {
#ifdef DEBUG
					NSLog(@"Initialize task failed, error code %d",[_currentTask terminationStatus]);
#endif
					[self _setState:PGServerStateError];
				}
				_currentTask = nil;
			}
			break;
		case PGServerStateInitialized:
			// data directory is initialized, so proceed to starting server
			isSuccess = [self _startTaskServer];
			if(isSuccess==NO) {
#ifdef DEBUG
				NSLog(@"_startTaskServer failed, setting state to PGServerStateStopped");
#endif
				[self _setState:PGServerStateStopped];
			} else {
				[self _setState:PGServerStateStarting];
			}
			break;
		case PGServerStateStarting:
			if(_currentTask==nil || [_currentTask isRunning]==NO) {
				// Error occured during startup
				[self _delegateMessage:[NSString stringWithFormat:@"Task ended with status %d",[_currentTask terminationStatus]]];
				[self _setState:PGServerStateError];
			}
			break;
		case PGServerStateRunning0:
			// get pid from the task
			_pid = [_currentTask processIdentifier];
			[self _delegateMessage:[NSString stringWithFormat:@"Server started with pid %d",_pid]];
			[self _setPropertiesFromPidFile];
			[self _setState:PGServerStateRunning];
			break;
		case PGServerStateAlreadyRunning0:
			[self _setPropertiesFromPidFile];
			[self _setState:PGServerStateAlreadyRunning];
			break;
		case PGServerStateRunning:
		case PGServerStateAlreadyRunning:
			// check pid and make sure the process still exists
			if([self _doesProcessExist:_pid]==NO) {
				[self _delegateMessage:@"Server has been stopped"];
				[self _setState:PGServerStateStopping];
			}
			break;			
		case PGServerStateRestart:
			if([self _doesProcessExist:_pid]==NO) {
				[self _delegateMessage:@"Server has been stopped"];
				[self _setState:PGServerStateStopping];
			} else {
				// stop server
				[self _stopProcess:_pid];
				_currentTask = nil;
				[self _setState:PGServerStateIgnition];
			}
			break;
		case PGServerStateStopping:
			// stop server
			[self _stopProcess:_pid];
			[self _setState:PGServerStateStopped];
			break;
		case PGServerStateStopped:
		case PGServerStateError:
			_hostname = nil;
			_port = 0;
			_pid = -1;
			_currentTask = nil;
			_startTime = 0;
			[_timer invalidate];
			_timer = nil;
			break;
		default:
			NSAssert(NO,@"Don't know what to do for that state (%@) in _firedTimer",[PGServer stateAsString:_state]);
			break;
	}
}

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic version;
@dynamic uptime;
@synthesize pid = _pid;
@synthesize port = _port;
@synthesize state = _state;
@synthesize dataPath = _dataPath;
@synthesize socketPath = _socketPath;
@synthesize hostname = _hostname;

-(NSString* )version {
	NSPipe* theOutPipe = [[NSPipe alloc] init];
	NSTask* theTask = [[NSTask alloc] init];
	[theTask setStandardOutput:theOutPipe];
	[theTask setStandardError:theOutPipe];
	[theTask setLaunchPath:[PGServer _serverBinary]];
	[theTask setArguments:[NSArray arrayWithObject:@"--version"]];
	[theTask setEnvironment:[NSDictionary dictionaryWithObject:[PGServer _libraryPath] forKey:@"DYLD_LIBRARY_PATH"]];
	
	// get the version number
#ifdef DEBUG
	NSLog(@"launchPath = %@",[PGServer _serverBinary]);
#endif	
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
		NSString* version = [[NSString alloc] initWithData:theVersion encoding:NSUTF8StringEncoding];
		return [version stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	} else {
		return nil;
	}
}

-(NSTimeInterval)uptime {
	if(_startTime > 0) {
		NSDate* then = [NSDate dateWithTimeIntervalSince1970:_startTime];
		return -[then timeIntervalSinceNow];
	} else {
		return 0;
	}
}

////////////////////////////////////////////////////////////////////////////////
// start server method

-(BOOL)start {
	return [self startWithPort:PGServerDefaultPort];
}

-(BOOL)startWithPort:(NSUInteger)port {
	return [self startWithNetworkBinding:nil port:port];
}

-(BOOL)startWithPort:(NSUInteger)port socketPath:(NSString* )socketPath {
	return [self startWithNetworkBinding:nil port:port socketPath:socketPath];
}

-(BOOL)startWithNetworkBinding:(NSString* )hostname port:(NSUInteger)port {
	return [self startWithNetworkBinding:hostname port:port socketPath:nil];
}

-(BOOL)startWithNetworkBinding:(NSString* )hostname port:(NSUInteger)port socketPath:(NSString* )socketPath {
	NSParameterAssert([self dataPath]);

	// check current state, needs to be unknown or stopped
	if([self state] != PGServerStateUnknown && [self state] != PGServerStateStopped) {
		return NO;
	}
	
	// check for writable socket path
	if(socketPath) {
		BOOL isFolder = NO;
		if([[NSFileManager defaultManager] fileExistsAtPath:socketPath isDirectory:&isFolder]==NO) {
#ifdef DEBUG
			NSLog(@"socketPath does not exist: %@",socketPath);
#endif
			return NO;
		}
		if(isFolder==NO || [[NSFileManager defaultManager] isWritableFileAtPath:socketPath]==NO) {
#ifdef DEBUG
			NSLog(@"socketPath not a folder or not writable: %@",socketPath);
#endif
			return NO;
		}
	}
	
	// if database process is already running, then set this as the state
	int thePid = [self _pidFromPath:[self dataPath]];
	if(thePid > 0 && [self _doesProcessExist:thePid]) {
		_pid = thePid;
		_hostname = nil;
		_port = 0;
		_socketPath = nil;
		[self _setState:PGServerStateAlreadyRunning0];
#ifdef DEBUG
		NSLog(@"Set state: PGServerStateAlreadyRunning0, pid = %d",thePid);
#endif
	} else {
		// create the data path if nesessary
		if([self _createDataPath:[self dataPath]]==NO) {
			[self _setState:PGServerStateError];
			[self _delegateMessage:[NSString stringWithFormat:@"Unable to create data path: %@",[self dataPath]]];
			return NO;
		}
		// set the pid to zero and state to ignition
		_pid = 0;
		_hostname = [hostname copy];
		_port = port;
		_socketPath = socketPath;
		[self _setState:PGServerStateIgnition];
	}
	
	// start the state machine timer
	[self _startTimer];

	// return YES
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// stop, reload and restart server

-(BOOL)stop {
	if([self state] != PGServerStateRunning && [self state] != PGServerStateAlreadyRunning) {
		return NO;
	}
	if(_pid <= 0) {
		return NO;
	}
	// set state to stop server
	[self _setState:PGServerStateStopping];

	// start the state machine timer
	[self _startTimer];

	// return success
	return YES;
}

-(BOOL)restart {
	if([self state] != PGServerStateRunning && [self state] != PGServerStateAlreadyRunning) {
		return NO;
	}
	if(_pid <= 0) {
		return NO;
	}

	// set state to restart server
	[self _setState:PGServerStateRestart];
	
	// start the state machine timer
	[self _startTimer];

	// return success
	return YES;
}

-(BOOL)reload {
	if([self state] != PGServerStateRunning && [self state] != PGServerStateAlreadyRunning) {
		return NO;
	}
	if(_pid <= 0) {
		return NO;
	}
	// send HUP
#ifdef DEBUG
	NSLog(@"Sending HUP signal to %d",_pid);
#endif
	kill(_pid,SIGHUP);

	// return success
	return YES;
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
		case PGServerStateInitialized:
		case PGServerStateInitializing:
			return @"PGServerStateInitialize";
		case PGServerStateRunning:
		case PGServerStateRunning0:
		case PGServerStateAlreadyRunning0:
		case PGServerStateAlreadyRunning:
			return @"PGServerStateRunning";
		case PGServerStateRestart:
			return @"PGServerStateRestart";
		case PGServerStateUnknown:
			return @"PGServerStateUnknown";
		case PGServerStateError:
			return @"PGServerStateError";
		default:
			return @"????";
	}
}

@end

