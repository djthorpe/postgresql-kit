
#import "AppDelegate.h"
#import "PGTabView.h"

@interface AppDelegate ()
@property (weak) IBOutlet NSWindow* window;
@property (weak) IBOutlet PGTabView* tabView;
@end

@implementation AppDelegate

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSParameterAssert([self tabView]);

	[[self tabView] addTabViewWithTitle:@"First Tab"];
	[[self tabView] addTabViewWithTitle:@"Second Tab"];
	
}

-(void)applicationWillTerminate:(NSNotification *)aNotification {

}

-(IBAction)doAddTab:(id)sender {
	[[self tabView] addTabViewWithTitle:@"TAB"];
}

@end
