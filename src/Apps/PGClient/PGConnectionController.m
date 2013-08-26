
#import "PGConnectionController.h"
#import "PGClientApplication.h"

@implementation PGConnectionController

-(id)init {
    self = [super init];
    if(self) {
        _connections = [NSMutableDictionary dictionary];
        _urls = [NSMutableDictionary dictionary];
		_consoles = [NSMutableDictionary dictionary];
    }
    return self;
}

// TODO: Method for closing single connections

-(void)closeAllConnections {
	for(PGConnection* connection in _connections) {
		if([connection status]==PGConnectionStatusConnected) {
			[connection disconnect];
		}
	}
}

-(PGConnection* )createConnectionWithURL:(NSURL* )url forKey:(NSUInteger)key {
	NSParameterAssert(url);
	NSParameterAssert(key);
	PGConnection* connection = [[PGConnection alloc] init];
	NSNumber* keyObject = [NSNumber numberWithUnsignedInteger:key];
	NSParameterAssert(connection);
	NSParameterAssert([_connections objectForKey:keyObject]==nil);
	NSParameterAssert([_urls objectForKey:keyObject]==nil);
	[_connections setObject:connection forKey:keyObject];
	[_urls setObject:url forKey:keyObject];
	return connection;
}

-(PGConnection* )connectionForKey:(NSUInteger)key {
	NSParameterAssert(key);
	NSNumber* keyObject = [NSNumber numberWithUnsignedInteger:key];
	return [_connections objectForKey:keyObject];
}

-(PGConsoleView* )consoleForKey:(NSUInteger)key {
	NSParameterAssert(key);
	NSNumber* keyObject = [NSNumber numberWithUnsignedInteger:key];
	PGConsoleView* console = [_consoles objectForKey:keyObject];
	if(console==nil) {
		console = [[PGConsoleView alloc] init];
		// set console delegate
		[console setDelegate:self];
	}
	NSParameterAssert([console isKindOfClass:[PGConsoleView class]]);
	return console;
}

-(BOOL)openConnectionWithKey:(NSUInteger)key {
	NSNumber* keyObject = [NSNumber numberWithUnsignedInteger:key];
	PGConnection* connection = [_connections objectForKey:keyObject];
	NSURL* url = [_urls objectForKey:keyObject];
	if(connection==nil || url==nil) {
		return NO;
	}
	
	// post notification that connection is opening
	[[NSNotificationCenter defaultCenter] postNotificationName:PGClientNotificationServerStatusChange object:@"Connection is opening"];

	[connection connectInBackgroundWithURL:url whenDone:^(PGConnectionStatus status,NSError* error) {
		if(status==PGConnectionStatusConnected) {
			[[NSNotificationCenter defaultCenter] postNotificationName:PGClientNotificationServerStatusChange object:@"Connection is opened"];
		} else {
			[[NSNotificationCenter defaultCenter] postNotificationName:PGClientNotificationServerStatusChange object:@"Connection cannot be opened"];
		}
	}];
	return YES;
}

-(BOOL)closeConnectionForKey:(NSUInteger)key {
	NSNumber* keyObject = [NSNumber numberWithUnsignedInteger:key];
	PGConnection* connection = [_connections objectForKey:keyObject];
	NSParameterAssert(connection);
	[[NSNotificationCenter defaultCenter] postNotificationName:PGClientNotificationServerStatusChange object:@"Connection is closing"];
	return [connection disconnect];
}

////////////////////////////////////////////////////////////////////////////////
// PGConsoleView delegate

-(NSUInteger)numberOfRowsInConsoleView:(PGConsoleView* )view {
	return 10;
}

-(NSString* )consoleView:(PGConsoleView* )view stringForRow:(NSUInteger)row {
	return @"XX";
}




@end
