//
//  AppDelegate.m
//  PGServer
//
//  Created by David Thorpe on 02/09/2012.
//
//

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

-(void)pgserverStateChange:(PGServer* )sender {
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
// Application signals

-(void)awakeFromNib {
	[[PGServer sharedServer] setDelegate:self];
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	PGServer* theServer = [PGServer sharedServer];
	
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
	do {
		// stop the server
		[[PGServer sharedServer] stop];
		// wait for a little while
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
	} while([[PGServer sharedServer] state] != PGServerStateUnknown && [[PGServer sharedServer] state] != PGServerStateStopped && [[PGServer sharedServer] state] != PGServerStateError);
}

////////////////////////////////////////////////////////////////////////////////
// Backup methods

-(void)backupToPath:(NSURL* )thePath {
	NSParameterAssert([thePath isFileURL]);
	[[PGServer sharedServer] backupToFolderPath:[thePath path] superPassword:nil];
}

////////////////////////////////////////////////////////////////////////////////
// IBActions

-(IBAction)ibStartButtonPressed:(id)sender {
	[self addLogMessage:[NSString stringWithFormat:@"Starting server with data path: %@",[self dataPath]] color:[NSColor redColor] bold:NO];

	NSLog(@"remoteConnectionAllowed = %d",[self prefRemoteConnectionAllowed]);
	
	
	[[PGServer sharedServer] startWithDataPath:[self dataPath]];
}

-(IBAction)ibStopButtonPressed:(id)sender {
	[[PGServer sharedServer] stop];
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

////////////////////////////////////////////////////////////////////////////////
// Connection preferences

-(IBAction)ibToolbarConnectionPressed:(id)sender {
	// TODO: set state
	// show sheet
	[NSApp beginSheet:[self ibConnectionWindow] modalForWindow:[self ibWindow] modalDelegate:self didEndSelector:@selector(ibToolbarConnectionEndSheet:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction)ibToolbarConnectionSheetClose:(NSButton* )theButton {
	NSParameterAssert([theButton isKindOfClass:[NSButton class]]);
	// Cancel and Restart buttons
	if([[theButton title] isEqualToString:@"Cancel"]) {
		[NSApp endSheet:[theButton window] returnCode:NSCancelButton];
	} else {
		[NSApp endSheet:[theButton window] returnCode:NSOKButton];
	}
}

-(void)ibToolbarConnectionEndSheet:(NSWindow *)theSheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[theSheet orderOut:self];

	NSLog(@"sheet did end: %ld",returnCode);
}

@end
