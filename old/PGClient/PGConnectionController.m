
#import "PGConnectionController.h"
#import "PGClientApplication.h"

#define CONNECT_IN_BACKGROUND 1             // 0 for foreground, else background

@implementation PGConnectionController

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
    self = [super init];
    if(self) {
		_passwords = [[PGPasswordStore alloc] init];
        _connections = [NSMutableDictionary dictionary];
        _urls = [NSMutableDictionary dictionary];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// connection methods

-(void)closeAllConnections {
	for(NSNumber* keyObject in _connections) {
		PGConnection* connection = [_connections objectForKey:keyObject];
		if([connection status]==PGConnectionStatusConnected) {
			[connection disconnect];
		}
	}
	[_connections removeAllObjects];
	[_urls removeAllObjects];
}

-(void)closeConnectionForKey:(NSUInteger)key {
	NSParameterAssert(key);
	NSNumber* keyObject = [NSNumber numberWithUnsignedInteger:key];
	PGConnection* connection = [_connections objectForKey:keyObject];
	if(connection && [connection status]==PGConnectionStatusConnected) {
		[connection disconnect];
	}
	if([[self delegate] respondsToSelector:@selector(connectionClosedWithKey:)]) {
		[[self delegate] connectionClosedWithKey:key];
	}
	[_connections removeObjectForKey:keyObject];
	[_urls removeObjectForKey:keyObject];
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
	
	// set delegate method and tag
	[connection setDelegate:self];
	[connection setTag:key];
	
	return connection;
}

-(PGConnection* )connectionForKey:(NSUInteger)key {
	NSParameterAssert(key);
	NSNumber* keyObject = [NSNumber numberWithUnsignedInteger:key];
	return [_connections objectForKey:keyObject];
}

-(BOOL)openConnectionForKey:(NSUInteger)key {
	NSNumber* keyObject = [NSNumber numberWithUnsignedInteger:key];
	PGConnection* connection = [_connections objectForKey:keyObject];
	NSURL* url = [_urls objectForKey:keyObject];
	if(connection==nil || url==nil) {
		return NO;
	}
	
	// send status message to delegate
	if([[self delegate] respondsToSelector:@selector(connectionOpeningWithKey:)]) {
		[[self delegate] connectionOpeningWithKey:key];
	}

#ifdef CONNECT_IN_BACKGROUND
	[connection connectInBackgroundWithURL:url whenDone:^(NSError* error) {
		if([error code]==PGClientErrorNone) {
			if([[self delegate] respondsToSelector:@selector(connectionOpenWithKey:)]) {
				[[self delegate] connectionOpenWithKey:key];
			}
		} else if([error code]==PGClientErrorNeedsPassword) {
			if([[self delegate] respondsToSelector:@selector(connectionNeedsPasswordWithKey:)]) {
				[[self delegate] connectionNeedsPasswordWithKey:key];
			}
		} else if([error code]==PGClientErrorInvalidPassword) {
			if([[self delegate] respondsToSelector:@selector(connectionInvalidPasswordWithKey:)]) {
				[[self delegate] connectionInvalidPasswordWithKey:key];
			}
		} else {
			if([[self delegate] respondsToSelector:@selector(connectionRejectedWithKey:error:)]) {
				[[self delegate] connectionRejectedWithKey:key error:error];
			}			
		}
	}];
#else
	NSError* error = nil;
	[connection connectWithURL:url error:&error];
	if([error code]==PGClientErrorNone) {
		if([[self delegate] respondsToSelector:@selector(connectionOpenWithKey:)]) {
			[[self delegate] connectionOpenWithKey:key];
		}
	} else if([error code]==PGClientErrorNeedsPassword) {
		if([[self delegate] respondsToSelector:@selector(connectionInvalidPasswordWithKey:)]) {
			[[self delegate] connectionInvalidPasswordWithKey:key];
		}
	} else if([error code]==PGClientErrorInvalidPassword) {
		if([[self delegate] respondsToSelector:@selector(connectionNeedsPasswordWithKey:)]) {
			[[self delegate] connectionNeedsPasswordWithKey:key];
		}
	} else {
		if([[self delegate] respondsToSelector:@selector(connectionRejectedWithKey:error:)]) {
			[[self delegate] connectionRejectedWithKey:key error:error];
		}
	}
#endif
	return YES;
}

-(NSString* )databaseSelectedForConnectionWithKey:(NSUInteger)key {
	NSParameterAssert(key);
	PGConnection* connection = [self connectionForKey:key];
	if([connection status] != PGConnectionStatusConnected) {
		return nil;
	}
	return [connection database];
}

////////////////////////////////////////////////////////////////////////////////
// password methods

-(NSString* )passwordForKey:(NSUInteger)key {
	NSParameterAssert(key);
	NSNumber* keyObject = [NSNumber numberWithUnsignedInteger:key];
	NSURL* url = [_urls objectForKey:keyObject];
	NSParameterAssert(url && [url isKindOfClass:[NSURL class]]);
	NSString* password = [url password];
	if(password==nil) {
		NSError* error = nil;
		password = [_passwords passwordForURL:url error:&error];
		if(error) {
			// TODO: Handle errors due to keychain access
			NSLog(@"Error getting password, %@",error);
		}
	}
	return password;
}

-(BOOL)setPassword:(NSString* )password forKey:(NSUInteger)key saveToKeychain:(BOOL)saveToKeychain {
	NSParameterAssert(key);
	NSNumber* keyObject = [NSNumber numberWithUnsignedInteger:key];
	NSURL* url = [_urls objectForKey:keyObject];
	NSParameterAssert(url && [url isKindOfClass:[NSURL class]]);
	return [_passwords setPassword:password forURL:url saveToKeychain:saveToKeychain];
}

////////////////////////////////////////////////////////////////////////////////
// PGConnectionDelegate methods

-(void)connection:(PGConnection* )connection willOpenWithParameters:(NSMutableDictionary* )dictionary {
	NSNumber* keyObject = [NSNumber numberWithUnsignedInteger:[connection tag]];
	NSParameterAssert(keyObject);
	NSURL* url = [_urls objectForKey:keyObject];
	NSParameterAssert(url);
	if([dictionary objectForKey:@"password"]==nil) {
		NSString* password = [_passwords passwordForURL:url];
		if(password) {
			[dictionary setObject:password forKey:@"password"];
		}
	}
#ifdef DEBUG
	if([dictionary objectForKey:@"password"]==nil) {
		NSLog(@"No password could be used to connect to %@",url);
	} else {
		NSLog(@"Password could be used to connect to %@",url);
	}
#endif	
}


@end
