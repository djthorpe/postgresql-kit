
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

#import "PGTabViewCell.h"
#import "PGTabView.h"

const CGFloat kCloseButtonWidth = 8.0;

@implementation PGTabViewCell

////////////////////////////////////////////////////////////////////////////////
#pragma mark constructors
////////////////////////////////////////////////////////////////////////////////

-(instancetype)init {
	return nil;
}

-(instancetype)initWithTabView:(PGTabView* )tabView title:(NSString* )title {
	NSParameterAssert(tabView);
	NSParameterAssert(title);
	self = [super initTextCell:title];
	if(self) {
		_tabView = tabView;
		_active = NO;
		_hoverstate = PGTabViewCellHoverStateNone;
		_dragging = NO;
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

@synthesize tabView = _tabView;
@synthesize active = _active;
@synthesize hoverstate = _hoverstate;
@synthesize dragging = _dragging;

////////////////////////////////////////////////////////////////////////////////
#pragma mark private methods
////////////////////////////////////////////////////////////////////////////////

-(NSRect)closeButtonRectForFrame:(NSRect)frame {
    NSRect rect = NSMakeRect(NSMaxX(frame) - frame.size.height,0,frame.size.height,frame.size.height);
    return CGRectInset(rect,kCloseButtonWidth,kCloseButtonWidth);
}

-(void)drawCloseButtonInFrame:(NSRect)frame {
    NSBezierPath* path = [NSBezierPath bezierPath];
    CGFloat minX = NSMinX(frame);
    CGFloat maxX = NSMaxX(frame);
    CGFloat minY = NSMinY(frame);
    CGFloat maxY = NSMaxY(frame);
    NSPoint leftBottomPoint = NSMakePoint(minX,minY);
    NSPoint leftTopPoint = NSMakePoint(minX,maxY);
    NSPoint rightBottomPoint = NSMakePoint(maxX,minY);
    NSPoint rightTopPoint = NSMakePoint(maxX,maxY);

	if([self hoverstate]==PGTabViewCellHoverStateClose) {
		NSRect circleRect = NSInsetRect(frame,-4.0,-4.0);
		[path appendBezierPathWithOvalInRect:circleRect];
		[[_tabView inactiveTabColor] setFill];
		[path setLineWidth:0.0];
		[path fill];
		[path stroke];
	}

    [path moveToPoint:leftBottomPoint];
    [path lineToPoint:rightTopPoint];
    [path moveToPoint:leftTopPoint];
    [path lineToPoint:rightBottomPoint];
    [path setLineWidth:[_tabView tabBorderWidth]];
	[[_tabView tabBorderColor] set];
    [path stroke];
	
	
}

-(void)mouseMovedForFrame:(NSRect)frame point:(NSPoint)point {
	NSUInteger newHoverState = PGTabViewCellHoverStateNone;
	if(NSPointInRect(point,frame)==NO) {
		newHoverState = PGTabViewCellHoverStateNone;
	} else if(NSPointInRect(point,[self closeButtonRectForFrame:frame])) {
		newHoverState = PGTabViewCellHoverStateClose;
	} else {
		newHoverState = PGTabViewCellHoverStateTab;
	}
	if([self hoverstate] != newHoverState) {
		NSLog(@"needs redisplay = %@",self);
		[_tabView setNeedsDisplay:YES];
		[self setHoverstate:newHoverState];
	}
}

-(void)mouseDownForFrame:(NSRect)frame point:(NSPoint)point {
	if(NSPointInRect(point,[self closeButtonRectForFrame:frame]) && [self hoverstate]==PGTabViewCellHoverStateClose) {
		[_tabView closeTab:self];
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark NSCell overrides
////////////////////////////////////////////////////////////////////////////////

-(void)drawWithFrame:(NSRect)cellFrame inView:(NSView* )controlView {
	NSParameterAssert([controlView isKindOfClass:[PGTabView class]]);
	CGFloat borderWidth = [_tabView tabBorderWidth];
	CGFloat borderRadius = [_tabView tabBorderRadius];
    NSRect rect = NSInsetRect(cellFrame,borderWidth / 2.0,borderWidth / 2.0);
    rect = NSIntegralRect(rect);
    NSBezierPath* path = [NSBezierPath bezierPath];
    int minX = NSMinX(rect);
    int midX = NSMidX(rect);
    int maxX = NSMaxX(rect);
    int minY = NSMinY(rect);
    int midY = NSMidY(rect);
    int maxY = NSMaxY(rect);
    NSPoint leftBottomPoint = NSMakePoint(minX,minY);
    NSPoint leftMiddlePoint = NSMakePoint(minX,midY);
    NSPoint topMiddlePoint = NSMakePoint(midX,maxY);
    NSPoint rightMiddlePoint = NSMakePoint(maxX,midY);
    NSPoint rightBottomPoint = NSMakePoint(maxX,minY);
	
    // move path to left bottom point
    [path moveToPoint:leftBottomPoint];
    // left bottom to left middle
    [path appendBezierPathWithArcFromPoint:NSMakePoint(minX, minY) toPoint:leftMiddlePoint radius:borderRadius];
    // left middle to top middle
    [path appendBezierPathWithArcFromPoint:NSMakePoint(minX, maxY) toPoint:topMiddlePoint radius:borderRadius];
    // top middle to right middle
    [path appendBezierPathWithArcFromPoint:NSMakePoint(maxX, maxY) toPoint:rightMiddlePoint radius:borderRadius];
    // right middle to right bottom
    [path appendBezierPathWithArcFromPoint:NSMakePoint(maxX, minY) toPoint:rightBottomPoint radius:borderRadius];
	
    [path setLineWidth:borderWidth];
    
    // Draw tab background
	NSColor* backgroundColor;
	if([self active]) {
		backgroundColor = [_tabView activeTabColor];
	} else {
		backgroundColor = [_tabView inactiveTabColor];
		if([self hoverstate] == PGTabViewCellHoverStateNone) {
			backgroundColor = [backgroundColor colorWithAlphaComponent:0.5];
		}
	}
	NSColor* borderColor = [_tabView tabBorderColor];
	[backgroundColor set];
    [path fill];

	// Draw outline
	[borderColor set];
	[_tabView tabBorderWidth];
    [path stroke];

	// Draw close button
	[self drawCloseButtonInFrame:[self closeButtonRectForFrame:cellFrame]];
	
	// Draw text
	NSRect titleRect = cellFrame;
	NSAttributedString* string = [[NSAttributedString alloc] initWithString:[self stringValue]];
    CGFloat fontHeight = string.size.height;
    int yOffset = (titleRect.size.height - fontHeight) / 2.0;
    
    titleRect.size.height = fontHeight;
    titleRect.origin.y += yOffset;
    titleRect = NSInsetRect(titleRect,26, 0);
    [string drawInRect:titleRect];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark NSObject overrides
////////////////////////////////////////////////////////////////////////////////

-(NSString* )description {
	return [NSString stringWithFormat:@"<%@ %@>",NSStringFromClass([self class]),[self stringValue]];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark PGTabViewCellImage implementation
////////////////////////////////////////////////////////////////////////////////

@implementation PGTabViewCellImage

// properties
@synthesize cell = _cell;

// constructor
-(instancetype)init {
	return nil;
}

-(instancetype)initWithTabViewCell:(PGTabViewCell* )cell {
	NSParameterAssert(cell);
	NSRect frame = NSMakeRect(0.0,0.0,cell.frame.size.width,cell.frame.size.height);
	self = [super initWithSize:frame.size];
	if(self) {
		_cell = cell;
	}
	return self;
}

-(void)draw {
	[self lockFocus];
    [[NSColor clearColor] set];     // Transparent
    NSRectFill([cell frame]);
    [[self cell] drawWithFrame:[cell frame] inView:nil];
    [self unlockFocus];
}

@end
