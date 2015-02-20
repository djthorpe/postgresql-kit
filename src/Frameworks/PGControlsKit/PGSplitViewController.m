
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

@interface PGSplitViewController ()

@property (assign) IBOutlet NSView* ibGrabberView;
@property (weak) IBOutlet NSView* ibLeftView;
@property (weak) IBOutlet NSView* ibRightView;
@property (weak) IBOutlet NSView* ibActionButton;

@end

enum {
	PGSplitViewTagLeftStausView = 1000
};

@implementation PGSplitViewController

////////////////////////////////////////////////////////////////////////////////
// constructors

-(id)init {
    NSString* nibName = @"PGSplitView";
    NSBundle* bundle = [NSBundle bundleForClass:[self class]];;
    return [super initWithNibName:nibName bundle:bundle];
}

-(void)loadView {
	[super loadView];

	// set delegate
	[(NSSplitView* )[self view] setDelegate:self];
	
	// insert action button
	NSView* leftStatusView = [[self view] viewWithTag:PGSplitViewTagLeftStausView];
	NSParameterAssert([self ibActionButton]);
	NSParameterAssert(leftStatusView);
	[leftStatusView addSubview:[self ibActionButton]];
	
	// set minimum size
	[self setMinimumSize:[[self ibGrabberView] bounds].size.width];
}

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic autosaveName;
@synthesize minimumSize;

-(NSString* )autosaveName {
	return [(NSSplitView* )[self view] autosaveName];
}

-(void)setAutosaveName:(NSString* )value {
	[(NSSplitView* )[self view] setAutosaveName:value];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(BOOL)setView:(NSView* )subView parentView:(NSView* )parentView {
	NSParameterAssert(subView && parentView);

	// add splitview to the content view
	[parentView addSubview:subView];
	[subView setTranslatesAutoresizingMaskIntoConstraints:NO];

	// make it resize with the window
	NSDictionary* views = NSDictionaryOfVariableBindings(subView);
	[parentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[subView]|" options:0 metrics:nil views:views]];
	[parentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[subView]|" options:0 metrics:nil views:views]];
	
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(BOOL)setLeftView:(id)viewOrController {
	NSParameterAssert([viewOrController isKindOfClass:[NSView class]] || [viewOrController isKindOfClass:[NSViewController class]]);
	if([viewOrController isKindOfClass:[NSViewController class]]) {
		return [self setView:[viewOrController view] parentView:[self ibLeftView]];
	} else if([viewOrController isKindOfClass:[NSView class]]) {
		return [self setView:viewOrController parentView:[self ibLeftView]];
	} else {
		return NO;
	}
}

-(BOOL)setRightView:(id)viewOrController {
	NSParameterAssert([viewOrController isKindOfClass:[NSView class]] || [viewOrController isKindOfClass:[NSViewController class]]);
	if([viewOrController isKindOfClass:[NSViewController class]]) {
		return [self setView:[viewOrController view] parentView:[self ibRightView]];
	} else if([viewOrController isKindOfClass:[NSView class]]) {
		return [self setView:viewOrController parentView:[self ibRightView]];
	} else {
		return NO;
	}
}

-(void)addMenuItem:(NSMenuItem* )menuItem {
	NSMenu* menu = [[self ibActionButton] menu];
	NSParameterAssert(menu);
	[menu addItem:menuItem];
}

-(void)removeAllMenuItems {
	NSMenu* menu = [[self ibActionButton] menu];
	NSParameterAssert(menu);
	[menu removeAllItems];
}

////////////////////////////////////////////////////////////////////////////////
// NSSplitViewDelegate

-(NSRect)splitView:(NSSplitView* )splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex {
	NSParameterAssert([self ibGrabberView]);
	return [[self ibGrabberView] convertRect:[[self ibGrabberView] bounds] toView:splitView];
}

-(CGFloat)splitView:(NSSplitView* )splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex {
	// constrain view to width of grabber view
	NSParameterAssert([self ibGrabberView]);
	CGFloat grabberWidth = [[self ibGrabberView] bounds].size.width;
	CGFloat minSize = [self minimumSize] > grabberWidth ? [self minimumSize] : grabberWidth;
	if(proposedPosition < minSize) {
		proposedPosition = minSize;
	}
	return proposedPosition;
}

@end
