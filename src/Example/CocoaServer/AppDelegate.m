
#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window;
@synthesize textField;
@synthesize textLog;
@synthesize timer;
@dynamic server;
@dynamic dataPath;
@synthesize serverStatusField;
@synthesize backupStatusField;

////////////////////////////////////////////////////////////////////////////////
// properties

-(FLXPostgresServer* )server {
	return [FLXPostgresServer sharedServer];
}

-(NSString* )dataPath {
	NSString* theIdent = @"PostgreSQL";
	NSArray* theApplicationSupportDirectory = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask, YES);
	NSParameterAssert([theApplicationSupportDirectory count]);
	return [[theApplicationSupportDirectory objectAtIndex:0] stringByAppendingPathComponent:theIdent];
}


-(void)addLogMessage:(NSString* )theMessage {
	[[self textLog] appendFormat:@"%@\n",theMessage];
    [self willChangeValueForKey:@"textField"];
	[self setTextField:[[self textLog] copy]];
    [self didChangeValueForKey:@"textField"];
}


////////////////////////////////////////////////////////////////////////////////
// FLXPostgresServerDelegate

-(void)serverMessage:(NSString* )theMessage {	
	[self addLogMessage:theMessage];
}

-(void)serverStateDidChange:(NSString* )theMessage {	
	[self setServerStatusField:[[self server] stateAsString]];
	[self setBackupStatusField:[[self server] backupStateAsString]];
}

////////////////////////////////////////////////////////////////////////////////

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// set text field
	[self setTextLog:[[NSMutableString alloc] init]];
	
	// create a timer
	NSTimer* theTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
	[self setTimer:theTimer];
	
	// set server delegate
	[[self server] setDelegate:self];		
}

-(void)applicationWillTerminate:(NSNotification *)aNotification {
	do {
		// stop the server
		[[self server] stop];
		// wait for a little while
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
	} while([[self server] state] != FLXServerStateStopped);
	
	// invalidate the timer - remove from run loop
	[[self timer] invalidate];
}

////////////////////////////////////////////////////////////////////////////////

-(IBAction)doServerStart:(id)sender {
	[[self server] startWithDataPath:[self dataPath]];
}

-(IBAction)doServerStop:(id)sender {
	[[self server] stop];
}

-(IBAction)doServerBackup:(id)sender {
	
}

-(IBAction)doServerAccess:(id)sender {
	
}


////////////////////////////////////////////////////////////////////////////////

-(void)timerFired:(id)theTimer {
	
	// stop server if it is already running
	if([[self server] state]==FLXServerStateAlreadyRunning) {
		[[self server] stop];
		return;
	}
	
	// start server if state is unknown
	if([[self server] state]==FLXServerStateUnknown || [[self server] state]==FLXServerStateStopped) {
		BOOL isStarting = [[self server] startWithDataPath:[self dataPath]];
		if(isStarting==NO) {
			[[self server] stop];
		}
		return;
	}
	
}

@end
