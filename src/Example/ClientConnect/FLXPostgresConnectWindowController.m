
#import "FLXPostgresConnectWindowController.h"

@implementation FLXPostgresConnectWindowController

////////////////////////////////////////////////////////////////////////////////

@synthesize netServiceBrowser;

////////////////////////////////////////////////////////////////////////////////

-(id)init {
	self = [super init];
	if (self != nil) {
		[self setNetServiceBrowser:[[[NSNetServiceBrowser alloc] init] autorelease]];
	}
	return self;
}

-(void)dealloc {
	[self setNetServiceBrowser:nil];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////

-(NSString* )windowNibName {
	return @"ConnectPanel";
}

-(NSString* )bonjourServiceType {
	return @"_postgresql._tcp";
}

-(BOOL)isVisible {
	return [[self window] isVisible];
}

////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////

-(void)beginSheetForWindow:(NSWindow* )mainWindow {
	[NSApp beginSheet:[self window] modalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
	
	// search for postgresql server instances which announce themselves through bonjour
	[[self netServiceBrowser] setDelegate:self];
	[[self netServiceBrowser] searchForServicesOfType:[self bonjourServiceType] inDomain:nil];
}

-(IBAction)doEndSheet:(id)sender {
	[NSApp endSheet:[self window] returnCode:NSOKButton];
}

-(void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	[[self window] orderOut:self];
	[[self netServiceBrowser] stop];

	NSLog(@"ended sheet, return code = %d",returnCode);
}

-(IBAction)doAdvancedSettings:(id)sender {
	if([ibAdvancedSettingsButton state]==NSOnState) {
		[ibAdvancedSettingsView setHidden:NO];
		[ibAdvancedSettingsView setNeedsDisplay:YES];
				
		NSRect theNewFrame = [[self window] frame];
		theNewFrame.size.height += 100;
		theNewFrame.origin.y -= 100;
		// resize window
		[[self window] setFrame:theNewFrame display:YES animate:YES];
	} else {
		[ibAdvancedSettingsView setHidden:YES];
		[ibAdvancedSettingsView setNeedsDisplay:YES];
		NSRect theNewFrame = [[self window] frame];
		theNewFrame.size.height -= 100;
		theNewFrame.origin.y += 100;
		// resize window
		[[self window] setFrame:theNewFrame display:YES animate:YES];
	}
}

////////////////////////////////////////////////////////////////////////////////

-(void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing {	
	[settings addObject:netService];
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing {
	[settings removeObject:netService];
}

////////////////////////////////////////////////////////////////////////////////



@end
