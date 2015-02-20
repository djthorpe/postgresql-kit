
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

@interface PGSourceViewNode : NSObject {
	NSString* _name;
	NSMutableDictionary* _dictionary;
}

// constructors
+(PGSourceViewNode* )headingWithName:(NSString* )name;
+(PGSourceViewNode* )connectionWithURL:(NSURL* )url;
+(PGSourceViewNode* )nodeFromDictionary:(NSDictionary* )dictionary;

// properties
@property NSString* name;
@property (readonly) BOOL isGroupItem;
@property (readonly) BOOL isSelectable;
@property (readonly) BOOL isNameEditable;
@property (readonly) BOOL isDraggable;
@property (readonly) BOOL isDeletable;
@property (retain) NSArray* childClasses;
@property (readonly) NSDictionary* dictionary;

// methods
-(NSDictionary* )dictionaryWithKey:(id)key;
-(NSTableCellView* )cellViewForOutlineView:(NSOutlineView* )outlineView tableColumn:(NSTableColumn* )tableColumn owner:(id)owner tag:(NSInteger)tag;
-(BOOL)canAcceptDrop:(PGSourceViewNode* )node;
-(void)writeToPasteboard:(NSPasteboard* )pboard;

@end
