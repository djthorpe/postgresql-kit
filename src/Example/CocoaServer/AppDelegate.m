
/*
 This example shows how to use the PostgresServerKit to create a server, as
 a cocoa application. It includes the ability to backup the server data, and
 determine whether remote connections are allowed, and on what port.
 */


#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window;
@synthesize ibLogView;
@synthesize ibPreferencesWindow;
@synthesize port;
@synthesize timer;
@dynamic server;
@dynamic dataPath;
@synthesize serverStatusField;
@synthesize backupStatusField;
@synthesize isStartButtonEnabled;
@synthesize isStopButtonEnabled;
@synthesize isAllowRemoteConnections;
@synthesize isCustomPort;
@synthesize selectedPortOption;
@synthesize isServerRestarting;

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

	// set button state - isDefaultPort
	if([self port]==[FLXPostgresServer defaultPort]) {
		[self setSelectedPortOption:0];
		[self setIsCustomPort:NO];
	} else {
		[self setIsCustomPort:YES];
		[self setSelectedPortOption:1];
	}			
}

-(void)backupToPath:(NSString* )thePath {
	[self addLogMessage:[NSString stringWithFormat:@"Backing up to path: %@",thePath]];
	[[self server] backupInBackgroundToFolderPath:thePath superPassword:nil];
}

-(void)preferencesDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[sheet orderOut:self];	
	
	if(returnCode==NSOKButton) {
		// if OK, then apply these new values
		[[self server] setPort:[self port]];
		if([self isAllowRemoteConnections]) {
			[[self server] setHostname:@"*"];
		} else {
			[[self server] setHostname:@""];			
		}
		
		// restart the server
		[self setIsServerRestarting:YES];
		
	} else {
		// else obtain them from server again
		[self setPort:[[self server] port]];
		if([[[self server] hostname] length]) {
			[self setIsAllowRemoteConnections:YES];			
		} else {			
			[self setIsAllowRemoteConnections:NO];
		}
	}
	
	// set button states
	[self setButtonStates];
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
	
	// set port
	[self setPort:[[self server] port]];
	if([[self server] hostname]==nil) {
		[self setIsAllowRemoteConnections:NO];
	} else {
		[self setIsAllowRemoteConnections:YES];		
	}	
	
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
					[self backupToPath:[[[thePanel URLs] objectAtIndex:0] path]];
				}
				break;
			default:
				break;
		 }}];
}

-(IBAction)doServerAccess:(id)sender {
	// TODO
}

-(IBAction)doPreferences:(id)sender {
	[[self ibPreferencesWindow] endEditingFor:nil];
	[[self ibPreferencesWindow] makeFirstResponder:nil];
	
	[NSApp beginSheet:[self ibPreferencesWindow] modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(preferencesDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction)doPreferencesButton:(id)sender {
	NSButton* theButton = (NSButton* )sender;
	NSParameterAssert([theButton isKindOfClass:[NSButton class]]);
	
	[[self ibPreferencesWindow] endEditingFor:nil];
	
	if([[theButton title] isEqual:@"OK"]) {
		[NSApp endSheet:[self ibPreferencesWindow] returnCode:NSOKButton];
	} else {
		[NSApp endSheet:[self ibPreferencesWindow] returnCode:NSCancelButton];
	}
}

-(IBAction)doPortRadioButton:(id)sender {
	if([self selectedPortOption]==1) {
		[self setIsCustomPort:YES];
	} else {
		[self setIsCustomPort:NO];
		[self setPort:[FLXPostgresServer defaultPort]];
	}
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
