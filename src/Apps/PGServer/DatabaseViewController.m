
#import "DatabaseViewController.h"
#import "AppDelegate.h"

@implementation DatabaseViewController

-(NSString* )nibName {
	return @"DatabaseView";
}

-(NSString* )identifier {
	return @"databases";
}

-(NSInteger)tag {
	return 5;
}

-(PGConnection* )connection {
	return [[self delegate] connection];
}

////////////////////////////////////////////////////////////////////////////////
// NSSplitView delegate methods

-(NSRect)splitView:(NSSplitView* )splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex {
	return [_resizeView convertRect:[_resizeView bounds] toView:splitView];
}

////////////////////////////////////////////////////////////////////////////////
// NSTableViewDataSource implementation

-(NSInteger)numberOfRowsInTableView:(NSTableView* )tableView {
	if([self result]==nil) {
		return 0;
	}
	return [[self result] size];
}

-(id)tableView:(NSTableView* )tableView objectValueForTableColumn:(NSTableColumn* )tableColumn row:(NSInteger)rowIndex {
	NSParameterAssert([self result]);
	NSParameterAssert(rowIndex < [[self result] size]);
	
	// fetch the record
	[[self result] setRowNumber:rowIndex];
	NSDictionary* row = [[self result] fetchRowAsDictionary];
	// get cell value
	id cell = [row objectForKey:[tableColumn identifier]];
	return cell ? cell : [NSNull null];
}

////////////////////////////////////////////////////////////////////////////////
// NSTableViewDelegate implementation

-(void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	NSIndexSet* selectedRows = [_tableView selectedRowIndexes];
	NSLog(@"selected = %@",selectedRows);
}


////////////////////////////////////////////////////////////////////////////////
// Get list of databases

-(void)refreshDatabases:(id)sender {
	PGConnection* connection = [self connection];
	NSError* error = nil;
	PGResult* result = [connection execute:@"SELECT datname AS database FROM pg_database WHERE NOT(datistemplate)" format:PGClientTupleFormatBinary error:&error];
	if(error) {
#ifdef DEBUG
		NSLog(@"refreshDatabases: Error: %@",error);
#endif
		result = nil;
	}
	[self setResult:result];
	[_tableView reloadData];
}

////////////////////////////////////////////////////////////////////////////////
// NSViewController overrides

-(BOOL)willSelectView:(id)sender {
	// only allow view to be selected if server is running
	PGServer* server = [[self delegate] server];
	if([server state]==PGServerStateAlreadyRunning || [server state]==PGServerStateRunning) {
		[self refreshDatabases:sender];
		return YES;
	} else {
		return NO;
	}
}

-(BOOL)willUnselectView:(id)sender {
	[self setResult:nil];
	return YES;
}


////////////////////////////////////////////////////////////////////////////////
// Init methods

-(void)loadView {
	[super loadView];
}


////////////////////////////////////////////////////////////////////////////////
// Actions

-(IBAction)ibCreateDatabase:(id)sender {
	NSLog(@"create");
}

-(IBAction)ibDropDatabase:(id)sender {
	NSLog(@"drop");
}

-(IBAction)ibBackupDatabase:(id)sender {
	NSLog(@"backup");	
}


@end
