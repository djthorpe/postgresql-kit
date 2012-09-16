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
		[self setStartButtonEnabled:NO];
		[self setStopButtonEnabled:YES];
		[self setReloadButtonEnabled:YES];
		[self setBackupButtonEnabled:YES];
	} else if([sender state]==PGServerStateStopped) {
		[self setStartButtonEnabled:YES];
		[self setStopButtonEnabled:NO];
		[self setReloadButtonEnabled:NO];
		[self setBackupButtonEnabled:NO];
	} else if([sender state]==PGServerStateStarting || [sender state]==PGServerStateInitialize || [sender state]==PGServerStateStopping) {
		[self setStartButtonEnabled:NO];
		[self setStopButtonEnabled:NO];
		[self setReloadButtonEnabled:NO];
		[self setBackupButtonEnabled:NO];
	} else {
		[self setStartButtonEnabled:YES];
		[self setStopButtonEnabled:YES];
		[self setReloadButtonEnabled:YES];
		[self setBackupButtonEnabled:NO];
	}
}

////////////////////////////////////////////////////////////////////////////////
// Application signals

-(void)awakeFromNib {
	[[PGServer sharedServer] setDelegate:self];
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	PGServer* theServer = [PGServer sharedServer];
	[self addLogMessage:[theServer version] color:[NSColor greenColor] bold:YES];
	[self setStartButtonEnabled:YES];
	[self setStopButtonEnabled:NO];
	[self setReloadButtonEnabled:NO];
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

-(IBAction)ibPlayButton:(id)sender {
	[self addLogMessage:[NSString stringWithFormat:@"Starting with data path: %@",[self dataPath]] color:[NSColor redColor] bold:NO];
	[[PGServer sharedServer] startWithDataPath:[self dataPath]];
}

-(IBAction)ibStopButton:(id)sender {
	[[PGServer sharedServer] stop];
}

-(IBAction)ibReloadButton:(id)sender {
	[[PGServer sharedServer] reload];
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

@end
