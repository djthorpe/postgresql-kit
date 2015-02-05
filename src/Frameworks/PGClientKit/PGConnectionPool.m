
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

#import "PGClientKit.h"
#import "PGClientKit+Private.h"

@implementation PGConnectionPool

////////////////////////////////////////////////////////////////////////////////
// constructors

-(id)init {
	self = [super init];
	if(self) {
		_connection = [NSMutableDictionary new];
		_url = [NSMutableDictionary new];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// private methods

+(id)keyForTag:(NSInteger)tag {
	return [NSNumber numberWithInteger:tag];
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(PGConnection* )connectionWithURL:(NSURL* )url tag:(NSInteger)tag error:(NSError** )error {
	NSParameterAssert(url);
	id key = [PGConnectionPool keyForTag:tag];
	NSParameterAssert(key);
	if([_connection objectForKey:key]) {
		// TODO: error - tag already exists
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

@end
