
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

#import "PGTabView.h"
#import "PGTabViewCell.h"

@implementation PGTabView

////////////////////////////////////////////////////////////////////////////////
#pragma mark constructor
////////////////////////////////////////////////////////////////////////////////

-(instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
		_tabs = [NSMutableArray new];
		_bgcolor = [NSColor redColor];
		_minimumTabWidth = 100;
		_maximumTabWidth = 180;
		_absoluteTabHeight = 30;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

@synthesize tabs = _tabs;

////////////////////////////////////////////////////////////////////////////////
#pragma mark private methods
////////////////////////////////////////////////////////////////////////////////

-(NSRect)rectForTabIndex:(NSUInteger)index {
	CGFloat totalWidth = [self frame].size.width;
	CGFloat tabWidth = 0.0;
	if([[self tabs] count]) {
		tabWidth = totalWidth / (CGFloat)[[self tabs] count];
		if(tabWidth < _minimumTabWidth) {
			tabWidth = _minimumTabWidth;
		}
		if(tabWidth > _maximumTabWidth) {
			tabWidth = _maximumTabWidth;
		}
	}
	return NSMakeRect((index * tabWidth),0,tabWidth,_absoluteTabHeight);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark public methods
////////////////////////////////////////////////////////////////////////////////

-(NSCell* )addTabViewWithTitle:(NSString* )title {
    PGTabViewCell* tab = [[PGTabViewCell alloc] initWithTabView:self title:title];
	
	// TODO: say "will be created" to delegate
	
	// add tab onto the end of the list of tabs
    [_tabs addObject:tab];

/*
    // If the new tab(add it to last) is not fully shown in the tabbar view, we
    // then exchange it with first(0 index) tab, and then active it.
    NSUInteger tabIndex = [[self tabs] indexOfObject:tab];
    NSRect tabBarViewRect = [self bounds];
    NSRect tabRect = [self tabRectFromIndex:tabIndex];
    if (!CGRectContainsRect(tabBarViewRect, tabRect)) {
        [self exchangeTabWithIndex:tabIndex withTab:0];
    }

    [tab setAsActiveTab];
*/
/*
    if ([[self delegate] respondsToSelector:@selector(tabDidBeCreated:)]) {
        [[self delegate] tabDidBeCreated:tab];
    }
*/
/*
    [self redraw];
*/
	[self setNeedsDisplay:YES];
    return tab;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark NSView overrides
////////////////////////////////////////////////////////////////////////////////

-(void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
	
	// draw the background
    [_bgcolor set];
    NSRect rect = [self frame];
    rect.origin = NSZeroPoint;
    NSRectFill(rect);
	
    // draw the tabs
    for(NSUInteger i = 0; i < [[self tabs] count]; i++) {
		PGTabViewCell* tabCell = [[self tabs] objectAtIndex:i];
		NSRect tabRect = [self rectForTabIndex:i];
		if(tabRect.size.width && tabRect.size.height) {
			[tabCell drawWithFrame:tabRect inView:self];
		}
    }
}

@end
