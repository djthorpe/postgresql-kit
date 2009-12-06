
/*
 This example shows how to use the PostgresServerKit to create a server, as
 a cocoa application. It includes the ability to backup the server data, and
 determine whether remote connections are allowed, and on what port. Also
 provides a host-access control editor.
 */


#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window;
@synthesize ibLogView;
@synthesize ibPreferencesWindow;
@synthesize ibHostAccessWindow;

@synthesize port;
@synthesize timer;
@synthesize serverStatusField;
@synthesize backupStatusField;
@synthesize isStartButtonEnabled;
@synthesize isStopButtonEnabled;
@synthesize isAllowRemoteConnections;
@synthesize isCustomPort;
@synthesize selectedPortOption;
@synthesize isServerRestarting;
@synthesize stateImage;
@synthesize backupStateImage;
@dynamic server;
@dynamic dataPath;
@synthesize hostAccessTuples;
@synthesize selectedHostAccessTuples;

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

	// set button state - isDefaultPort
	if([self port]==[FLXPostgresServer defaultPort]) {
		[self setSelectedPortOption:0];
		[self setIsCustomPort:NO];
	} else {
		[self setIsCustomPort:YES];
		[self setSelectedPortOption:1];
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

-(void)hostAccessDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[sheet orderOut:self];	
	
	if(returnCode==NSOKButton) {
		BOOL isSuccess = [[self server] writeAccessTuples:[self hostAccessTuples]];
		if(isSuccess==NO) {
			[self addLogMessage:@"ERROR: Unable to write host access file" color:[NSColor redColor] bold:YES];
		} else {
			[[self server] reload];
		}
	}
	
	// release memory
	[self setHostAccessTuples:nil];	

}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	// when access type switches from local to host, empty or fill address field
	if([object isKindOfClass:[FLXPostgresServerAccessTuple class]]==NO) {
		return;	
	}

	NSString* old = [change objectForKey:NSKeyValueChangeOldKey];
	NSString* new = [change objectForKey:NSKeyValueChangeNewKey];
	FLXPostgresServerAccessTuple* theTuple = (FLXPostgresServerAccessTuple* )object;
	
	if([keyPath isEqual:@"type"] && [old isEqual:new]==NO) {		
		if([new isEqual:@"local"]) {
			[theTuple setAddress:nil];
		} else {
			[theTuple setAddress:@"127.0.0.1/32"];
		}
	}


	if([keyPath isEqual:@"method"] && [old isEqual:new]==NO) {		
		if([new isEqual:@"ident"]) {
			[theTuple setOptions:@""];
		} else {
			[theTuple setOptions:nil];
		}
	}
	

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
	
	// set port
	[self setPort:[[self server] port]];
	if([[self server] hostname]==nil) {
		[self setIsAllowRemoteConnections:NO];
	} else {
		[self setIsAllowRemoteConnections:YES];		
	}	
	
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

-(IBAction)doPreferences:(id)sender {
	[[self ibPreferencesWindow] endEditingFor:nil];
	[[self ibPreferencesWindow] makeFirstResponder:nil];
	
	[NSApp beginSheet:[self ibPreferencesWindow] modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(preferencesDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction)doHostAccess:(id)sender {
	[[self ibHostAccessWindow] makeFirstResponder:nil];
	
	// obtain the host access list
	NSArray* theTuples = [[self server] readAccessTuples];
	if([theTuples count]==0) {
		[self addLogMessage:@"ERROR: Unable to read host access file" color:[NSColor redColor] bold:YES];
		return;
	}
		
	[self setHostAccessTuples:[[NSMutableArray alloc] initWithArray:theTuples]];	

	// we observe certain values of host access tuples
	for(FLXPostgresServerAccessTuple* theTuple in [self hostAccessTuples]) {
		[theTuple addObserver:self forKeyPath:@"type" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
		[theTuple addObserver:self forKeyPath:@"method" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
	}		
	
	// begin display	
	[NSApp beginSheet:[self ibHostAccessWindow] modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(hostAccessDidEnd:returnCode:contextInfo:) contextInfo:nil];
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

-(IBAction)doHostAccessButton:(id)sender {
	NSButton* theButton = (NSButton* )sender;
	NSParameterAssert([theButton isKindOfClass:[NSButton class]]);
	
	if([[theButton title] isEqual:@"OK"]) {
		[NSApp endSheet:[self ibHostAccessWindow] returnCode:NSOKButton];
	} else {
		[NSApp endSheet:[self ibHostAccessWindow] returnCode:NSCancelButton];
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

-(IBAction)doRemoveHostAccessTuple:(id)sender {
	NSLog(@"remove %@",[self selectedHostAccessTuples]);
}

-(IBAction)doInsertHostAccessTuple:(id)sender {
	NSLog(@"insert %@",[self selectedHostAccessTuples]);
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
