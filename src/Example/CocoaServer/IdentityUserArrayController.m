
#import "IdentityUserArrayController.h"
#import <PostgresServerKit/PostgresServerKit.h>

@implementation IdentityUserArrayController
@synthesize ibTableView;

// addObject overridden to allow table cell to be edited on insert
-(void)addObject:(id) newObject {
	[super addObject:newObject];
	NSInteger row = [[self arrangedObjects] indexOfObjectIdenticalTo:newObject];
	[[self ibTableView] editColumn:0 row:row withEvent:nil select:YES];
}

@end
