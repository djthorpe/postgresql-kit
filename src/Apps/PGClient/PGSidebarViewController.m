
#import "PGSidebarViewController.h"
#import "PGSidebarNode.h"
#import "PGClientApplication.h"

@implementation PGSidebarViewController

////////////////////////////////////////////////////////////////////////////////
// initializers

-(id)init {
    self = [super init];
    if (self) {
		_nodes = [NSMutableArray array];
		_servers = nil;
    }
    return self;
}

-(void)applicationDidFinishLaunching:(NSNotification* )aNotification {
	[self willChangeValueForKey:@"nodes"];

	// create headers in the sidebar
	_servers = [[PGSidebarNode alloc] initWithHeader:@"SERVERS"];
	[_nodes addObject:_servers];
	[_nodes addObject:[[PGSidebarNode alloc] initWithHeader:@"DATABASES"]];
	[_nodes addObject:[[PGSidebarNode alloc] initWithHeader:@"QUERIES"]];
	
	// add local database connection
	[[_servers children] addObject:[[PGSidebarNode alloc] initWithInternalServer]];

	[self didChangeValueForKey:@"nodes"];
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize nodes = _nodes;
@synthesize servers = _servers;
@synthesize selectedNode = _selectedNode;

////////////////////////////////////////////////////////////////////////////////
// Notification

-(void)ibNotificationAddConnection:(NSNotification* )notification {
	NSURL* url = [notification object];
	NSParameterAssert([url isKindOfClass:[NSURL class]]);
	PGSidebarNode* node = [[PGSidebarNode alloc] initWithLocalServerURL:url];
	NSParameterAssert(node);

	[self willChangeValueForKey:@"nodes"];
	[[_servers children] addObject:node];
	[self didChangeValueForKey:@"nodes"];
}

////////////////////////////////////////////////////////////////////////////////
// NSOutlineView delegate

-(NSView* )outlineView:(NSOutlineView* )outlineView viewForTableColumn:(NSTableColumn* )column item:(id)treeNode {
    PGSidebarNode* item = [treeNode representedObject];
    BOOL isHeader = [item isHeader];
	return [outlineView makeViewWithIdentifier:isHeader ? @"HeaderCell" : @"DataCell" owner:self];
}

-(BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)treeNode {
	PGSidebarNode* item = [treeNode representedObject];
	if([item isHeader]) {
		return NO;
	}
	return YES;
}

-(void)outlineViewSelectionDidChange:(NSNotification* )notification {
	NSParameterAssert([[notification object] isKindOfClass:[NSOutlineView class]]);
	NSOutlineView* view = (NSOutlineView* )[notification object];
	NSIndexSet* selectedRows = [view selectedRowIndexes];
	PGSidebarNode* selectedNode = nil;
	if([selectedRows count]) {
		// only select first item
		id item = [view itemAtRow:[selectedRows firstIndex]];
		NSParameterAssert(item);
		PGSidebarNode* node = [item representedObject];
		NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);
		selectedNode = node;
	}
	_selectedNode = selectedNode;
}

////////////////////////////////////////////////////////////////////////////////
// IBActions

-(IBAction)doOpen:(id)sender {
	PGSidebarNode* node = [self selectedNode];
	if([node isServer]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:PGClientNotificationOpenConnection object:node];
	}
}

-(IBAction)doClose:(id)sender {
	PGSidebarNode* node = [self selectedNode];
	if([node isServer]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:PGClientNotificationCloseConnection object:node];
	}
}

@end
