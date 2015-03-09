
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

@interface PGQuery_tests : XCTestCase {
	PGUnitTester* tester;
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation PGQuery_tests

////////////////////////////////////////////////////////////////////////////////

-(instancetype)init {
	self = [super init];
	if(self) {
		tester = [PGUnitTester new];
		NSParameterAssert(tester);
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////

-(void)setUp {
    [super setUp];
	if(tester==nil) {
		tester = [PGUnitTester new];
	}
	XCTAssertTrue([tester setUp]);
	XCTAssertTrue([tester connectClientToServer]);
}

-(void)tearDown {
    XCTAssertTrue([tester tearDown]);
	[super tearDown];
}

////////////////////////////////////////////////////////////////////////////////

-(void)test_001 {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQuery* query = [PGQuery new];
	XCTAssertNil(query,@"new method does not return nil");
}

-(void)test_002 {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	NSString* statement = @"SELECT 1";
	PGQuery* query = [PGQuery queryWithString:statement];
	XCTAssertEqualObjects(statement,[query quoteForConnection:client error:nil],@"statements are not equal");
}

-(void)test_003 {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	NSString* statement = @"NULL";
	PGQueryPredicate* query = [PGQueryPredicate nullPredicate];
	XCTAssertEqualObjects(statement,[query quoteForConnection:client error:nil],@"statements are not equal");
}

-(void)test_004 {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQueryPredicate* input = [PGQueryPredicate string:@"SELECT 1"];
	NSString* output = @"'SELECT 1'";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_005 {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQuerySelect* input = [PGQuerySelect select:@"table" options:0];
	NSString* output = @"SELECT * FROM table";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_999 {
	[tester setLastTest:YES];
}

@end
