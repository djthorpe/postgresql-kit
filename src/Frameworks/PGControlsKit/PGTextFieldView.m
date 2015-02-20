
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

#import "PGTextFieldView.h"

@implementation PGTextFieldView

-(void)drawInsertionPointInRect:(NSRect)rect color:(NSColor* )color {
	[[self font] set];
	NSRect stringBoundsRect = [[self stringValue] boundingRectWithSize:[self bounds].size options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingDisableScreenFontSubstitution attributes:nil];
    color = [color colorWithAlphaComponent:0.5];
    [color set];
    NSRectFillUsingOperation(stringBoundsRect,NSCompositeSourceOver);
}

/*

-(void)drawInsertionPointInRect:(NSRect)rect color:(NSColor *)color turnedOn:(BOOL)flag{
    // Call super class first.
    [super drawInsertionPointInRect:rect color:color turnedOn:flag];
    // Then tell the view to redraw to clear a caret.
    if( !flag ){
        [self setNeedsDisplay:YES];
    }
}
*/

-(void)drawRect:(NSRect)dirtyRect {
	[self drawInsertionPointInRect:[self bounds] color:[NSColor redColor]];
    [super drawRect:dirtyRect];
}

@end
