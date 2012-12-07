
#import "ConnectionPrefs.h"
#import <PGServerKit/PGServerKit.h>
#import "Controller.h"

@implementation ConnectionPrefs

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic port;
@dynamic hostname;

-(NSUInteger)port {
	// check where no port number
	if([[self portValue] length]==0) {
		return 0;
	}
	// retrieve port from portField
	NSUInteger port = [[NSDecimalNumber decimalNumberWithString:[self portValue]] unsignedIntegerValue];
	if(port > 0 && port < 65535) {
		return port;
	} else {
		return 0;
	}
}

-(NSString* )hostname {
	if([self remoteConnectionValue]) {
		return @"*";
	} else {
		return nil;
	}
}

////////////////////////////////////////////////////////////////////////////////

-(IBAction)ibStateChange:(id)sender {
	// set bonjour state to reflect remote connection setting
	if([self remoteConnectionValue]==YES) {
		[self setBonjourEnabled:YES];
	} else {
		[self setBonjourEnabled:NO];
	}
}

-(IBAction)ibPortDefaultButtonPressed:(id)sender {
	// set the port to the default port
	[self setPortValue:[NSString stringWithFormat:@"%lu",PGServerDefaultPort]];
}

-(IBAction)ibBonjourServiceDefaultButtonPressed:(id)sender {
	// what is the default bonjour service value
	NSString* hostName = [[NSProcessInfo processInfo] hostName];
	// set the service name to the default
	[self setBonjourServiceValue:hostName];
}

////////////////////////////////////////////////////////////////////////////////

-(void)readDefaults:(PGServerPreferences* )configuration {
	// port
	NSUInteger port = [configuration port];
	[self setPortValue:[NSString stringWithFormat:@"%lu",port]];
	// hostname
	NSString* hostname = [configuration listenAddresses];
	if([hostname isEqualToString:@"*"]) {
		[self setRemoteConnectionValue:YES];
	} else {
		[self setRemoteConnectionValue:NO];
	}
}

-(void)writeDefaults:(PGServerPreferences* )configuration  {
	// port
	[configuration setPort:[self port]];
	// hostname
	[configuration setListenAddresses:[self hostname]];
}

-(IBAction)ibSheetOpen:(NSWindow* )window delegate:(id)sender {
	PGServerPreferences* prefs = [[self delegate] configuration];
	NSParameterAssert(prefs);

	// load defaults into the dialog
	[self readDefaults:prefs];
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
	PGServerPreferences* prefs = [[self delegate] configuration];
	NSParameterAssert(prefs);
	
	[theSheet orderOut:self];
	
	if(returnCode==NSOKButton) {
		
		[self writeDefaults:prefs];
		
		BOOL success = [prefs save];
		NSParameterAssert(success==YES || success==NO);
#ifdef DEBUG
		if(success==NO) {
			NSLog(@"PGServerPreferences save: save failed");
		}
#endif
		if([[self delegate] respondsToSelector:@selector(restartServer)]){
			[[self delegate] restartServer];
		}
	} else {
		// revert preferences
		BOOL success = [prefs revert];
		NSParameterAssert(success==YES || success==NO);
#ifdef DEBUG
		if(success==NO) {
			NSLog(@"PGServerPreferences revert: revert failed");
		}
#endif
	}
}

/*
// validate port value, make sure it's all numbers
-(void)controlTextDidChange:(NSNotification* )notification {
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
*/

@end
