
#import "Application.h"

@interface Application ()
@property (weak) IBOutlet NSWindow* window;
@end

@implementation Application

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	self = [super init];
	if(self) {
		_connection = [Connection new];
	}
	NSParameterAssert(_connection);
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize connection = _connection;

////////////////////////////////////////////////////////////////////////////////
// NSApplicationDelegate implementation

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// connect to remote server
	[[self connection] login];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// disconnect from remote server
	[[self connection] disconnect];
}

@end
