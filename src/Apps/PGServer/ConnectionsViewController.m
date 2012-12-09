
#import "ConnectionsViewController.h"

@implementation ConnectionsViewController

-(NSString* )nibName {
	return @"ConnectionsView";
}

-(NSString* )identifier {
	return @"connections";
}

-(BOOL)willSelectView:(id)sender {
	// only allow view to be selected if server is running
	PGServer* server = [[self delegate] server];
	if([server state]==PGServerStateAlreadyRunning || [server state]==PGServerStateRunning) {
		return YES;
	} else {
		return NO;
	}
}

@end
