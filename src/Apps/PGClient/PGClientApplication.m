
#import "PGClientApplication.h"
#import "PGSidebarNode.h"
#import "PGConnectionController.h"

////////////////////////////////////////////////////////////////////////////////
// constants

NSString* PGClientAddConnectionURL = @"PGClientAddConnectionURL";
NSString* PGClientNotificationOpenConnection = @"PGClientNotificationOpenConnection";
NSString* PGClientNotificationCloseConnection = @"PGClientNotificationCloseConnection";
NSString* PGClientNotificationDeleteConnection = @"PGClientNotificationDeleteConnection";

@implementation PGClientApplication

////////////////////////////////////////////////////////////////////////////////
// initializers

-(id)init {
    self = [super init];
    if (self) {
		_internalServer = nil;
		_connections = [[PGConnectionController alloc] init];
		_terminationRequested = NO;
    }
    return self;
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// populate sidebar
	[[self ibSidebarViewController] applicationDidFinishLaunching:aNotification];
	
	// add observers
	[[NSNotificationCenter defaultCenter] addObserver:[self ibSidebarViewController] selector:@selector(ibNotificationAddConnection:) name:PGClientAddConnectionURL object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ibNotificationOpenConnection:) name:PGClientNotificationOpenConnection object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ibNotificationCloseConnection:) name:PGClientNotificationCloseConnection object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ibNotificationDeleteConnection:) name:PGClientNotificationDeleteConnection object:nil];
	
	// set delegate for connections controller
	[[self connections] setDelegate:self];
	
	// internal server
	if(_internalServer==nil) {
		_internalServer = [PGServer serverWithDataPath:[self _internalServerDataPath]];
		[_internalServer setDelegate:self];
	}
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize internalServer = _internalServer;
@synthesize terminationRequested = _terminationRequested;
@synthesize connections = _connections;

////////////////////////////////////////////////////////////////////////////////
// private methods

-(NSString* )_internalServerDataPath {
	NSString* theIdent = [[NSBundle mainBundle] bundleIdentifier];
	NSArray* theAppFolder = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask, YES);
	NSParameterAssert([theAppFolder count]);
	return [[theAppFolder objectAtIndex:0] stringByAppendingPathComponent:theIdent];
}

-(BOOL)_canOpenInternalServer {
	PGServerState state = [[self internalServer] state];
	if(state != PGServerStateStopped && state != PGServerStateUnknown) {
		return NO;
	}
	return YES;
}

-(BOOL)_canCloseInternalServer {
	PGServerState state = [[self internalServer] state];
	if(state != PGServerStateRunning && state != PGServerStateAlreadyRunning) {
		return NO;
	}
	return YES;
}

-(BOOL)_openInternalServer {
	if([self _canOpenInternalServer]==NO) {
		return NO;
	}
		
	// add console to the tab view, if not already added
	PGSidebarNode* node = [[self ibSidebarViewController] nodeForKey:PGSidebarNodeKeyInternalServer];
	[[self ibTabViewController] openConsoleViewWithName:[node name] forKey:PGSidebarNodeKeyInternalServer];

	// start internal server
	return [[self internalServer] startWithPort:PGServerDefaultPort socketPath:[self _internalServerDataPath]];
}

-(BOOL)_openConnectionForNode:(PGSidebarNode* )node {
	NSParameterAssert(node);
	NSParameterAssert([node type]==PGSidebarNodeTypeServer);

	// get existing connection object
	PGConnection* connection = [[self connections] connectionForKey:[node key]];
	if(connection==nil) {
		connection = [[self connections] createConnectionWithURL:[node URL] forKey:[node key]];
		NSParameterAssert(connection);
	}

	// make sure connection is not connected
	if([connection status] != PGConnectionStatusDisconnected) {
		return NO;
	}
	
	// add console to the tab view, if not already added
	[[self ibTabViewController] openConsoleViewWithName:[node name] forKey:[node key]];

	// ask connection controller to open connection in background,
	// and return success condition
	return [[self connections] openConnectionForKey:[node key]];
}

-(void)_closeConnectionForNode:(PGSidebarNode* )node {
	NSParameterAssert(node);
	NSParameterAssert([node type]==PGSidebarNodeTypeServer);
	[[self connections] closeConnectionForKey:[node key]];
}

-(BOOL)_openInternalServerConnectionWithURL:(NSURL* )url {
	NSParameterAssert(url);
	// get existing connection object
	PGConnection* connection = [[self connections] connectionForKey:PGSidebarNodeKeyInternalServer];
	if(connection==nil) {
		connection = [[self connections] createConnectionWithURL:url forKey:PGSidebarNodeKeyInternalServer];
		NSParameterAssert(connection);
	}

	// make sure connection is not connected
	if([connection status] != PGConnectionStatusDisconnected) {
		return NO;
	}
	
	// ask connection controller to open connection in background,
	// and return success condition
	return [[self connections] openConnectionForKey:PGSidebarNodeKeyInternalServer];
}

-(BOOL)_closeInternalServer {
	[[self connections] closeConnectionForKey:PGSidebarNodeKeyInternalServer];
	if([self _canCloseInternalServer]) {
		return [_internalServer stop];
	} else {
		return NO;
	}
}

////////////////////////////////////////////////////////////////////////////////
// IBActions

-(IBAction)doAddLocalConnection:(id)sender {
	[[self ibLocalConnectionWindowController] beginSheetForParentWindow:[self window]];
}

-(IBAction)doAddRemoteConnection:(id)sender {
	[[self ibRemoteConnectionWindowController] beginSheetForParentWindow:[self window]];
}

////////////////////////////////////////////////////////////////////////////////
// Notifications

-(void)ibNotificationOpenConnection:(NSNotification* )notification {
	PGSidebarNode* node = [notification object];
	NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);
	NSParameterAssert([node type]==PGSidebarNodeTypeServer);

	// if this is the internal connection, then see if we need to start the
	// server first
	if([node key]==PGSidebarNodeKeyInternalServer) {
		BOOL isSuccess = [self _openInternalServer];
		if(isSuccess==NO) {
			NSLog(@"[self _openInternalServer] failed");
		}
	} else {
		[self _openConnectionForNode:node];
	}
}

-(void)ibNotificationCloseConnection:(NSNotification* )notification {
	PGSidebarNode* node = [notification object];
	NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);
	NSParameterAssert([node type]==PGSidebarNodeTypeServer);
	
	// if this is the internal connection, then see if we need to start the
	// server first
	if([node key]==PGSidebarNodeKeyInternalServer) {
		BOOL isSuccess = [self _closeInternalServer];
		if(isSuccess==NO) {
			NSLog(@"[self _closeInternalServer] failed");
		}
	} else {
		[self _closeConnectionForNode:node];
	}
}

-(void)ibNotificationDeleteConnection:(NSNotification* )notification {
	PGSidebarNode* node = [notification object];
	NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);

	// TODO: Add are you sure you want to delete? sheet confirmation
	
	[[self ibSidebarViewController] deleteNode:node];
}

////////////////////////////////////////////////////////////////////////////////
// PGConnectionController delegate

-(void)connectionOpeningWithKey:(NSUInteger)key {
	PGSidebarNode* node = [[self ibSidebarViewController] nodeForKey:key];
	NSParameterAssert(node);
	NSLog(@"%@ => Opening",node);
}

-(void)connectionOpenWithKey:(NSUInteger)key {
	PGSidebarNode* node = [[self ibSidebarViewController] nodeForKey:key];
	NSParameterAssert(node);
	NSLog(@"%@ => Open",node);
}

-(void)connectionRejectedWithKey:(NSUInteger)key error:(NSError* )error {
	PGSidebarNode* node = [[self ibSidebarViewController] nodeForKey:key];
	NSParameterAssert(node);
	NSLog(@"%@ => Rejected: %@",node,[error localizedDescription]);
}

-(void)connectionNeedsPasswordWithKey:(NSUInteger)key {
	PGSidebarNode* node = [[self ibSidebarViewController] nodeForKey:key];
	NSParameterAssert(node);
	NSLog(@"%@ => Needs password",node);
}

-(void)connectionClosedWithKey:(NSUInteger)key {
	PGSidebarNode* node = [[self ibSidebarViewController] nodeForKey:key];
	NSParameterAssert(node);
	NSLog(@"%@ => Closed",node);
}

////////////////////////////////////////////////////////////////////////////////
// NSApplication delegate

-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication* )sender {	
	// send message to the sidebar controller
	[[self ibSidebarViewController] applicationWillTerminate:self];
	
	// close all database connections
	[[self connections] closeAllConnections];
	
	// terminate internal server if necessary
	if([[self internalServer] state]==PGServerStateRunning) {
#ifdef DEBUG
		NSLog(@"Terminating later, stopping the server");
#endif
		[[self internalServer] stop];
		[self setTerminationRequested:YES];
		return NSTerminateCancel;
	} else {
		return NSTerminateNow;
	}
}

////////////////////////////////////////////////////////////////////////////////
// NSSplitView delegate

-(NSRect)splitView:(NSSplitView* )splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex {
	return [[self ibGrabberView] convertRect:[[self ibGrabberView] bounds] toView:splitView];
}

-(CGFloat)splitView:(NSSplitView* )splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex {
	// constrain view to width of grabber view
	CGFloat grabberWidth = [[self ibGrabberView] bounds].size.width;
	if(proposedPosition < grabberWidth) {
		proposedPosition = grabberWidth;
	}
	return proposedPosition;
}

////////////////////////////////////////////////////////////////////////////////
// PGServer delegate

-(void)pgserver:(PGServer* )server stateChange:(PGServerState)state {
	switch(state) {
		case PGServerStateAlreadyRunning:
		case PGServerStateRunning:
			{
				NSURL* url = [NSURL URLWithSocketPath:[server socketPath] port:[server port] database:nil username:PGServerSuperuser params:nil];
				[self _openInternalServerConnectionWithURL:url];
			}
			break;
		case PGServerStateError:
			// TODO: Error message and set status to red
			break;
		case PGServerStateStopped:
			// TODO: Set bubble to grey
			if([self terminationRequested]) {
#ifdef DEBUG
				NSLog(@"PGServerStateStopped state reached, quitting application");
#endif
				[[NSApplication sharedApplication] terminate:self];
			}
			break;
		default:
			// TODO: Set bubble to orange
			break;
	}
}

-(void)pgserver:(PGServer* )server message:(NSString* )message {
	[[self ibTabViewController] appendConsoleMessage:message forKey:PGSidebarNodeKeyInternalServer];
}

@end
