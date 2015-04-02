
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
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

@synthesize tabView = _tabView;

////////////////////////////////////////////////////////////////////////////////
#pragma mark NSCell overrides
////////////////////////////////////////////////////////////////////////////////

-(void)drawWithFrame:(NSRect)cellFrame inView:(NSView* )controlView {
	CGFloat _borderWidth = 1.0;
	CGFloat _radius = 16.0;
    NSRect rect = NSInsetRect(cellFrame,_borderWidth / 2.0,_borderWidth / 2.0);
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
    [path appendBezierPathWithArcFromPoint:NSMakePoint(minX, minY) toPoint:leftMiddlePoint radius:_radius];
    // left middle to top middle
    [path appendBezierPathWithArcFromPoint:NSMakePoint(minX, maxY) toPoint:topMiddlePoint radius:_radius];
    // top middle to right middle
    [path appendBezierPathWithArcFromPoint:NSMakePoint(maxX, maxY) toPoint:rightMiddlePoint radius:_radius];
    // right middle to right bottom
    [path appendBezierPathWithArcFromPoint:NSMakePoint(maxX, minY) toPoint:rightBottomPoint radius:_radius];
	
    [path setLineWidth:_borderWidth];
    
    // Draw tab background 
	[[NSColor whiteColor] set];
    [path fill];
	// Draw outline
	[[NSColor blackColor] set];
    [path stroke];
	
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


@end
