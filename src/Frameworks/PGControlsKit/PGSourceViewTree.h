
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
#import <PGControlsKit/PGControlsKit.h>

@interface PGSourceViewTree : NSObject {
	NSMutableDictionary* _tags;
	NSMutableDictionary* _children;
	NSInteger _counter;
}

// properties
@property (readonly) NSUInteger count;

// methods
-(void)removeAllNodes;
-(void)removeNode:(PGSourceViewNode* )node;
-(NSInteger)addNode:(PGSourceViewNode* )node parent:(PGSourceViewNode* )parent;
-(NSInteger)addNode:(PGSourceViewNode* )node parent:(PGSourceViewNode* )parent tag:(NSInteger)tag;
-(PGSourceViewNode* )nodeAtIndex:(NSInteger)index parent:(PGSourceViewNode* )parent;
-(NSInteger)numberOfChildrenOfParent:(PGSourceViewNode* )parent;
-(PGSourceViewNode* )nodeForTag:(NSInteger)tag;
-(NSInteger)tagForNode:(PGSourceViewNode* )node;
-(BOOL)moveNode:(PGSourceViewNode* )node parent:(PGSourceViewNode* )parent index:(NSInteger)index;

// methods - NSUserDefaults
-(BOOL)loadFromUserDefaults;
-(BOOL)saveToUserDefaults;

@end
