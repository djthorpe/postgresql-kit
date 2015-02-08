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

////////////////////////////////////////////////////////////////////////////////

@interface PGConsoleViewController ()
@property (weak) IBOutlet NSTableView* ibTableView;
@end

////////////////////////////////////////////////////////////////////////////////

@implementation PGConsoleViewController

////////////////////////////////////////////////////////////////////////////////
// constructors

-(id)init {
    self = [super initWithNibName:@"PGConsoleView" bundle:[NSBundle bundleForClass:[self class]]];
	if(self) {
		_textFont = [NSFont fontWithName:@"Monaco" size:11];
		_textColor = [NSColor grayColor];
		_backgroundColor = [NSColor blackColor];
	}
	return self;
}

-(void)awakeFromNib {
	[[self ibTableView] setBackgroundColor:_backgroundColor];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(NSUInteger)_numberOfRows {
	return 0;
}

////////////////////////////////////////////////////////////////////////////////
// NSTableViewDataSource implementation

-(NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	NSInteger numOfRows = [self _numberOfRows];
/*	if([self editable]) {
		// we add one row at the bottom for the prompt
		numOfRows = numOfRows + 1;
	}*/
	return numOfRows;
}

-(NSView* )tableView:(NSTableView* )tableView viewForTableColumn:(NSTableColumn* )tableColumn row:(NSInteger)row {
	return [NSImageView new];
}

-(BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex {
	return NO;
}

/*
-(CGFloat)tableView:(NSTableView* )tableView heightOfRow:(NSInteger)row	{
	NSUInteger numberOfLines = [self _numberOfLinesForRow:row];
	return numberOfLines > 0 ? (numberOfLines * [self textHeight]) : [self textHeight];
}
*/

@end
