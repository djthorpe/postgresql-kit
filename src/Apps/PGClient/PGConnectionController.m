
#import "PGConnectionController.h"

@implementation PGConnectionController

-(id)init {
    self = [super init];
    if(self) {
        _connections = [NSMutableDictionary dictionary];
        _urls = [NSMutableDictionary dictionary];
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

-(BOOL)openConnectionWithKey:(NSUInteger)key {
	NSNumber* keyObject = [NSNumber numberWithUnsignedInteger:key];
	PGConnection* connection = [_connections objectForKey:keyObject];
	NSURL* url = [_urls objectForKey:keyObject];
	if(connection==nil || url==nil) {
		return NO;
	}
	[connection connectInBackgroundWithURL:url whenDone:^(PGConnectionStatus status,NSError* error) {
		if(status==PGConnectionStatusConnected) {
			NSLog(@"connection %lu OK",key);
		} else {
			NSLog(@"connection %lu BAD",key);
		}
	}];
	return YES;
}
@end
