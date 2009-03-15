
#import "Controller.h"

@implementation Controller
@synthesize client;
@synthesize connectPanel;

-(id)init {
	self = [super init];
	if (self != nil) {
		[self setClient:[[[FLXPostgresConnection alloc] init] autorelease]];
		[self setConnectPanel:nil];
	}
	return self;
}

-(void)dealloc {
	[self setClient:nil];
	[self setConnectPanel:nil];
	[super dealloc];
}

-(void)awakeFromNib {
	FLXPostgresConnectWindowController* thePanel = [[[FLXPostgresConnectWindowController alloc] init] autorelease];
	if(thePanel==nil) {
		NSLog(@"Error - can't load the panel");
	} else {
		[self setConnectPanel:thePanel];
	}

	[ibMainWindow setDelegate:self];
}

-(void)windowDidBecomeMain:(NSNotification *)notification {
	// show sheet if not already visible
	if([connectPanel isVisible]==NO) {
		[connectPanel beginSheetForWindow:ibMainWindow];
	}
}

@end
