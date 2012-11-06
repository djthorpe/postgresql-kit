
#import "ConnectionPrefs.h"
#import <PGServerKit/PGServerKit.h>
#import "AppDelegate.h"

@implementation ConnectionPrefs

-(void)readDefaults {
	// retrieve defaults
	NSUserDefaults* theDefaults = [NSUserDefaults standardUserDefaults];
	[self setAllowRemoteConnections:[theDefaults boolForKey:@"allowRemoteConnections"]];
	[self setPortField:[theDefaults stringForKey:@"port"]];

	// update UX to display correct state
	[self updateDisplayOptions];
}

-(void)writeDefaults {
	// retrieve defaults
	NSUserDefaults* theDefaults = [NSUserDefaults standardUserDefaults];
	[theDefaults setBool:[self allowRemoteConnections] forKey:@"allowRemoteConnections"];
	[theDefaults setObject:[self portField] forKey:@"port"];
	[theDefaults synchronize];
}

-(NSUInteger)port {
	// check where no port number
	if([[self portField] length]==0) {
		return 0;
	}
	// retrieve port from portField
	NSUInteger port = [[NSDecimalNumber decimalNumberWithString:[self portField]] unsignedIntegerValue];
	if(port > 0 && port < 65535) {
		return port;
	} else {
		return 0;
	}
}

-(NSString* )hostname {
	if([self allowRemoteConnections]) {
		return @"*";
	} else {
		return nil;
	}
}

-(void)updateDisplayOptions {
	if([self allowRemoteConnections]==NO) {
		[self setSelectedPortOption:0];
		[self setPortField:nil];
		[self setLastPortField:[self portField]];
		[self setPortEditable:NO];
		[self setCustomPortEditable:NO];
	} else if([self selectedPortOption]==0) {
		// Use default port
		[self setPortField:[NSString stringWithFormat:@"%lu",PGServerDefaultPort]];
		[self setLastPortField:[self portField]];
		[self setCustomPortEditable:NO];
		[self setPortEditable:YES];
	} else {
		// Use custom port
		[self setCustomPortEditable:YES];
		[self setPortEditable:YES];
		[self setLastPortField:[self portField]];
	}
}

-(IBAction)ibConnectionChangeState:(id)sender {
	[self updateDisplayOptions];
}

-(IBAction)ibSetDefaultCustomPort:(id)sender {
	[self updateDisplayOptions];
}

-(IBAction)ibSheetOpen:(NSWindow* )window delegate:(id)sender {
	// set state of window from defaults
	[self readDefaults];
	[self updateDisplayOptions];
	// set the sender
	[self setDelegate:sender];
	// begin the sheet
	[NSApp beginSheet:[self ibWindow] modalForWindow:window modalDelegate:self didEndSelector:@selector(endSheet:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction)ibToolbarConnectionSheetClose:(NSButton* )theButton {
	NSParameterAssert([theButton isKindOfClass:[NSButton class]]);
	// Cancel and Restart buttons
	if([[theButton title] isEqualToString:@"Cancel"]) {
		[NSApp endSheet:[theButton window] returnCode:NSCancelButton];
	} else {
		[NSApp endSheet:[theButton window] returnCode:NSOKButton];
	}
}

-(void)endSheet:(NSWindow *)theSheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[theSheet orderOut:self];
	if(returnCode==NSOKButton) {
		[self writeDefaults];
		if([[self delegate] respondsToSelector:@selector(restartServer)]){
			[[self delegate] restartServer];
		}
	}
}

// validate port value, make sure it's all numbers
-(void)controlTextDidChange:(NSNotification *)notification {
	if([notification object] != [self ibCustomPort]) {
		return;
	}
	NSString* value = [[self ibCustomPort] stringValue];
	if([value length]==0) {
		return;
	} else if([value integerValue] > 0) {
		[self setLastPortField:[[self ibCustomPort] stringValue]];
	} else {
		[[self ibCustomPort] setStringValue:[self lastPortField]];
		NSBeep();
	}
}


@end
