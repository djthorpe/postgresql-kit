
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

#import "PGUnitTester.h"

@implementation PGUnitTester

// constructor
-(instancetype)init {
    self = [super init];
    if (self) {
		_server = nil;
		_client = nil;
		_port = 9999;
		_lastTest = NO;
    }
    return self;
}

// properties
@synthesize server = _server;
@synthesize client = _client;
@synthesize port = _port;
@synthesize lastTest = _lastTest;
@dynamic url;

-(NSURL* )url {
	return [NSURL URLWithSocketPath:nil port:[self port] database:nil username:PGServerSuperuser params:nil];
}

// methods
-(BOOL)setUp {
	NSLog(@"setUp");
	if(_server == nil) {
		// create a server object
		_server = [PGFoundationServer new];
		// signal the server to start
		if([_server startWithPort:[self port]] != YES) {
			return NO;
		}
	}
	if(_client==nil) {
		_client = [PGConnection new];
		if(_client==nil) {
			return NO;
		}
		[_client setDelegate:self];
	}
	return YES;
}

-(BOOL)tearDown {
	NSLog(@"tearDown");

	if([self lastTest]==NO) {
		return YES;
	}

	// disconnect the client
	if([self client]) {
		[[self client] disconnect];
	}

	// stop the server
	if([[self server] stop]==NO) {
		return NO;
	}

	// delete the data files
	NSString* dataPath = [[self server] dataPath];
	NSError* error = nil;
	BOOL success = [[NSFileManager defaultManager] removeItemAtPath:dataPath error:&error];
	if(success==NO) {
		return NO;
	}

	// reset instance variables
	_client = nil;
	_server = nil;
	_lastTest = NO;

	return YES;
}

////////////////////////////////////////////////////////////////////////////////


-(void)connection:(PGConnection *)connection willOpenWithParameters:(NSMutableDictionary *)dictionary {
	NSLog(@"willopenwithparameters = %@",dictionary);
}

-(void)connection:(PGConnection *)connection statusChange:(PGConnectionStatus)status {
	switch(status) {
		case PGConnectionStatusConnected:
			NSLog(@"status change = PGConnectionStatusConnected");
			break;
		case PGConnectionStatusConnecting:
			NSLog(@"status change = PGConnectionStatusConnecting");
			break;
		case PGConnectionStatusDisconnected:
			NSLog(@"status change = PGConnectionStatusDisconnected");
			break;
		case PGConnectionStatusRejected:
			NSLog(@"status change = PGConnectionStatusRejected");
			break;
		case PGConnectionStatusBusy:
			NSLog(@"status change = PGConnectionStatusBusy");
			break;
	}
}


-(void)connection:(PGConnection* )connection error:(NSError *)error {
	NSLog(@"ERROR: %@",error);
}

////////////////////////////////////////////////////////////////////////////////

@end
