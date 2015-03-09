
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
	
	// perform connection
	XCTAssert([tester url]);
	XCTestExpectation* expectation = [self expectationWithDescription:@"Connect"];
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
	
	
}

-(void)tearDown {
	// disconnect client
	[[tester client] disconnect];
	// potentially disconnect server
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

-(void)test_006 {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQuerySelect* input = [PGQuerySelect select:@"table" options:PGQueryOptionDistinct];
	NSString* output = @"SELECT DISTINCT * FROM table";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_007 {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQuerySelect* input = [PGQuerySelect select:@"table" options:PGQueryOptionDistinct];
	[input setLimit:1];
	NSString* output = @"SELECT DISTINCT * FROM table LIMIT 1";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_008 {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQuerySelect* input = [PGQuerySelect select:@"table" options:PGQueryOptionDistinct];
	[input setLimit:PGQuerySelectNoLimit];
	NSString* output = @"SELECT DISTINCT * FROM table";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_009 {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQuerySelect* input = [PGQuerySelect select:@"table" options:PGQueryOptionDistinct];
	[input setLimit:0];
	NSString* output = @"SELECT DISTINCT * FROM table LIMIT 0";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_010 {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQuerySelect* input = [PGQuerySelect select:@"table" options:PGQueryOptionDistinct];
	[input setOffset:0];
	NSString* output = @"SELECT DISTINCT * FROM table";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_011 {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQuerySelect* input = [PGQuerySelect select:@"table" options:PGQueryOptionDistinct];
	[input setOffset:1];
	NSString* output = @"SELECT DISTINCT * FROM table OFFSET 1";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_012 {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQuerySelect* input = [PGQuerySelect select:@"table" options:PGQueryOptionDistinct];
	[input setOffset:10 limit:10];
	NSString* output = @"SELECT DISTINCT * FROM table OFFSET 10 LIMIT 10";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_013 {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQuerySelect* input = [PGQuerySelect select:@"table" options:0];
	[input andWhere:@"NULL"];
	NSString* output = @"SELECT * FROM table WHERE NULL";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_014 {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQuerySelect* input = [PGQuerySelect select:@"table" options:0];
	[input andWhere:@"NULL1"];
	[input andWhere:@"NULL2"];
	NSString* output = @"SELECT * FROM table WHERE NULL1 AND NULL2";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_015 {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQuerySelect* input = [PGQuerySelect select:@"table" options:0];
	[input andWhere:@"NULL1"];
	[input orWhere:@"NULL2"];
	NSString* output = @"SELECT * FROM table WHERE (NULL1 OR NULL2)";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_016 {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQuerySelect* input = [PGQuerySelect select:@"table" options:0];
	[input andWhere:@"NULL1"];
	[input orWhere:@"NULL2"];
	[input orWhere:@"NULL3"];
	NSString* output = @"SELECT * FROM table WHERE (NULL1 OR NULL2 OR NULL3)";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_999 {
	[tester setLastTest:YES];
}

@end
