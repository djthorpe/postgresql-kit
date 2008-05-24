
#import "FLXServer.h"
#include <sys/sysctl.h>

static FLXServer* FLXSharedServer = nil;
const unsigned FLXDefaultPostgresPort = 5432;

@interface FLXServer (Private)
-(BOOL)_createDataPath;
-(int)_processIdentifierFromDataPath;
-(void)_delegateServerMessage:(NSString* )theMessage;
-(void)_delegateServerStateDidChange:(NSString* )theMessage;  
-(NSString* )_messageFromState;
-(int)_doesProcessExist:(int)thePid;
@end

@implementation FLXServer

////////////////////////////////////////////////////////////////////////////////
// singleton design pattern
// see http://www.cocoadev.com/index.pl?SingletonDesignPattern

+(FLXServer* )sharedServer {
  @synchronized(self) {
    if (FLXSharedServer == nil) {
      [[self alloc] init]; // assignment not done here
    }
  }
  return FLXSharedServer;
}

+(id)allocWithZone:(NSZone *)zone {
  @synchronized(self) {
    if (FLXSharedServer == nil) {
      FLXSharedServer = [super allocWithZone:zone];
      return FLXSharedServer;  // assignment and return on first allocation
    }
  }
  return nil; //on subsequent allocation attempts return nil
}

-(id)copyWithZone:(NSZone *)zone {
  return self;
}

-(id)retain {
  return self;
}

-(unsigned)retainCount {
  return UINT_MAX;  //denotes an object that cannot be released
}

-(void)release {
  // do nothing
}

-(id)autorelease {
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// constructor and destructor

-(id)init {
  self = [super init];
  if(self) {
    m_theDataPath = nil;
    m_theState = FLXServerStateUnknown;
    m_theProcessIdentifier = -1;
    m_theHostname = @""; // defaults to socket-based communication
    m_thePort = FLXDefaultPostgresPort;    // default postgres port
    m_theDelegate = nil;
  }
  return self;
}

-(void)dealloc {
  [m_theDataPath release];
  [m_theHostname release];
  [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// delegates

-(void)setDelegate:(id)theDelegate {
  m_theDelegate = theDelegate;
}

-(id)delegate {
  return m_theDelegate;
}

////////////////////////////////////////////////////////////////////////////////
// properties

-(FLXServerState)state {
  return m_theState;
}

-(void)setState:(FLXServerState)theState {
  @synchronized(self) {
    if(m_theState != theState) {
      m_theState = theState;
      [self _delegateServerStateDidChange:[self _messageFromState]];
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

-(NSString* )dataPath {
  return m_theDataPath;
}

-(void)setDataPath:(NSString* )thePath {
  [thePath retain];
  [m_theDataPath release];
  m_theDataPath = thePath;
}

-(int)processIdentifier {
  return m_theProcessIdentifier;
}

-(void)setProcessIdentifier:(int)theProcessIdentifier {
  m_theProcessIdentifier = theProcessIdentifier;  
}

-(void)setHostname:(NSString* )theHostname {
  NSParameterAssert(theHostname);
  [theHostname retain];
  [m_theHostname release];
  m_theHostname = theHostname;
}

-(NSString* )hostname {
  return m_theHostname;
}

-(void)setPort:(int)thePort {
  NSParameterAssert(thePort > 0);
  m_thePort = thePort;
}

-(int)port {
  return m_thePort;
}

+(NSString* )bundlePath {
  return [[NSBundle bundleForClass:[self class]] bundlePath];
}

+(NSString* )postgresServerPath {
  return [[self bundlePath] stringByAppendingPathComponent:@"Resources/postgresql-8.2.5/bin/postgres"];
}

+(NSString* )postgresInitPath {
  return [[self bundlePath] stringByAppendingPathComponent:@"Resources/postgresql-8.2.5/bin/initdb"];
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(BOOL)startWithDataPath:(NSString* )thePath {
  NSParameterAssert(thePath);

  [self _delegateServerMessage:[NSString stringWithFormat:@"Starting server with data path: %@",thePath]];

  if([self state] != FLXServerStateStopped && [self state] != FLXServerStateUnknown) {
    [self _delegateServerMessage:@"Invalid or unknown server state"];
    return NO;    
  }
  
  // set the data path and the pid  
  [self setDataPath:thePath];
  [self setProcessIdentifier:-1];

  // if database process is already running, then set this as the state
  // and return NO
  int thePid = [self _processIdentifierFromDataPath];
  if(thePid > 0) {
    [self setProcessIdentifier:thePid];
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
  if([self _createDataPath]==NO) {
    [self setState:FLXServerStateStartingError];
    [self _delegateServerMessage:[NSString stringWithFormat:@"Unable to create data directory: %@",[self dataPath]]];
    return NO;    
  }

  [self _delegateServerMessage:@"Starting background server thread"];

  // set the pid to zero
  [self setProcessIdentifier:0];
  [self setState:FLXServerStateIgnition];
  // start the background thread to start the server
  [NSThread detachNewThreadSelector:@selector(_backgroundThread:) toTarget:self withObject:nil];

  // immediate return
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
  [self setProcessIdentifier:-1];
  [self setState:FLXServerStateStopped];
  
  // return success
  return YES;
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(NSString* )_messageFromState {
  switch([self state]) {
    case FLXServerStateAlreadyRunning:
      return @"Already Running";
    case FLXServerStateIgnition:
      return @"Starting";
    case FLXServerStateInitializing:
      return @"Initializing";
    case FLXServerStateStarting:
      return @"Starting";
    case FLXServerStateStarted:
      return @"Started";
    case FLXServerStateStartingError:
      return @"Error";
    case FLXServerStateStopping:
      return @"Stopping";
    case FLXServerStateStopped:
      return @"Stopped";
    default:
      return @"Unknown";
  }
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
  // then advance state to FLXServerStateStarted
  if([theMessage hasSuffix:@"database system is ready"] && [self state]==FLXServerStateStarting) {
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
  NSDictionary* theAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:thePath traverseLink:YES];
  if([theAttributes fileSize] > 1024) {
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

-(BOOL)_createDataPath {
  // if data directory already exists
  BOOL isDirectory = NO;
  if([[NSFileManager defaultManager] fileExistsAtPath:[self dataPath] isDirectory:&isDirectory]==NO) {
    // create the directory
    if([[NSFileManager defaultManager] createDirectoryAtPath:[self dataPath] attributes:nil]==NO) {
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
  [theTask setArguments:[NSArray arrayWithObjects:@"-D",[self dataPath],@"--encoding=UTF8",@"--no-locale",nil]];
  
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
  [theTask setArguments:[NSArray arrayWithObjects:@"-D",[self dataPath],@"-h",[self hostname],@"-p",[NSString stringWithFormat:@"%d",[self port]],nil]];
  
  // launch the postgres database, set the pid
  [theTask launch];                                                 
  [self setProcessIdentifier:[theTask processIdentifier]];
  
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

-(void)_backgroundThread:(id)anObject {
  NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];

  // create a scheduled timer
  [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_backgroundThreadFire:) userInfo:nil repeats:YES];
  
  // create the runloop
  double resolution = 300.0;
  BOOL isRunning;
  do {
    // run the loop!
    NSDate* theNextDate = [NSDate dateWithTimeIntervalSinceNow:resolution]; 
    isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:theNextDate]; 
    // occasionally re-create the autorelease pool whilst program is running
    [thePool release];
    thePool = [[NSAutoreleasePool alloc] init];            
  } while(isRunning==YES && [self processIdentifier] >= 0);  
  
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
      [self setProcessIdentifier:-1];
      CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
      break;
    default:
      NSAssert(NO,@"Don't know what to do for that state in _backgroundThreadFire");
      break;
  }
}

@end
