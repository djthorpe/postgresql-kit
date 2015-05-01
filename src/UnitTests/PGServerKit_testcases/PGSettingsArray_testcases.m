
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

@interface PGSettingsArray_testcases : XCTestCase {
	PGFoundationServer* _server;
	BOOL _lastTest;
}

@property (readonly) PGServer* server;

@end

////////////////////////////////////////////////////////////////////////////////

@implementation PGSettingsArray_testcases

@dynamic server;

-(PGServer* )server {
	return [_server pgserver];
}

-(void)setUp {
    [super setUp];
	if(_server==nil) {
		_server = [[PGFoundationServer alloc] init];
		_lastTest = NO;
	}
	XCTAssert(_server);
	if(_server && [_server isStarted]==NO) {
		[_server start];
	}
}

- (void)tearDown {
	if(_lastTest && _server) {
		[_server stop];
	}
    [super tearDown];
}

////////////////////////////////////////////////////////////////////////////////

-(void)test_001 {
	XCTAssert([_server isStarted]==YES);
}

-(void)test_002 {
	XCTAssert([_server isStarted]==YES);
	NSData* settings = [[self server] readSettingsConfiguration];
	XCTAssert(settings);
}

-(void)test_003 {
	XCTAssert([_server isStarted]==YES);
	NSData* data = [[self server] readSettingsConfiguration];
	PGSettingsArray* settings = [[PGSettingsArray alloc] initWithData:data];
	NSLog(@"settings = %@",settings);
	XCTAssert(settings);
}

-(void)test_999 {
	_lastTest = YES;
}

@end
