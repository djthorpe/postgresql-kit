
#import "ConfigurationViewController.h"

@implementation ConfigurationViewController

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
// NSSplitView delegate methods

-(NSRect)splitView:(NSSplitView* )splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex {
	return [_resizeView convertRect:[_resizeView bounds] toView:splitView];
}

////////////////////////////////////////////////////////////////////////////////
// NSTableViewDataSource implementation

-(NSInteger)numberOfRowsInTableView:(NSTableView* )tableView {
	NSArray* keys = [[self configuration] keys];
	NSLog(@"configuration = %@",keys);
	return [keys count];
}

-(id)tableView:(NSTableView* )tableView objectValueForTableColumn:(NSTableColumn* )tableColumn row:(NSInteger)rowIndex {
	return [NSString stringWithFormat:@"%@",[self configuration]];
}


@end
