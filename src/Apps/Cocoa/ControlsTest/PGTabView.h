
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

////////////////////////////////////////////////////////////////////////////////

@class PGTabViewCell;

////////////////////////////////////////////////////////////////////////////////

@protocol PGTabViewDelegate <NSObject>
@optional
//-(void)tabView:(PGTabView* ) active:(PGTabViewCell* )tab;
//-(void)tabView:(PGTabView* ) closed:(PGTabViewCell* )tab;
//-(void)tabView:(PGTabView* ) created:(PGTabViewCell* )tab;
@end

////////////////////////////////////////////////////////////////////////////////


@interface PGTabView : NSView {
	NSMutableArray* _tabs;
	NSColor* _backgroundColor;
	NSColor* _tabBorderColor;
	NSColor* _inactiveTabColor;
	NSColor* _activeTabColor;
	CGFloat _minimumTabWidth;
	CGFloat _maximumTabWidth;
	CGFloat _tabHeight;
	CGFloat _tabBorderWidth;
	CGFloat _tabBorderRadius;
	NSTrackingArea* _trackingArea;
	PGTabViewCell* _selectedTab;
}

// properties
@property (weak) id<PGTabViewDelegate> delegate;
@property (readonly) NSArray* tabs;
@property (retain) NSColor* backgroundColor;
@property (retain) NSColor* tabBorderColor;
@property (retain) NSColor* inactiveTabColor;
@property (retain) NSColor* activeTabColor;
@property CGFloat minimumTabWidth;
@property CGFloat maximumTabWidth;
@property CGFloat tabHeight;
@property CGFloat tabBorderWidth;
@property CGFloat tabBorderRadius;
@property PGTabViewCell* selectedTab;

// public methods
-(PGTabViewCell* )addTabViewWithTitle:(NSString* )title;
-(void)closeTab:(PGTabViewCell* )tab;

@end
