
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
#import <XCTest/XCTest.h>
#import <PGClientKit/PGClientKit.h>
#import "PGUnitTester.h"

////////////////////////////////////////////////////////////////////////////////

@interface PGConnection_tests : XCTestCase <PGConnectionDelegate> {
	PGUnitTester* tester;
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation PGConnection_tests

////////////////////////////////////////////////////////////////////////////////

-(void)setUp {
    [super setUp];
	if(tester==nil) {
		tester = [PGUnitTester new];
	}
	XCTAssertTrue([tester setUp]);
}

-(void)tearDown {
    XCTAssertTrue([tester tearDown]);
	[super tearDown];
}

////////////////////////////////////////////////////////////////////////////////

-(void)test_000 {
	// check PGDefaultPort
	XCTAssertEqual(PGServerDefaultPort,(NSUInteger)5432,@"Incorrect default port");
}

-(void)test_001 {
	XCTAssertTrue([[tester client] isKindOfClass:[PGConnection class]] ? YES : NO,@"client could not be created");
	XCTAssert([[tester client] serverProcessID]==0);
	XCTAssert([[tester client] timeout]==0);
	XCTAssert([[tester client] user]==nil);
	XCTAssert([[tester client] database]==nil);
}

-(void)test_002 {
	// check client
	XCTAssert([tester client]);
	XCTAssertEqual([[tester client] status],PGConnectionStatusDisconnected);

	// perform connection
	XCTAssert([tester url]);
	XCTestExpectation* expectation = [self expectationWithDescription:@"Conect"];
	[[tester client] connectWithURL:[tester url] whenDone:^(BOOL usedPassword, NSError *error) {
		XCTAssert(usedPassword==NO);
		XCTAssert(error==nil);
		XCTAssertEqual([[tester client] status],PGConnectionStatusConnected);
		XCTAssert([[tester client] serverProcessID] != 0);
		XCTAssert([[tester client] user]);
		XCTAssert([[tester client] database]);
		[expectation fulfill];
	}];

	// wait for callback to complete
	[self waitForExpectationsWithTimeout:1.0 handler:^(NSError *error) {
		XCTAssertNil(error,@"Timeout Error: %@", error);
	}];
	
	// disconnect
	[[tester client] disconnect];

	XCTAssertEqual([[tester client] status],PGConnectionStatusDisconnected);
	XCTAssert([[tester client] serverProcessID]==0);
	XCTAssert([[tester client] timeout]==0);
	XCTAssert([[tester client] user]==nil);
	XCTAssert([[tester client] database]==nil);
}

-(void)test_003 {
	XCTAssertEqual([[tester client] status],PGConnectionStatusDisconnected);
	XCTAssert([[tester client] serverProcessID]==0);
	XCTAssert([[tester client] timeout]==0);
	XCTAssert([[tester client] user]==nil);
	XCTAssert([[tester client] database]==nil);

	// check for nil bad parameters
	[[tester client] connectWithURL:[NSURL URLWithString:@""] whenDone:^(BOOL usedPassword, NSError *error) {
		XCTAssertEqual([error code],PGClientErrorParameters,@"connectWithURL Error: %@",error);
	}];

	XCTAssertEqual([[tester client] status],PGConnectionStatusDisconnected);
	XCTAssert([[tester client] serverProcessID]==0);
	XCTAssert([[tester client] timeout]==0);
	XCTAssert([[tester client] user]==nil);
	XCTAssert([[tester client] database]==nil);
}


-(void)test_004 {
	XCTAssertEqual([[tester client] status],PGConnectionStatusDisconnected);
	XCTAssert([[tester client] serverProcessID]==0);
	XCTAssert([[tester client] timeout]==0);
	XCTAssert([[tester client] user]==nil);
	XCTAssert([[tester client] database]==nil);

	// perform ping in foreground
	NSURL* url = [tester url];
	[[tester client] pingWithURL:url whenDone:^(NSError *error) {
		XCTAssertFalse(error,@"pingWithURL Error: %@",error);
	}];

	XCTAssertEqual([[tester client] status],PGConnectionStatusDisconnected);
	XCTAssert([[tester client] serverProcessID]==0);
	XCTAssert([[tester client] timeout]==0);
	XCTAssert([[tester client] user]==nil);
	XCTAssert([[tester client] database]==nil);
}

/*
-(void)test_005 {
	// perform connection and then a reset in foreground

	XCTAssertEqual([[tester client] status],PGConnectionStatusDisconnected);
	XCTAssert([[tester client] serverProcessID]==0);
	XCTAssert([[tester client] timeout]==0);
	XCTAssert([[tester client] user]==nil);
	XCTAssert([[tester client] database]==nil);

	// perform connection in foreground
	NSURL* url = [tester url];
	[[tester client] connectWithURL:url whenDone:^(BOOL usedPassword, NSError *error) {
		XCTAssertFalse(error,@"connectWithURL Error: %@",error);
	}];

	XCTAssertEqual([[tester client] status],PGConnectionStatusConnected);
	// TODO XCTAssertEqual([client serverProcessID],[server pid]);
	XCTAssertEqual([[tester client] timeout],0);
	XCTAssertEqualObjects([[tester client] user],PGServerSuperuser);
	XCTAssertEqualObjects([[tester client] database],PGServerSuperuser);

	[[tester client] resetWhenDone:^(NSError *error) {
		XCTAssertFalse(error,@"resetWhenDone Error: %@",error);
	}];

	
	// disconnect
	[[tester client] disconnect];

	XCTAssertEqual([[tester client] status],PGConnectionStatusDisconnected);
	XCTAssertEqual([[tester client] serverProcessID],0);
	XCTAssertEqual([[tester client] timeout],0);
	XCTAssertNil([[tester client] user]);
	XCTAssertNil([[tester client] database]);
}
*/

-(void)test_999 {
	// signal last test, so that database is destroyed
	[tester setLastTest:YES];
}

@end
