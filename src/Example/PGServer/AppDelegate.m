
#import "AppDelegate.h"
#import <PGServerKit/PGServerKit.h>

@implementation AppDelegate

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

-(void)pgserverMessage:(NSString* )theMessage {
	if([theMessage hasPrefix:@"ERROR:"]) {
		[self addLogMessage:theMessage color:[NSColor redColor] bold:NO];
	} else if([theMessage hasPrefix:@"WARNING:"]) {
			[self addLogMessage:theMessage color:[NSColor redColor] bold:NO];
	} else if([theMessage hasPrefix:@"FATAL:"]) {
		[self addLogMessage:theMessage color:[NSColor redColor] bold:NO];
	} else {
		[self addLogMessage:theMessage color:nil bold:NO];
	}
}

-(void)pgserverStateChange:(PGServer* )sender {
#ifdef DEBUG
	NSLog(@"state changed => %d %@",[sender state],[PGServer stateAsString:[sender state]]);
#endif
	
	if([sender state]==PGServerStateRunning) {
		[self setIbStartButtonEnabled:NO];
		[self setIbStopButtonEnabled:YES];
		[self setIbBackupButtonEnabled:YES];
		[self setIbServerStatusIcon:[NSImage imageNamed:@"green"]];
	} else if([sender state]==PGServerStateStopped) {
		[self setIbStartButtonEnabled:YES];
		[self setIbStopButtonEnabled:NO];
		[self setIbBackupButtonEnabled:NO];
		[self setIbServerStatusIcon:[NSImage imageNamed:@"red"]];
	} else if([sender state]==PGServerStateStarting || [sender state]==PGServerStateInitialize || [sender state]==PGServerStateStopping) {
		[self setIbStartButtonEnabled:NO];
		[self setIbStopButtonEnabled:NO];
		[self setIbBackupButtonEnabled:NO];
		[self setIbServerStatusIcon:[NSImage imageNamed:@"yellow"]];
	} else {
		[self setIbStartButtonEnabled:YES];
		[self setIbStopButtonEnabled:YES];
		[self setIbBackupButtonEnabled:NO];
		[self setIbServerStatusIcon:[NSImage imageNamed:@"yellow"]];
	}
	
	// set configuration preferences toolbar item
	if([sender state]==PGServerStateRunning) {
		[[self ibToolbarItemConfiguration] setEnabled:YES];
		[[self ibToolbarItemConnection] setEnabled:YES];
	} else {
		[[self ibToolbarItemConfiguration] setEnabled:NO];
		[[self ibToolbarItemConnection] setEnabled:NO];
	}
	
	// check for terminating
	if([sender state]==PGServerStateStopped && [self terminateRequested]) {
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
	[[PGServer sharedServer] startWithDataPath:[self dataPath] hostname:[[self ibConnectionPrefs] hostname] port:[[self ibConnectionPrefs] port]];
}

-(void)stopServer {
	PGServer* theServer = [PGServer sharedServer];
	[self addLogMessage:[NSString stringWithFormat:@"Stopping server"] color:[NSColor redColor] bold:NO];
	// stop the server
	[theServer stop];
}

-(void)restartServer {
	// stop server
	if([[PGServer sharedServer] state]==PGServerStateRunning) {
		[[PGServer sharedServer] restart];
	} else {
#ifdef DEBUG
		NSLog(@"Unable to restart a server which isn't in PGServerStateRunning state");
#endif
	}
}

-(void)reloadServer {
	// reload server
	if([[PGServer sharedServer] state]==PGServerStateRunning) {
		[[PGServer sharedServer] reload];
	} else {
#ifdef DEBUG
		NSLog(@"Unable to reload a server which isn't in PGServerStateRunning state");
#endif
	}
}

////////////////////////////////////////////////////////////////////////////////
// Application signals

-(void)applicationDidFinishLaunching:(NSNotification* )aNotification {
	PGServer* theServer = [PGServer sharedServer];
	
	// set version number
	[self setIbServerVersion:[theServer version]];

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
	[[PGServer sharedServer] setDelegate:self];
}

-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication* )sender {
	if([[PGServer sharedServer] state]==PGServerStateRunning) {
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

//-(void)applicationWillTerminate:(NSNotification *)aNotification {
//	[self stopServer];
//}


////////////////////////////////////////////////////////////////////////////////
// Backup methods

-(void)backupToPath:(NSURL* )thePath {
	NSParameterAssert([thePath isFileURL]);
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
