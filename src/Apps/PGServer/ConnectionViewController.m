
#import "ConnectionViewController.h"
#import <PGServerKit/PGServerKit.h>

@implementation ConnectionViewController

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize isRemoteConnection;
@synthesize port;
@synthesize isDefaultPort;

-(NSString* )nibName {
	return @"ConnectionView";
}

-(NSString* )identifier {
	return @"connection";
}


-(PGServerConfiguration* )configuration {
	return [[[self delegate] server] configuration];
}

////////////////////////////////////////////////////////////////////////////////
// methods

-(void)loadView {
	[super loadView];
}

-(IBAction)ibUseDefaultPort:(id)sender {
	[self setPort:PGServerDefaultPort];
	[self setIsDefaultPort:YES];
}

@end
