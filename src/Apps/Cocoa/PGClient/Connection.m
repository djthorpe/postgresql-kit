
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
	[[self connection] beginSheetForParentWindow:window contextInfo:nil];
}

-(void)disconnect {
	[[self connection] disconnect];
}

////////////////////////////////////////////////////////////////////////////////
// PGConnectionWindowDelegate

-(void)connectionWindow:(PGConnectionWindowController* )windowController endedWithStatus:(NSInteger)status contextInfo:(void* )contextInfo {
	BOOL returnValue = NO;
	if(status==NSModalResponseOK && [windowController url]) {
		returnValue = [windowController connect];
	}
	
	if(returnValue==NO) {
		NSLog(@"DISPLAY ERROR MESSAGE");
	}
}

@end
