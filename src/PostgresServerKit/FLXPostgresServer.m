
#import "PostgresServerKit.h"
#include <sys/sysctl.h>
#import <zlib.h>
#include <pg_config.h>

static FLXPostgresServer* FLXSharedServer = nil;
const NSUInteger FLXDefaultPostgresPort = DEF_PGPORT;

@interface FLXPostgresServer (Private)
-(BOOL)_createPath:(NSString* )thePath;
-(NSString* )_backupFilePathForFolder:(NSString* )thePath;
-(int)_processIdentifierFromDataPath;
-(void)_delegateServerMessage:(NSString* )theMessage;
-(void)_delegateServerMessageFromData:(NSData* )theData;
-(void)_delegateServerStateDidChange:(NSString* )theMessage;  
-(void)_delegateBackupStateDidChange:(NSString* )theMessage;
-(NSString* )_messageFromState:(FLXServerState)theState;
-(int)_doesProcessExist:(int)thePid;
@end

@implementation FLXPostgresServer

@synthesize dataPath = m_theDataPath;
@synthesize state = m_theState;
@synthesize backupState = m_theBackupState;
@synthesize stateAsString;
@synthesize backupStateAsString;
@synthesize processIdentifier = m_theProcessIdentifier;
@synthesize hostname = m_theHostname;
@synthesize serverVersion;
@synthesize port = m_thePort;
@synthesize delegate = m_theDelegate;
@synthesize isRunning;

////////////////////////////////////////////////////////////////////////////////
// singleton design pattern
// see http://www.cocoadev.com/index.pl?SingletonDesignPattern

+(FLXPostgresServer* )sharedServer {
	@synchronized(self) {
		if (FLXSharedServer == nil) {
			FLXSharedServer = [[super allocWithZone:nil] init];
		}
	}
	return FLXSharedServer;
}

+(id)allocWithZone:(NSZone *)zone {
	return [[self sharedServer] retain];
}

-(id)copyWithZone:(NSZone *)zone {
	return self;
}

-(id)retain {
	return self;
}

-(NSUInteger)retainCount {
	return NSUIntegerMax;  // denotes an object that cannot be released
}

-(void)release {
	// do nothing
}

-(id)autorelease {
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	self = [super init];
	if(self) {
		m_theDataPath = nil;
		m_theState = FLXServerStateUnknown;
		m_theBackupState = FLXBackupStateIdle;
		m_theProcessIdentifier = -1;
		m_theHostname = @""; // defaults to socket-based communication
		m_thePort = FLXDefaultPostgresPort;    // default postgres port
		m_theDelegate = nil;
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

-(NSString* )stateAsString {
	return [self _messageFromState:[self state]];
}

-(NSString* )backupStateAsString {
	return [self _messageFromState:[self backupState]];
}

-(void)setState:(FLXServerState)theState {
	@synchronized(self) {
		if(m_theState != theState) {
			m_theState = theState;
			[self _delegateServerStateDidChange:[self _messageFromState:m_theState]];
		}     
	}
}

-(void)setBackupState:(FLXServerState)theState {
	@synchronized(self) {
		if(m_theBackupState != theState) {
			m_theBackupState = theState;
			[self _delegateBackupStateDidChange:[self _messageFromState:m_theBackupState]];
		}     
	}
}

-(BOOL)isRunning {
	switch([self state]) {
		case FLXServerStateUnknown:
		case FLXServerStateStartingError:
		case FLXServerStateStopped:
			return NO;
		default:
			return YES;
	}         
}

+(NSUInteger)defaultPort {
	return FLXDefaultPostgresPort;
}

+(NSString* )superUsername {
	return @"postgres";
}

+(NSString* )backupFileSuffix {
	return @"sql.gz";
}

+(NSString* )bundlePath {
	return [[NSBundle bundleForClass:[self class]] bundlePath];
}

+(NSString* )postgresServerPath {
	return [[self bundlePath] stringByAppendingPathComponent:@"Resources/postgresql-current/bin/postgres"];
}

+(NSString* )postgresDumpPath {
	return [[self bundlePath] stringByAppendingPathComponent:@"Resources/postgresql-current/bin/pg_dumpall"];
}

+(NSString* )postgresInitPath {
	return [[self bundlePath] stringByAppendingPathComponent:@"Resources/postgresql-current/bin/initdb"];
}

+(NSString* )postgresLibPath {
	return [[self bundlePath] stringByAppendingPathComponent:@"Resources/postgresql-current/lib"];
}

+(NSString* )postgresAccessPathForDataPath:(NSString* )thePath {
	return [thePath stringByAppendingPathComponent:@"data/pg_hba.conf"];
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(BOOL)startWithDataPath:(NSString* )thePath {
	NSParameterAssert(thePath);
	
	if([self state] == FLXServerStateStarted || [self state] == FLXServerStateAlreadyRunning) {
		[self _delegateServerMessage:@"Server is already running"];
		return NO;
	}
	
	[self _delegateServerMessage:[NSString stringWithFormat:@"Starting server with data path: %@",thePath]];
	
	if([self state] != FLXServerStateStopped && [self state] != FLXServerStateUnknown && [self state] != FLXServerStateStartingError) {
		[self _delegateServerMessage:@"Invalid or unknown server state"];
		return NO;    
	}
	
	// set the data path and the pid  
	m_theDataPath = thePath;
	m_theProcessIdentifier = -1;
	
	// if database process is already running, then set this as the state
	// and return NO
	int thePid = [self _processIdentifierFromDataPath];
	if(thePid > 0) {
		m_theProcessIdentifier = thePid;
		[self setState:FLXServerStateAlreadyRunning];
		[self _delegateServerMessage:[NSString stringWithFormat:@"Server is already running, pid=%d",thePid]];
		return NO;
	}
	// if we received a minus one, an error occurred doing this step
	if(thePid < 0) {
		[self setState:FLXServerStateStartingError];
		[self _delegateServerMessage:@"Error occured in _processIdentifierFromDataPath"];
		return NO;
	}
	// create the data path if nesessary
	if([self _createPath:[self dataPath]]==NO) {
		[self setState:FLXServerStateStartingError];
		[self _delegateServerMessage:[NSString stringWithFormat:@"Unable to create data directory: %@",[self dataPath]]];
		return NO;    
	}
	
	[self _delegateServerMessage:@"Starting background server thread"];
	
	// set the pid to zero
	m_theProcessIdentifier = 0;
	[self setState:FLXServerStateIgnition];
	// start the background thread to start the server
	[NSThread detachNewThreadSelector:@selector(_backgroundThread:) toTarget:self withObject:nil];
	
	// immediate return
	return YES;  
}

-(BOOL)reload {
	if([self state] != FLXServerStateStarted && [self state] != FLXServerStateAlreadyRunning) {
		[self _delegateServerMessage:@"Server cannot be reloaded, not running"];
		return NO;    
	}
	if([self processIdentifier] <= 0) {
		[self _delegateServerMessage:@"Server cannot be reloaded, cannot identify PID"];
		return NO;
	}

	[self _delegateServerMessage:[NSString stringWithFormat:@"Sending HUP signal: %d",[self processIdentifier]]];
	kill([self processIdentifier],SIGHUP);
	
	// return success
	return YES;
}

-(BOOL)stop {
	if([self state] != FLXServerStateStarted && [self state] != FLXServerStateAlreadyRunning) {
		[self _delegateServerMessage:@"Server cannot be stopped, not running"];
		return NO;    
	}
	if([self processIdentifier] <= 0) {
		[self _delegateServerMessage:@"Server cannot be stopped, cannot identify PID"];
		return NO;
	}
	
	// counter
	int theCounter = 0;
	
	// set state
	[self setState:FLXServerStateStopping];
	
	// wait until process identifier is minus one
	do {
		if(theCounter==0) {
			[self _delegateServerMessage:[NSString stringWithFormat:@"Sending TERM signal: %d",[self processIdentifier]]];
			kill([self processIdentifier],SIGTERM);
		} else if(theCounter==100) {
			[self _delegateServerMessage:[NSString stringWithFormat:@"Sending INT signal: %d",[self processIdentifier]]];
			kill([self processIdentifier],SIGINT);
		} else if(theCounter==300) {
			[self _delegateServerMessage:[NSString stringWithFormat:@"Sending KILL signal: %d",[self processIdentifier]]];
			kill([self processIdentifier],SIGKILL);
		}
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		theCounter++;
	} while([self _doesProcessExist:[self processIdentifier]]);
	
	[self _delegateServerMessage:[NSString stringWithFormat:@"Process is ended with pid: %d",[self processIdentifier]]];
	
	// set process identifier to zero
	m_theProcessIdentifier = -1;
	[self setState:FLXServerStateStopped];
	
	// return success
	return YES;
}

-(NSString* )serverVersion {
	NSPipe* theOutPipe = [[NSPipe alloc] init];
	NSTask* theTask = [[NSTask alloc] init]; 
	[theTask setStandardOutput:theOutPipe];
	[theTask setStandardError:theOutPipe];
	[theTask setLaunchPath:[[self class] postgresServerPath]];  
	[theTask setArguments:[NSArray arrayWithObject:@"--version"]];
	[theTask setEnvironment:[NSDictionary dictionaryWithObject:[[self class] postgresLibPath] forKey:@"DYLD_LIBRARY_PATH"]];

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
	[theTask release];
	[theOutPipe release];    
	
	if(theReturnCode==0 && [theVersion length]) {
		return [[[NSString alloc] initWithData:theVersion encoding:NSUTF8StringEncoding] autorelease];
	} else {
		return nil;
	}
}

-(BOOL)backupInBackgroundToFolderPath:(NSString* )thePath superPassword:(NSString* )thePassword {
	NSParameterAssert(thePath);
	// return NO if already running
	if([self backupState] == FLXBackupStateRunning) {
		return NO;
	}
	// create the backup path if nesessary
	if([self _createPath:thePath]==NO) {
		[self setBackupState:FLXBackupStateError];
		[self _delegateServerMessage:[NSString stringWithFormat:@"Unable to create backup directory: %@",thePath]];
		return NO;    
	}
	
	// start the background thread to perform backup
	[NSThread detachNewThreadSelector:@selector(_backgroundBackupThread:) toTarget:self withObject:[NSArray arrayWithObjects:thePath,thePassword,nil]];
	
	// return YES
	return YES;
}

// performs a backup of the local postgres database using the superuser account, returns the path to the backup file
// performs .gz compression on the file
-(NSString* )backupToFolderPath:(NSString* )thePath superPassword:(NSString* )thePassword {
	NSParameterAssert(thePath);

	// construct file for writing
	NSString* theOutputFilePath = [self _backupFilePathForFolder:thePath];
	if(theOutputFilePath==nil) {
		[self _delegateServerMessage:@"Unable to determine output file path for backup"];
		return nil;
	}	
	// create the file
	if([[NSFileManager defaultManager] createFileAtPath:theOutputFilePath contents:nil attributes:nil]==NO) {
		[self _delegateServerMessage:[NSString stringWithFormat:@"Unable to create output file path for backup: %@",theOutputFilePath]];
		return nil;		
	}
	// open the file for writing
	NSFileHandle* theOutputFile = [NSFileHandle fileHandleForWritingAtPath:theOutputFilePath];
	if(theOutputFile==nil) {
		[self _delegateServerMessage:[NSString stringWithFormat:@"Unable to create output file path for backup: %@",theOutputFilePath]];
		return nil;
	}	

	// create gzip file descriptor
	gzFile theCompressedOutputFile = gzdopen([theOutputFile fileDescriptor],"wb");
	NSParameterAssert(theCompressedOutputFile);
	
	// setup the task
	NSPipe* theOutPipe = [[NSPipe alloc] init];
	NSPipe* theErrPipe = [[NSPipe alloc] init];
	NSTask* theTask = [[NSTask alloc] init]; 
	[theTask setStandardOutput:theOutPipe];
	[theTask setStandardError:theErrPipe];
	[theTask setLaunchPath:[[self class] postgresDumpPath]];  
	[theTask setArguments:[NSArray arrayWithObjects:@"-U",[[self class] superUsername],@"-S",[[self class] superUsername],@"--disable-triggers",nil]];
	
	if([thePassword length]) {
		// set the PGPASSWORD env variable
		[theTask setEnvironment:[NSDictionary dictionaryWithObjectsAndKeys:thePassword,@"PGPASSWORD",[[self class] postgresLibPath],@"DYLD_LIBRARY_PATH",nil]];
	} else {
		[theTask setEnvironment:[NSDictionary dictionaryWithObject:[[self class] postgresLibPath] forKey:@"DYLD_LIBRARY_PATH"]];
	}
	
	// perform the backup
	[theTask launch];                                                 
	
	NSData* theData = nil;
	while((theData = [[theOutPipe fileHandleForReading] availableData]) && [theData length]) {
		NSInteger bytesWritten = gzwrite(theCompressedOutputFile,[theData bytes],[theData length]);
		NSParameterAssert(bytesWritten);
	}  

	// close the compressed stream
	gzclose(theCompressedOutputFile);
	
	// get error information....
	while((theData = [[theErrPipe fileHandleForReading] availableData]) && [theData length]) {
		[self _delegateServerMessageFromData:theData];
	}  
	
	// wait until task is actually completed
	[theTask waitUntilExit];
	int theReturnCode = [theTask terminationStatus];    
	[theTask release];
	[theOutPipe release];    
	[theErrPipe release];    
	[theOutputFile closeFile];
	
	if(theReturnCode==0) {
		return theOutputFilePath;
	} else {
		[[NSFileManager defaultManager] removeItemAtPath:theOutputFilePath error:nil];
		return nil;
	}	
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(NSString* )_messageFromState:(FLXServerState)theState {
	switch(theState) {
		case FLXServerStateAlreadyRunning:
			return @"Already Running";
		case FLXServerStateIgnition:
			return @"Starting";
		case FLXServerStateInitializing:
			return @"Initializing";
		case FLXServerStateStarting:
			return @"Starting";
		case FLXServerStateStarted:
			return @"Running";
		case FLXServerStateStartingError:
			return @"Error whilst starting server";
		case FLXServerStateStopping:
			return @"Stopping";
		case FLXBackupStateIdle:
			return @"Backup idle";
		case FLXBackupStateError:
			return @"Backup error";
		case FLXBackupStateRunning:
			return @"Backup in progress";			
		case FLXServerStateStopped:
		default:
			return @"Stopped";
	}
}

// create a unique backup filename
-(NSString* )_backupFilePathForFolder:(NSString* )thePath {	
	// ensure path is a directory
	BOOL isDirectory;
	if([[NSFileManager defaultManager] fileExistsAtPath:thePath isDirectory:&isDirectory]==NO || isDirectory==NO) {
		return nil;
	}
	// initialize random seed	
	srand(time(nil));
	long theRandomNumber = rand() % 10000L;
	// construct filename	
	NSCalendarDate* theDate = [NSCalendarDate calendarDate];
	NSString* theFilename = [NSString stringWithFormat:@"pgdump-%@-%04ld.%@",[theDate descriptionWithCalendarFormat:@"%Y%m%d-%H%M%S"],theRandomNumber,[[self class] backupFileSuffix]];
	NSString* theFilepath = [thePath stringByAppendingPathComponent:theFilename];
	// make sure file does not exist
	if([[NSFileManager defaultManager] fileExistsAtPath:theFilepath]==YES) {
		return nil;
	}
	// return filename
	return theFilepath;
}

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

-(void)_delegateServerMessage:(NSString* )theMessage {  
	if([[self delegate] respondsToSelector:@selector(serverMessage:)] && [theMessage length]) {
		[[self delegate] performSelectorOnMainThread:@selector(serverMessage:) withObject:theMessage waitUntilDone:NO];
	}
	// if message is "database system is ready" and server in state FLXServerStateStarting
	// then advance state to FLXServerStateStarted.
	// For 8.3, the message is "database system is ready to accept connections"
	if([theMessage hasSuffix:@"database system is ready"] && [self state]==FLXServerStateStarting) {
		[self setState:FLXServerStateStarted];
	} else if([theMessage hasSuffix:@"database system is ready to accept connections"] && [self state]==FLXServerStateStarting) {
		[self setState:FLXServerStateStarted];
	}
}

-(void)_delegateServerMessageFromData:(NSData* )theData {
	NSString* theMessage = [[NSString alloc] initWithData:theData encoding:NSUTF8StringEncoding];  
	NSArray* theArray = [theMessage componentsSeparatedByString:@"\n"];
	NSEnumerator* theEnumerator = [theArray objectEnumerator];
	NSString* theLine = nil;
	while(theLine = [theEnumerator nextObject]) {
		[self _delegateServerMessage:[theLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	}
	[theMessage release];
}

-(void)_delegateServerStateDidChange:(NSString* )theMessage {
	if([[self delegate] respondsToSelector:@selector(serverStateDidChange:)]) {
		[[self delegate] performSelectorOnMainThread:@selector(serverStateDidChange:) withObject:theMessage waitUntilDone:YES];
	}
}

-(void)_delegateBackupStateDidChange:(NSString* )theMessage {
	if([[self delegate] respondsToSelector:@selector(backupStateDidChange:)]) {
		[[self delegate] performSelectorOnMainThread:@selector(backupStateDidChange:) withObject:theMessage waitUntilDone:YES];
	}
}

-(int)_processIdentifierFromDataPath {  
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
	
-(BOOL)_createPath:(NSString* )thePath {
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
	[theTask setLaunchPath:[[self class] postgresInitPath]];
	[theTask setArguments:[NSArray arrayWithObjects:@"-D",[self dataPath],@"--encoding=UTF8",@"--no-locale",@"-U",[[self class] superUsername],nil]];
	[theTask setEnvironment:[NSDictionary dictionaryWithObject:[[self class] postgresLibPath] forKey:@"DYLD_LIBRARY_PATH"]];
	
	// launch the init method
	[theTask launch];
	
	NSData* theData = nil;
	while((theData = [[theOutPipe fileHandleForReading] availableData]) && [theData length]) {
		[self _delegateServerMessageFromData:theData];
	}  
	// wait until task is actually completed
	[theTask waitUntilExit];
	int theReturnCode = [theTask terminationStatus];    
	[theTask release];
	[theOutPipe release];    
	
	[self _delegateServerMessage:[NSString stringWithFormat:@"Initialize method returned status %d",theReturnCode]];
	
	return theReturnCode ? NO : YES;
}

-(BOOL)_start {
	NSPipe* theOutPipe = [[NSPipe alloc] init];
	NSTask* theTask = [[NSTask alloc] init]; 
	[theTask setStandardOutput:theOutPipe];
	[theTask setStandardError:theOutPipe];
	[theTask setLaunchPath:[[self class] postgresServerPath]];
	[theTask setEnvironment:[NSDictionary dictionaryWithObject:[[self class] postgresLibPath] forKey:@"DYLD_LIBRARY_PATH"]];
	
	// set arguments
	NSMutableArray* theArguments = [NSMutableArray arrayWithObjects:@"-D",[self dataPath],nil];
	if([[self hostname] length]) {
		[theArguments addObject:@"-h"];
		[theArguments addObject:[self hostname]];
		if([self port] != 0 && [self port] != FLXDefaultPostgresPort) {
			[theArguments addObject:@"-p"];
			[theArguments addObject:[NSString stringWithFormat:@"%d",[self port]]];
		}
	} else {
		[theArguments addObject:@"-h"];		
		[theArguments addObject:@""];		
	}
	
	// launch the postgres database, set the pid
	[theTask setArguments:theArguments];
	[theTask launch];                                                 
	m_theProcessIdentifier = [theTask processIdentifier];
	
	NSData* theData = nil;
	while((theData = [[theOutPipe fileHandleForReading] availableData]) && [theData length]) {
		[self _delegateServerMessageFromData:theData];
	}  
	// wait until task is actually completed
	[theTask waitUntilExit];
	int theReturnCode = [theTask terminationStatus];    
	[theTask release];
	[theOutPipe release];    
	
	[self _delegateServerMessage:[NSString stringWithFormat:@"Start method returned status %d",theReturnCode]];
	
	return theReturnCode ? NO : YES;
}

-(void)_backgroundBackupThread:(NSArray* )theArguments {
	NSParameterAssert(theArguments && [theArguments count]);
	NSParameterAssert([self backupState] != FLXBackupStateRunning);

	NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];

	[self setBackupState:FLXBackupStateRunning];
	NSString* theBackupFilePath;
	if([theArguments count]==2) {
		theBackupFilePath = [self backupToFolderPath:[theArguments objectAtIndex:0] superPassword:[theArguments objectAtIndex:1]];
	} else {
		theBackupFilePath = [self backupToFolderPath:[theArguments objectAtIndex:0] superPassword:nil];
	}
	if(theBackupFilePath==nil) {
		[self setBackupState:FLXBackupStateError];
	} else {
		[self _delegateServerMessage:[NSString stringWithFormat:@"Backup completed to file: %@",theBackupFilePath]];
		[self setBackupState:FLXBackupStateIdle];		
	}
	
	[thePool release];	
}

-(void)_backgroundThread:(id)anObject {
	NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
	
	// create a scheduled timer
	[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_backgroundThreadFire:) userInfo:nil repeats:YES];
	
	// create the runloop
	double resolution = 300.0;
	BOOL _isRunning;
	do {
		// run the loop!
		NSDate* theNextDate = [NSDate dateWithTimeIntervalSinceNow:resolution]; 
		_isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:theNextDate]; 
		// occasionally re-create the autorelease pool whilst program is running
		[thePool release];
		thePool = [[NSAutoreleasePool alloc] init];            
	} while(_isRunning==YES && [self processIdentifier] >= 0);  
	
	[self _delegateServerMessage:@"Background thread has terminated"];
	
	[thePool release];
}

-(void)_backgroundThreadFire:(id)sender {
	BOOL isSuccess = NO;
	switch([self state]) {
		case FLXServerStateIgnition:
			// determine if we need to initialize the data directory
			if([self _shouldInitialize]) {
				[self setState:FLXServerStateInitializing];
			} else {
				[self setState:FLXServerStateStarting];        
			}
			break;
		case FLXServerStateInitializing:
			// initialize the data directory
			isSuccess = [self _initialize];
			if(isSuccess==NO) {
				[self setState:FLXServerStateStartingError];
			} else {
				[self setState:FLXServerStateStarting];
			}
			break;
		case FLXServerStateStarting:
			// start the server
			[self _start];
			// this should return only when stopping is happening
			if([self state] == FLXServerStateStarting) {
				// if server was starting up, then an error occurs here
				[self setState:FLXServerStateStartingError];
			}
		case FLXServerStateStartingError:
			// an error occurred when starting the server
			// in this state, we need to quit the runloop and close down everything
			[self _delegateServerMessage:@"Terminating background thread"];
			m_theProcessIdentifier = -1;
			CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
			break;
		default:
			NSAssert(NO,@"Don't know what to do for that state in _backgroundThreadFire");
			break;
	}
}

@end
