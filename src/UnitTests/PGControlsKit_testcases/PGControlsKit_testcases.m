
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

PGSourceViewTree* tree = nil;

////////////////////////////////////////////////////////////////////////////////

@interface PGControlsKit_testcases : XCTestCase

@end

////////////////////////////////////////////////////////////////////////////////

@implementation PGControlsKit_testcases

-(void)setUp {
    [super setUp];
	tree = [PGSourceViewTree new];
}

-(void)tearDown {
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
	PGSourceViewTree* tree = [PGSourceViewTree new];
	XCTAssert(tree);

	// add a single node
	PGSourceViewNode* node001 = [[PGSourceViewNode alloc] initWithName:@"HEADER_001"];
	XCTAssert(node001);
	[tree addNode:node001 parent:nil];
	XCTAssert([tree count]==1);

	PGSourceViewNode* node002 = [[PGSourceViewNode alloc] initWithName:@"HEADER_002"];
	XCTAssert(node002);
	[tree addNode:node002 parent:nil];
	XCTAssert([tree count]==2);

	PGSourceViewNode* node003 = [[PGSourceViewNode alloc] initWithName:@"HEADER_003"];
	XCTAssert(node003);
	[tree addNode:node003 parent:nil];
	XCTAssert([tree count]==3);
	
	NSLog(@"tree=%@",[tree dictionary]);
}

-(void)test_003 {
	PGSourceViewTree* tree = [PGSourceViewTree new];
	XCTAssert(tree);

	// add a single node
	PGSourceViewNode* node001 = [[PGSourceViewNode alloc] initWithName:@"HEADER_001"];
	XCTAssert(node001);
	[tree addNode:node001 parent:nil];
	XCTAssert([tree count]==1);

	PGSourceViewNode* node002 = [[PGSourceViewNode alloc] initWithName:@"HEADER_002"];
	XCTAssert(node002);
	[tree addNode:node002 parent:nil];
	XCTAssert([tree count]==2);

	PGSourceViewNode* node003 = [[PGSourceViewNode alloc] initWithName:@"HEADER_003"];
	XCTAssert(node003);
	[tree addNode:node003 parent:nil];
	XCTAssert([tree count]==3);
	
	// add subnodes
	PGSourceViewNode* node004 = [[PGSourceViewNode alloc] initWithName:@"SUBNODE_004"];
	XCTAssert(node004);
	[tree addNode:node004 parent:node001];
	XCTAssert([tree count]==4);

	PGSourceViewNode* node005 = [[PGSourceViewNode alloc] initWithName:@"SUBNODE_005"];
	XCTAssert(node005);
	[tree addNode:node005 parent:node001];
	XCTAssert([tree count]==5);

	PGSourceViewNode* node006 = [[PGSourceViewNode alloc] initWithName:@"SUBNODE_006"];
	XCTAssert(node006);
	[tree addNode:node006 parent:node001];
	XCTAssert([tree count]==6);

	// check subnodes
	XCTAssert([tree nodeAtIndex:0 parent:node001]==node004);
	XCTAssert([tree nodeAtIndex:1 parent:node001]==node005);
	XCTAssert([tree nodeAtIndex:2 parent:node001]==node006);
	
	// check subnode counts
	XCTAssert([tree numberOfChildrenOfParent:node001]==3);
	XCTAssert([tree numberOfChildrenOfParent:node002]==0);
	XCTAssert([tree numberOfChildrenOfParent:node003]==0);
	XCTAssert([tree numberOfChildrenOfParent:node004]==0);
	XCTAssert([tree numberOfChildrenOfParent:node005]==0);
	XCTAssert([tree numberOfChildrenOfParent:node006]==0);

	NSLog(@"tree=%@",[tree dictionary]);
}

@end
