
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
#import <XCTest/XCTest.h>

////////////////////////////////////////////////////////////////////////////////

PGFoundationServer* server = nil;
PGConnection* client = nil;
NSUInteger port = 9999;
BOOL lastTest = NO;

////////////////////////////////////////////////////////////////////////////////

@interface PGConnection_tests : XCTestCase

@end

////////////////////////////////////////////////////////////////////////////////

@implementation PGConnection_tests

-(void)setUp {
    [super setUp];
	if(server==nil) {
		// create a server object
		server = [PGFoundationServer new];
		// signal the server to start
		if([server startWithPort:port] != YES) {
			STFail(@"Server could not be started");
		}
	}
}

-(void)tearDown {
	if(lastTest==YES) {
		// stop the server
		if(![server stop]) {
			STFail(@"Server could not be stopped");
		}
		// delete the data files
		NSString* dataPath = [server dataPath];
		NSError* error = nil;
		BOOL success = [[NSFileManager defaultManager] removeItemAtPath:dataPath error:&error];
		if(success==NO) {
			STFail(@"Error in tearDown: %@",[error localizedDescription]);
		}
	}
	// call superclass
    [super tearDown];
}

-(void)test_000 {
	// check PGDefaultPort
	STAssertEquals(PGServerDefaultPort,(NSUInteger)5432,@"Incorrect default port");
}

-(void)test_001 {
	// create client object
	STAssertNil(client,@"client not nil");
	client = [[PGConnection alloc] init];
	STAssertTrue([client isKindOfClass:[PGConnection class]] ? YES : NO,@"client could not be created");
}

-(void)test_002 {
	// perform connection
	NSURL* url = [NSURL URLWithSocketPath:nil port:port database:nil username:PGServerSuperuser params:nil];
	NSError* error = nil;
	BOOL connection = [client connectWithURL:url error:&error];
	STAssertTrue(connection,@"connectWithURL returned false: %@",[error localizedDescription]);
	// disconnection
	BOOL disconnected = [client disconnect];
	STAssertTrue(disconnected,@"disconnect returned false: %@",[error localizedDescription]);	
}

-(void)test_003 {
	// perform connection
	NSURL* url = [NSURL URLWithSocketPath:nil port:port database:nil username:PGServerSuperuser params:nil];
	NSError* error = nil;	
	client = [PGConnection connectionWithURL:url error:&error];
	STAssertNotNil(client,@"connectionWithURL returned false: %@",[error localizedDescription]);
	// disconnection
	BOOL disconnected = [client disconnect];
	STAssertTrue(disconnected,@"disconnect returned false: %@",[error localizedDescription]);	
}

-(void)test_004 {
	// ping server
	NSURL* url = [NSURL URLWithSocketPath:nil port:port database:nil username:PGServerSuperuser params:nil];
	NSError* error = nil;
	client = [[PGConnection alloc] init];
	BOOL pinged = [client pingWithURL:url error:&error];
	STAssertTrue(pinged, @"pingWithURL returned false: %@",[error localizedDescription]);
}

-(void)test_999 {
	// signal last test, so that database is destroyed
	lastTest = YES;
}

@end
