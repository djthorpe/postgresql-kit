
#import "PGConnectionController.h"
#import "PGClientApplication.h"

#define CONNECT_IN_BACKGROUND 1             // 0 for foreground, else background

@implementation PGConnectionController

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
    self = [super init];
    if(self) {
        _connections = [NSMutableDictionary dictionary];
        _urls = [NSMutableDictionary dictionary];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// methods

// TODO: Method for closing single connections

-(void)closeAllConnections {
	for(NSNumber* keyObject in _connections) {
		PGConnection* connection = [_connections objectForKey:keyObject];
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

-(BOOL)openConnectionWithKey:(NSUInteger)key {
	NSNumber* keyObject = [NSNumber numberWithUnsignedInteger:key];
	PGConnection* connection = [_connections objectForKey:keyObject];
	NSURL* url = [_urls objectForKey:keyObject];
	if(connection==nil || url==nil) {
		return NO;
	}
	
	// post notification that connection is opening
	[[NSNotificationCenter defaultCenter] postNotificationName:PGClientNotificationServerStatusChange object:@"Connection is opening"];

#ifdef CONNECT_IN_BACKGROUND
	[connection connectInBackgroundWithURL:url whenDone:^(NSError* error) {
		if([error code]==PGClientErrorNone) {
			[[NSNotificationCenter defaultCenter] postNotificationName:PGClientNotificationServerStatusChange object:@"Connection is opened"];
		} else {
			[[NSNotificationCenter defaultCenter] postNotificationName:PGClientNotificationServerStatusChange object:[error localizedDescription]];
		}
	}];
#else
	NSError* error = nil;
	[connection connectWithURL:url error:&error];
	if([error code]==PGClientErrorNone) {
		[[NSNotificationCenter defaultCenter] postNotificationName:PGClientNotificationServerStatusChange object:@"Connection is opened"];
	} else {
		[[NSNotificationCenter defaultCenter] postNotificationName:PGClientNotificationServerStatusChange object:[error localizedDescription]];
	}
#endif
	
	return YES;
}

-(BOOL)closeConnectionForKey:(NSUInteger)key {
	NSNumber* keyObject = [NSNumber numberWithUnsignedInteger:key];
	PGConnection* connection = [_connections objectForKey:keyObject];
	NSParameterAssert(connection);
	[[NSNotificationCenter defaultCenter] postNotificationName:PGClientNotificationServerStatusChange object:@"Connection is closing"];
	return [connection disconnect];
}

@end
