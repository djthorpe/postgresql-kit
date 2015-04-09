
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

#import <Cocoa/Cocoa.h>

// forward declarations
@class PGTabView;

// mouse state
enum {
	PGTabViewCellHoverStateNone     = 0x0000, // no hover state
	PGTabViewCellHoverStateTab      = 0x0001, // tab is being hovered on
	PGTabViewCellHoverStateClose    = 0x0002  // tab close button hover
};

@interface PGTabViewCell : NSCell {
	PGTabView* _tabView;
	NSUInteger _hoverstate;
	BOOL _active;
	BOOL _dragging;
}

// constructors
-(instancetype)initWithTabView:(PGTabView* )tabView title:(NSString* )title;

// properties
@property (readonly) PGTabView* tabView;
@property BOOL active;
@property BOOL dragging;
@property NSUInteger hoverstate;

// methods
-(void)drawWithFrame:(NSRect)cellFrame inView:(NSView* )controlView;
-(void)mouseMovedForFrame:(NSRect)frame point:(NSPoint)point;
-(void)mouseDownForFrame:(NSRect)frame point:(NSPoint)point;

@end

////////////////////////////////////////////////////////////////////////////////

@interface PGTabViewCellImage : NSImage {
    PGTabViewCell* _cell;
}

// constructor
-(instancetype)initWithTabViewCell:(PGTabViewCell* )cell;

// properties
@property PGTabViewCell* cell;

@end

////////////////////////////////////////////////////////////////////////////////

