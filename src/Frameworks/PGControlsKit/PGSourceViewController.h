
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

#import <Cocoa/Cocoa.h>

////////////////////////////////////////////////////////////////////////////////

@protocol PGSourceViewDelegate <NSObject>
@optional
	-(void)sourceView:(PGSourceViewController* )sourceView selectedNode:(PGSourceViewNode* )node;
	-(void)sourceView:(PGSourceViewController* )sourceView deleteNode:(PGSourceViewNode* )node;
	-(void)sourceView:(PGSourceViewController* )sourceView doubleClickedNode:(PGSourceViewNode* )node;
	-(NSMenu* )sourceView:(PGSourceViewController* )sourceView menuForNode:(PGSourceViewNode* )node;
@end

////////////////////////////////////////////////////////////////////////////////

@interface PGSourceViewController : NSViewController <NSOutlineViewDelegate,NSOutlineViewDataSource>

// properties
@property (readonly) NSUInteger count;
@property (weak,nonatomic) id<PGSourceViewDelegate> delegate;

// methods - getting information about the source view
-(PGSourceViewNode* )clickedNode;
-(PGSourceViewNode* )selectedNode;
-(PGSourceViewNode* )nodeForTag:(NSInteger)tag;
-(NSInteger)tagForNode:(PGSourceViewNode* )node;

// methods - adding nodes
-(NSInteger)addNode:(PGSourceViewNode* )node parent:(PGSourceViewNode* )parent;
-(NSInteger)addNode:(PGSourceViewNode* )node parent:(PGSourceViewNode* )parent tag:(NSInteger)tag;

// methods - modifying the source view
-(BOOL)selectNode:(PGSourceViewNode* )node;
-(void)expandNode:(PGSourceViewNode* )node;
-(void)reloadNode:(PGSourceViewNode* )node;

// methods - removing nodes
-(void)removeNode:(PGSourceViewNode* )node;
-(void)removeAllNodes;

// methods - NSUserDefaults
-(BOOL)loadFromUserDefaults;
-(BOOL)saveToUserDefaults;

@end
