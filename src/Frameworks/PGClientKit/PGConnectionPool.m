
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

@implementation PGConnectionPool

////////////////////////////////////////////////////////////////////////////////
// constructors

-(id)init {
	self = [super init];
	if(self) {
		_connection = [NSMutableDictionary new];
		_url = [NSMutableDictionary new];
		_passwd = [PGPasswordStore new];
		NSParameterAssert(_connection && _url && _passwd);
		_useKeychain = YES;
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize passwordStore = _passwd;
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

-(void)setURL:(NSURL* )url forTag:(NSInteger)tag {
	NSParameterAssert(url);
	id key = [PGConnectionPool keyForTag:tag];
	NSParameterAssert(key);
	[_url setObject:url forKey:key];
}

-(NSURL* )URLForTag:(NSInteger)tag {
	id key = [PGConnectionPool keyForTag:tag];
	NSParameterAssert(key);
	return [_url objectForKey:key];
}

-(BOOL)connectWithTag:(NSInteger)tag whenDone:(void(^)(NSError* error)) callback {
	id key = [PGConnectionPool keyForTag:tag];
	NSParameterAssert(key);
	PGConnection* connection = [_connection objectForKey:key];
	if(connection==nil) {
		return NO;
	}
	NSURL* url = [_url objectForKey:key];
	if(url==nil) {
		return NO;
	}
	return [connection connectInBackgroundWithURL:url whenDone:callback];
}

-(BOOL)disconnectWithTag:(NSInteger)tag {
	id key = [PGConnectionPool keyForTag:tag];
	NSParameterAssert(key);
	PGConnection* connection = [_connection objectForKey:key];
	if(connection==nil) {
		return NO;
	}
	return [connection disconnect];
}

-(BOOL)removeWithTag:(NSInteger)tag {
	id key = [PGConnectionPool keyForTag:tag];
	NSParameterAssert(key);
	BOOL returnValue = [self disconnectWithTag:tag];
	[_connection removeObjectForKey:key];
	[_url removeObjectForKey:key];
	return returnValue;
}

-(void)removeAll {
	for(PGConnection* connection in [self connections]) {
		NSParameterAssert(connection);
		[self removeWithTag:[connection tag]];
	}
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

-(PGResult* )execute:(NSString* )query forTag:(NSInteger)tag {
	id key = [PGConnectionPool keyForTag:tag];
	NSParameterAssert(key);
	PGConnection* connection = [_connection objectForKey:key];
	if([connection status]==PGConnectionStatusConnected) {
		NSError* error = nil;
		return [connection execute:query error:&error];
	} else {
		return nil;
	}
}

////////////////////////////////////////////////////////////////////////////////
// PGConnectionDelegate

-(void)connection:(PGConnection* )connection willOpenWithParameters:(NSMutableDictionary* )dictionary {
	// retrieve password from store
	NSParameterAssert([self passwordStore]);
	if([dictionary objectForKey:@"password"]==nil) {
		NSError* error = nil;
		NSURL* url = [self URLForTag:[connection tag]];
		NSParameterAssert(url);
		NSString* password = [[self passwordStore] passwordForURL:url readFromKeychain:[self useKeychain] error:&error];
		if(password) {
			[dictionary setObject:password forKey:@"password"];
		}
		if(error) {
			NSLog(@"connection:willOpenWithParameters: error: %@",error);
		}
	}
}

// cludge to make this send message to the delegate on the main thread

-(void)errorMainThread:(NSArray* )payload {
	NSError* error = payload[0];
	NSNumber* tag = payload[1];
	if([[self delegate] respondsToSelector:@selector(connectionPool:tag:error:)]) {
		[[self delegate] connectionPool:self tag:[tag integerValue] error:error];
	}
}

-(void)connection:(PGConnection* )connection error:(NSError* )error {
	NSArray* payload = @[error,[NSNumber numberWithInteger:[connection tag]]];
	[self performSelectorOnMainThread:@selector(errorMainThread:) withObject:payload waitUntilDone:YES];
}

// cludge to make this send message to the delegate on the main thread
typedef struct {
    NSUInteger tag;
	PGConnectionStatus status;
} PGConnectionDelegateTagStatus;

-(void)statusChangeMainThread:(NSValue* )value {
	PGConnectionDelegateTagStatus payload;
	[value getValue:&payload];
	if([[self delegate] respondsToSelector:@selector(connectionPool:tag:statusChanged:)]) {
		[[self delegate] connectionPool:self tag:payload.tag statusChanged:payload.status];
	}
}

-(void)connection:(PGConnection* )connection statusChange:(PGConnectionStatus)status {
	// perform this on the main thread
	PGConnectionDelegateTagStatus payload = { [connection tag],status };
	NSValue* value = [NSValue valueWithBytes:&payload objCType:@encode(PGConnectionDelegateTagStatus)];
	[self performSelectorOnMainThread:@selector(statusChangeMainThread:) withObject:value waitUntilDone:YES];
}

@end
