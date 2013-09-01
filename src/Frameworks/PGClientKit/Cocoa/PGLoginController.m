
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
	return [NSURL URLWithString:[self ibURL]];
}

-(NSUInteger)timeout {
	return 0;
}

-(void)setLoginStatus:(NSString* )status {
	if(status==nil) {
		[self setIbURL:nil];
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
	[self _loadDefaults];

	[NSApp beginSheet:[self window] modalForWindow:window modalDelegate:self didEndSelector:@selector(_endSheet:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction)ibEndLoginSheetForButton:(id)sender {
	NSParameterAssert([sender isKindOfClass:[NSButton class]]);
	if([[(NSButton* )sender title] isEqualToString:@"Cancel"]) {
		// Cancel button pressed, immediately quit
		[NSApp endSheet:[(NSButton* )sender window] returnCode:NSCancelButton];
	} else {
		[self setLoginStatus:@"Logging in"];
		[self _doConnection];
	}
}

-(void)_endSheet:(NSWindow *)theSheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[theSheet orderOut:self];
	if(returnCode != NSOKButton) {
		[[self delegate] loginCompleted:returnCode];
	} else {
		[[self delegate] loginCompleted:returnCode];
		[self _saveDefaults];
	}
}

-(void)_doConnection {
	NSParameterAssert([[self connection] status] != PGConnectionStatusConnected);
	[[self connection] connectInBackgroundWithURL:[self url] whenDone:^(NSError* error) {
		if([error code]==PGClientErrorNone) {
			// end sheet
			[NSApp endSheet:[self window] returnCode:NSOKButton];
		} else {
			[self setLoginStatus:[error localizedDescription]];
			[self setIbStatusAnimate:NO];
		}
	}];
}

-(void)_saveDefaults {
	if([self ibRememberCheckbox]==YES) {
		[[NSUserDefaults standardUserDefaults] setURL:[self url] forKey:@"url"];
	} else {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];
	}
}

-(void)_loadDefaults {
	NSURL* theURL = [[NSUserDefaults standardUserDefaults] URLForKey:@"url"];
	if(theURL) {
		[self setIbURL:[theURL absoluteString]];
		[self setIbRememberCheckbox:YES];
	} else {
		[self setIbURL:nil];
		[self setIbRememberCheckbox:NO];
	}
}

@end
