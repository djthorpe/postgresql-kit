
#import "Application.h"

@implementation Application

NSString* PGServerHostAccessDragType = @"PGServerHostAccessDragType";

-(void)awakeFromNib {
	[_tableView setDataSource:self];
	[_tableView reloadData];
	[_tableView registerForDraggedTypes:[NSArray arrayWithObject:PGServerHostAccessDragType]];
}

////////////////////////////////////////////////////////////////////////////////
// file open/save/revert action

-(IBAction)ibFileOpen:(id)sender {
	// open the sheet which allows you to select a pg_hba.conf file
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	[panel setCanChooseDirectories:NO];
	[panel setCanChooseFiles:YES];
	[panel setAllowsMultipleSelection:NO];
	[panel beginSheetModalForWindow:_mainWindow completionHandler:^(NSInteger returnCode) {
		if(returnCode==NSOKButton) {
			BOOL isSuccess = [self load:[panel URL]];
			if(isSuccess==NO) {
				NSLog(@"error!");
				return;
			}
			[self setSaveEnabled:YES];
			[_tableView reloadData];
		}
    }];

}

-(void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	// do nothing
}

-(IBAction)ibFileSave:(id)sender {
	if(_hostAccessRules==nil) {
		// nothing loaded, ignore
		NSLog(@"ibFileSave: Nothing loaded, so ignoring action");
	}
	BOOL success = [_hostAccessRules save];
	if(success==NO) {
		NSLog(@"Save failed!");
	}
	[_tableView reloadData];
}

-(IBAction)ibFileRevert:(id)sender {
	if(_hostAccessRules==nil) {
		// nothing loaded, ignore
		NSLog(@"ibFileSave: Nothing loaded, so ignoring action");
	}
	BOOL success = [_hostAccessRules load];
	if(success==NO) {
		NSLog(@"Revert failed!");
	}	
	[_tableView reloadData];
}

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic modified;

-(BOOL)modified {
	return [_hostAccessRules modified];
}

////////////////////////////////////////////////////////////////////////////////
// methods

-(BOOL)load:(NSURL* )url {
	PGServerHostAccess* hostAccessRules = [[PGServerHostAccess alloc] initWithPath:[url path]];
	if(hostAccessRules==nil) {
		return NO;
	}
	// load the host access rules
	if([hostAccessRules load]==NO) {		
		return NO;
	}
	// set host access rules
	[self setHostAccessRules:hostAccessRules];
	// return success
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// NSTableViewDataSource implementation

-(NSInteger)numberOfRowsInTableView:(NSTableView* )tableView {
	if(_hostAccessRules==nil) {
		return 0;
	}
	return [_hostAccessRules count];
}

-(id)tableView:(NSTableView* )tableView objectValueForTableColumn:(NSTableColumn* )tableColumn row:(NSInteger)rowIndex {
	if(_hostAccessRules==nil) {
		return nil;
	}
	PGServerHostAccessRule* rule = [_hostAccessRules ruleAtIndex:rowIndex];
	NSString* identifier = [tableColumn identifier];
	if([identifier isEqual:@"type"]) {
		return [rule type];
	}
	if([identifier isEqual:@"method"]) {
		return [rule method];
	}	
	return [rule description];
}


////////////////////////////////////////////////////////////////////////////////
// NSTableView dragging implementation

-(BOOL)tableView:(NSTableView* )tableView writeRowsWithIndexes:(NSIndexSet* )rowIndexes toPasteboard:(NSPasteboard* )pboard {
	// return NO if more than one row
	if([rowIndexes count] != 1) {
		return NO;
	}
	NSUInteger firstIndex = [rowIndexes firstIndex];
	if(firstIndex >= [_hostAccessRules count]) {
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
		PGServerHostAccessRule* rule = [_hostAccessRules ruleAtIndex:[rowIndex unsignedIntegerValue]];		
		NSUInteger newRow = [_hostAccessRules insertRule:rule atIndex:proposedRow];
		[_tableView reloadData];
		if(newRow < [_hostAccessRules	count]) {
			[_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:newRow] byExtendingSelection:NO];
		} else {
			[_tableView deselectAll:self];
		}
	}
	return YES;
}

@end
