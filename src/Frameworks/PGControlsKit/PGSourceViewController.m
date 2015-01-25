
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

////////////////////////////////////////////////////////////////////////////////

NSString* PGSourceViewDragType = @"PGSourceViewDragType";

////////////////////////////////////////////////////////////////////////////////

@interface PGSourceViewController ()
@property (readonly) PGSourceViewTree* model;
@property (weak) IBOutlet NSOutlineView* ibOutlineView;
@end

////////////////////////////////////////////////////////////////////////////////

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
	// register for dragging
	[[self ibOutlineView] registerForDraggedTypes:@[ PGSourceViewDragType ]];
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
// NSOutlineView editing cell contents

-(IBAction)doEditCell:(id)sender {
	NSTextField* view = (NSTextField* )sender;
	NSParameterAssert([view isKindOfClass:[NSTextField class]]);
	PGSourceViewNode* node = [view tag] ? [[self model] nodeForTag:[view tag]] : nil;
	if(node==nil) {
		return;
	}
	NSString* value = [[view stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if([value length]) {
		// set the name here
		[node setName:value];
	}
	// Redisplay the data for this row, for some reason we have to do this in a tricky way
	NSInteger rowIndex = [[self ibOutlineView] rowForItem:node];
	[[self ibOutlineView] reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

////////////////////////////////////////////////////////////////////////////////
// NSOutlineView delegate

-(BOOL)outlineView:(NSOutlineView* )outlineView isGroupItem:(id)item {
	NSParameterAssert([item isKindOfClass:[PGSourceViewNode class]]);
	return [item isGroupItem];
}

-(BOOL)outlineView:(NSOutlineView* )outlineView shouldSelectItem:(id)item {
	NSParameterAssert([item isKindOfClass:[PGSourceViewNode class]]);
	return [item isSelectable];
}

-(NSView* )outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn* )tableColumn item:(id)item {
	NSParameterAssert([item isKindOfClass:[PGSourceViewNode class]]);
	NSInteger tag = [[self model] tagForNode:((PGSourceViewNode* )item)];
	return [item cellViewForOutlineView:outlineView tableColumn:tableColumn owner:self tag:tag];
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

////////////////////////////////////////////////////////////////////////////////
// NSOutlineView drag and drop

-(BOOL)outlineView:(NSOutlineView* )outlineView writeItems:(NSArray* )items toPasteboard:(NSPasteboard* )pboard {
	NSParameterAssert([items count]==1);
    PGSourceViewNode* node = [items objectAtIndex:0];
	NSParameterAssert([node isKindOfClass:[PGSourceViewNode class]]);
	// node which cannot be dragged
	if([node isDraggable]==NO) {
		return NO;
	}
	// use key object as the pasteboard content
	NSInteger tag = [[self model] tagForNode:node];
	if(tag) {
		[pboard setPropertyList:[NSNumber numberWithInteger:tag] forType:PGSourceViewDragType];
		return YES;
	} else {
		return NO;
	}
}

-(NSDragOperation)outlineView:(NSOutlineView* )outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
	NSParameterAssert(item==nil || [item isKindOfClass:[PGSourceViewNode class]]);
	if(item==nil) {
		return NSDragOperationNone;
	}
	// retrieve dragged node from pasteboard
	NSPasteboard* pasteboard = [info draggingPasteboard];
	NSNumber* key = [pasteboard propertyListForType:PGSourceViewDragType];
	NSParameterAssert([key isKindOfClass:[NSNumber class]]);
	PGSourceViewNode* draggedNode = [[self model] nodeForTag:[key integerValue]];
	NSParameterAssert(draggedNode);
	if(index==-1) {
		// item is on the heading
		return NO;
	}
	if([draggedNode isDraggable]==NO) {
		return NSDragOperationNone;
	}
	if([item canAcceptDrop:draggedNode]==NO) {
		return NSDragOperationNone;
	}
	NSLog(@"dragging %@ => %@ to %ld",draggedNode,item,index);
	return NSDragOperationMove;
}
/*
-(BOOL)outlineView:(NSOutlineView* )outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index {
        PGSidebarNode* node = (PGSidebarNode* )item;
        if(node==nil) {
                return NO;
        }
        NSParameterAssert([item isKindOfClass:[PGSidebarNode class]]);
        
        // retrieve dragged node from pasteboard
        NSPasteboard* pasteboard = [info draggingPasteboard];
        NSNumber* nodeKey = [pasteboard propertyListForType:PGSidebarDragType];
        NSParameterAssert([nodeKey isKindOfClass:[NSNumber class]]);
        PGSidebarNode* draggedNode = [self nodeForKey:[nodeKey unsignedIntegerValue]];
        NSParameterAssert(draggedNode);
        
        // determine if the move can occur
        if(![node canContainNode:draggedNode]) {
                return NSDragOperationNone;
        }
        
        if(index < 1) {
                // drop onto the group header, thus move to index position 0
                [node insertChild:draggedNode atIndex:0];
        } else {
                // drop underneath existing item
                [node insertChild:draggedNode atIndex:(index-1)];
        }
        // reload data
        [outlineView reloadData];

        // select dragged object
        NSInteger rowIndex = [outlineView rowForItem:draggedNode];
        NSParameterAssert(rowIndex >= 0);
        [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];

        return YES;
}
*/

@end
