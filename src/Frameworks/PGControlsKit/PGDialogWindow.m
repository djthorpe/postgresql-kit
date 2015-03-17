
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
#import <PGControlsKit/PGControlsKit+Private.h>

@interface PGDialogWindow ()
@property (nonatomic,weak) IBOutlet PGDialogBackgroundView* ibBackgroundView;
@property (readonly) PGConnection* connection;
@property (readonly) NSMutableDictionary* parameters;
@end

@implementation PGDialogWindow

////////////////////////////////////////////////////////////////////////////////
#pragma mark constructors
////////////////////////////////////////////////////////////////////////////////

-(instancetype)init {
	self = [super init];
	if(self) {
		_connection = [PGConnection new];
		_parameters = [NSMutableDictionary new];
		NSParameterAssert(_connection);
		NSParameterAssert(_parameters);
	}
	return self;
}

-(NSString* )windowNibName {
	return @"PGDialog";
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark static methods
////////////////////////////////////////////////////////////////////////////////

+(NSURL* )defaultNetworkURL {
	return [NSURL URLWithHost:@"localhost" port:PGClientDefaultPort ssl:YES username:NSUserName() database:NSUserName() params:nil];
}

+(NSURL* )defaultFileURL {
	return [NSURL URLWithSocketPath:NSHomeDirectory() port:PGClientDefaultPort database:NSUserName() username:NSUserName() params:nil];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

@synthesize connection = _connection;
@synthesize parameters = _parameters;

////////////////////////////////////////////////////////////////////////////////
#pragma mark private methods
////////////////////////////////////////////////////////////////////////////////

-(void)load {
	[super loadWindow];
}

/**
 *  This method sets the subview for the window and sets the constraints
 */
-(BOOL)setView:(NSView* )subView parentView:(NSView* )parentView {
	NSParameterAssert(subView);
	NSParameterAssert(parentView);

	[parentView setSubviews:@[ subView ]];
	[subView setTranslatesAutoresizingMaskIntoConstraints:NO];

	// make it resize with the window
	NSDictionary* views = NSDictionaryOfVariableBindings(subView);
	[parentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[subView]|" options:0 metrics:nil views:views]];
	[parentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[subView]|" options:0 metrics:nil views:views]];
	
	return YES;
}

-(IBAction)doButtonPressed:(id)sender {
	NSParameterAssert([sender isKindOfClass:[NSButton class]]);
	NSWindow* theWindow = [(NSButton* )sender window];
	NSWindow* parentWindow = [theWindow sheetParent];
	
	if([[(NSButton* )sender title] isEqualToString:@"Cancel"]) {
		// Cancel
		[parentWindow endSheet:theWindow returnCode:NSModalResponseCancel];
	} else if([[(NSButton* )sender title] isEqualToString:@"OK"]) {
		// OK
		[parentWindow endSheet:theWindow returnCode:NSModalResponseOK];
	} else {
		// Unknown button clicked
		NSLog(@"Button clicked, ignoring: %@",sender);
	}
	
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark IBActions
////////////////////////////////////////////////////////////////////////////////

-(IBAction)doEndDialog:(id)sender {
	NSParameterAssert([sender isKindOfClass:[NSButton class]]);
	NSWindow* theWindow = [(NSButton* )sender window];
	NSWindow* parentWindow = [theWindow sheetParent];
	
	// get NSModalResponse value from delegate
	NSModalResponse returnValue = NSModalResponseOK;

	// TODO: Alter modal response
	
	[parentWindow endSheet:theWindow returnCode:returnValue];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark public methods
////////////////////////////////////////////////////////////////////////////////

-(void)beginCustomSheetWithTitle:(NSString* )title description:(NSString* )description view:(PGDialogView* )view parentWindow:(NSWindow* )parentWindow whenDone:(void(^)(NSModalResponse response)) callback {
	NSParameterAssert(title);
	NSParameterAssert(parentWindow);
	NSParameterAssert(view);
	NSParameterAssert(callback);

	// check to ensure NIB is loaded
	if([self window]==nil) {
		[self load];
		NSParameterAssert([self window] != nil);
	}

	// set window title
	[[self parameters] setObject:title forKey:@"window_title"];
	if(description) {
		[[self parameters] setObject:description forKey:@"window_description"];
	} else {
		[[self parameters] removeObjectForKey:@"window_description"];
	}

	// send message to delegate
	if([[self delegate] respondsToSelector:@selector(window:dialogWillOpenWithParameters:)]) {
		[[self delegate] window:self dialogWillOpenWithParameters:[self parameters]];
	}

	// set parameters for the view
	[view setViewParameters:[self parameters]];
	
	// set view and add constraints
	[self setView:[view view] parentView:[self ibBackgroundView]];

	// start sheet
	[parentWindow beginSheet:[self window] completionHandler:^(NSModalResponse returnValue) {
		[view viewDidEnd];
		callback(returnValue);
	}];
}

-(void)beginNetworkConnectionSheetWithURL:(NSURL* )url parentWindow:(NSWindow* )parentWindow whenDone:(void(^)(NSURL* url,NSModalResponse response)) callback {
	NSParameterAssert(parentWindow);
	NSString* title = @"Create Network Connection";
	NSString* description = @"Enter the details for the connection to the remote PostgreSQL database";
	PGDialogView* view = [self ibNetworkConnectionView];
	NSParameterAssert(view);

	// set the parameters from the URL
	[[self parameters] removeAllObjects];
	if(url==nil) {
		url = [[self class] defaultNetworkURL];
	}
	[[self parameters] setValuesForKeysWithDictionary:[url postgresqlParameters]];
	NSLog(@"params = %@",[self parameters]);
	
	[self beginCustomSheetWithTitle:title description:description view:view parentWindow:parentWindow whenDone:^(NSModalResponse response) {
		NSDictionary* parameters = [view parameters];
		callback([NSURL URLWithPostgresqlParams:parameters],response);
	}];
}

@end
