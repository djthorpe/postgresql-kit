
#import "HostAccessViewController.h"

@implementation HostAccessViewController

NSString* PGServerHostAccessDragType = @"PGServerHostAccessDragType";

-(NSString* )nibName {
	return @"HostAccessView";
}

-(NSString* )identifier {
	return @"hostaccess";
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
	return [[self hostAccessRules] count];
}

-(id)tableView:(NSTableView* )tableView objectValueForTableColumn:(NSTableColumn* )tableColumn row:(NSInteger)rowIndex {
	return [NSString stringWithFormat:@"HELLO"];
}


////////////////////////////////////////////////////////////////////////////////
// NSTableView dragging implementation

-(BOOL)tableView:(NSTableView* )tableView writeRowsWithIndexes:(NSIndexSet* )rowIndexes toPasteboard:(NSPasteboard* )pboard {
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
