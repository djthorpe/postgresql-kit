
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

#import "PGControlsKit.h"

@implementation PGConsoleView

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle* )nibBundleOrNil {
	if(nibBundleOrNil==nil) {
		nibBundleOrNil = [NSBundle bundleForClass:[self class]];
	}
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		_textFont = [NSFont fontWithName:@"Monaco" size:11];
		_textColor = [NSColor grayColor];
		_backgroundColor = [NSColor blackColor];
		_showGutter = YES;
		_editable = NO;
		_editBuffer = [NSMutableString string];
    }
    return self;
}

-(void)awakeFromNib {
	[[self tableView] setBackgroundColor:_backgroundColor];
	// set gutter size to be the default
	NSTableColumn* column = [[self tableView] tableColumnWithIdentifier:@"gutter"];
	NSParameterAssert(column);
	[column setWidth:[self defaultGutterWidth]];
}

-(NSBundle* )bundle {
	return [NSBundle bundleForClass:[self class]];
}

-(NSImage* )image {
	NSString* path = [[self bundle] pathForImageResource:@"traffic-green"];
	NSParameterAssert(path);
	return [[NSImage alloc] initWithContentsOfFile:path];
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize textFont = _textFont;
@synthesize textColor = _textColor;
@synthesize editable = _editable;
@synthesize backgroundColor = _backgroundColor;
@synthesize editBuffer = _editBuffer;
@synthesize delegate;
@dynamic textHeight;
@dynamic showGutter;
@dynamic defaultGutterWidth;

-(CGFloat)textHeight {
	return [[self textFont] capHeight] * 2;
}

-(CGFloat)defaultGutterWidth {
	// gutter size is the size of the image
	return [[self image] size].width;
}

-(NSString *)nibName {
	return @"PGConsoleView";
}

-(void)setShowGutter:(BOOL)value {
	_showGutter = value;
	NSTableColumn* column = [[self tableView] tableColumnWithIdentifier:@"gutter"];
	NSParameterAssert(column);
	[column setHidden:(value ? NO : YES)];
}

-(BOOL)showGutter {
	return _showGutter;
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(NSUInteger)_numberOfRows {
	if([self delegate] && [[self delegate] respondsToSelector:@selector(numberOfRowsInConsoleView:)]) {
		return [[self delegate] numberOfRowsInConsoleView:self];
	} else {
		return 0;
	}
}

-(NSString* )_stringForRow:(NSUInteger)rowIndex {
	NSString* string = nil;
	NSUInteger actualLines = [self _numberOfRows];
	if([self editable] && rowIndex==actualLines) {
		// display prompt
		return [self editBuffer];
	} else if([self delegate] && [[self delegate] respondsToSelector:@selector(consoleView:stringForRow:)]) {
		string = [[self delegate] consoleView:self stringForRow:rowIndex];
	}
	return string;
}

-(NSUInteger)_numberOfLinesForRow:(NSUInteger)rowIndex {
	NSString* string = [self _stringForRow:rowIndex];
	NSUInteger numberOfLines = 0;
	for(NSUInteger index = 0; index < [string length]; numberOfLines++) {
		index = NSMaxRange([string lineRangeForRange:NSMakeRange(index, 0)]);		
	}
	return numberOfLines;
}

-(NSView* )_gutterView {
	NSImage* image = [self image];
	NSRect frame = NSMakeRect(0, 0, [image size].width,[image size].height);
	NSImageView* imageView = [[NSImageView alloc] initWithFrame:frame];
	[imageView setImage:image];
	[imageView setImageAlignment:(NSImageAlignTop | NSImageAlignLeft)];
	[imageView setImageScaling:NSImageScaleNone];
	return imageView;
}

-(NSTextField* )_textView {
	NSRect frame = NSMakeRect(0,0,0,[self textHeight]);
	NSTextField* textField = [[NSTextField alloc] initWithFrame:frame];
	[textField setEditable:NO];
	[textField setFont:[self textFont]];
	[textField setDrawsBackground:NO];
	[textField setBordered:NO];
	[textField setBezeled:NO];
	[textField setTextColor:_textColor];
	return textField;
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(void)reloadData {
	[[self tableView] reloadData];
}

-(void)scrollToBottom {
	NSScrollView* scrollView = (NSScrollView* )[self view];
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
	if([self editable]) {
		// we add one row at the bottom for the prompt
		numOfRows = numOfRows + 1;
	}
	return numOfRows;
}

-(NSView* )tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if([[tableColumn identifier] isEqualToString:@"gutter"]) {
		return [self _gutterView];
	} else {
		NSTextField* view = [self _textView];
		[view setStringValue:[self _stringForRow:row]];
		return view;
	}
}

-(BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex {
	return NO;
}

-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row	{
	NSUInteger numberOfLines = [self _numberOfLinesForRow:row];
	return numberOfLines > 0 ? (numberOfLines * [self textHeight]) : [self textHeight];
}

////////////////////////////////////////////////////////////////////////////////
// NSControl implementation

-(void)keyDown:(NSEvent *)event {
	NSString* chars = [event characters];
	if([chars length]==0) {
		return;
	}
	NSUInteger charCode = [[event characters] characterAtIndex:0];
	if(charCode == NSDeleteCharacter || charCode == NSDeleteFunctionKey || charCode== NSBackspaceCharacter) {
		// delete edit buffer
		if([[self editBuffer] length]) {
			NSRange range = NSMakeRange([[self editBuffer] length] - 1, 1);
			[[self editBuffer] deleteCharactersInRange:range];
		}
		[self reloadData];
		[self scrollToBottom];
		return;
	}
	if(charCode == NSCarriageReturnCharacter || charCode == NSEnterCharacter) {
		if([event modifierFlags] & NSCommandKeyMask) {
			[[self editBuffer] appendString:@"\n"];
		} else if([self delegate] && [[self delegate] respondsToSelector:@selector(consoleView:appendString:)]) {
			[[self delegate] consoleView:self appendString:[[self editBuffer] copy]];
			[[self editBuffer] setString:@""];
		}
		return;
	}

	// append to edit buffer
	[[self editBuffer] appendString:chars];
	// scroll to end
	[self reloadData];
	[self scrollToBottom];
}


@end
