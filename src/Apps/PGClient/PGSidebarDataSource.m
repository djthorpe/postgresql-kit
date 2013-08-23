
#import "PGSidebarDataSource.h"

@implementation PGSidebarDataSource

////////////////////////////////////////////////////////////////////////////////
// initializers

-(id)init {
    self = [super init];
    if (self) {
        _nodes = [NSMutableArray array];
    }
    return self;
}

-(void)awakeFromNib {
	
	PGSidebarNode* serverGroup = [[PGSidebarNode alloc] initAsGroup:@"SERVERS"];
	PGSidebarNode* databaseGroup = [[PGSidebarNode alloc] initAsGroup:@"DATABASES"];
	PGSidebarNode* queryGroup = [[PGSidebarNode alloc] initAsGroup:@"QUERIES"];
	[[self nodes] addObject:serverGroup];
	[[self nodes] addObject:databaseGroup];
	[[self nodes] addObject:queryGroup];
	
	// Add Internal Server database
	PGSidebarNode* internalServer = [[PGSidebarNode alloc] initAsServer:@"Internal Server"];
	[serverGroup addChild:internalServer];
	
	// Add in some dummies
	[serverGroup addChild:[[PGSidebarNode alloc] initAsServer:@"A Server"]];
	[databaseGroup addChild:[[PGSidebarNode alloc] initAsDatabase:@"Database1"]];
	[databaseGroup addChild:[[PGSidebarNode alloc] initAsDatabase:@"Database1"]];
	[queryGroup addChild:[[PGSidebarNode alloc] initAsQuery:@"Query1"]];
	[queryGroup addChild:[[PGSidebarNode alloc] initAsQuery:@"Query2"]];
	[queryGroup addChild:[[PGSidebarNode alloc] initAsQuery:@"Query3"]];	
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize nodes = _nodes;

////////////////////////////////////////////////////////////////////////////////
// methods

-(void)addServer:(PGSidebarNode* )node {
	PGSidebarNode* serverGroup = [[self nodes] objectAtIndex:0];
	NSParameterAssert([node type]==PGSidebarNodeTypeServer);
	[serverGroup addChild:node];
}

////////////////////////////////////////////////////////////////////////////////
// NSOutlineViewDataSource

-(id)outlineView:(NSOutlineView* )outlineView child:(NSInteger)index ofItem:(id)item {
	if(item==nil) {
		return [[self nodes] objectAtIndex:index];
	}
	PGSidebarNode* node = (PGSidebarNode* )item;
	NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);	
	return [node childAtIndex:index];
}

-(NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	if(item==nil) {
		return [[self nodes] count];
	}
	PGSidebarNode* node = (PGSidebarNode* )item;
	NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);
	return [node numberOfChildren];
}

-(BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	NSInteger count = [self outlineView:outlineView numberOfChildrenOfItem:item];
	return count ? YES : NO;
}

-(id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	PGSidebarNode* node = (PGSidebarNode* )item;
	NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);
	return [node name];
}

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
	[pboard setPropertyList:[NSNumber numberWithBool:YES] forType:@"PGSidebarDragType"];
	return YES;
}

-(NSDragOperation)outlineView:(NSOutlineView* )outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
	PGSidebarNode* node = (PGSidebarNode* )item;
	if(node==nil) {
		return NSDragOperationNone;
	}
	NSParameterAssert([item isKindOfClass:[PGSidebarNode class]]);
	// can only move within groups
	if([node type] != PGSidebarNodeTypeGroup) {
		return NSDragOperationNone;
	}
	NSLog(@"Proposed move to %ld of %@",index,[node name]);
	// TODO: Only allow it to be moved within the same group
	// TODO: Read item from pasteboard
	return NSDragOperationMove;
}

-(BOOL)outlineView:(NSOutlineView* )outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index {
	PGSidebarNode* node = (PGSidebarNode* )item;
	if(node==nil) {
		return NO;
	}
	NSParameterAssert([item isKindOfClass:[PGSidebarNode class]]);
	NSLog(@"Accepted move to %ld of %@",index,[node name]);
	// TODO: Read item from pasteboard
	return YES;
}

@end
