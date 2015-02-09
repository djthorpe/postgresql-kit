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
@property (weak) IBOutlet NSScrollView* ibScrollView;
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
	[[self ibScrollView] setScrollerKnobStyle:NSScrollerKnobStyleLight];
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize dataSource;
@synthesize tag;

////////////////////////////////////////////////////////////////////////////////
// private methods

-(NSUInteger)_numberOfRows {
	if([[self dataSource] respondsToSelector:@selector(numberOfRowsForConsoleView:)]) {
		return [[self dataSource] numberOfRowsForConsoleView:self];
	} else {
		return 0;
	}
}

-(NSUInteger)_numberOfLinesForRow:(NSUInteger)rowIndex {
	NSString* string = [self _stringForRow:rowIndex];
	NSUInteger numberOfLines = 0;
	for(NSUInteger index = 0; index < [string length]; numberOfLines++) {
		index = NSMaxRange([string lineRangeForRange:NSMakeRange(index, 0)]);		
	}
	return numberOfLines;
}

-(NSString* )_stringForRow:(NSUInteger)row {
	if([[self dataSource] respondsToSelector:@selector(consoleView:stringForRow:)]) {
		return [[self dataSource] consoleView:self stringForRow:row];
	} else {
		return nil;
	}
}

-(CGFloat)_textHeight {
	return [_textFont capHeight] * 2;
}

-(NSTextField* )_textView {
	NSRect frame = NSMakeRect(0,0,0,[self _textHeight]);
	NSTextField* textField = [[NSTextField alloc] initWithFrame:frame];
	[textField setEditable:NO];
	[textField setFont:_textFont];
	[textField setDrawsBackground:NO];
	[textField setBordered:NO];
	[textField setBezeled:NO];
	[textField setTextColor:_textColor];
	return textField;
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(void)reloadData {
	[[self ibTableView] reloadData];
}

-(void)scrollToBottom {
	NSScrollView* scrollView = (NSScrollView* )[self view];
	NSParameterAssert([scrollView isKindOfClass:[NSScrollView class]]);
	NSPoint newScrollOrigin;
    // assume that the scrollview is an existing variable
    if ([[scrollView documentView] isFlipped]) {
        newScrollOrigin=NSMakePoint(0.0,NSMaxY([[scrollView documentView] frame])-NSHeight([[scrollView contentView] bounds]));
    } else {
        newScrollOrigin=NSMakePoint(0.0,0.0);
    }	
    [[scrollView documentView] scrollPoint:newScrollOrigin];
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
	NSTextField* view = [self _textView];
	[view setStringValue:[self _stringForRow:row]];
	return view;
}

-(BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex {
	return NO;
}

-(CGFloat)tableView:(NSTableView* )tableView heightOfRow:(NSInteger)row	{
	NSUInteger numberOfLines = [self _numberOfLinesForRow:row];
	return numberOfLines > 0 ? (numberOfLines * [self _textHeight]) : [self _textHeight];
}

@end
