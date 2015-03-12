//
//  AppDelegate.m
//  ControlsTest
//
//  Created by David Thorpe on 12/03/2015.
//
//

#import "AppDelegate.h"
#import <PGControlsKit/PGControlsKit.h>

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}


-(IBAction)doCreateConnectionURL:(id)sender {
	PGConnectionWindowController* controller = [PGConnectionWindowController new];
	[controller beginConnectionSheetWithURL:nil parentWindow:[self window] whenDone:^(NSURL *url) {
		NSLog(@"GOT URL: %@",url);
	}];
}

@end
