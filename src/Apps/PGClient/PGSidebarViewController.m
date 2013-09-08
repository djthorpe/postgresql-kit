

#import <Cocoa/Cocoa.h>
#import "PGSidebarViewController.h"
#import "PGSidebarDataSource.h"
#import "PGClientApplication.h"
#import "PGSidebarNode.h"

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

	// Setup datasource
	[[self datasource] addGroup:[[PGSidebarNode alloc] initAsGroupWithKey:PGSidebarNodeKeyServerGroup name:@"SERVERS"]];
	[[self datasource] addGroup:[[PGSidebarNode alloc] initAsGroupWithKey:PGSidebarNodeKeyDatabaseGroup name:@"DATABASES"]];
	[[self datasource] addGroup:[[PGSidebarNode alloc] initAsGroupWithKey:PGSidebarNodeKeyQueryGroup name:@"QUERIES"]];

	// Add Internal Server database
	PGSidebarNode* internalServer = [[PGSidebarNode alloc] initAsServerWithKey:PGSidebarNodeKeyInternalServer name:@"Internal Server"];
	[[self datasource] addServer:internalServer];
		
	// Add in some dummies - HACK!
	[[self datasource] addQuery:[[PGSidebarNode alloc] initAsQueryWithKey:[[self datasource] nextKey] name:@"Query1"]];
	[[self datasource] addQuery:[[PGSidebarNode alloc] initAsQueryWithKey:[[self datasource] nextKey] name:@"Query2"]];
	[[self datasource] addQuery:[[PGSidebarNode alloc] initAsQueryWithKey:[[self datasource] nextKey] name:@"Query3"]];
	
	// load user defaults
	[self loadFromUserDefaults];	

	// set view datasource and doubleclick action
	NSParameterAssert([[self view] isKindOfClass:[NSOutlineView class]]);
	NSOutlineView* view = (NSOutlineView* )[self view];
	[view setDataSource:[self datasource]];
	[view setTarget:self];
	[view setDoubleAction:@selector(doDoubleClick:)];
	
	// set row height
	[view setRowHeight:20.0];

	// expand all group
	for(PGSidebarNode* group in [[self datasource] groups]) {
		[view expandItem:group];
	}

	// register for dragging
	[view registerForDraggedTypes:[NSArray arrayWithObject:PGSidebarDragType]];
}

-(void)applicationWillTerminate:(id)sender {
	// save user defaults
	[self saveToUserDefaults];
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize datasource = _datasource;
@dynamic canOpen;
@dynamic canClose;
@dynamic canDelete;

-(BOOL)canOpen {
	PGSidebarNode* node = [self selectedNode];
	if(node==nil) {
		return NO;
	}
	if([node type]==PGSidebarNodeTypeServer) {
		// TODO: Check to make sure not already opened
		return YES;
	}
	return NO;
}

-(BOOL)canClose {
	PGSidebarNode* node = [self selectedNode];
	if(node==nil) {
		return NO;
	}
	if([node type]==PGSidebarNodeTypeServer) {
		// TODO: Check to make sure not already closed
		return YES;
	}
	return NO;	
}

-(BOOL)canDelete {
	PGSidebarNode* node = [self selectedNode];
	if(node==nil) {
		return NO;
	}
	if([node type]==PGSidebarNodeTypeServer && [node key]==PGSidebarNodeKeyInternalServer) {
		return NO;
	}
	if([node type]==PGSidebarNodeTypeServer) {
		// TODO: Can't delete if server is connected
		return YES;
	}
	return NO;
}

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

-(PGSidebarNode* )clickedNode {
	NSOutlineView* view = (NSOutlineView* )[self view];
	NSInteger row = [view clickedRow];
	if(row < 0) {
		return nil;
	}
	PGSidebarNode* node = [view itemAtRow:row];
	NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);
	return node;
}

-(void)selectNode:(PGSidebarNode* )node {
	NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);
	NSOutlineView* view = (NSOutlineView* )[self view];
	if(node==nil) {
		[view deselectAll:self];
	} else {
		NSInteger rowIndex = [view rowForItem:node];
		NSParameterAssert([node type] != PGSidebarNodeTypeGroup);
		NSParameterAssert(rowIndex >= 0);
		[view selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
	}
}

-(void)deleteNode:(PGSidebarNode* )node {
	NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);
	[[self datasource] deleteNode:node];
	if([node type]==PGSidebarNodeTypeServer) {
		// TODO: Also delete all databases
		NSLog(@"TODO: Delete databases");
	} else if([node type]==PGSidebarNodeTypeDatabase) {
		// TODO: Also delete all queries??
		NSLog(@"TODO: Delete queries");
	}
	// TODO: only do this on all deletes having been done
	[(NSOutlineView* )[self view] reloadData];
	[self selectNode:nil];
}

-(PGSidebarNode* )nodeForKey:(NSUInteger)key {
	return [[self datasource] nodeForKey:key];
}

-(void)setNode:(PGSidebarNode* )node status:(PGSidebarNodeStatusType)status {
	NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);
	if([node status] != status) {
		[node setStatus:status];
		PGSidebarNode* selectedNode = [self selectedNode];
		[(NSOutlineView* )[self view] reloadData];
		[self selectNode:selectedNode];
	}
}

-(void)expandNodeWithKey:(NSUInteger)key {
	NSParameterAssert(key);
	PGSidebarNode* node = [self nodeForKey:key];
	NSParameterAssert(node);
	[(NSOutlineView* )[self view] expandItem:node];
}


////////////////////////////////////////////////////////////////////////////////
// load and save from defaults

-(BOOL)loadFromUserDefaults {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary* serverNodes = [defaults dictionaryForKey:@"server"];
	if(serverNodes) {
		NSArray* children = [serverNodes objectForKey:@"children"];
		NSParameterAssert(children && [children isKindOfClass:[NSArray class]]);
		for(NSDictionary* nodeDictionary in children) {
			NSNumber* key = [nodeDictionary objectForKey:@"key"];
			if([key unsignedIntegerValue]==PGSidebarNodeKeyInternalServer) {
				// Ignore internal server key
				continue;
			}
			PGSidebarNode* node = [[PGSidebarNode alloc] initWithUserDefaults:nodeDictionary];
			if([node type]==PGSidebarNodeTypeServer) {
				if([[self datasource] nodeForKey:[node key]]) {
					NSLog(@"WARNING: Ignoring PGSidebarNode which has duplicate key: %@",node);
					continue;
				}
				[[self datasource] addServer:node];
			}
		}
	}
	NSDictionary* databaseNodes = [defaults dictionaryForKey:@"database"];
	if(databaseNodes) {
		NSArray* children = [databaseNodes objectForKey:@"children"];
		NSParameterAssert(children && [children isKindOfClass:[NSArray class]]);
		for(NSDictionary* nodeDictionary in children) {
			NSNumber* parentKey = [nodeDictionary objectForKey:@"parentKey"];
			PGSidebarNode* serverNode = [[self datasource] nodeForKey:[parentKey unsignedIntegerValue]];
			PGSidebarNode* node = [[PGSidebarNode alloc] initWithUserDefaults:nodeDictionary];
			if(serverNode==nil || [serverNode type] != PGSidebarNodeTypeServer) {
				NSLog(@"WARNING: Ignoring PGSidebarNode which has missing server: %@",node);
				continue;
			}
			if([[self datasource] nodeForKey:[node key]]) {
				NSLog(@"WARNING: Ignoring PGSidebarNode which has duplicate key: %@",node);
				continue;
			}
			if([node type]==PGSidebarNodeTypeDatabase) {
				[[self datasource] addDatabase:node];
			}
		}
	}
	// TODO: load queries
	return YES;
}

-(BOOL)saveToUserDefaults {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	// servers
	PGSidebarNode* serverGroup = [[self datasource] nodeForKey:PGSidebarNodeKeyServerGroup];
	NSParameterAssert(serverGroup);
	[defaults setObject:[serverGroup userDefaults] forKey:@"server"];
	// databases
	PGSidebarNode* databaseGroup = [[self datasource] nodeForKey:PGSidebarNodeKeyDatabaseGroup];
	NSParameterAssert(databaseGroup);
	[defaults setObject:[databaseGroup userDefaults] forKey:@"database"];
	// queries
	PGSidebarNode* queryGroup = [[self datasource] nodeForKey:PGSidebarNodeKeyQueryGroup];
	NSParameterAssert(queryGroup);
	[defaults setObject:[queryGroup userDefaults] forKey:@"query"];
	// synchronize to disk
	return [defaults synchronize];
}

////////////////////////////////////////////////////////////////////////////////
// database methods

-(PGSidebarNode* )selectDatabaseNodeWithName:(NSString* )name serverWithKey:(NSUInteger)key {
	// find existing database node
	PGSidebarNode* databaseGroup = [[self datasource] nodeForKey:PGSidebarNodeKeyDatabaseGroup];
	NSParameterAssert(databaseGroup);
	for(PGSidebarNode* node in [databaseGroup children]) {
		NSParameterAssert([node type]==PGSidebarNodeTypeDatabase);
		if([[node name] isEqual:name] && [node parentKey]==key) {
			return node;
		}
	}

	// no database node at this point, so create one
	PGSidebarNode* newDatabaseNode = [[PGSidebarNode alloc] initAsDatabaseWithKey:[[self datasource] nextKey] serverKey:key name:name];
	NSParameterAssert(newDatabaseNode);
	[[self datasource] addDatabase:newDatabaseNode];
	
	NSLog(@"New node => %@",newDatabaseNode);
	
	NSOutlineView* view = (NSOutlineView* )[self view];
	[view reloadData];
	
	return newDatabaseNode;
}

////////////////////////////////////////////////////////////////////////////////
// Notification

-(void)ibNotificationAddConnection:(NSNotification* )notification {
	NSURL* url = [notification object];
	NSParameterAssert([url isKindOfClass:[NSURL class]]);
	
	// create name for the server
	NSString* host = [url host];	
	NSString* name = nil;
	if([host hasPrefix:@"/"]) {
		name = [NSString stringWithFormat:@"%@@[%@]",[url user],[host lastPathComponent]];
	} else {
		name = [NSString stringWithFormat:@"%@@%@",[url user],host];
	}
	PGSidebarNode* node = [[PGSidebarNode alloc] initAsServerWithKey:[[self datasource] nextKey] name:name];
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

-(BOOL)outlineView:(NSOutlineView* )outlineView isGroupItem:(id)item {
	PGSidebarNode* node = (PGSidebarNode* )item;
	if(item==nil) return NO;
	NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);
	return [node type]==PGSidebarNodeTypeGroup;
}

-(BOOL)outlineView:(NSOutlineView* )outlineView shouldSelectItem:(id)item {
	PGSidebarNode* node = (PGSidebarNode* )item;
	NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);
	return [node type]!=PGSidebarNodeTypeGroup;
}

-(NSString* )outlineView:(NSOutlineView* )outlineView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tc item:(id)item mouseLocation:(NSPoint)mouseLocation {
	// show tooltip of the server URL for server items
	PGSidebarNode* node = (PGSidebarNode* )item;
	NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);
	if([node type]==PGSidebarNodeTypeServer) {
		return [[node URL] absoluteString];
	}
	return nil;
}

-(BOOL)outlineView:(NSOutlineView* )outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	// prevent editing of the internal server name
	PGSidebarNode* node = (PGSidebarNode* )item;
	NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);
	if([node key]==PGSidebarNodeKeyInternalServer) {
		return NO;
	}
	return YES;
}

-(NSView* )outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn* )tableColumn item:(id)item {
	NSParameterAssert([item isKindOfClass:[PGSidebarNode class]]);
	
	NSTableCellView* result = nil;
	PGSidebarNode* node = (PGSidebarNode* )item;
	
    if([node type]==PGSidebarNodeTypeGroup) {
		result = [outlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
		[[result textField] setStringValue:[node name]];
	} else {
        result = [outlineView makeViewWithIdentifier:@"DataCell" owner:self];
		[[result textField] setStringValue:[node name]];
		switch([node status]) {
			case PGSidebarNodeStatusGreen:
				[[result imageView] setImage:[NSImage imageNamed:@"traffic-green"]];
				break;
			case PGSidebarNodeStatusRed:
				[[result imageView] setImage:[NSImage imageNamed:@"traffic-red"]];
				break;
			case PGSidebarNodeStatusOrange:
				[[result imageView] setImage:[NSImage imageNamed:@"traffic-orange"]];
				break;
			case PGSidebarNodeStatusGrey:
			default:
				[[result imageView] setImage:[NSImage imageNamed:@"traffic-grey"]];
				break;
		}
    }
    return result;
}

////////////////////////////////////////////////////////////////////////////////
// IBActions

-(IBAction)doOpen:(id)sender {
	PGSidebarNode* node = [self selectedNode];
	NSParameterAssert(node);
	if([self canOpen] && [node type]==PGSidebarNodeTypeServer) {
		[[NSNotificationCenter defaultCenter] postNotificationName:PGClientNotificationOpenConnection object:node];
	}
}

-(IBAction)doClose:(id)sender {
	PGSidebarNode* node = [self selectedNode];
	NSParameterAssert(node);
	if([self canClose] && [node type]==PGSidebarNodeTypeServer) {
		[[NSNotificationCenter defaultCenter] postNotificationName:PGClientNotificationCloseConnection object:node];
	}
}

-(IBAction)doDelete:(id)sender {
	PGSidebarNode* node = [self selectedNode];
	NSParameterAssert(node);
	if([self canDelete] && [node type]==PGSidebarNodeTypeServer) {
		[[NSNotificationCenter defaultCenter] postNotificationName:PGClientNotificationDeleteConnection object:node];
	}
}

-(IBAction)doDoubleClick:(id)sender {
	PGSidebarNode* node = [self clickedNode];
	NSParameterAssert(node);
	if([node type]==PGSidebarNodeTypeServer) {
		[[NSNotificationCenter defaultCenter] postNotificationName:PGClientNotificationEditConnection object:node];
	}
}

@end
