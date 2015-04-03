
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
		_backgroundColor = [NSColor windowBackgroundColor];
		_tabBorderColor = [NSColor controlDarkShadowColor];
		_inactiveTabColor = [NSColor controlShadowColor];
		_activeTabColor = [NSColor selectedMenuItemColor];
		_minimumTabWidth = 50;
		_maximumTabWidth = 120;
		_tabHeight = frame.size.height;
		_tabBorderWidth = 0.1;
		_tabBorderRadius = 4.0;
		_trackingArea = nil;
		_selectedTab = nil;
		[self setFrame:frame];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

@synthesize tabs = _tabs;
@synthesize backgroundColor = _backgroundColor;
@synthesize tabBorderColor = _tabBorderColor;
@synthesize inactiveTabColor = _inactiveTabColor;
@synthesize activeTabColor = _activeTabColor;
@synthesize minimumTabWidth = _minimumTabWidth;
@synthesize maximumTabWidth = _maximumTabWidth;
@synthesize tabHeight= _tabHeight;
@synthesize tabBorderWidth= _tabBorderWidth;
@synthesize tabBorderRadius= _tabBorderRadius;
@dynamic selectedTab;

-(PGTabViewCell* )selectedTab {
	return _selectedTab;
}

-(void)setSelectedTab:(PGTabViewCell* )selectedTab {
	for(PGTabViewCell* tab in _tabs) {
		if(tab==selectedTab && [tab active] != YES) {
			NSLog(@"set selected tab: %@ active=%@",selectedTab,[selectedTab active] ? @"YES" : @"NO");
			[tab setActive:YES];
			[self setNeedsDisplay:YES];
		} else {
			[tab setActive:NO];
		}
	}
}

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
	return NSMakeRect((index * tabWidth),0,tabWidth,_tabHeight);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark public methods
////////////////////////////////////////////////////////////////////////////////

-(PGTabViewCell* )addTabViewWithTitle:(NSString* )title {
    PGTabViewCell* tab = [[PGTabViewCell alloc] initWithTabView:self title:title];
	
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
*/
	[self setSelectedTab:tab];
	[self setNeedsDisplay:YES];
    return tab;
}

-(void)closeTab:(PGTabViewCell* )tab {
	NSParameterAssert(tab);
    NSUInteger i = [_tabs indexOfObject:tab];
	if(i==NSNotFound) {
		return;
	}
	[_tabs removeObjectAtIndex:i];
	if([_tabs count] > 0) {
		if(i >= [_tabs count]) {
			i = [_tabs count] - 1;
		}
		[self setSelectedTab:[_tabs objectAtIndex:i]];
	}
	[self setNeedsDisplay:YES];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark NSView overrides
////////////////////////////////////////////////////////////////////////////////

-(void)setFrame:(NSRect)frame {
	[super setFrame:frame];
	if(_trackingArea) {
		[super removeTrackingArea:_trackingArea];
	}
    NSTrackingAreaOptions options = (NSTrackingActiveAlways | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved);
	_trackingArea = [[NSTrackingArea alloc] initWithRect:[self frame] options:options owner:self userInfo:nil];
	NSParameterAssert(_trackingArea);
    [super addTrackingArea:_trackingArea];
}

-(void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
	
	// draw the background
    [_backgroundColor set];
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

-(void)mouseMoved:(NSEvent* )theEvent{
    NSPoint p = [theEvent locationInWindow];
    p = [self convertPoint:p fromView:[[self window] contentView]];

	// determine which tab this is in
    for(NSUInteger i = 0; i < [_tabs count]; i++) {
		NSRect r = [self rectForTabIndex:i];
		if(NSPointInRect(p,r)==NO) {
			continue;
		}
        [[_tabs objectAtIndex:i] mouseMovedForFrame:r point:p];
    }
}

-(void)mouseDown:(NSEvent* )theEvent {
    NSPoint p = [theEvent locationInWindow];
    p = [self convertPoint:p fromView:[[self window] contentView]];

	// determine which tab this is in
    for(NSUInteger i = 0; i < [_tabs count]; i++) {
		NSRect r = [self rectForTabIndex:i];
		if(NSPointInRect(p,r)==NO) {
			continue;
		}
        [[_tabs objectAtIndex:i] mouseDownForFrame:r point:p];
    }
}


@end
