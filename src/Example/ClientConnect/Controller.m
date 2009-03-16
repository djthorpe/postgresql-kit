
#import "Controller.h"

@implementation Controller
@synthesize connectPanel;

-(id)init {
	self = [super init];
	if (self != nil) {
		[self setConnectPanel:nil];
	}
	return self;
}

-(void)dealloc {
	[self setConnectPanel:nil];
	[super dealloc];
}

-(void)awakeFromNib {
	[self setConnectPanel:[[[FLXPostgresConnectWindowController alloc] init] autorelease]];
	[ibMainWindow setDelegate:self];
}

-(void)windowDidBecomeMain:(NSNotification *)notification {
	// show sheet if not already visible
	if([connectPanel isVisible]==NO) {
		[connectPanel beginSheetForWindow:ibMainWindow modalDelegate:self didEndSelector:@selector(didLogin:password:)];
	}
}

-(void)didLogin:(FLXPostgresConnection* )connection password:(NSString* )thePassword {
	NSLog(@"Performed login, host = %@, database = %@, user = %@, port = %u, password = %@",[connection host],
		  [connection database],[connection user],[connection port],thePassword);
}

@end
