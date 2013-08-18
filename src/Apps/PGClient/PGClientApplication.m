
#import "PGClientApplication.h"
#import "PGSidebarNode.h"

////////////////////////////////////////////////////////////////////////////////
// constants

NSString* PGClientAddConnectionURL = @"PGClientAddConnectionURL";
NSString* PGClientNotificationOpenConnection = @"PGClientNotificationOpenConnection";
NSString* PGClientNotificationCloseConnection = @"PGClientNotificationCloseConnection";

@implementation PGClientApplication

////////////////////////////////////////////////////////////////////////////////
// initializers

-(id)init {
    self = [super init];
    if (self) {
		_internalServer = nil;
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
	
	// internal server
	if(_internalServer==nil) {
		_internalServer = [PGServer serverWithDataPath:[self _internalServerDataPath]];
		[_internalServer setDelegate:self];
	}
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize ibGrabberView;
@synthesize internalServer = _internalServer;

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
		NSLog(@"cannot open, state = %@",[PGServer stateAsString:state]);
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
	PGServerState state = [[self internalServer] state];
	BOOL success = NO;
	if(state==PGServerStateUnknown) {
		success = [[self internalServer] start];
	}
	return success;
}

-(BOOL)_closeInternalServer {
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
	
	// if internal connection
	if([node isInternalServer]) {
		BOOL isSuccess = [self _openInternalServer];
		if(isSuccess==NO) {
			NSLog(@"Cannot open internal server!");
		}
	} else {
		NSLog(@"open = %@",[node url]);
	}
}

-(void)ibNotificationCloseConnection:(NSNotification* )notification {
	PGSidebarNode* node = [notification object];
	NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);
	
	// if internal connection
	if([node isInternalServer]) {
		BOOL isSuccess = [self _closeInternalServer];
		if(isSuccess==NO) {
			NSLog(@"Cannot close internal");
		}
	} else {
		NSLog(@"close = %@",[node url]);
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
			NSLog(@"STARTED - PID %d PORT %lu PATH %@",[server pid],[server port],[server socketPath]);
			break;
		case PGServerStateError:
			NSLog(@"ERROR");
			break;
		case PGServerStateStopped:
			NSLog(@"SERVER STOPPED");
			break;
		default:
			break;
	}
}

-(void)pgserver:(PGServer* )server message:(NSString* )message {
	NSLog(@"%@",message);
}

@end
