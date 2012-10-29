#import "ConfigurationPrefs.h"

@implementation ConfigurationPrefs

@dynamic configuration;

-(PGServerPreferences* )configuration {
	return [[PGServer sharedServer] configuration];
}

-(IBAction)ibToolbarConfigurationSheetOpen:(id)sender {
	NSWindow* theParentWindow = [[self appController] ibWindow];
	
	// TODO: Setup the window
	NSLog(@"configuration = %@",[self configuration]);
	
	// begin sheet
	[NSApp beginSheet:[self ibWindow] modalForWindow:theParentWindow modalDelegate:self didEndSelector:@selector(endSheet:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction)ibToolbarConfigurationSheetClose:(id)sender {
	NSParameterAssert([sender isKindOfClass:[NSButton class]]);
	// Cancel and Reload buttons
	if([[(NSButton* )sender title] isEqualToString:@"Cancel"]) {
		[NSApp endSheet:[(NSButton* )sender window] returnCode:NSCancelButton];
	} else {
		[NSApp endSheet:[(NSButton* )sender window] returnCode:NSOKButton];
	}
}

-(void)endSheet:(NSWindow *)theSheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[theSheet orderOut:self];
	if(returnCode==NSOKButton) {
		NSLog(@"OK Button pressed");
	}
}

@end
