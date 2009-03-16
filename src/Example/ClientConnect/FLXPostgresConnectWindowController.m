

#import "FLXPostgresConnectWindowController.h"
#import "FLXPostgresConnectSetting.h"

@implementation FLXPostgresConnectWindowController

////////////////////////////////////////////////////////////////////////////////

@synthesize netServiceBrowser;
@synthesize returnCode;
@synthesize connection;

////////////////////////////////////////////////////////////////////////////////

-(id)init {
	self = [super init];
	if (self != nil) {
		[self setNetServiceBrowser:[[[NSNetServiceBrowser alloc] init] autorelease]];
		[self setConnection:[[[FLXPostgresConnection alloc] init] autorelease]];
		[self setReturnCode:0];
	}
	return self;
}

-(void)dealloc {
	[self setNetServiceBrowser:nil];
	[self setConnection:nil];
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

-(void)beginSheetForWindow:(NSWindow* )mainWindow modalDelegate:(id)theDelegate didEndSelector:(SEL)theSelector {
	NSParameterAssert(mainWindow);
	NSParameterAssert(theDelegate);
	NSParameterAssert(theSelector);
	
	// begin sheet
	NSArray* contextInfo = [NSArray arrayWithObjects:theDelegate,NSStringFromSelector(theSelector),nil];
	[NSApp beginSheet:[self window] modalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:[contextInfo retain]];
	
	// search for postgresql server instances which announce themselves through bonjour
	[[self netServiceBrowser] setDelegate:self];
	[[self netServiceBrowser] searchForServicesOfType:[self bonjourServiceType] inDomain:nil];
}

-(IBAction)doEndSheet:(id)sender {
	[NSApp endSheet:[self window] returnCode:NSOKButton];
}

-(void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)theReturnCode contextInfo:(NSArray* )contextInfo {
	NSParameterAssert(contextInfo);
	NSParameterAssert([contextInfo isKindOfClass:[NSArray class]]);
	NSParameterAssert([contextInfo count] >= 2);
	
	[[self window] orderOut:self];
	[[self netServiceBrowser] stop];
	
	// set connect properties
	FLXPostgresConnectSetting* theSetting = nil;
	if([[settings selectedObjects] count]==0) {
		[self setReturnCode:NSCancelButton];
	} else {
		theSetting = [[settings selectedObjects] objectAtIndex:0];
		NSParameterAssert([theSetting isKindOfClass:[FLXPostgresConnectSetting class]]);
		[self setReturnCode:theReturnCode];		
		[[self connection] setHost:[theSetting host]];
		[[self connection] setUser:[theSetting user]];
		[[self connection] setPort:[theSetting port]];
		[[self connection] setDatabase:[theSetting database]];
	}
	
	// call delegate, passing the connection & password back
	id theDelegate = [contextInfo objectAtIndex:0];
	SEL theSelector = NSSelectorFromString([contextInfo objectAtIndex:1]);
	[theDelegate performSelector:theSelector withObject:[self connection] withObject:[theSetting password]];
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
	FLXPostgresConnectSetting* theSetting = [FLXPostgresConnectSetting settingWithNetService:netService];
	if([[settings arrangedObjects] containsObject:theSetting]==NO) {
		[settings addObject:theSetting];
		NSLog(@"added %@",theSetting);
	}
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing {
	FLXPostgresConnectSetting* theSetting = [FLXPostgresConnectSetting settingWithNetService:netService];
	if([[settings arrangedObjects] containsObject:theSetting]) {
		[settings removeObject:netService];
	}	
}

////////////////////////////////////////////////////////////////////////////////



@end
