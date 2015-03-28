
// Copyright 2009-2015 David Thorpe
// https://github.com/djthorpe/postgresql-kit
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

#import "LogController.h"

////////////////////////////////////////////////////////////////////////////////

@interface LogController ()
@property (weak) IBOutlet NSWindow* window;
@property (weak) IBOutlet NSTableView* tableView;
@property (retain,readonly) NSMutableArray* log;
@end

////////////////////////////////////////////////////////////////////////////////

@implementation LogController

////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructor
////////////////////////////////////////////////////////////////////////////////

-(instancetype)init {
    self = [super init];
    if (self) {
        _log = [NSMutableArray new];
		NSParameterAssert(_log);
    }
    return self;
}

-(void)awakeFromNib {
	NSParameterAssert(_log);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Properties
////////////////////////////////////////////////////////////////////////////////

@synthesize log = _log;

////////////////////////////////////////////////////////////////////////////////
#pragma mark Public Methods
////////////////////////////////////////////////////////////////////////////////

-(void)appendLog:(NSString* )text {
	NSParameterAssert(text);
	[[self log] addObject:text];
	[[self tableView] reloadData];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark IBActions
////////////////////////////////////////////////////////////////////////////////

-(IBAction)showHideWindow:(id)sender {
	if([[self window] isVisible]) {
		[[self window] close];
	} else {
		[[self window] makeKeyAndOrderFront:sender];
	}
}

-(IBAction)removeAllItems:(id)sender {
	[[self log] removeAllObjects];
	[[self tableView] reloadData];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark NSTableViewDataSource
////////////////////////////////////////////////////////////////////////////////

-(NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [[self log] count];
}

-(NSView* )tableView:(NSTableView* )tableView viewForTableColumn:(NSTableColumn* )tableColumn row:(NSInteger)rowIndex {
	NSTableCellView* cellView = [tableView makeViewWithIdentifier:[tableColumn identifier] owner:tableColumn];
	NSTextField* cell = [cellView textField];
    [cell setStringValue:[[self log] objectAtIndex:rowIndex]];
	return cellView;
}

@end
