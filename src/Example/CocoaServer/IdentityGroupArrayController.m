
#import "IdentityGroupArrayController.h"
#import <PostgresServerKit/PostgresServerKit.h>

@implementation IdentityGroupArrayController

@synthesize ibTableView;
@dynamic selectedGroup;

// addObject overridden to allow table cell to be edited on insert
-(void)addObject:(id) newObject {
	[super addObject:newObject];
	NSInteger row = [[self arrangedObjects] indexOfObjectIdenticalTo:newObject];
	[[self ibTableView] editColumn:0 row:row withEvent:nil select:YES];
}


-(NSString* )selectedGroup {
	if([[self selectedObjects] count] != 1) {
		return nil;
	}
	NSDictionary* theGroup = [[self selectedObjects] objectAtIndex:0];
	NSParameterAssert([theGroup isKindOfClass:[NSDictionary class]]);	
	return [theGroup objectForKey:@"group"];
}

@end
