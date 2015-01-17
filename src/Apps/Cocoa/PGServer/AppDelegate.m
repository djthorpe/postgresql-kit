
#import "AppDelegate.h"
#import "NSWindow+ResizeAdditions.h"
#import "ViewController.h"

#import "LogViewController.h"
#import "ConnectionViewController.h"
#import "ConnectionsViewController.h"
#import "UsersRolesViewController.h"
#import "DatabaseViewController.h"

NSString* PGServerMessageNotificationError = @"PGServerMessageNotificationError";
NSString* PGServerMessageNotificationWarning = @"PGServerMessageNotificationWarning";
NSString* PGServerMessageNotificationFatal = @"PGServerMessageNotificationFatal";
NSString* PGServerMessageNotificationInfo = @"PGServerMessageNotificationInfo";

const NSInteger PGServerButtonCancel = 100;
const NSInteger PGServerButtonConnections = 200;
const NSInteger PGServerButtonContinue = 300;
const NSInteger PGServerMenuTagStart = 1;
const NSInteger PGServerMenuTagStop = 2;
const NSInteger PGServerMenuTagReload = 3;
const NSInteger PGServerMenuTagRestart = 4;

@implementation AppDelegate

////////////////////////////////////////////////////////////////////////////////
#pragma mark Initialization
////////////////////////////////////////////////////////////////////////////////

-(id)init {
    self = [super init];
    if (self) {
        _views = [[NSMutableDictionary alloc] init];
		_connection = [[PGConnection alloc] init];
		_server = [PGServer serverWithDataPath:[self _dataPath]];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Properties
////////////////////////////////////////////////////////////////////////////////

@synthesize server = _server;
@synthesize connection = _connection;
@synthesize preferences = _preferences;
@synthesize mainWindow = _mainWindow;
@synthesize uptimeString;
@synthesize versionString;
@synthesize buttonText;

////////////////////////////////////////////////////////////////////////////////
#pragma mark Private methods
////////////////////////////////////////////////////////////////////////////////

-(NSString* )_dataPath {
	NSString* theIdent = @"PostgreSQL";
	NSArray* theApplicationSupportDirectory = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask, YES);
	NSParameterAssert([theApplicationSupportDirectory count]);
	return [[theApplicationSupportDirectory objectAtIndex:0] stringByAppendingPathComponent:theIdent];
}


-(void)_addViewController:(ViewController* )viewController {
	// set delegate
	[viewController setDelegate:self];
	// add tab to tab view
	NSTabViewItem* item = [[NSTabViewItem alloc] initWithIdentifier:[viewController identifier]];
	[item setView:[viewController view]];
	[_tabView addTabViewItem:item];
	[_views setObject:viewController forKey:[viewController identifier]];
}

-(void)_toolbarSelectItemWithIdentifier:(NSString* )identifier {
	[[_mainWindow toolbar] setSelectedItemIdentifier:identifier];
	for(NSToolbarItem* item in [[_mainWindow toolbar] items]) {
		if([[item itemIdentifier] isEqual:identifier]) {
			[self ibToolbarItemClicked:item];
		}
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Awake from NIB file
////////////////////////////////////////////////////////////////////////////////

-(void)awakeFromNib {
	// add the views
	[self _addViewController:[[LogViewController alloc] init]];
	[self _addViewController:[[ConnectionViewController alloc] init]];
	[self _addViewController:[[ConnectionsViewController alloc] init]];
	[self _addViewController:[[UsersRolesViewController alloc] init]];
	[self _addViewController:[[DatabaseViewController alloc] init]];
		
	// switch toolbar to log
	[self _toolbarSelectItemWithIdentifier:@"log"];
	
	// set server delegate
	[[self server] setDelegate:self];
	
	// set the uptime and server strings
	[self setUptimeString:@""];
	[self setVersionString:[[self server] version]];
	
	// set button state, server status
	[self _setButtonState:[[self server] state]];
	[self _setServerStatus:[[self server] state]];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Set UI State
////////////////////////////////////////////////////////////////////////////////

-(void)_setButtonState:(PGServerState)state {
	switch(state) {
		case PGServerStateRunning:
		case PGServerStateAlreadyRunning:
			[self setButtonText:@"Stop"];
			[self setButtonEnabled:YES];
			[self setButtonImage:[NSImage imageNamed:@"green"]];
			break;
		case PGServerStateStopped:
		case PGServerStateUnknown:
			[self setButtonText:@"Start"];
			[self setButtonEnabled:YES];
			[self setButtonImage:[NSImage imageNamed:@"red"]];
			break;
		default:
			[self setButtonEnabled:NO];
			[self setButtonImage:[NSImage imageNamed:@"yellow"]];			
			break;
	}
}

-(void)_setStatusString:(PGServerState)state {
	switch(state) {
		case PGServerStateRunning:
		case PGServerStateAlreadyRunning:
			[self setStatusString:@"Running"];
			break;
		case PGServerStateUnknown:
			[self setStatusString:@""];
			break;
		case PGServerStateStopped:
			[self setStatusString:@"Stopped"];
			break;
		case PGServerStateInitializing:
			[self setStatusString:@"Initializing"];
			break;
		case PGServerStateError:
			[self setStatusString:@"Error starting"];
			break;
		case PGServerStateStopping:
			[self setStatusString:@"Stopping"];
			break;
		case PGServerStateStarting:
			[self setStatusString:@"Starting"];
			break;
		default:
			break;
	 }
}

-(void)_setConnection:(PGServerState)state {
	switch(state) {
		case PGServerStateRunning:
			if([[self connection] status] != PGConnectionStatusConnected) {
#ifdef DEBUG
				NSLog(@"PGConnection Connecting to server");
#endif
				NSError* theError = nil;
				// TODO!!!!
				NSURL* theURL = [NSURL URLWithString:@"pgsql://postgres@/"];
				BOOL isSuccess = [[self connection] connectWithURL:theURL error:&theError];
				if(isSuccess==NO) {
					NSString* message = [NSString stringWithFormat:@"Connection error: %@",[theError description]];
					[[NSNotificationCenter defaultCenter] postNotificationName:PGServerMessageNotificationError object:message];
				}
			}
			break;
		case PGServerStateStopping:
		case PGServerStateRestart:
			if([[self connection] status]==PGConnectionStatusConnected) {
#ifdef DEBUG
				NSLog(@"PGConnection Disconnecting from server");
#endif
				[[self connection] disconnect];
			}
			break;
		default:
			break;
	}
	
	switch([[self connection] status]) {
		case PGConnectionStatusConnected:
			[self setClientConnected:YES];
			break;
		default:
			[self setClientConnected:NO];
			break;			
	}
}

-(void)_setServerStatus:(PGServerState)state {
	// set serverRunning state
	if(state==PGServerStateAlreadyRunning || state==PGServerStateRunning) {
		[self setServerRunning:YES];
	} else {
		[self setServerRunning:NO];
	}
	
	// set serverStopped state
	if(state==PGServerStateUnknown || state==PGServerStateStopped) {
		[self setServerStopped:YES];
	} else {
		[self setServerStopped:NO];
	}
}

-(void)_setDockIcon {
	// Dock Icon shows badge
	NSDockTile* dockIcon = [[NSApplication sharedApplication] dockTile];
	if([self serverRunning]) {
		[dockIcon setBadgeLabel:[NSString stringWithFormat:@"%ld",[self numberOfConnections]]];
	} else {
		[dockIcon setBadgeLabel:nil];
	}
}

-(void)_setUptimeString:(PGServerState)state {
	if(state==PGServerStateRunning || state==PGServerStateAlreadyRunning) {
		NSTimeInterval uptime = [[self server] uptime];
		if(uptime < 1.0) {
			[self setUptimeString:@""];
		} else if(uptime < 60.0) {
			[self setUptimeString:[NSString stringWithFormat:@"Uptime: %lu secs",(NSUInteger)uptime]];
		} else if(uptime < 3600.0) {
			[self setUptimeString:[NSString stringWithFormat:@"Uptime: %lu mins",(NSUInteger)(uptime / 60.0)]];
		} else {
			[self setUptimeString:[NSString stringWithFormat:@"Uptime: %lu hours",(NSUInteger)(uptime / 3600.0)]];
		}
	} else {
		[self setUptimeString:@""];
	}
}

-(void)_setNumberOfConnections:(PGServerState)state {
	if(state != PGServerStateRunning && state != PGServerStateAlreadyRunning) {
		[self setNumberOfConnections:0];
		return;
	}
	if([[self connection] status] != PGConnectionStatusConnected) {
		[self setNumberOfConnections:0];
		return;
	}
	NSError* error = nil;
	PGResult* result = [[self connection] execute:NSLocalizedStringFromTable(@"PGServerNumberOfConnections",@"SQL",@"")
										   format:PGClientTupleFormatBinary
											error:&error];
	if(error || result==nil) {
#ifdef DEBUG
		NSLog(@"_numberOfConnections: Error: %@",error);
#endif
		[self setNumberOfConnections:0];
		return;
	}
	if([result dataReturned]==NO) {
		[self setNumberOfConnections:0];
		return;
	}
	
	NSParameterAssert([result size]==1);
	NSParameterAssert([result numberOfColumns]==1);
	NSArray* row = [result fetchRowAsArray];
	NSNumber* numConnections = [row objectAtIndex:0];
	NSParameterAssert([numConnections isKindOfClass:[NSNumber class]]);
	[self setNumberOfConnections:[numConnections unsignedIntegerValue]];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Start, Stop, Reload and Restart server
////////////////////////////////////////////////////////////////////////////////

-(void)_doServerStop:(id)sender {
	PGServerState state = [[self server] state];
	switch(state) {
		case PGServerStateRunning:
		case PGServerStateAlreadyRunning:
			[self _setNumberOfConnections:state];
			if([self numberOfConnections] > 0) {
				// confirm stopping
				[self ibConfirmCloseStartSheet:sender];
			} else {
				// switch to logging pane
				[self _toolbarSelectItemWithIdentifier:@"log"];
				// stop the server
				[[self server] stop];
			}
			break;
		default:
#ifdef DEBUG
			NSLog(@"_doServerStop: wrong state: %@: sender: %@",[PGServer stateAsString:state],sender);
#endif		
			break;
	}
}

-(void)_doServerStart:(id)sender {
	PGServerState state = [[self server] state];
	switch(state) {
		case PGServerStateUnknown:
		case PGServerStateStopped:
			// start the server
			[[self server] start];
			// switch to logging pane
			[self _toolbarSelectItemWithIdentifier:@"log"];
			break;
		default:
#ifdef DEBUG
			NSLog(@"_doServerStart: wrong state: %@: sender: %@",[PGServer stateAsString:state],sender);
#endif
			break;
	}
}

-(void)_doServerRestart:(id)sender {
	PGServerState state = [[self server] state];
	switch(state) {
		case PGServerStateRunning:
		case PGServerStateAlreadyRunning:
			[self _setNumberOfConnections:state];
			if([self numberOfConnections] > 0) {
				// confirm stopping
				[self ibConfirmCloseStartSheet:sender];
			} else {
				// switch to logging pane
				[self _toolbarSelectItemWithIdentifier:@"log"];
				// restart the server
				[[self server] restart];
			}
			break;
		default:
#ifdef DEBUG
			NSLog(@"_doServerRestart: wrong state: %@: sender: %@",[PGServer stateAsString:state],sender);
#endif
			break;
	}	
}

-(void)_doServerReload:(id)sender {
	PGServerState state = [[self server] state];
	switch(state) {
		case PGServerStateRunning:
		case PGServerStateAlreadyRunning:
			// switch to logging pane
			[self _toolbarSelectItemWithIdentifier:@"log"];
			// reload the server
			[[self server] reload];
			break;
		default:
#ifdef DEBUG
			NSLog(@"_doServerReload: wrong state: %@: sender: %@",[PGServer stateAsString:state],sender);
#endif
			break;
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Confirm Server Stop/Restart
////////////////////////////////////////////////////////////////////////////////

-(IBAction)ibConfirmCloseStartSheet:(id)sender {
	[NSApp beginSheet:_closeConfirmSheet modalForWindow:_mainWindow modalDelegate:self didEndSelector:@selector(_endCloseConfirmSheet:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction)ibConfirmCloseSheetForButton:(id)sender {
	NSParameterAssert([sender isKindOfClass:[NSButton class]]);
	NSInteger returnCode = -1;
	if([[(NSButton* )sender title] isEqualToString:@"Cancel"]) {
		returnCode = PGServerButtonCancel;
	} else if([[(NSButton* )sender title] isEqualToString:@"Continue"]) {
		returnCode = PGServerButtonContinue;
	} else if([[(NSButton* )sender title] isEqualToString:@"Connections"]) {
		returnCode = PGServerButtonConnections;
	}
	[NSApp endSheet:[(NSButton* )sender window] returnCode:returnCode];
}


-(void)_endCloseConfirmSheet:(NSWindow* )sheet returnCode:(NSInteger)returnCode contextInfo:(void* )contextInfo {
	[sheet orderOut:self];

	switch(returnCode) {
		case PGServerButtonContinue:
			// TODO
			NSLog(@"TODO: TERMINATE CONNECTIONS");
			break;
		case PGServerButtonConnections:
			// switch toolbar to connections
			[self _toolbarSelectItemWithIdentifier:@"connections"];
			break;
		default:
			break;
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark NSApplicationDelegate
////////////////////////////////////////////////////////////////////////////////

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {

	// show/hide window, automatically start server
	if([[self preferences] autoHideWindow]) {
		[_mainWindow miniaturize:self];
	}
	if([[self preferences] autoStartServer]) {
		[self _doServerStart:nil];
	}
	
	// schedule timer for retrieving connection count and server uptime
	[NSTimer scheduledTimerWithTimeInterval:[[self preferences] statusRefreshInterval] target:self selector:@selector(statusRefreshTimer:) userInfo:nil repeats:YES];
}

-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication* )sender {
	if([[self server] state]==PGServerStateRunning) {
#ifdef DEBUG
		NSLog(@"Terminating later, stopping the server");
#endif
		[[self server] stop];
		[self setTerminateRequested:YES];
		return NSTerminateCancel;
	} else {
		return NSTerminateNow;
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark PGServerDelegate
////////////////////////////////////////////////////////////////////////////////

-(void)pgserver:(PGServer *)sender message:(NSString *)message {
	if([message hasPrefix:@"ERROR:"]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:PGServerMessageNotificationError object:message];
	} else if([message hasPrefix:@"WARNING:"]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:PGServerMessageNotificationWarning object:message];
	} else if([message hasPrefix:@"FATAL:"]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:PGServerMessageNotificationFatal object:message];
	} else {
		[[NSNotificationCenter defaultCenter] postNotificationName:PGServerMessageNotificationInfo object:message];
	}
#ifdef DEBUG
	NSLog(@"%@",message);
#endif
}

-(void)pgserver:(PGServer* )server stateChange:(PGServerState)state {
#ifdef DEBUG
	NSLog(@"state changed => %d %@",state,[PGServer stateAsString:state]);
#endif
	[self _setButtonState:state];
	[self _setStatusString:state];
	[self _setConnection:state];
	[self _setServerStatus:state];
	[self _setUptimeString:state];
	[self _setDockIcon];
	
	// check for terminating
	if(state==PGServerStateStopped && [self terminateRequested]) {
#ifdef DEBUG
		NSLog(@"PGServerStateStopped state reached, quitting application");
#endif
		[[NSApplication sharedApplication] terminate:self];
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark IBActions
////////////////////////////////////////////////////////////////////////////////

-(IBAction)ibToolbarItemClicked:(id)sender {
	NSToolbarItem* item = (NSToolbarItem* )sender;
	NSParameterAssert([item isKindOfClass:[NSToolbarItem class]]);
	NSString* identifier = [item itemIdentifier];

	NSString* oldIdentifier = [[_tabView selectedTabViewItem] identifier];
	ViewController* oldViewController = [_views objectForKey:oldIdentifier];

	// determine if we really want to deselect the view
	BOOL deselectView = YES;
	if([oldViewController respondsToSelector:@selector(willUnselectView:)]) {
		deselectView = [oldViewController willUnselectView:self];
	}
	if(deselectView==NO) {
		[[item toolbar] setSelectedItemIdentifier:oldIdentifier];
		return;
	}
	
	// new view
	ViewController* newViewController = [_views objectForKey:identifier];
	BOOL selectView = YES;
	if([newViewController respondsToSelector:@selector(willSelectView:)]) {
		selectView = [newViewController willSelectView:self];
	}
	if(selectView==NO) {
		[[item toolbar] setSelectedItemIdentifier:oldIdentifier];
		return;
	}

	NSSize viewControllerSize = [[oldViewController view] frame].size;
	NSSize windowContentSize = [[_mainWindow contentView] frame].size;
	CGFloat extraHeight = windowContentSize.height - viewControllerSize.height;
	NSSize newViewControllerSize = [newViewController frameSize];
	if(viewControllerSize.height > 0 && extraHeight > 0) {
		newViewControllerSize.height += extraHeight;
	}	
	[_tabView selectTabViewItemWithIdentifier:identifier];
	[_mainWindow resizeToSize:newViewControllerSize];
}

-(IBAction)ibStartStopButtonClicked:(id)sender {
	PGServerState state = [[self server] state];
	switch(state) {
		case PGServerStateUnknown:
		case PGServerStateStopped:
			[self _doServerStart:sender];
			break;
		case PGServerStateRunning:
		case PGServerStateAlreadyRunning:
			[self _doServerStop:sender];
		default:
#ifdef DEBUG
			NSLog(@"button pressed, but don't know what to do: %@",[PGServer stateAsString:state]);
#endif
			break;
	}
}

-(IBAction)ibServerMenuItemClicked:(NSMenuItem* )menuItem {
	NSParameterAssert([menuItem isKindOfClass:[NSMenuItem class]]);
	switch([menuItem tag]) {
		case PGServerMenuTagStart:
			[self _doServerStart:menuItem];
			break;
		case PGServerMenuTagStop:
			[self _doServerStop:menuItem];
			break;
		case PGServerMenuTagReload:
			[self _doServerReload:menuItem];
			break;
		case PGServerMenuTagRestart:
			[self _doServerRestart:menuItem];
			break;
		default:
#ifdef DEBUG
			NSLog(@"menuItem pressed, but don't know what to do: %@",menuItem);
#endif
			break;
	}
}

-(IBAction)ibViewMenuItemClicked:(NSMenuItem* )menuItem {
	NSParameterAssert([menuItem isKindOfClass:[NSMenuItem class]]);
	for(ViewController* viewController in [_views allValues]) {
		if([viewController tag]==[menuItem tag]) {
			[self _toolbarSelectItemWithIdentifier:[viewController identifier]];
		}
	}
}

-(IBAction)ibStatusStringClicked:(id)sender {
	NSLog(@"click %@!",sender);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Timers
////////////////////////////////////////////////////////////////////////////////

-(void)statusRefreshTimer:(id)sender {
	[self _setUptimeString:[[self server] state]];
	[self _setNumberOfConnections:[[self server] state]];
	[self _setDockIcon];
}

////////////////////////////////////////////////////////////////////////////////

@end
