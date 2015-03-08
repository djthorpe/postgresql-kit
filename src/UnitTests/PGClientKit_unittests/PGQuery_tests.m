
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

@interface PGQuery_tests : XCTestCase
@property PGConnection* connection;
@end

////////////////////////////////////////////////////////////////////////////////

@implementation PGQuery_tests

-(void)setUp {
    [super setUp];
	[self setConnection:[PGConnection new]];
}

-(void)tearDown {
	[self setConnection:nil];
    [super tearDown];
}

-(void)test_001 {
	PGQuery* query = [PGQuery new];
	XCTAssertNil(query,@"new method does not return nil");
}

-(void)test_002 {
	NSString* statement = @"SELECT 1";
	PGQuery* query = [PGQuery queryWithString:statement];
	XCTAssertEqualObjects(statement,[query quoteForConnection:[self connection] error:nil],@"statements are not equal");
}

-(void)test_003 {
	NSString* statement = @"NULL";
	PGQueryPredicate* query = [PGQueryPredicate nullPredicate];
	XCTAssertEqualObjects(statement,[query quoteForConnection:[self connection] error:nil],@"statements are not equal");
}

-(void)test_004 {
	PGQueryPredicate* input = [PGQueryPredicate string:@"SELECT 1"];
	NSString* output = @"'SELECT 1'";
	NSString* comparison = [input quoteForConnection:[self connection] error:nil];
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_005 {
	PGQuerySelect* input = [PGQuerySelect select:@"table" options:0];
	NSString* output = @"SELECT * FROM table";
	NSString* comparison = [input quoteForConnection:[self connection] error:nil];
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

@end
