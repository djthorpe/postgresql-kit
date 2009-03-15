
#import "FLXPostgresConnectWindowController.h"

@implementation FLXPostgresConnectWindowController

////////////////////////////////////////////////////////////////////////////////

@synthesize netServiceBrowser;
@synthesize settings;

////////////////////////////////////////////////////////////////////////////////

-(id)init {
	self = [super init];
	if (self != nil) {
		[self setNetServiceBrowser:[[[NSNetServiceBrowser alloc] init] autorelease]];
		[self setSettings:[NSMutableArray array]];
	}
	return self;
}

-(void)dealloc {
	[self setNetServiceBrowser:nil];
	[self setSettings:nil];
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
	
	// search for postgresql instances
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

////////////////////////////////////////////////////////////////////////////////

-(void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing {
	[settings addObject:[NSDictionary dictionaryWithObject:netService forKey:@"title"]];

	NSLog(@"found service %@",settings);

}

-(void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing {
	NSLog(@"service removed %@",netService);	
}

////////////////////////////////////////////////////////////////////////////////



@end
