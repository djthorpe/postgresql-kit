
#import "AppDelegate.h"
#import "NSWindow+ResizeAdditions.h"
#import "ViewController.h"

#import "LogViewController.h"
#import "HostAccessViewController.h"
#import "ConfigurationViewController.h"
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
// init method

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
// Properties

@synthesize server = _server;
@synthesize connection = _connection;
@synthesize uptimeString;
@synthesize versionString;
@synthesize buttonText;

////////////////////////////////////////////////////////////////////////////////
// Private methods

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

-(void)awakeFromNib {
	// add the views
	[self _addViewController:[[LogViewController alloc] init]];
	[self _addViewController:[[HostAccessViewController alloc] init]];
	[self _addViewController:[[ConfigurationViewController alloc] init]];
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
	
	// timer to update the uptime
	[NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
}

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

-(void)timerFired:(id)sender {
	NSTimeInterval uptime = [[self server] uptime];
	if(uptime > 0.0) {
		NSTimeInterval mins = (uptime / 60.0);
		[self setUptimeString:[NSString stringWithFormat:@"Running %lu mins",(NSUInteger)mins]];
	} else {
		[self setUptimeString:@""];		
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

////////////////////////////////////////////////////////////////////////////////
// Retrieve number of remote connections

-(NSUInteger)_numberOfConnections {
	if([[self connection] status] != PGConnectionStatusConnected) {
		return 0;
	}
	NSError* error;
	PGResult* result = [[self connection] execute:@"SELECT COUNT(*) AS num_connections FROM pg_stat_activity WHERE procpid <> pg_backend_pid()" format:PGClientTupleFormatBinary error:&error];
	if(error) {
#ifdef DEBUG
		NSLog(@"_numberOfConnections: Error: %@",error);
		result = nil;
#endif
	}
	if([result dataReturned]) {
		NSParameterAssert([result size]==1);
		NSParameterAssert([result numberOfColumns]==1);
		NSArray* row = [result fetchRowAsArray];
		NSNumber* numConnections = [row objectAtIndex:0];
		NSParameterAssert([numConnections isKindOfClass:[NSNumber class]]);
		return [numConnections unsignedIntegerValue];
	}
	return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Confirm Server Stop/Restart

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
			NSLog(@"TERMINATE CONNECTIONS");
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
// NSApplicationDelegate

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
// PGServerDelegate

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
	
	// check for terminating
	if(state==PGServerStateStopped && [self terminateRequested]) {
#ifdef DEBUG
		NSLog(@"PGServerStateStopped state reached, quitting application");
#endif
		[[NSApplication sharedApplication] terminate:self];
	}
}

////////////////////////////////////////////////////////////////////////////////
// IBActions

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
			// start the server
			[[self server] start];
			// switch to logging pane
			[self _toolbarSelectItemWithIdentifier:@"log"];
			break;
		case PGServerStateRunning:
		case PGServerStateAlreadyRunning:
			if([self _numberOfConnections] > 0) {
				// confirm stopping
				[self ibConfirmCloseStartSheet:sender];
			} else {
				// switch to logging pane
				[self _toolbarSelectItemWithIdentifier:@"log"];
				// stop the server
				[[self server] stop];
			}
		default:
			// don't know what to do!
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
			// start the server
			[[self server] start];
			// switch to logging pane
			[self _toolbarSelectItemWithIdentifier:@"log"];
			break;
		case PGServerMenuTagStop:
			if([self _numberOfConnections] > 0) {
				// confirm stopping
				[self ibConfirmCloseStartSheet:menuItem];
			} else {
				// switch to logging pane
				[self _toolbarSelectItemWithIdentifier:@"log"];
				// stop the server
				[[self server] stop];
			}
			break;
		case PGServerMenuTagReload:
			// reload the server
			[[self server] reload];
			// switch to logging pane
			[self _toolbarSelectItemWithIdentifier:@"log"];
			break;
		case PGServerMenuTagRestart:
			if([self _numberOfConnections] > 0) {
				// confirm stopping
				[self ibConfirmCloseStartSheet:menuItem];
			} else {
				// switch to logging pane
				[self _toolbarSelectItemWithIdentifier:@"log"];
				// restart the server
				[[self server] restart];
			}
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


@end
