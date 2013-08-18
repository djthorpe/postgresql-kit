
#import "PGSidebarViewController.h"
#import "PGSidebarNode.h"

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
	_servers = [[PGSidebarNode alloc] initWithName:@"SERVERS" isHeader:YES];
	[_nodes addObject:_servers];
	[_nodes addObject:[[PGSidebarNode alloc] initWithName:@"DATABASES" isHeader:YES]];
	[_nodes addObject:[[PGSidebarNode alloc] initWithName:@"QUERIES" isHeader:YES]];
	
	// add local database connection
	[[_servers children] addObject:[[PGSidebarNode alloc] initWithName:@"Internal Server" isHeader:NO]];

	[self didChangeValueForKey:@"nodes"];
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize nodes = _nodes;
@synthesize servers = _servers;

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

-(NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)column item:(id)treeNode {
    PGSidebarNode* item = [treeNode representedObject];
    BOOL isHeader = [item isHeader];
	return [outlineView makeViewWithIdentifier:isHeader ? @"HeaderCell" : @"DataCell" owner:self];
}

@end
