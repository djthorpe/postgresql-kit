
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

@interface NSString_PGNetworkValidationAdditions_tests : XCTestCase

@end

////////////////////////////////////////////////////////////////////////////////

@implementation NSString_PGNetworkValidationAdditions_tests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

////////////////////////////////////////////////////////////////////////////////

-(void)test_000 {
	NSString* ipAddress = @"0.0.0.0";
	XCTAssert([ipAddress isNetworkAddress]);
	XCTAssert([ipAddress isNetworkAddressV4]);
	XCTAssertFalse([ipAddress isNetworkAddressV6]);
	XCTAssertFalse([ipAddress isNetworkHostname]);
}

-(void)test_001 {
	NSString* ipAddress = @"256.0.0.0";
	XCTAssertFalse([ipAddress isNetworkAddress]);
	XCTAssertFalse([ipAddress isNetworkAddressV4]);
	XCTAssertFalse([ipAddress isNetworkAddressV6]);
	XCTAssert([ipAddress isNetworkHostname]);
}

-(void)test_002 {
	NSString* ipAddress = @"0.0.0.256";
	XCTAssertFalse([ipAddress isNetworkAddress]);
	XCTAssertFalse([ipAddress isNetworkAddressV4]);
	XCTAssertFalse([ipAddress isNetworkAddressV6]);
	XCTAssert([ipAddress isNetworkHostname]);
}

-(void)test_003 {
	NSString* ipAddress = @"255.255.255";
	XCTAssertFalse([ipAddress isNetworkAddress]);
	XCTAssertFalse([ipAddress isNetworkAddressV4]);
	XCTAssertFalse([ipAddress isNetworkAddressV6]);
	XCTAssert([ipAddress isNetworkHostname]);
}

-(void)test_004 {
	NSString* ipAddress = @"localhost";
	XCTAssertFalse([ipAddress isNetworkAddress]);
	XCTAssertFalse([ipAddress isNetworkAddressV4]);
	XCTAssertFalse([ipAddress isNetworkAddressV6]);
	XCTAssert([ipAddress isNetworkHostname]);
}


-(void)test_005 {
	NSString* ipAddress = @"a.b";
	XCTAssertFalse([ipAddress isNetworkAddress]);
	XCTAssertFalse([ipAddress isNetworkAddressV4]);
	XCTAssertFalse([ipAddress isNetworkAddressV6]);
	XCTAssert([ipAddress isNetworkHostname]);
}

@end
