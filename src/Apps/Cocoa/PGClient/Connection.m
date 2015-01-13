
#import "Connection.h"

@implementation Connection

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	self = [super init];
	if(self) {
		_connection = [PGConnectionWindowController new];
		NSParameterAssert(_connection);
		// set delegate
		[_connection setDelegate:self];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic url;

-(NSURL* )url {
	return [NSURL URLWithString:@"postgres://pttnkktdoyjfyc@ec2-54-227-255-156.compute-1.amazonaws.com:5432/dej7aj0jp668p5"];
}

////////////////////////////////////////////////////////////////////////////////
// methods

-(void)loginWithWindow:(NSWindow* )window {
	NSParameterAssert(window);

	// set default URL
	[[self connection] setUrl:[self url]];

	// begin sheet
	[[self connection] beginSheetForParentWindow:window];
}

-(void)disconnect {
	[[self connection] disconnect];
}

////////////////////////////////////////////////////////////////////////////////
// PGConnectionWindowDelegate

-(void)connectionWindow:(PGConnectionWindowController* )windowController status:(PGConnectionWindowStatus)status {
	switch(status) {
		case PGConnectionWindowStatusOK:
			[windowController connect];
			break;
		case PGConnectionWindowStatusNeedsPassword:
			[[self connection] beginPasswordSheetForParentWindow:nil];
			break;
		case PGConnectionWindowStatusCancel:
			NSLog(@"PGConnectionWindow sent status CANCEL PRESSED");
			break;
		case PGConnectionWindowStatusConnecting:
			NSLog(@"PGConnectionWindow sent status CONNECTING");
			break;
		case PGConnectionWindowStatusBadParameters:
			NSLog(@"PGConnectionWindow sent status BAD PARAMETERS");
			break;
		case PGConnectionWindowStatusRejected:
			NSLog(@"PGConnectionWindow sent status REJECTED CONNECTION");
			break;
		case PGConnectionWindowStatusConnected:
			NSLog(@"PGConnectionWindow sent status CONNECTED");
			break;
	}
}

@end
