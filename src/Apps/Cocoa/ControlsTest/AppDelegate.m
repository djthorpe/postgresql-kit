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
@property (weak) IBOutlet NSWindow* window;
@property (retain) PGConnection* connection;
@property (retain) PGConnectionWindowController* connectionWindow;
@property (retain) NSURL* url;
@property (readonly) NSString* urlstring;
@end

@implementation AppDelegate

@dynamic urlstring;

-(NSString* )urlstring {
	return [[self url] absoluteString];
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// create connection class
	[self setConnection:[PGConnection new]];
	[self setConnectionWindow:[PGConnectionWindowController new]];
	// get user default for url
	NSString* url = [[NSUserDefaults standardUserDefaults] objectForKey:@"url"];
	if(url) {
		[super willChangeValueForKey:@"urlstring"];
		[self setUrl:[NSURL URLWithString:url]];
		[super didChangeValueForKey:@"urlstring"];
	}
}

-(void)applicationWillTerminate:(NSNotification *)aNotification {
	[[self connection] disconnect];
}

-(void)handleLoginError:(NSError* )error {
	if([[error domain] isEqualToString:PGClientErrorDomain] && [error code]==PGClientErrorNeedsPassword) {
		[[self connectionWindow] beginPasswordSheetWithParentWindow:[self window] whenDone:^(NSString* password, BOOL useKeychain) {
			NSLog(@"SAVE PASSWORD: %@",error);
		}];
		return;
	}

	[[self connectionWindow] beginErrorSheetWithError:error parentWindow:[self window] whenDone:^(NSModalResponse response) {
		if(response==NSModalResponseContinue) {
			[self doCreateConnectionURL:nil];
		}
	}];

}

-(IBAction)doCreateConnectionURL:(id)sender {
	[[self connectionWindow] beginConnectionSheetWithURL:[self url] parentWindow:[self window] whenDone:^(NSURL *url) {
		if(url) {
			// set the URL
			[super willChangeValueForKey:@"urlstring"];
			[self setUrl:url];
			[super didChangeValueForKey:@"urlstring"];

			// save URL
			[[NSUserDefaults standardUserDefaults] setObject:[[self url] absoluteString] forKey:@"url"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
	}];
}

-(IBAction)doCustomWindow:(id)sender {
	[[self connectionWindow] loadWindow];

	NSView* view = [[self connectionWindow] ibCreateRoleView];
	[[self connectionWindow] beginCustomSheetWithTitle:@"Create new role" description:nil view:view parentWindow:[self window] whenDone:^(NSModalResponse response) {
		NSLog(@"DONE, RESPONSE = %ld",response);
	}];
}

-(IBAction)doLogin:(id)sender {
	if([self url]) {
		[[self connection] connectWithURL:[self url] whenDone:^(BOOL usedPassword, NSError *error) {
			if(error) {
				[self handleLoginError:error];
			}
		}];
	}
}

-(IBAction)doLogout:(id)sender {
	[[self connection] disconnect];
}

@end
