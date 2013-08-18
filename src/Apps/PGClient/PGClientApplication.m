
#import "PGClientApplication.h"
#import "PGSidebarNode.h"

////////////////////////////////////////////////////////////////////////////////
// constants

NSString* PGClientAddConnectionURL = @"PGClientAddConnectionURL";

@implementation PGClientApplication

////////////////////////////////////////////////////////////////////////////////
// initializers

-(id)init {
    self = [super init];
    if (self) {
		// Do initialization
    }
    return self;
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// populate sidebar
	[[self ibSidebarViewController] applicationDidFinishLaunching:aNotification];
	
	// add observers for sidebar
	[[NSNotificationCenter defaultCenter] addObserver:[self ibSidebarViewController] selector:@selector(ibNotificationAddConnection:) name:PGClientAddConnectionURL object:nil];
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize ibGrabberView;

////////////////////////////////////////////////////////////////////////////////
// IBActions

-(IBAction)doAddLocalConnection:(id)sender {
	[[self ibLocalConnectionWindowController] beginSheetForParentWindow:[self window]];
}

-(IBAction)doAddRemoteConnection:(id)sender {
	[[self ibRemoteConnectionWindowController] beginSheetForParentWindow:[self window]];
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

@end
