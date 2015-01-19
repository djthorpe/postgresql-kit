
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
#import <PGControlsKit/PGSourceViewTree.h>

////////////////////////////////////////////////////////////////////////////////

@interface PGControlsKit_testcases : XCTestCase

@end

////////////////////////////////////////////////////////////////////////////////

@implementation PGControlsKit_testcases

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
	NSString* name = @"TEST";
	PGSourceViewNode* node = [[PGSourceViewNode alloc] initWithName:name];
	XCTAssert(node);
	XCTAssert([[node name] isEqual:name]);
}

-(void)test_002 {
	NSString* name = @"HEADER NODE";
	PGSourceViewNode* node = [[PGSourceViewNode alloc] initWithName:name];
	XCTAssert(node);
	PGSourceViewTree* tree = [PGSourceViewTree new];
	XCTAssert(tree);
	[tree addNode:node parent:nil];
	NSLog(@"tree=%@",[tree dictionary]);
}



@end
