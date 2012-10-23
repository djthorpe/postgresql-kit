
#import "AppDelegate.h"

@implementation AppDelegate

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[self setLoginController:[[PGLoginController alloc] init]];
}

-(IBAction)doLogin:(id)sender {
	[[self loginController] beginLoginSheetForWindow:[self window]];
}


@end
