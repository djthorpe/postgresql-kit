
#import "Controller.h"

@implementation Controller

////////////////////////////////////////////////////////////////////////////////
// init method

-(id)init {
	self = [super init];
	if(self) {
		_connection = [[PGConnection alloc] init];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// Properties

@dynamic server;
@dynamic connection;

-(PGConnection* )connection {
	return _connection;
}

-(PGServer* )server {
	return _server;
}

-(PGServerPreferences* )configuration {
	return [[self server] configuration];
}

////////////////////////////////////////////////////////////////////////////////
// Utility functions

-(NSString* )dataPath {
	NSString* theIdent = @"PostgreSQL";
	NSArray* theApplicationSupportDirectory = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask, YES);
	NSParameterAssert([theApplicationSupportDirectory count]);
	return [[theApplicationSupportDirectory objectAtIndex:0] stringByAppendingPathComponent:theIdent];
}

////////////////////////////////////////////////////////////////////////////////
// Log

-(void)clearLog {
	NSMutableAttributedString* theLog = [[self ibLogTextView] textStorage];
	[theLog deleteCharactersInRange:NSMakeRange(0,[theLog length])];
}

-(void)addLogMessage:(NSString* )theString color:(NSColor* )theColor bold:(BOOL)isBold {
	NSMutableAttributedString* theLog = [[self ibLogTextView] textStorage];
	NSUInteger theStartPoint = [theLog length];
	NSFont* theFont = [NSFont userFixedPitchFontOfSize:9.0];
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
	[[self ibLogTextView] scrollRangeToVisible:NSMakeRange(theStartPoint,[theLog length])];
}

////////////////////////////////////////////////////////////////////////////////
// PGServer delegate messages

-(void)message:(PGServer* )server message:(NSString* )message {
	if([message hasPrefix:@"ERROR:"]) {
		[self addLogMessage:message color:[NSColor redColor] bold:NO];
	} else if([message hasPrefix:@"WARNING:"]) {
			[self addLogMessage:message color:[NSColor redColor] bold:NO];
	} else if([message hasPrefix:@"FATAL:"]) {
		[self addLogMessage:message color:[NSColor redColor] bold:NO];
	} else {
		[self addLogMessage:message color:nil bold:NO];
	}
}

-(void)pgserver:(PGServer* )server stateChange:(PGServerState)state {	
#ifdef DEBUG
	NSLog(@"state changed => %d %@",state,[PGServer stateAsString:state]);
#endif
	
	switch(state) {
		case PGServerStateRunning:
			[self setIbStartButtonEnabled:NO];
			[self setIbStopButtonEnabled:YES];
			[self setIbBackupButtonEnabled:YES];
			[self setIbServerStatusIcon:[NSImage imageNamed:@"green"]];
			break;
		case PGServerStateStopped:
			[self setIbStartButtonEnabled:YES];
			[self setIbStopButtonEnabled:NO];
			[self setIbBackupButtonEnabled:NO];
			[self setIbServerStatusIcon:[NSImage imageNamed:@"red"]];
			break;
		case PGServerStateStarting:
		case PGServerStateInitialize:
		case PGServerStateStopping:
			[self setIbStartButtonEnabled:NO];
			[self setIbStopButtonEnabled:NO];
			[self setIbBackupButtonEnabled:NO];
			[self setIbServerStatusIcon:[NSImage imageNamed:@"yellow"]];
			break;
		default:
			[self setIbStartButtonEnabled:YES];
			[self setIbStopButtonEnabled:YES];
			[self setIbBackupButtonEnabled:NO];
			[self setIbServerStatusIcon:[NSImage imageNamed:@"yellow"]];
			break;
	}

	// connect and disconnect
	if(state==PGServerStateRunning &&  [[self connection] status] != PGConnectionStatusConnected) {
#ifdef DEBUG
		NSLog(@"Connecting to server");
#endif
		NSError* theError = nil;
		NSURL* theURL = [NSURL URLWithString:@"pgsql://postgres@/"];
		BOOL isSuccess = [[self connection] connectWithURL:theURL error:&theError];
		if(isSuccess==NO) {
			[self addLogMessage:[NSString stringWithFormat:@"Connection error: %@",[theError description]] color:[NSColor redColor] bold:NO];
		}
		
	} else if((state==PGServerStateStopping || state==PGServerStateRestart) && [[self connection] status]==PGConnectionStatusConnected) {
#ifdef DEBUG
		NSLog(@"Disconnecting from server");
#endif
		[[self connection] disconnect];
	}
	
	// set configuration preferences toolbar item
	if(state==PGServerStateRunning) {
		[[self ibToolbarItemConfiguration] setEnabled:YES];
		[[self ibToolbarItemConnection] setEnabled:YES];
	} else {
		[[self ibToolbarItemConfiguration] setEnabled:NO];
		[[self ibToolbarItemConnection] setEnabled:NO];
	}
	
	// check for terminating
	if(state==PGServerStateStopped && [self terminateRequested]) {
#ifdef DEBUG
		NSLog(@"PGServerStateStopped state reached, quitting application");
#endif
		[[NSApplication sharedApplication] terminate:self];
	}
}

////////////////////////////////////////////////////////////////////////////////
// Stop and Restart (or start) the server

-(void)startServer {
	[self addLogMessage:[NSString stringWithFormat:@"Starting server with data path: %@",[self dataPath]] color:[NSColor redColor] bold:NO];
	
	NSString* hostname = [[self ibConnectionPrefs] hostname];
	NSUInteger port = [[self ibConnectionPrefs] port];	
	[[self server] startWithNetworkBinding:hostname port:port];
}

-(void)stopServer {
	[self addLogMessage:[NSString stringWithFormat:@"Stopping server"] color:[NSColor redColor] bold:NO];
	// stop the server
	[[self server] stop];
}

-(void)restartServer {
	// stop server
	if([[self server] state]==PGServerStateRunning) {
		[[self server] restart];
	} else {
#ifdef DEBUG
		NSLog(@"Unable to restart a server which isn't in PGServerStateRunning state");
#endif
	}
}

-(void)reloadServer {
	// reload server
	if([[self server] state]==PGServerStateRunning) {
		[[self server] reload];
	} else {
#ifdef DEBUG
		NSLog(@"Unable to reload a server which isn't in PGServerStateRunning state");
#endif
	}
}

////////////////////////////////////////////////////////////////////////////////
// Application signals

-(void)applicationDidFinishLaunching:(NSNotification* )aNotification {
	// set version number
	[self setIbServerVersion:[[self server] version]];

	// set button states
	[self setIbStartButtonEnabled:YES];
	[self setIbStopButtonEnabled:NO];
	[self setIbBackupButtonEnabled:NO];
	
	// set toolbar status
	[[self ibToolbarItemConfiguration] setEnabled:NO];
	[[self ibToolbarItemConnection] setEnabled:NO];

	// set status icons
	[self setIbServerStatusIcon:[NSImage imageNamed:@"red"]];

	// no termination requested
	[self setTerminateRequested:nil];
	
	// set server delegate
	[[self server] setDelegate:self];
}

-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication* )sender {
	if([[self server] state]==PGServerStateRunning) {
#ifdef DEBUG
		NSLog(@"Terminating later, stopping the server");
#endif
		[self stopServer];
		[self setTerminateRequested:[NSDate date]];
		// need to send a cancel message to keep timers running, then finally
		// terminate when state changes to PGServerStateStopped
		return NSTerminateCancel;
	} else {
		return NSTerminateNow;
	}
}

////////////////////////////////////////////////////////////////////////////////
// Backup methods

-(void)backupToPath:(NSURL* )thePath {
	NSParameterAssert([thePath isFileURL]);
	NSLog(@"NOT YET IMPLEMENTED");
//	[[PGServer2 sharedServer] backupToFolderPath:[thePath path] superPassword:nil];
}

////////////////////////////////////////////////////////////////////////////////
// IBActions

-(IBAction)ibStartButtonPressed:(id)sender {
	[self startServer];
}

-(IBAction)ibStopButtonPressed:(id)sender {
	[self stopServer];
}

-(IBAction)ibBackupButtonPressed:(id)sender {
	NSButton* theButton = (NSButton* )sender;
	NSOpenPanel* thePanel = [NSOpenPanel openPanel];
	[thePanel setCanChooseFiles:NO];
	[thePanel setCanChooseDirectories:YES];
	[thePanel setAllowsMultipleSelection:NO];	
	[thePanel beginSheetModalForWindow:[theButton window] completionHandler:^(NSInteger returnCode) {
		if(returnCode==NSFileHandlingPanelOKButton) {
			if([[thePanel URLs] count]) {
				[self backupToPath:[[thePanel URLs] objectAtIndex:0]];
			 }
		}
	}];
}

-(IBAction)ibToolbarConnectionPressed:(id)sender {
	[[self ibConnectionPrefs] ibSheetOpen:[self ibWindow] delegate:self];
}

-(IBAction)ibToolbarConfigurationPressed:(id)sender {
	[[self ibConfigurationPrefs] ibSheetOpen:[self ibWindow] delegate:self];
}

@end
