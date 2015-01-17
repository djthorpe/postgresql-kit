
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
	return @"network";
}

-(NSInteger)tag {
	return 1;
}

////////////////////////////////////////////////////////////////////////////////
// get hostname

-(NSString* )listenAddresses {
	// if server is running, then get from there
	PGServer* server = [[self delegate] server];
	PGServerState state = [server state];
	if(state==PGServerStateRunning || state==PGServerStateAlreadyRunning) {
		return [server hostname];
	} else {
		return nil;
	}
}

-(NSUInteger)configPort {
	// if server is running, then get from there
	PGServer* server = [[self delegate] server];
	PGServerState state = [server state];
	if(state==PGServerStateRunning || state==PGServerStateAlreadyRunning) {
		return [server port];
	} else {
		return 0;
	}	
}

////////////////////////////////////////////////////////////////////////////////
// methods

-(void)loadView {
	[super loadView];
#ifdef DEBUG
	NSLog(@"listen = %@",[self listenAddresses]);
	NSLog(@"port = %lu",[self configPort]);
#endif
}

-(IBAction)ibUseDefaultPort:(id)sender {
	[self setPort:PGServerDefaultPort];
	[self setIsDefaultPort:YES];
}

@end
