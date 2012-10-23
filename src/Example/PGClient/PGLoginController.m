
#import "PGLoginController.h"

@implementation PGLoginController

-(id)init {
	self = [super init];
	if(self) {
		[self setConnection:[[PGConnection alloc] init]];
	}
	return self;
}

-(NSString* )windowNibName {
	return @"PGLoginController";
}

-(NSURL* )url {
	return [NSURL URLWithString:@"pgsql://postgres@/"];
}

-(NSUInteger)timeout {
	return 0;
}

-(void)setLoginStatus:(NSString* )status {
	if(status==nil) {
		// make status hidden
		[self setIbStatusVisibility:YES];
		[self setIbStatusText:@""];
		[self setIbStatusAnimate:NO];
	} else {
		[self setIbStatusVisibility:NO];
		[self setIbStatusText:status];
		[self setIbStatusAnimate:YES];
	}
}

-(void)beginLoginSheetForWindow:(NSWindow* )window {
	NSParameterAssert([window isKindOfClass:[NSWindow class]]);
	NSParameterAssert([self delegate]);
	NSParameterAssert([[self connection] status] != PGConnectionStatusConnected);

	[self setLoginStatus:nil];

	[NSApp beginSheet:[self window] modalForWindow:window modalDelegate:self didEndSelector:@selector(_endSheet:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction)ibEndLoginSheetForButton:(id)sender {
	NSParameterAssert([sender isKindOfClass:[NSButton class]]);
	if([[(NSButton* )sender title] isEqualToString:@"Cancel"]) {
		// Cancel button pressed
		[NSApp endSheet:[(NSButton* )sender window] returnCode:NSCancelButton];
	} else {
		[self setLoginStatus:@"Logging in"];
		[[self connection] connectInBackgroundWithURL:[self url] timeout:[self timeout] whenDone:^(PGConnectionStatus status,NSError* error){
			[NSApp endSheet:[(NSButton* )sender window] returnCode:NSOKButton];
		}];
	}
}

-(void)_endSheet:(NSWindow *)theSheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[theSheet orderOut:self];
	if(returnCode != NSOKButton) {
		[[self delegate] loginCompleted:returnCode];
	} else {
		[[self delegate] loginCompleted:returnCode];
	}
}

@end
