
#import "AppDelegate.h"
#import "NSWindow+ResizeAdditions.h"
#import "ViewController.h"

#import "LogViewController.h"
#import "HostAccessViewController.h"
#import "ConfigurationViewController.h"
#import "ConnectionViewController.h"
#import "ConnectionsViewController.h"

NSString* PGServerMessageNotificationError = @"PGServerMessageNotificationError";
NSString* PGServerMessageNotificationWarning = @"PGServerMessageNotificationWarning";
NSString* PGServerMessageNotificationFatal = @"PGServerMessageNotificationFatal";
NSString* PGServerMessageNotificationInfo = @"PGServerMessageNotificationInfo";

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
	
	// switch toolbar to log
	[self _toolbarSelectItemWithIdentifier:@"log"];
	
	// set server delegate
	[[self server] setDelegate:self];
	
	// set the uptime and server strings
	[self setUptimeString:@""];
	[self setVersionString:[[self server] version]];
	
	// set button state
	[self _setButtonState:[[self server] state]];
	
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

	/*
	// connect and disconnect
	if(state==PGServerStateRunning &&  [[self connection] status] != PGConnectionStatusConnected) {
#ifdef DEBUG
		NSLog(@"Connecting to server");
#endif
		NSError* theError = nil;
		NSURL* theURL = [NSURL URLWithString:@"pgsql://postgres@/"];
		BOOL isSuccess = [[self connection] connectWithURL:theURL error:&theError];
		if(isSuccess==NO) {
			[self addLogMessage:[NSString stringWithFormat:@"Connection error: %@",[theError description]] color:[NSColor redColor] bold:NO];
		}
		
	} else if((state==PGServerStateStopping || state==PGServerStateRestart) && [[self connection] status]==PGConnectionStatusConnected) {
#ifdef DEBUG
		NSLog(@"Disconnecting from server");
#endif
		[[self connection] disconnect];
	}
	*/
	
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
	ViewController* viewController = [_views objectForKey:identifier];
	[_tabView selectTabViewItemWithIdentifier:identifier];
	[_mainWindow resizeToSize:[viewController frameSize]];
}

-(IBAction)ibStartStopButtonClicked:(id)sender {
	PGServerState state = [[self server] state];
	if(state==PGServerStateUnknown || state==PGServerStateStopped) {
		// start the server
		[[self server] start];
		// switch to logging pane
		[self _toolbarSelectItemWithIdentifier:@"log"];
	} else if(state==PGServerStateRunning || state==PGServerStateAlreadyRunning) {
		// stop the server
		[[self server] stop];
	} else {
		// don't know what to do!
#ifdef DEBUG
		NSLog(@"button pressed, but don't know what to do: %@",[PGServer stateAsString:state]);
#endif		
	}
}

@end
