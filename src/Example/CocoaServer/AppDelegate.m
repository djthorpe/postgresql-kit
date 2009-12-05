
#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window;
@synthesize ibLogView;
@synthesize timer;
@dynamic server;
@dynamic dataPath;
@synthesize serverStatusField;
@synthesize backupStatusField;
@synthesize isStartButtonEnabled;
@synthesize isStopButtonEnabled;

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

////////////////////////////////////////////////////////////////////////////////
// private methods

-(void)addLogMessage:(NSString* )theMessage {
	NSAttributedString* theString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n",theMessage]];
	NSMutableAttributedString* theLog = [[self ibLogView] textStorage];
	[theLog appendAttributedString:theString];
}

-(void)setButtonStates {	
	// set button states - start
	if([[self server] state]==FLXServerStateStarted || [[self server] state]==FLXServerStateUnknown ||
	   [[self server] state]==FLXServerStateAlreadyRunning || [[self server] state]==FLXServerStateInitializing ||
	   [[self server] state]==FLXServerStateStarting) {
		[self setIsStartButtonEnabled:NO];
	} else {
		[self setIsStartButtonEnabled:YES];		
	}
	
	// set button states - stop. backup, access
	if([[self server] state]==FLXServerStateStarted) {
		[self setIsStopButtonEnabled:YES];
	} else {
		[self setIsStopButtonEnabled:NO];		
	}	
}

-(void)backupToPath:(NSString* )thePath {
	[self addLogMessage:[NSString stringWithFormat:@"Backing up to path: %@",thePath]];
	[[self server] backupInBackgroundToFolderPath:thePath superPassword:nil];
}

////////////////////////////////////////////////////////////////////////////////
// FLXPostgresServerDelegate

-(void)serverMessage:(NSString* )theMessage {	
	[self addLogMessage:theMessage];
}

-(void)serverStateDidChange:(NSString* )theMessage {	
	[self setServerStatusField:[[self server] stateAsString]];
	[self setBackupStatusField:[[self server] backupStateAsString]];
	[self setButtonStates];
}

////////////////////////////////////////////////////////////////////////////////

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	// create a timer
	[self setTimer:[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES]];
	
	// set initial button states
	[self setButtonStates];
	
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
	// create a file panel
	NSOpenPanel* thePanel = [NSOpenPanel openPanel];
	[thePanel setCanChooseFiles:NO];
	[thePanel setCanChooseDirectories:YES];
	[thePanel setAllowsMultipleSelection:NO];
	
	[thePanel beginSheetModalForWindow:[self window] completionHandler:
		^(NSInteger returnCode) {
			switch (returnCode) {
			case NSFileHandlingPanelOKButton:
				if([[thePanel URLs] count]) {
					NSURL* theURL = [[thePanel URLs] objectAtIndex:0];					
					[self backupToPath:[theURL path]];
				}
				break;
			default:
				break;
		 }
		}];
}

-(IBAction)doServerAccess:(id)sender {
	// TODO
}


////////////////////////////////////////////////////////////////////////////////

-(void)timerFired:(id)theTimer {
	
	// stop server if it is already running
	if([[self server] state]==FLXServerStateAlreadyRunning) {
		[[self server] stop];
		return;
	}
	
	// start server if state is unknown
	if([[self server] state]==FLXServerStateUnknown) {
		BOOL isStarting = [[self server] startWithDataPath:[self dataPath]];
		if(isStarting==NO) {
			[[self server] stop];
		}
		return;
	}
	
}

@end
