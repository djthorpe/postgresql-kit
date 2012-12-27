
#import "HostAccessViewController.h"

@implementation HostAccessViewController

NSString* PGServerHostAccessDragType = @"PGServerHostAccessDragType";

-(NSString* )nibName {
	return @"HostAccessView";
}

-(NSString* )identifier {
	return @"hostaccess";
}

-(NSInteger)tag {
	return 3;
}

-(PGServer* )server {
	return [[self delegate] server];
}

-(PGServerHostAccess* )hostAccessRules {
	return [[[self delegate] server] hostAccessRules];
}

-(void)loadView {
	[super loadView];
	[_tableView registerForDraggedTypes:[NSArray arrayWithObject:PGServerHostAccessDragType]];
	[_tableView reloadData];
}

////////////////////////////////////////////////////////////////////////////////
// NSSplitView delegate methods

-(NSRect)splitView:(NSSplitView* )splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex {
	return [_resizeView convertRect:[_resizeView bounds] toView:splitView];
}


////////////////////////////////////////////////////////////////////////////////
// NSTableViewDataSource implementation

-(NSInteger)numberOfRowsInTableView:(NSTableView* )tableView {
	if([self hostAccessRules]) {
		return [[self hostAccessRules] count];
	} else {
		return 0;
	}
}

-(id)tableView:(NSTableView* )tableView objectValueForTableColumn:(NSTableColumn* )tableColumn row:(NSInteger)rowIndex {
	NSParameterAssert([self hostAccessRules]);
	NSParameterAssert(rowIndex >= 0 && rowIndex < [[self hostAccessRules] count]);
	PGServerHostAccessRule* rule = [[self hostAccessRules] ruleAtIndex:rowIndex];
	return [rule description];
}

////////////////////////////////////////////////////////////////////////////////
// NSTableView dragging implementation

-(BOOL)tableView:(NSTableView* )tableView writeRowsWithIndexes:(NSIndexSet* )rowIndexes toPasteboard:(NSPasteboard* )pboard {
	NSParameterAssert([self hostAccessRules]);
	// return NO if more than one row
	if([rowIndexes count] != 1) {
		return NO;
	}
	NSUInteger firstIndex = [rowIndexes firstIndex];
	if(firstIndex >= [[self hostAccessRules] count]) {
		return NO;
	}
	NSDictionary* propertyList = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:firstIndex] forKey:@"rule"];
	[pboard setPropertyList:propertyList forType:PGServerHostAccessDragType];
	[tableView selectRowIndexes:rowIndexes byExtendingSelection:NO];
	return YES;
}

-(NSDragOperation)tableView:(NSTableView* )tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
	NSParameterAssert([self hostAccessRules]);
	if(operation==NSTableViewDropAbove) {
		return NSDragOperationMove;
	}
	return NSDragOperationNone;
}

-(BOOL)tableView:(NSTableView* )tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)proposedRow dropOperation:(NSTableViewDropOperation)operation {
	NSPasteboard* pboard = [info draggingPasteboard];
	NSDictionary* propertyList = [pboard propertyListForType:PGServerHostAccessDragType];
	NSParameterAssert(pboard && propertyList);
	NSNumber* rowIndex = [propertyList objectForKey:@"rule"];
	if(operation==NSTableViewDropAbove) {
		PGServerHostAccessRule* rule = [[self hostAccessRules] ruleAtIndex:[rowIndex unsignedIntegerValue]];
		NSUInteger newRow = [[self hostAccessRules] insertRule:rule atIndex:proposedRow];
		[_tableView reloadData];
		if(newRow < [[self hostAccessRules]	count]) {
			[_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:newRow] byExtendingSelection:NO];
		} else {
			[_tableView deselectAll:self];
		}
	}
	return YES;
}

@end
