
#import "ConnectionPreferences.h"

@implementation ConnectionPreferences
@synthesize ibMainWindow;
@synthesize ibConnectionWindow;
@synthesize ibAppDelegate;
@dynamic server;
@synthesize isAllowRemoteConnections;
@synthesize isCustomPort;
@synthesize selectedPortOption;
@synthesize port;

////////////////////////////////////////////////////////////////////////////////
// properties

-(FLXPostgresServer* )server {
	return [FLXPostgresServer sharedServer];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(void)setButtonStates {
	// set button state - isDefaultPort
	if([self port]==[FLXPostgresServer defaultPort]) {
		[self setSelectedPortOption:0];
		[self setIsCustomPort:NO];
	} else {
		[self setIsCustomPort:YES];
		[self setSelectedPortOption:1];
	}	
}	

-(void)preferencesDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[sheet orderOut:self];	
	
	if(returnCode==NSOKButton) {
		// if OK, then apply these new values
		[[self server] setPort:[self port]];
		if([self isAllowRemoteConnections]) {
			[[self server] setHostname:@"*"];
		} else {
			[[self server] setHostname:@""];			
		}
		
		// restart the server
		[[self ibAppDelegate] setIsServerRestarting:YES];
		
	} else {
		// else obtain them from server again
		[self setPort:[[self server] port]];
		if([[[self server] hostname] length]) {
			[self setIsAllowRemoteConnections:YES];			
		} else {			
			[self setIsAllowRemoteConnections:NO];
		}
	}
}

////////////////////////////////////////////////////////////////////////////////
// IBActions

-(IBAction)doConnectionPreferences:(id)sender {

	// reset window state
	[[self ibConnectionWindow] endEditingFor:nil];
	[[self ibConnectionWindow] makeFirstResponder:nil];
	
	// set port
	[self setPort:[[self server] port]];
	if([[self server] hostname]==nil) {
		[self setIsAllowRemoteConnections:NO];
	} else {
		[self setIsAllowRemoteConnections:YES];		
	}	
	
	// set the "is default or custom port"
	[self setButtonStates];

	// view the sheet
	[NSApp beginSheet:[self ibConnectionWindow] modalForWindow:[self ibMainWindow] modalDelegate:self didEndSelector:@selector(preferencesDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction)doButton:(id)sender {
	NSButton* theButton = (NSButton* )sender;
	NSParameterAssert([theButton isKindOfClass:[NSButton class]]);
	
	[[self ibConnectionWindow] endEditingFor:nil];
	
	if([[theButton title] isEqual:@"Restart"]) {
		[NSApp endSheet:[self ibConnectionWindow] returnCode:NSOKButton];
	} else {
		[NSApp endSheet:[self ibConnectionWindow] returnCode:NSCancelButton];
	}
}

-(IBAction)doPortRadioButton:(id)sender {
	if([self selectedPortOption]==1) {
		[self setIsCustomPort:YES];
	} else {
		[self setIsCustomPort:NO];
		[self setPort:[FLXPostgresServer defaultPort]];
	}
}

@end
