
#import "PGControlsKit.h"
#import "PGControlsKit+Private.h"

@implementation PGPasswordWindow

////////////////////////////////////////////////////////////////////////////////
// initializers

-(NSString* )windowNibName {
	return @"PGPasswordWindow";
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(void)beginSheetForParentWindow:(NSWindow* )parentWindow contextInfo:(void* )contextInfo {
	// set parameters
	[self setPasswordField:@""];
	[self setSaveToKeychain:YES];
	// start sheet
	[NSApp beginSheet:[self window] modalForWindow:parentWindow modalDelegate:self didEndSelector:@selector(_endSheet:returnCode:contextInfo:) contextInfo:contextInfo];
}

-(void)_endSheet:(NSWindow *)theSheet returnCode:(NSInteger)returnCode contextInfo:(void* )contextInfo {
	// remove sheet
	[theSheet orderOut:self];
	// perform action
	[[self delegate] passwordWindow:self endedWithStatus:returnCode contextInfo:contextInfo];
}

////////////////////////////////////////////////////////////////////////////////
// ibactions

-(IBAction)ibEndSheetForButton:(id)sender {
	NSParameterAssert([sender isKindOfClass:[NSButton class]]);
	if([[(NSButton* )sender title] isEqualToString:@"Cancel"]) {
		// Cancel button pressed, immediately quit
		[NSApp endSheet:[(NSButton* )sender window] returnCode:NSCancelButton];
	} else {
		// Do something here
		[NSApp endSheet:[(NSButton* )sender window] returnCode:NSOKButton];
	}
}


@end
