
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
	if([theMessage hasPrefix:@"ERROR"]) {
		[self addLogMessage:theMessage color:[NSColor redColor] bold:NO];
	} else {
		[self addLogMessage:theMessage color:nil bold:NO];
	}
}

-(void)pgserverStateChange:(PGServer2* )sender {
	if([sender state]==PGServerStateRunning || [sender state]==PGServerStateAlreadyRunning) {
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
}

////////////////////////////////////////////////////////////////////////////////
// Stop and Restart (or start) the server

-(void)startServer {
	[self addLogMessage:[NSString stringWithFormat:@"Starting server with data path: %@",[self dataPath]] color:[NSColor redColor] bold:NO];
	[[PGServer2 sharedServer] startWithDataPath:[self dataPath] hostname:[[self ibConnectionPrefs] hostname] port:[[self ibConnectionPrefs] port]];
}

-(void)stopServer {
	[self addLogMessage:[NSString stringWithFormat:@"Stopping server"] color:[NSColor redColor] bold:NO];
	// stop the server
	[[PGServer2 sharedServer] stop];
}

-(void)restartServer {
	// stop server
	if([[PGServer2 sharedServer] state]==PGServerStateRunning || [[PGServer sharedServer] state]==PGServerStateAlreadyRunning) {
		[[PGServer2 sharedServer] restart];
	}
}

////////////////////////////////////////////////////////////////////////////////
// Application signals

-(void)awakeFromNib {
	[[PGServer2 sharedServer] setDelegate:self];
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	PGServer2* theServer = [PGServer2 sharedServer];
	
	// set version number
	[self setIbServerVersion:[theServer version]];

	// set button states
	[self setIbStartButtonEnabled:YES];
	[self setIbStopButtonEnabled:NO];
	[self setIbBackupButtonEnabled:NO];
	
	// set status icons
	[self setIbServerStatusIcon:[NSImage imageNamed:@"red"]];
	
}

-(void)applicationWillTerminate:(NSNotification *)aNotification {
	[self stopServer];
}

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
	[[self ibConnectionPrefs] ibToolbarConnectionSheetOpen:[self ibWindow] delegate:self];
}

@end
