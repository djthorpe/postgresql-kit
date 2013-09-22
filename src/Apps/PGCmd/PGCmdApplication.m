
#import "PGCmdApplication.h"

@implementation PGCmdApplication

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[self setView:[[PGConsoleView alloc] init]];
	[[self view] setDelegate:self];
	[[self window] setContentView:[[self view] view]];
	[[self view] setShowGutter:YES];
	[[self view] setEditable:YES];
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
