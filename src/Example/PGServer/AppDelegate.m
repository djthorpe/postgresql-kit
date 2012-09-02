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

-(IBAction)ibPlayButton:(id)sender {
	NSLog(@"Play button has been pressed");
}

-(IBAction)ibStopButton:(id)sender {
	NSLog(@"Stop button has been pressed");
}

-(IBAction)ibReloadButton:(id)sender {
	NSLog(@"Reload button has been pressed");
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	PGServer* theServer = [PGServer sharedServer];
}

@end
