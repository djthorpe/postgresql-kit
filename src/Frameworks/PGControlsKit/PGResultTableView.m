
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

#import <PGControlsKit/PGControlsKit.h>

@interface PGResultTableView ()
@end

@implementation PGResultTableView

////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructor
////////////////////////////////////////////////////////////////////////////////

-(instancetype)init {
	return nil;
}

-(instancetype)initWithDataSource:(PGResult* )dataSource {
    self = [super init];
    if(self) {
		_dataSource = dataSource;
		_scrollView = nil;
		_tableView = nil;
		NSParameterAssert(_dataSource);
		[self _doinit];
		NSParameterAssert(_scrollView);
		NSParameterAssert(_tableView);
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Properties
////////////////////////////////////////////////////////////////////////////////

@synthesize view = _scrollView;
@synthesize tableView = _tableView;
@synthesize dataSource = _dataSource;

////////////////////////////////////////////////////////////////////////////////
#pragma mark Private Methods
////////////////////////////////////////////////////////////////////////////////

-(void)_doinit {
	NSParameterAssert(_tableView==nil);
	NSParameterAssert(_scrollView==nil);
	_scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0,0,100,100)];
	_tableView = [[NSTableView alloc] initWithFrame:NSMakeRect(0,0,100,100)];
	NSParameterAssert(_scrollView);
	NSParameterAssert(_tableView);

	// set table properties
	[[self view] setFocusRingType:NSFocusRingTypeNone];

	// create columns
	for(NSString* identifier in [[self dataSource] columnNames]) {
		NSTableColumn* column = [[NSTableColumn alloc] initWithIdentifier:identifier];
		[[column headerCell] setStringValue:identifier];
		[column setWidth:100];
		[column setEditable:NO];
		[[self tableView] addTableColumn:column];
	}

	// set data source
	[[self tableView] setDataSource:self];

	// add table view to scroll view
	[_scrollView setDocumentView:[self tableView]];
	[_scrollView setHasVerticalScroller:YES];
	[_scrollView setAutohidesScrollers:YES];
	[_scrollView setAutoresizesSubviews:YES];
	
	// add table header

	// reload table data
	[[self tableView] reloadData];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark NSTableViewDataSource implementation
////////////////////////////////////////////////////////////////////////////////

-(NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	NSParameterAssert(aTableView==[self tableView]);
	return [[self dataSource] size];
}

-(id)tableView:(NSTableView* )aTableView objectValueForTableColumn:(NSTableColumn* )aTableColumn row:(NSInteger)rowIndex {
	NSParameterAssert(aTableView==[self tableView]);
	[[self dataSource] setRowNumber:rowIndex];
	NSDictionary* row = [[self dataSource] fetchRowAsDictionary];
	return [row objectForKey:[aTableColumn identifier]];
}

@end
