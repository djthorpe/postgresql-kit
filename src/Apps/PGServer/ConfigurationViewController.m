
#import "ConfigurationViewController.h"

@implementation ConfigurationViewController

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize ibKeyString,ibValueString,ibCommentString,ibEnabled;

-(NSString* )nibName {
	return @"ConfigurationView";
}

-(NSString* )identifier {
	return @"configuration";
}

-(PGServer* )server {
	return [[self delegate] server];
}

-(PGServerConfiguration* )configuration {
	return [[[self delegate] server] configuration];
}

-(void)loadView {
	[super loadView];
	[_tableView reloadData];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(NSString* )_keyForRow:(NSUInteger)rowIndex {
	NSArray* keys = [[self configuration] keys];
	NSParameterAssert(rowIndex < [keys count]);
	return [keys objectAtIndex:rowIndex];
}

////////////////////////////////////////////////////////////////////////////////
// NSSplitView delegate methods

-(NSRect)splitView:(NSSplitView* )splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex {
	return [_resizeView convertRect:[_resizeView bounds] toView:splitView];
}

////////////////////////////////////////////////////////////////////////////////
// NSTableViewDataSource implementation

-(NSInteger)numberOfRowsInTableView:(NSTableView* )tableView {
	NSArray* keys = [[self configuration] keys];
	return [keys count];
}

-(id)tableView:(NSTableView* )tableView objectValueForTableColumn:(NSTableColumn* )tableColumn row:(NSInteger)rowIndex {
	return [self _keyForRow:rowIndex];
}

////////////////////////////////////////////////////////////////////////////////
// NSTableViewDelegate implementation

-(void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	NSIndexSet* selectedRows = [_tableView selectedRowIndexes];
	NSParameterAssert([selectedRows count] == 1);
	
	NSString* key = [self _keyForRow:[selectedRows firstIndex]];
	[self setIbKeyString:key];
	[self setIbValueString:[[self configuration] stringForKey:key]];
	[self setIbCommentString:[[self configuration] commentForKey:key]];
	[self setIbEnabled:[[self configuration] enabledForKey:key]];
}


@end
