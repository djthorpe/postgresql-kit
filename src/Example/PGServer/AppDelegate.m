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


-(void)pgserverMessage:(NSString* )theMessage {
	[self setMessage:theMessage];
}

-(void)pgserverState:(PGServerState)theState {	
	[self setMessage:[PGServer stateAsString:theState]];

	if(theState==PGServerStateRunning || theState==PGServerStateAlreadyRunning) {
		[self setStartButtonEnabled:NO];
		[self setStopButtonEnabled:YES];
		[self setReloadButtonEnabled:YES];
	} else if(theState==PGServerStateStopped) {
		[self setStartButtonEnabled:YES];
		[self setStopButtonEnabled:NO];
		[self setReloadButtonEnabled:NO];
	} else if(theState==PGServerStateStarting || theState==PGServerStateInitialize || theState==PGServerStateStopping) {
		[self setStartButtonEnabled:NO];
		[self setStopButtonEnabled:NO];
		[self setReloadButtonEnabled:NO];
	} else {
		[self setStartButtonEnabled:YES];
		[self setStopButtonEnabled:YES];
		[self setReloadButtonEnabled:YES];
	}
}

-(void)awakeFromNib {
	[[PGServer sharedServer] setDelegate:self];
}

-(NSString* )dataPath {
	NSString* theIdent = @"PostgreSQL";
	NSArray* theApplicationSupportDirectory = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask, YES);
	NSParameterAssert([theApplicationSupportDirectory count]);
	return [[theApplicationSupportDirectory objectAtIndex:0] stringByAppendingPathComponent:theIdent];
}

-(IBAction)ibPlayButton:(id)sender {
	[[PGServer sharedServer] startWithDataPath:[self dataPath]];
}

-(IBAction)ibStopButton:(id)sender {
	[[PGServer sharedServer] stop];
}

-(IBAction)ibReloadButton:(id)sender {
	[[PGServer sharedServer] reload];
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	PGServer* theServer = [PGServer sharedServer];
	[self setMessage:[theServer version]];
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

@end
