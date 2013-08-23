

#import <Cocoa/Cocoa.h>
#import "PGSidebarViewController.h"
#import "PGSidebarDataSource.h"
#import "PGClientApplication.h"
#import "PGSidebarNode.h"


NSString* PGSidebarDragType = @"PGSidebarDragType";

@implementation PGSidebarViewController

////////////////////////////////////////////////////////////////////////////////
// initializers

-(id)init {
    self = [super init];
    if (self) {
		_datasource = [[PGSidebarDataSource alloc] init];
    }
    return self;
}

-(void)applicationDidFinishLaunching:(NSNotification* )aNotification {
	// call awakeFromNib - setup datasource
	[[self datasource] awakeFromNib];
	// set view datasource
	NSParameterAssert([[self view] isKindOfClass:[NSOutlineView class]]);
	NSOutlineView* view = (NSOutlineView* )[self view];
	[view setDataSource:[self datasource]];
	// set row height
	[view setRowHeight:20.0];
	// expand all group
	for(PGSidebarNode* group in [[self datasource] nodes]) {
		[view expandItem:group];
	}
	// register for dragging
	[view registerForDraggedTypes:[NSArray arrayWithObject:PGSidebarDragType]];
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize datasource = _datasource;

////////////////////////////////////////////////////////////////////////////////
// methods

-(PGSidebarNode* )selectedNode {
	NSOutlineView* view = (NSOutlineView* )[self view];
	NSInteger row = [view selectedRow];
	if(row < 0) {
		return nil;
	}
	PGSidebarNode* node = [view itemAtRow:row];
	NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);
	return node;
}

-(void)selectNode:(PGSidebarNode* )node {
	NSOutlineView* view = (NSOutlineView* )[self view];
	NSInteger rowIndex = [view rowForItem:node];
	NSParameterAssert([node type] != PGSidebarNodeTypeGroup);
	NSParameterAssert(rowIndex >= 0);
	[view selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
}

////////////////////////////////////////////////////////////////////////////////
// Notification

-(void)ibNotificationAddConnection:(NSNotification* )notification {
	NSURL* url = [notification object];
	NSParameterAssert([url isKindOfClass:[NSURL class]]);
	
	// create name for the server
	NSString* name = [NSString stringWithFormat:@"%@@localhost",[url user]];
	PGSidebarNode* node = [[PGSidebarNode alloc] initAsServer:name];
	NSParameterAssert(node);

	// add URL to the node
	[node setURL:url];
	
	// datasource
	[[self datasource] addServer:node];
	// reload view
	NSOutlineView* view = (NSOutlineView* )[self view];
	[view reloadData];
	// select item
	[self selectNode:node];
}

////////////////////////////////////////////////////////////////////////////////
// NSOutlineView delegate

-(BOOL)outlineView:(NSOutlineView*)outlineView isGroupItem:(id)item {
	PGSidebarNode* node = (PGSidebarNode* )item;
	NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);
	return [node type]==PGSidebarNodeTypeGroup;
}

-(BOOL)outlineView:(NSOutlineView*) outlineView shouldSelectItem:(id)item {
	PGSidebarNode* node = (PGSidebarNode* )item;
	NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);
	return [node type]!=PGSidebarNodeTypeGroup;
}

////////////////////////////////////////////////////////////////////////////////
// IBActions

-(IBAction)doOpen:(id)sender {
	PGSidebarNode* node = [self selectedNode];
	if(node && [node type]==PGSidebarNodeTypeServer) {
		[[NSNotificationCenter defaultCenter] postNotificationName:PGClientNotificationOpenConnection object:node];
	}
}

-(IBAction)doClose:(id)sender {
	PGSidebarNode* node = [self selectedNode];
	if(node && [node type]==PGSidebarNodeTypeServer) {
		[[NSNotificationCenter defaultCenter] postNotificationName:PGClientNotificationOpenConnection object:node];
	}
}

@end
