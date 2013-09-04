
#import "PGSidebarDataSource.h"

NSString* PGSidebarDragType = @"PGSidebarDragType";

@implementation PGSidebarDataSource

////////////////////////////////////////////////////////////////////////////////
// initializers

-(id)init {
    self = [super init];
    if (self) {
        _nodes = [NSMutableArray array];
		_keys = [NSMutableDictionary dictionary];
		_nextkey = PGSidebarNodeKeyMaximum;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize groups = _nodes;

////////////////////////////////////////////////////////////////////////////////
// methods

-(NSUInteger)nextKey {
	while([self nodeForKey:_nextkey]) {
		_nextkey++;
	}
	return _nextkey++;
}

-(PGSidebarNode* )nodeForKey:(NSUInteger)key {
	return [_keys objectForKey:[NSNumber numberWithUnsignedInteger:key]];
}

-(BOOL)addGroup:(PGSidebarNode* )node {
	NSParameterAssert([node type]==PGSidebarNodeTypeGroup);
	NSParameterAssert([_keys objectForKey:[node keyObject]]==nil);
	[_nodes addObject:node];
	[_keys setObject:node forKey:[node keyObject]];
	return YES;
}

-(BOOL)addServer:(PGSidebarNode* )node {
	NSParameterAssert([node type]==PGSidebarNodeTypeServer);
	NSParameterAssert([_keys objectForKey:[node keyObject]]==nil);
	PGSidebarNode* group = [self nodeForKey:PGSidebarNodeKeyServerGroup];
	NSParameterAssert(group);
	[group addChild:node];
	[_keys setObject:node forKey:[node keyObject]];
	return YES;
}

-(BOOL)addDatabase:(PGSidebarNode* )node {
	NSParameterAssert([node type]==PGSidebarNodeTypeDatabase);
	NSParameterAssert([_keys objectForKey:[node keyObject]]==nil);
	PGSidebarNode* group = [self nodeForKey:PGSidebarNodeKeyDatabaseGroup];
	NSParameterAssert(group);
	[group addChild:node];
	[_keys setObject:node forKey:[node keyObject]];
	return YES;
}

-(BOOL)addQuery:(PGSidebarNode* )node {
	NSParameterAssert([node type]==PGSidebarNodeTypeQuery);
	NSParameterAssert([_keys objectForKey:[node keyObject]]==nil);
	PGSidebarNode* group = [self nodeForKey:PGSidebarNodeKeyQueryGroup];
	NSParameterAssert(group);
	[group addChild:node];
	[_keys setObject:node forKey:[node keyObject]];
	return YES;
}

-(BOOL)deleteNode:(PGSidebarNode* )node {
	NSParameterAssert(node);
	PGSidebarNode* group = nil;
	switch([node type]) {
		case PGSidebarNodeTypeDatabase:
			group = [self nodeForKey:PGSidebarNodeKeyDatabaseGroup];
			break;
		case PGSidebarNodeTypeServer:
			group = [self nodeForKey:PGSidebarNodeKeyServerGroup];
			break;
		case PGSidebarNodeTypeQuery:
			group = [self nodeForKey:PGSidebarNodeKeyQueryGroup];
			break;
		default:
			return NO;
	}
	NSParameterAssert(group && [group type]==PGSidebarNodeTypeGroup);
	// remove from group
	BOOL success = [group removeChild:node];
	if(success) {
		[_keys removeObjectForKey:[node keyObject]];
	}
	return success;
}

////////////////////////////////////////////////////////////////////////////////
// NSOutlineViewDataSource

-(id)outlineView:(NSOutlineView* )outlineView child:(NSInteger)index ofItem:(id)item {
	if(item==nil) {
		return [_nodes objectAtIndex:index];
	}
	PGSidebarNode* node = (PGSidebarNode* )item;
	NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);	
	return [node childAtIndex:index];
}

-(NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	if(item==nil) {
		return [_nodes count];
	}
	PGSidebarNode* node = (PGSidebarNode* )item;
	NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);
	return [node numberOfChildren];
}

-(BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	NSInteger count = [self outlineView:outlineView numberOfChildrenOfItem:item];
	return count ? YES : NO;
}

/*
-(id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	PGSidebarNode* node = (PGSidebarNode* )item;
	NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);
	return [node name];
}
*/

-(void)outlineView:(NSOutlineView* )outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	NSParameterAssert([object isKindOfClass:[NSString class]]);
	NSParameterAssert([item isKindOfClass:[PGSidebarNode class]]);
	PGSidebarNode* node = (PGSidebarNode* )item;
	NSString* newValue = [(NSString* )object stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if([newValue length]) {
		[node setName:newValue];
	}
}

-(BOOL)outlineView:(NSOutlineView* )outlineView writeItems:(NSArray* )items toPasteboard:(NSPasteboard* )pboard {
	NSParameterAssert([items count]==1);
	PGSidebarNode* node = [items objectAtIndex:0];
	// cannot move groups
	if([node type]==PGSidebarNodeTypeGroup) {
		return NO;
	}
	// cannot move internal server
	if([node key]==PGSidebarNodeKeyInternalServer) {
		return NO;
	}
	// use key object
	[pboard setPropertyList:[node keyObject] forType:PGSidebarDragType];
	return YES;
}

-(NSDragOperation)outlineView:(NSOutlineView* )outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
	PGSidebarNode* node = (PGSidebarNode* )item;
	if(node==nil) {
		return NSDragOperationNone;
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

	if([draggedNode type]==PGSidebarNodeTypeServer) {
		// TODO: Some issue which means "1" moves to wrong location!
		if(index <= 0) {
			// Cannot move servers to the first positon (internal server)
			return NSDragOperationNone;
		}
	}
	
	// allow moves to occur
	return NSDragOperationMove;
}

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

@end

