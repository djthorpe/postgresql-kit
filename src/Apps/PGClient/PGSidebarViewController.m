
#import "PGSidebarViewController.h"
#import "PGSidebarNode.h"

@implementation PGSidebarViewController

// initializers
-(id)init {
    self = [super init];
    if (self) {
        [self setNodes:[NSMutableArray array]];
    }
    return self;
}

-(void)awakeFromNib {
	NSLog(@"awakeFromNib");
	if([[self nodes] count]==0) {
		[self willChangeValueForKey:@"nodes"];
		PGSidebarNode* connections = [[PGSidebarNode alloc] initWithName:@"CONNECTIONS" isHeader:YES];
		[[self nodes] addObject:connections];
		[[self nodes] addObject:[[PGSidebarNode alloc] initWithName:@"DATABASES" isHeader:YES]];
		[[self nodes] addObject:[[PGSidebarNode alloc] initWithName:@"TABLES & VIEWS" isHeader:YES]];
		[[connections children] addObject:[[PGSidebarNode alloc] initWithName:@"Localhost" isHeader:NO]];
		[[connections children] addObject:[[PGSidebarNode alloc] initWithName:@"Second Localhost" isHeader:NO]];
		[self didChangeValueForKey:@"nodes"];
	}
}

// properties
@synthesize nodes;

////////////////////////////////////////////////////////////////////////////////
// NSOutlineView delegate

-(NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)column item:(id)treeNode {
    PGSidebarNode* item = [treeNode representedObject];
    BOOL isHeader = [item isHeader];
	return [outlineView makeViewWithIdentifier:isHeader ? @"HeaderCell" : @"DataCell" owner:self];
}

@end
