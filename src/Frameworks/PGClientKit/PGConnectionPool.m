
// Copyright 2009-2015 David Thorpe
// https://github.com/djthorpe/postgresql-kit
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

#import <PGClientKit/PGClientKit.h>
#import <PGClientKit/PGClientKit+Private.h>

enum {
	PGConnectionPoolTypeSimple = 0x0001 // only one connection per URL
};

@implementation PGConnectionPool

////////////////////////////////////////////////////////////////////////////////
// constructors

+(instancetype)sharedPool {
	static PGConnectionPool* pool = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		pool = [[self alloc] initWithType:PGConnectionPoolTypeSimple];
		NSParameterAssert(pool);
	});
	return pool;
}

-(id)init {
	return nil;
}

-(instancetype)initWithType:(int)poolType {
	self = [super init];
	if(self) {
		_type = poolType;
		_connection = [NSMutableDictionary new];
		_url = [NSMutableDictionary new];
		_passwords = [PGPasswordStore new];
		NSParameterAssert(_connection && _url && _passwords);
		_useKeychain = YES;
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize passwords = _passwords;
@synthesize useKeychain = _useKeychain;
@dynamic connections;

-(NSArray* )connections {
	return [_connection allValues];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

+(id)keyForTag:(NSInteger)tag {
	return [NSNumber numberWithInteger:tag];
}

-(NSInteger)_tagForConnection:(PGConnection* )connection {
	return [connection tag];
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(PGConnection* )createConnectionWithURL:(NSURL* )url tag:(NSInteger)tag {
	NSParameterAssert(url);
	id key = [PGConnectionPool keyForTag:tag];
	NSParameterAssert(key);
	if([_connection objectForKey:key]) {
		return nil;
	}
	NSParameterAssert([_url objectForKey:key]==nil);

	// create connection, set delegate
	PGConnection* connection = [PGConnection new];
	[connection setTag:tag];
	[connection setDelegate:self];

	// set objects
	[_url setObject:[url copy] forKey:key];
	[_connection setObject:connection forKey:key];

	// return connection
	return connection;
}

-(BOOL)connectForTag:(NSInteger)tag whenDone:(void(^)(NSError* error)) callback {
	id key = [PGConnectionPool keyForTag:tag];
	NSParameterAssert(key);
	PGConnection* connection = [_connection objectForKey:key];
	if(connection==nil) {
		return NO;
	}
	// if already connected, then ignore
	if([connection status]==PGConnectionStatusConnected || [connection status]==PGConnectionStatusBusy) {
		return NO;
	}
	// what is the URL we need to use
	NSURL* url = [_url objectForKey:key];
	if(url==nil) {
		return NO;
	}
	// perform the connection
	[connection connectWithURL:url whenDone:^(BOOL usedPassword, NSError *error) {
		if(usedPassword==YES && error==nil && [self useKeychain]) {
			// store password
			NSLog(@"TODO: store password in keychain");
		}
		callback(error);
	}];
	// return YES
	return YES;
}

-(BOOL)disconnectForTag:(NSInteger)tag {
	id key = [PGConnectionPool keyForTag:tag];
	NSParameterAssert(key);
	PGConnection* connection = [_connection objectForKey:key];
	if(connection==nil) {
		return NO;
	}
	if([connection status]==PGConnectionStatusConnected || [connection status]==PGConnectionStatusBusy) {
		[connection disconnect];
	}
	return YES;
}

-(BOOL)removeForTag:(NSInteger)tag {
	id key = [PGConnectionPool keyForTag:tag];
	NSParameterAssert(key);

	// fetch the URL
	NSURL* url = [self URLForTag:tag];
	if(url==nil) {
		return NO;
	}

	// disconnect
	BOOL returnValue = [self disconnectForTag:tag];

	// remove information about the connection
	[_connection removeObjectForKey:key];
	[_url removeObjectForKey:key];
	[[self passwords] removePasswordForURL:url saveToKeychain:NO error:nil];
	
	// return success
	return returnValue;
}

-(BOOL)removeAll {
	BOOL returnValue = YES;
	for(PGConnection* connection in [self connections]) {
		NSParameterAssert(connection);
		if([self removeForTag:[connection tag]]==NO) {
			returnValue = NO;
		}
	}
	[_connection removeAllObjects];
	[_url removeAllObjects];
	return returnValue;
}

-(BOOL)setPassword:(NSString* )password forTag:(NSInteger)tag saveInKeychain:(BOOL)saveInKeychain {
	NSURL* url = [self URLForTag:tag];
	if(url==nil) {
		return NO;
	}
	NSError* error = nil;
	BOOL returnValue = [[self passwords] setPassword:password forURL:url saveToKeychain:saveInKeychain error:&error];
	if(error && [[self delegate] respondsToSelector:@selector(connectionForTag:error:)]) {
		[[self delegate] connectionForTag:tag error:error];
	}
	return returnValue;
}

-(BOOL)removePasswordForTag:(NSInteger)tag {
	NSURL* url = [self URLForTag:tag];
	if(url==nil) {
		return NO;
	}
	NSError* error = nil;
	BOOL returnValue = [[self passwords] removePasswordForURL:url saveToKeychain:[self useKeychain] error:&error];
	if(error && [[self delegate] respondsToSelector:@selector(connectionForTag:error:)]) {
		[[self delegate] connectionForTag:tag error:error];
	}
	return returnValue;
}

-(NSURL* )URLForTag:(NSInteger)tag {
	id key = [PGConnectionPool keyForTag:tag];
	NSParameterAssert(key);
	return [_url objectForKey:key];
}

-(PGConnectionStatus)statusForTag:(NSInteger)tag {
	id key = [PGConnectionPool keyForTag:tag];
	NSParameterAssert(key);
	PGConnection* connection = [_connection objectForKey:key];
	if(connection==nil) {
		return PGConnectionStatusDisconnected;
	}
	return [connection status];
}

-(PGConnection* )connectionForTag:(NSInteger)tag {
	id key = [PGConnectionPool keyForTag:tag];
	NSParameterAssert(key);
	return [_connection objectForKey:key];
}

-(BOOL)execute:(PGTransaction* )transaction forTag:(NSInteger)tag whenDone:(void(^)(PGResult* result,NSError* error)) callback {
	id key = [PGConnectionPool keyForTag:tag];
	NSParameterAssert(key);
	PGConnection* connection = [_connection objectForKey:key];
	if([connection status] != PGConnectionStatusConnected && [connection status] != PGConnectionStatusBusy) {
		return NO;
	}
	// only runs the callback on the last query
	[connection queue:transaction whenQueryDone:^(PGResult* result, BOOL isLastQuery, NSError* error) {
		if(isLastQuery) {
			callback(result,error);
		}
	}];
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// PGConnectionDelegate

-(void)connection:(PGConnection* )connection error:(NSError* )error {
	if(error && [[self delegate] respondsToSelector:@selector(connectionForTag:error:)]) {
		NSInteger tag = [self _tagForConnection:connection];
		[[self delegate] connectionForTag:tag error:error];
	}
}

-(void)connection:(PGConnection* )connection notice:(NSString* )notice {
	if([[self delegate] respondsToSelector:@selector(connectionForTag:notice:)]) {
		NSInteger tag = [self _tagForConnection:connection];
		[[self delegate] connectionForTag:tag notice:notice];
	}
}

-(void)connection:(PGConnection* )connection notificationOnChannel:(NSString* )channelName payload:(NSString* )payload {
	if([[self delegate] respondsToSelector:@selector(connectionForTag:notificationOnChannel:payload:)]) {
		NSInteger tag = [self _tagForConnection:connection];
		[[self delegate] connectionForTag:tag notificationOnChannel:channelName payload:payload];
	}
}

-(void)connection:(PGConnection* )connection statusChange:(PGConnectionStatus)status description:(NSString* )description {
	if([[self delegate] respondsToSelector:@selector(connectionForTag:statusChanged:description:)]) {
		NSInteger tag = [self _tagForConnection:connection];
		[[self delegate] connectionForTag:tag statusChanged:status description:description];
	}
}

-(void)connection:(PGConnection* )connection willExecute:(NSString* )query {
	if([[self delegate] respondsToSelector:@selector(connectionForTag:willExecute:)]) {
		NSInteger tag = [self _tagForConnection:connection];
		[[self delegate] connectionForTag:tag willExecute:query];
	}
}

-(void)connection:(PGConnection* )connection willOpenWithParameters:(NSMutableDictionary* )dictionary {

	// give client opportunity to fudge with the parameters before opening
	if([[self delegate] respondsToSelector:@selector(connectionWithTag:willOpenWithParameters:)]) {
		NSInteger tag = [self _tagForConnection:connection];
		[[self delegate] connectionForTag:tag willOpenWithParameters:dictionary];
	}

	// get URL & password
	NSURL* url = [self URLForTag:[connection tag]];
	NSParameterAssert(url);
	NSString* password = [dictionary objectForKey:@"password"];
	
	// retrieve password from store
	if(password==nil) {
		NSError* error = nil;
		NSString* password = [[self passwords] passwordForURL:url readFromKeychain:[self useKeychain] error:&error];
		if(password) {
			[dictionary setObject:password forKey:@"password"];
		}
		if(error) {
			[self connection:connection error:error];
		}
	} else {
		// store password temporarily
		[[self passwords] setPassword:password forURL:url saveToKeychain:NO];
	}	
}

@end
