
#import "HostAccessArrayController.h"
#import <PostgresServerKit/PostgresServerKit.h>

@implementation HostAccessArrayController
@synthesize ibTableView;

static NSString* FLXHostAccessDropType = @"FLXHostAccessDropType";

-(void)awakeFromNib {
	NSLog(@"awake from nib %@",[self ibTableView]);
	
	// prevent table from being sortable by columns
	[[self ibTableView] unbind:@"sortDescriptors"];
	
	// register for drag and drop
	[[self ibTableView] registerForDraggedTypes:[NSArray arrayWithObjects:FLXHostAccessDropType, nil]];
	
	// set self as data source
	[[self ibTableView] setDataSource:self];
}

-(BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)thePasteboard {
	NSParameterAssert([rowIndexes count]==1);
	FLXPostgresServerAccessTuple* theTuple = [[self arrangedObjects] objectAtIndex:[rowIndexes firstIndex]];
	NSParameterAssert(theTuple);
	
	// if tuple is superadmin, don't allow moving
	if([theTuple isSuperadminAccess]==YES) {
		return NO;
	}
		
    // Copy the row numbers to the pasteboard.
    NSData* theData = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [thePasteboard declareTypes:[NSArray arrayWithObject:FLXHostAccessDropType] owner:self];
    [thePasteboard setData:theData forType:FLXHostAccessDropType];

    // return YES - we can drag
	return YES;
}

-(NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op {
	if([info draggingSource] == [self ibTableView]) {
		if(op == NSTableViewDropOn) {
			[tv setDropRow:row dropOperation:NSTableViewDropAbove];
		}		
		return NSDragOperationMove;
	} else {
		return NSDragOperationNone;
	}
}

-(BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)newRow dropOperation:(NSTableViewDropOperation)operation {
	NSPasteboard* thePasteboard = [info draggingPasteboard];
	NSData* theData = [thePasteboard dataForType:FLXHostAccessDropType];
	NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:theData];	
	NSParameterAssert([rowIndexes count]==1);
	NSInteger oldRow = [rowIndexes firstIndex];
	FLXPostgresServerAccessTuple* theTuple = [[self arrangedObjects] objectAtIndex:oldRow];
	NSParameterAssert(theTuple);
	
	// remove object
	[self removeObjectAtArrangedObjectIndex:oldRow];
	// add object
	if(oldRow > newRow) {
		[self insertObject:theTuple atArrangedObjectIndex:newRow];
	} else {
		[self insertObject:theTuple atArrangedObjectIndex:(newRow-1)];		
	}
	
	return YES;
}

@end
