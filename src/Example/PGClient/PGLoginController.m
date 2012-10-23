
#import "PGLoginController.h"

@implementation PGLoginController

-(NSString* )windowNibName {
	return @"PGLoginController";
}

-(void)beginLoginSheetForWindow:(NSWindow* )window {
	NSParameterAssert([window isKindOfClass:[NSWindow class]]);
	// TODO: Setup the window
	[NSApp beginSheet:[self window] modalForWindow:window modalDelegate:self didEndSelector:@selector(_endSheet:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction)ibEndLoginSheetForButton:(id)sender {
	NSParameterAssert([sender isKindOfClass:[NSButton class]]);
	if([[(NSButton* )sender title] isEqualToString:@"Cancel"]) {
		// Cancel button pressed
		[NSApp endSheet:[(NSButton* )sender window] returnCode:NSCancelButton];
	} else {
		// Login button pressed
		[NSApp endSheet:[(NSButton* )sender window] returnCode:NSOKButton];
	}
}

-(void)_endSheet:(NSWindow *)theSheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[theSheet orderOut:self];
	if(returnCode==NSOKButton) {
		NSLog(@"OK Button pressed");
	} else {
		NSLog(@"Cancel Button pressed");
	}
}

@end
