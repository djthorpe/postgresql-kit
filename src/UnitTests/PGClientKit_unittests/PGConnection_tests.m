
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

#import <Foundation/Foundation.h>
#import <PGClientKit/PGClientKit.h>
#import "PGFoundationServer.h"
#import <XCTest/XCTest.h>

////////////////////////////////////////////////////////////////////////////////

PGFoundationServer* server = nil;
PGConnection* client = nil;
NSUInteger port = 9999;
BOOL lastTest = NO;

////////////////////////////////////////////////////////////////////////////////

@interface PGConnection_tests : XCTestCase <PGConnectionDelegate>

@end

////////////////////////////////////////////////////////////////////////////////

@implementation PGConnection_tests

////////////////////////////////////////////////////////////////////////////////

-(void)setUp {
    [super setUp];
	if(server==nil) {
		// create a server object
		server = [PGFoundationServer new];
		// signal the server to start
		if([server startWithPort:port] != YES) {
			XCTFail(@"Server could not be started");
		}
	}
}

-(void)tearDown {
	if(lastTest==YES) {
		// stop the server
		if(![server stop]) {
			XCTFail(@"Server could not be started");
		}
		// delete the data files
		NSString* dataPath = [server dataPath];
		NSError* error = nil;
		BOOL success = [[NSFileManager defaultManager] removeItemAtPath:dataPath error:&error];
		if(success==NO) {
			XCTFail(@"Error in tearDown: %@",[error localizedDescription]);
		}
	}
	// call superclass
    [super tearDown];
}

////////////////////////////////////////////////////////////////////////////////

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
	}
}

////////////////////////////////////////////////////////////////////////////////

-(void)test_000 {
	// check PGDefaultPort
	XCTAssertEqual(PGServerDefaultPort,(NSUInteger)5432,@"Incorrect default port");
}

-(void)test_001 {
	// create client object
	XCTAssertNil(client,@"client not nil");
	client = [[PGConnection alloc] init];
	[client setDelegate:self];
	XCTAssertTrue([client isKindOfClass:[PGConnection class]] ? YES : NO,@"client could not be created");
	
	XCTAssert([client serverProcessID]==0);
	XCTAssert([client timeout]==0);
	XCTAssert([client user]==nil);
	XCTAssert([client database]==nil);
}

-(void)test_002 {
	// check client
	XCTAssert(client);
	XCTAssertEqual([client status],PGConnectionStatusDisconnected);

	// perform connection in foreground
	NSURL* url = [NSURL URLWithSocketPath:nil port:port database:nil username:PGServerSuperuser params:nil];
	[client connectWithURL:url whenDone:^(BOOL usedPassword, NSError *error) {
		XCTAssertFalse(error,@"connectWithURL Error: %@",error);
	}];

	XCTAssertEqual([client status],PGConnectionStatusConnected);
	XCTAssert([client serverProcessID] != 0);
	XCTAssert([client user]);
	XCTAssert([client database]);
	
	// disconnect
	[client disconnect];

	XCTAssertEqual([client status],PGConnectionStatusDisconnected);
	XCTAssert([client serverProcessID]==0);
	XCTAssert([client timeout]==0);
	XCTAssert([client user]==nil);
	XCTAssert([client database]==nil);
}

-(void)test_003 {
	XCTAssertEqual([client status],PGConnectionStatusDisconnected);
	XCTAssert([client serverProcessID]==0);
	XCTAssert([client timeout]==0);
	XCTAssert([client user]==nil);
	XCTAssert([client database]==nil);

	// check for nil bad parameters
	[client connectWithURL:nil whenDone:^(BOOL usedPassword, NSError *error) {
		XCTAssertEqual([error code],PGClientErrorParameters,@"connectWithURL Error: %@",error);
	}];

	XCTAssertEqual([client status],PGConnectionStatusDisconnected);
	XCTAssert([client serverProcessID]==0);
	XCTAssert([client timeout]==0);
	XCTAssert([client user]==nil);
	XCTAssert([client database]==nil);
}


-(void)test_004 {
	XCTAssertEqual([client status],PGConnectionStatusDisconnected);
	XCTAssert([client serverProcessID]==0);
	XCTAssert([client timeout]==0);
	XCTAssert([client user]==nil);
	XCTAssert([client database]==nil);

	// perform ping in foreground
	NSURL* url = [NSURL URLWithSocketPath:nil port:port database:nil username:PGServerSuperuser params:nil];
	[client pingWithURL:url whenDone:^(NSError *error) {
		XCTAssertFalse(error,@"pingWithURL Error: %@",error);
	}];

	XCTAssertEqual([client status],PGConnectionStatusDisconnected);
	XCTAssert([client serverProcessID]==0);
	XCTAssert([client timeout]==0);
	XCTAssert([client user]==nil);
	XCTAssert([client database]==nil);
}

-(void)test_005 {
	// perform connection and then a reset in foreground

	XCTAssertEqual([client status],PGConnectionStatusDisconnected);
	XCTAssert([client serverProcessID]==0);
	XCTAssert([client timeout]==0);
	XCTAssert([client user]==nil);
	XCTAssert([client database]==nil);

	// perform connection in foreground
	NSURL* url = [NSURL URLWithSocketPath:nil port:port database:nil username:PGServerSuperuser params:nil];
	[client connectWithURL:url whenDone:^(BOOL usedPassword, NSError *error) {
		XCTAssertFalse(error,@"connectWithURL Error: %@",error);
	}];

	XCTAssertEqual([client status],PGConnectionStatusConnected);
	// TODO XCTAssertEqual([client serverProcessID],[server pid]);
	XCTAssertEqual([client timeout],0);
	XCTAssertEqualObjects([client user],PGServerSuperuser);
	XCTAssertEqualObjects([client database],PGServerSuperuser);

	[client resetWhenDone:^(NSError *error) {
		XCTAssertFalse(error,@"resetWhenDone Error: %@",error);
	}];

	
	// disconnect
	[client disconnect];

	XCTAssertEqual([client status],PGConnectionStatusDisconnected);
	XCTAssertEqual([client serverProcessID],0);
	XCTAssertEqual([client timeout],0);
	XCTAssertNil([client user]);
	XCTAssertNil([client database]);
}

-(void)test_999 {
	// signal last test, so that database is destroyed
	lastTest = YES;
}

@end
