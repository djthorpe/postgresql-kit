

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

	// hide the advanced settings
	[self doAdvancedSettings:nil];
	
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
	if([[ibSettingsController selectedObjects] count]==0) {
		[self setReturnCode:NSCancelButton];
	} else {
		theSetting = [[ibSettingsController selectedObjects] objectAtIndex:0];
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
	NSButton* ibAdvancedSettingsButton = [[[self window] contentView] viewWithTag:-1002];
	NSView* ibAdvancedSettingsView = [[[self window] contentView] viewWithTag:-1001];	
	NSRect theNewFrame = [[self window] frame];
	if([ibAdvancedSettingsButton state] != NSOnState) {
		[ibAdvancedSettingsButton setState:NSOffState];
		if([ibAdvancedSettingsView isHidden]==NO) {
			[ibAdvancedSettingsView setHidden:YES];
			theNewFrame.size.height -= 100;
			theNewFrame.origin.y += 100;
		}
	} else {
		[ibAdvancedSettingsButton setState:NSOnState];
		if([ibAdvancedSettingsView isHidden]==YES) {
			[ibAdvancedSettingsView setHidden:NO];
			theNewFrame.size.height += 100;
			theNewFrame.origin.y -= 100;
		}
	}
	// resize window
	[[self window] setFrame:theNewFrame display:YES animate:YES];
}

////////////////////////////////////////////////////////////////////////////////

-(void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing {	
	FLXPostgresConnectSetting* theSetting = [FLXPostgresConnectSetting settingWithNetService:netService];
	if([[ibSettingsController arrangedObjects] containsObject:theSetting]==NO) {
		[ibSettingsController addObject:theSetting];
	}
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing {
	FLXPostgresConnectSetting* theSetting = [FLXPostgresConnectSetting settingWithNetService:netService];
	if([[ibSettingsController arrangedObjects] containsObject:theSetting]) {
		[ibSettingsController removeObject:theSetting];
	}	
}

////////////////////////////////////////////////////////////////////////////////



@end
