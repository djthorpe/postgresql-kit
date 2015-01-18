
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

#import <PGControlsKit/PGControlsKit.h>

@interface PGSourceViewController ()
@property (readonly) NSMutableDictionary* nodes;
@property (readonly) NSMutableDictionary* children;
@property (assign) NSUInteger counter;
@property (weak) IBOutlet NSOutlineView* ibOutlineView;
@end

@implementation PGSourceViewController

////////////////////////////////////////////////////////////////////////////////
// constructors

-(id)init {
    self = [super initWithNibName:@"PGSourceView" bundle:[NSBundle bundleForClass:[self class]]];
	if(self) {
		_nodes = [NSMutableDictionary new];
		_children = [NSMutableDictionary new];
		NSParameterAssert(_nodes && _children);
		_counter = 0;
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize nodes = _nodes;
@synthesize children = _children;
@synthesize counter = _counter;
@synthesize ibOutlineView;

////////////////////////////////////////////////////////////////////////////////
// methods

-(id)_getNewTag {
	do {
		id tag = [NSNumber numberWithUnsignedInteger:(_counter++)];
		if([_nodes objectForKey:tag]==nil) {
			// no existing tag
			return tag;
		}
	} while(_counter <= NSUIntegerMax);
	return nil;
}

-(id)rootTag {
	id tag = [NSNumber numberWithUnsignedInteger:0];
	return tag;
}

-(id)_addNode:(PGSourceViewNode* )node {
	NSParameterAssert(node);
	// add node into dictionary of nodes, and return a unique tag for the node
	id tag = [self _getNewTag];
	// check to ensure no tag in either dictionary
	NSParameterAssert([[self nodes] objectForKey:tag]==nil);
	NSParameterAssert([[self children] objectForKey:tag]==nil);
	[[self nodes] setObject:node forKey:tag];
	[[self children] setObject:[NSMutableArray new] forKey:tag];
	return tag;
}

-(void)_addTag:(id)tag parent:(id)parent {
	NSParameterAssert(tag);
	if(parent==nil) {
		parent = [self _rootTag];
	}
	NSMutableArray* children = [_tree objectForKey:parent];
	if(parent==nil) {
		children = [NSMutableArray new];
		[_tree setObject:children forKey:parent];
	}
	[children addObject:tag];
}

-(void)addRootNode:(PGSourceViewNode* )node {
	NSParameterAssert(node);
	// add node, return tag
	id tag = [self _addNode:node];
	NSParameterAssert(tag);
	// add tag to tree
	[self _addTag:tag parent:nil];
}

-(void)addHeadingWithTitle:(NSString* )title {
	PGSourceViewNode* node = [[PGSourceViewNode alloc] initWithName:title];
	[[self headings] addObject:node];
	[[self ibOutlineView] reloadData];
}

////////////////////////////////////////////////////////////////////////////////
// NSOutlineViewDataSource

-(id)outlineView:(NSOutlineView* )outlineView child:(NSInteger)index ofItem:(id)item {
	if(item==nil) {
		return [[self headings] objectAtIndex:index];
	}
	return nil;
}

-(NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	if(item==nil) {
		return [[self headings] count];
	}
	return 0;
}

-(BOOL)outlineView:(NSOutlineView* )outlineView isItemExpandable:(id)item {
	NSInteger count = [self outlineView:outlineView numberOfChildrenOfItem:item];
	return count ? YES : NO;
}


////////////////////////////////////////////////////////////////////////////////
// NSOutlineView delegate

-(BOOL)outlineView:(NSOutlineView* )outlineView isGroupItem:(id)item {
	NSParameterAssert([item isKindOfClass:[PGSourceViewNode class]]);
	return [item isGroupItem];
}

-(BOOL)outlineView:(NSOutlineView* )outlineView shouldSelectItem:(id)item {
	NSParameterAssert([item isKindOfClass:[PGSourceViewNode class]]);
	return [item shouldSelectItem];
}

-(NSString* )outlineView:(NSOutlineView* )outlineView toolTipForCell:(NSCell* )cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tc item:(id)item mouseLocation:(NSPoint)mouseLocation {
	NSParameterAssert([item isKindOfClass:[PGSourceViewNode class]]);
	return nil;
}

-(BOOL)outlineView:(NSOutlineView* )outlineView shouldEditTableColumn:(NSTableColumn* )tableColumn item:(id)item {
	return NO;
}

-(NSView* )outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn* )tableColumn item:(id)item {
	NSParameterAssert([item isKindOfClass:[PGSourceViewNode class]]);
	NSTableCellView* result = [outlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
	[[result textField] setStringValue:[item name]];
    return result;
}

@end
