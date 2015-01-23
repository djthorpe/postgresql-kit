
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
#import "PGSourceViewTree.h"

@interface PGSourceViewController ()
@property (readonly) PGSourceViewTree* model;
@property (weak) IBOutlet NSOutlineView* ibOutlineView;
@end

@implementation PGSourceViewController

////////////////////////////////////////////////////////////////////////////////
// constructors

-(id)init {
    self = [super initWithNibName:@"PGSourceView" bundle:[NSBundle bundleForClass:[self class]]];
	if(self) {
		_model = [PGSourceViewTree new];
		NSParameterAssert(_model);
	}
	return self;
}

-(void)awakeFromNib {
	[[self ibOutlineView] setTarget:self];
	[[self ibOutlineView] setDoubleAction:@selector(doDoubleClick:)];
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize model = _model;
@synthesize ibOutlineView;
@dynamic count;

-(NSUInteger)count {
	return [[self model] count];
}

////////////////////////////////////////////////////////////////////////////////
// methods

-(NSInteger)addNode:(PGSourceViewNode* )node parent:(PGSourceViewNode* )parent {
	NSInteger tag = [[self model] addNode:node parent:parent];
	if(tag) {
		[[self ibOutlineView] reloadData];
	}
	return tag;
}

-(NSInteger)addNode:(PGSourceViewNode* )node parent:(PGSourceViewNode* )parent tag:(NSInteger)tag {
	if([[self model] addNode:node parent:parent tag:tag]) {
		[[self ibOutlineView] reloadData];
	}
	return tag;
}

-(PGSourceViewNode* )nodeForTag:(NSInteger)tag {
	return [[self model] nodeForTag:tag];
}

-(BOOL)selectNode:(PGSourceViewNode* )node {
	NSParameterAssert(node);
	if(node==nil) {
		// deselect all nodes
		[[self ibOutlineView] deselectAll:self];
		return NO;
	}
	NSInteger rowIndex = [[self ibOutlineView] rowForItem:node];
	if(rowIndex >= 0) {
		[[self ibOutlineView] selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
		return YES;
	}
	// cannot select a node
	return NO;
}

-(void)expandNode:(PGSourceViewNode* )node {
	NSParameterAssert(node);
	[[self ibOutlineView] expandItem:node];
}

-(void)removeAllNodes {
	[[self model] removeAllNodes];
	[[self ibOutlineView] reloadData];
}

-(PGSourceViewNode* )clickedNode {
	NSInteger row = [[self ibOutlineView] clickedRow];
	if(row < 0) {
		return nil;
	}
	PGSourceViewNode* node = [[self ibOutlineView] itemAtRow:row];
	NSParameterAssert([node isKindOfClass:[PGSourceViewNode class]]);
	return node;
}

////////////////////////////////////////////////////////////////////////////////
// methods - IBActions

-(IBAction)doDoubleClick:(id)sender {
	PGSourceViewNode* node = [self clickedNode];
	NSParameterAssert(node);
	if([[self delegate] respondsToSelector:@selector(sourceView:doubleClickedNode:)]) {
		[[self delegate] sourceView:self doubleClickedNode:node];
	}
}

////////////////////////////////////////////////////////////////////////////////
// methods - NSUserDefaults

-(BOOL)loadFromUserDefaults {
	BOOL isSuccess = [[self model] loadFromUserDefaults];
	if(isSuccess) {
		[[self ibOutlineView] reloadData];
	}
	return isSuccess;
}

-(BOOL)saveToUserDefaults {
	return [[self model] saveToUserDefaults];
}

////////////////////////////////////////////////////////////////////////////////
// NSOutlineViewDataSource

-(id)outlineView:(NSOutlineView* )outlineView child:(NSInteger)index ofItem:(id)item {
	NSParameterAssert(outlineView==[self ibOutlineView]);
	NSParameterAssert(item==nil || [item isKindOfClass:[PGSourceViewNode class]]);
	return [[self model] nodeAtIndex:index parent:item];
}

-(NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	NSParameterAssert(outlineView==[self ibOutlineView]);
	NSParameterAssert(item==nil || [item isKindOfClass:[PGSourceViewNode class]]);
	return [[self model] numberOfChildrenOfParent:item];
}

-(BOOL)outlineView:(NSOutlineView* )outlineView isItemExpandable:(id)item {
	NSParameterAssert(outlineView==[self ibOutlineView]);
	NSParameterAssert(item==nil || [item isKindOfClass:[PGSourceViewNode class]]);
	return [[self model] numberOfChildrenOfParent:item] ? YES : NO;
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
	return [item cellViewForOutlineView:outlineView tableColumn:tableColumn owner:self];
}

-(void)outlineViewSelectionDidChange:(NSNotification* )notification {
	NSInteger selectedRow = [[self ibOutlineView] selectedRow];
	PGSourceViewNode* node = nil;
	if(selectedRow >= 0) {
		node = [[self ibOutlineView] itemAtRow:selectedRow];
		if([node isKindOfClass:[PGSourceViewNode class]]==NO) {
			node = nil;
		}
	}
	
	if([[self delegate] respondsToSelector:@selector(sourceView:selectedNode:)]) {
		[[self delegate] sourceView:self selectedNode:node];
	}
}


@end
