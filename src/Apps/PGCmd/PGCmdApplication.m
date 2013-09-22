
#import "PGCmdApplication.h"

@implementation PGCmdApplication

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[self setConsole:[[PGConsoleView alloc] init]];
	// set up the console
	[[self console] setDelegate:self];
	[[self console] setEditable:YES];
	
	// set the content view of the window
	[[self window] setContentView:[[self console] view]];
	
	// set focus
	[[self window] makeFirstResponder:[[self console] view]];
}

-(NSUInteger)numberOfRowsInConsoleView:(PGConsoleView* )view {
	return 20;
}

-(NSString* )consoleView:(PGConsoleView* )view stringForRow:(NSUInteger)row {
	return [NSString stringWithFormat:@"Line number %lu",row];
}

-(void)consoleView:(PGConsoleView* )view appendString:(NSString* )string {
	NSLog(@"append %@",string);
}

@end
