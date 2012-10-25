
#import "AppDelegate.h"

@implementation AppDelegate

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[self setLoginController:[[PGLoginController alloc] init]];
	[[self loginController] setDelegate:self];
}

-(IBAction)doLogin:(id)sender {
	if([[[self loginController] connection] status] == PGConnectionStatusConnected) {
		[[[self loginController] connection] disconnect];		
	}
	[[self loginController] beginLoginSheetForWindow:[self window]];
}

-(void)loginCompleted:(NSInteger)returnCode {
	NSLog(@"Login done, return code = %ld",returnCode);
}

@end
