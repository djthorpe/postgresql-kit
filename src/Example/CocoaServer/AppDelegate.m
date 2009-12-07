
/*
 This example shows how to use the PostgresServerKit to create a server, as
 a cocoa application. It includes the ability to backup the server data, and
 determine whether remote connections are allowed, and on what port. Also
 provides a host-access control editor.
 */


#import "AppDelegate.h"

@implementation AppDelegate
@synthesize ibWindow;
@synthesize ibLogView;
@synthesize timer;
@synthesize serverStatusField;
@synthesize backupStatusField;
@synthesize isStartButtonEnabled;
@synthesize isStopButtonEnabled;
@synthesize isServerRestarting;
@synthesize stateImage;
@synthesize backupStateImage;
@dynamic server;
@dynamic dataPath;

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

-(void)clearLog {
	NSMutableAttributedString* theLog = [[self ibLogView] textStorage];
	[theLog deleteCharactersInRange:NSMakeRange(0,[theLog length])];	
}

-(void)addLogMessage:(NSString* )theString color:(NSColor* )theColor bold:(BOOL)isBold {
	NSMutableAttributedString* theLog = [[self ibLogView] textStorage];
	NSUInteger theStartPoint = [theLog length];
	NSFont* theFont = [NSFont userFixedPitchFontOfSize:11.0];
	NSDictionary* theAttributes = nil;
	if(theColor) {
		theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:theColor,NSForegroundColorAttributeName,nil];
	}
	NSMutableAttributedString* theLine = nil;
	if(theStartPoint) {
		theLine = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@",theString] attributes:theAttributes];
	} else {
		theLine = [[NSMutableAttributedString alloc] initWithString:theString attributes:theAttributes];
	}
	[theLine addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:theFont,NSFontAttributeName,nil] range:NSMakeRange(0,[theLine length])];
	if(isBold) {
		[theLine applyFontTraits:NSBoldFontMask range:NSMakeRange(0,[theLine length])];
	} else {
		[theLine applyFontTraits:NSUnboldFontMask range:NSMakeRange(0,[theLine length])];		
	}
	[theLog appendAttributedString:theLine];
	[[self ibLogView] scrollRangeToVisible:NSMakeRange(theStartPoint,[theLog length])];	
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
	
	// set image state
	if([[self server] state]==FLXServerStateStarted) {
		[self setStateImage:[NSImage imageNamed:@"green"]];
	} else if([[self server] state]==FLXServerStateStopped || [[self server] state]==FLXServerStateUnknown || [[self server] state]==FLXServerStateStartingError) {
		[self setStateImage:[NSImage imageNamed:@"red"]];		
	} else {
		[self setStateImage:[NSImage imageNamed:@"yellow"]];
	}		

	// set backup image state
	if([self isStopButtonEnabled]==NO || [[self server] backupState]==FLXBackupStateError) {
		[self setBackupStateImage:[NSImage imageNamed:@"red"]];		
	} else if([[self server] backupState]==FLXBackupStateIdle) {
		[self setBackupStateImage:[NSImage imageNamed:@"green"]];		
	} else {
		[self setBackupStateImage:[NSImage imageNamed:@"yellow"]];
	}		
}

-(void)backupToPath:(NSString* )thePath {
	[self addLogMessage:[NSString stringWithFormat:@"Backing up to path: %@",thePath] color:nil bold:YES];
	[[self server] backupInBackgroundToFolderPath:thePath superPassword:nil];
}

////////////////////////////////////////////////////////////////////////////////
// FLXPostgresServerDelegate

-(void)serverMessage:(NSString* )theMessage {	
	if([theMessage hasPrefix:@"ERROR: "] || [theMessage hasPrefix:@"FATAL: "]) {
		[self addLogMessage:theMessage color:[NSColor redColor] bold:YES];
	} else if([theMessage hasPrefix:@"WARNING: "])  {
		[self addLogMessage:theMessage color:[NSColor orangeColor] bold:YES];		
	} else {
		[self addLogMessage:theMessage color:nil bold:NO];				
	}
}

-(void)serverStateDidChange:(NSString* )theMessage {	
	[self setServerStatusField:[[self server] stateAsString]];
	[self setButtonStates];
}

-(void)backupStateDidChange:(NSString* )theMessage {	
	[self setBackupStatusField:[[self server] backupStateAsString]];
	[self setButtonStates];
}

////////////////////////////////////////////////////////////////////////////////

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	// create a timer
	[self setTimer:[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES]];
		
	// set initial button states
	[self setButtonStates];
	
	// set initial state strings
	[self serverStateDidChange:nil];
	[self backupStateDidChange:nil];
	
	// set server delegate
	[[self server] setDelegate:self];	
}

-(void)applicationWillTerminate:(NSNotification *)aNotification {
	do {
		// stop the server
		[[self server] stop];
		// wait for a little while
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
	} while([[self server] state] != FLXServerStateStopped && [[self server] state] != FLXServerStateStartingError);
	
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
	
	[thePanel beginSheetModalForWindow:[self ibWindow] completionHandler:
		^(NSInteger returnCode) {
			switch (returnCode) {
			case NSFileHandlingPanelOKButton:
				if([[thePanel URLs] count]) {
					[self backupToPath:[[[thePanel URLs] objectAtIndex:0] path]];
				}
				break;
			default:
				break;
		 }}];
}

////////////////////////////////////////////////////////////////////////////////

-(void)timerFired:(id)theTimer {

	// if server is stopped, and restart required
	if([[self server] state]==FLXServerStateStopped && [self isServerRestarting]) {
		[self setIsServerRestarting:NO];
		BOOL isStarting = [[self server] startWithDataPath:[self dataPath]];
		if(isStarting==NO) {
			[[self server] stop];
		}
		return;
	}	
	
	// stop server if it is already running
	if([[self server] state]==FLXServerStateAlreadyRunning || [self isServerRestarting]==YES) {
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
