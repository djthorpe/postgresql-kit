
#import "PostgresPrefPaneController.h"
#import "PostgresPrefPaneServerApp.h"

@implementation PostgresPrefPaneController

@synthesize connection;

-(id)initWithBundle:(NSBundle *)bundle {
	self = [super initWithBundle:bundle];
    if(self) {
		[self setConnection:[NSConnection connectionWithRegisteredName:@"com.mutablelogic.PostgresPrefPaneServerApp" host:nil]];
	}
	return self;
}

-(void)dealloc {
	[self setConnection:nil];
	[super dealloc];
}

-(PostgresPrefPaneServerApp* )serverApp {
	return (PostgresPrefPaneServerApp* )[[self connection] rootProxy];
}

-(void)mainViewDidLoad {
	NSLog(@"loaded view, state = %d",[[self serverApp] serverState]);
}

-(IBAction)doStartServer:(id)sender {
	[[self serverApp] startServer];
}

-(IBAction)doStopServer:(id)sender {
	[[self serverApp] stopServer];
}

@end
