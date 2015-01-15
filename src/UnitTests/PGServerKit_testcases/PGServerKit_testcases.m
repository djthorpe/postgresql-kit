
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
#import <PGServerKit/PGServerKit.h>
#import "PGFoundationServer.h"

////////////////////////////////////////////////////////////////////////////////

PGFoundationServer* app = nil;
PGServer* server = nil;
NSString* dataPath = nil;

////////////////////////////////////////////////////////////////////////////////

@interface PGServerKit_testcases : XCTestCase

@end

////////////////////////////////////////////////////////////////////////////////

@implementation PGServerKit_testcases

-(void)setUp {
    [super setUp];
    // TODO
}

- (void)tearDown {
    // TODO
    [super tearDown];
}

////////////////////////////////////////////////////////////////////////////////

-(void)test_001 {
    XCTAssert(server==nil,@"Test 001A");
    XCTAssert(dataPath==nil,@"Test 001B");
}

-(void)test_002 {
	dataPath = [PGFoundationServer defaultDataPath];
	server = [PGServer serverWithDataPath:dataPath];
    XCTAssert(server!=nil,@"Test 002");
}

-(void)test_003 {
    XCTAssert(PGServerSuperuser,@"Test 003");
}

-(void)test_004 {
    XCTAssert(PGServerDefaultPort,@"Test 004");
}

-(void)test_005 {
    XCTAssert([server state]==PGServerStateUnknown,@"Test 005");
}

-(void)test_006 {
    XCTAssert([server version],@"Test 006");
}

-(void)test_007 {
    XCTAssert([[server dataPath] isEqualToString:dataPath],@"Test 007");
	NSLog(@"dataPath=%@",[server dataPath]);
}

-(void)test_008 {
    XCTAssert([server socketPath]==nil,@"Test 008");
}

-(void)test_009 {
    XCTAssert([server hostname]==nil,@"Test 009");
}

-(void)test_010 {
    XCTAssert([server port]==0,@"Test 010");
}

-(void)test_011 {
	// pid should be -1 when class is initialized
    XCTAssert([server pid]==-1,@"Test 011");
}

-(void)test_012 {
    XCTAssert([server uptime]==0,@"Test 012");
}

-(void)test_013 {
    XCTAssert(app==nil,@"Test 013A");
	app = [[PGFoundationServer alloc] initWithServer:server];
    XCTAssert(app,@"Test 013B");
}

-(void)test_014 {
	BOOL isSuccess;
	
	// stop the server
	[self test_999];

	// remove the data directory
	NSLog(@"Deleting data at %@",[app dataPath]);
	isSuccess = [app deleteData];
	XCTAssert(isSuccess,@"Test 014A");

	// start the server
	isSuccess = [app start];
	XCTAssert(isSuccess,@"Test 014B");
}

-(void)test_015 {
	BOOL isSuccess;
	
	// stop the server
	[self test_999];

	// start the server
	isSuccess = [app start];
	XCTAssert(isSuccess,@"Test 015B");
	
	// check the properties
	XCTAssert([server pid],@"Test 015C");
	XCTAssert([server port]==PGServerDefaultPort,@"Test 015D");
	// TODO
}

-(void)test_999 {
	if(app && [app isStarted]) {
		BOOL isSuccess = [app stop];
		XCTAssert(isSuccess,@"Test 999A");
	}
	NSUInteger counter = 0;
	while([app isStopped]==NO) {
		[NSThread sleepForTimeInterval:0.5];
		XCTAssert(counter < 10,@"Test 999B");
		counter++;
	}
	// remove the data directory
	if([app dataPath]) {
		NSLog(@"Deleting data at %@",[app dataPath]);
		BOOL isSuccess = [app deleteData];
		XCTAssert(isSuccess,@"Test 015A");
	}
}


@end
