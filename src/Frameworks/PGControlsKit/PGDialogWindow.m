
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
@property (readonly) PGConnection* connection;
@property (nonatomic,weak) IBOutlet PGDialogBackgroundView* ibBackgroundView;
@property (weak,nonatomic) IBOutlet PGDialogView* ibFileConnectionView;
@property (weak,nonatomic) IBOutlet PGDialogView* ibNetworkConnectionView;
@property (weak,nonatomic) IBOutlet PGDialogView* ibPasswordView;
@property (weak,nonatomic) IBOutlet PGDialogView* ibCreateRoleView;
@property (weak,nonatomic) IBOutlet PGDialogView* ibCreateSchemaView;
@property (weak,nonatomic) IBOutlet PGDialogView* ibCreateDatabaseView;
@end

@implementation PGDialogWindow

////////////////////////////////////////////////////////////////////////////////
#pragma mark constructors
////////////////////////////////////////////////////////////////////////////////

-(NSString* )windowNibName {
	return @"PGDialog";
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

@synthesize windowTitle;
@synthesize windowDescription;

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
#pragma mark private methods
////////////////////////////////////////////////////////////////////////////////

/**
 *  This method is called after the NIB is loaded
 */
-(void)awakeFromNib {
	// calculate the width and height of the window
	NSParameterAssert([self window]);
	NSParameterAssert([self ibBackgroundView]);
	NSSize windowSize = [[self window] frame].size;
	NSSize viewSize = [[self ibBackgroundView] frame].size;
	_offset.width = windowSize.width - viewSize.width;
	_offset.height = windowSize.height - viewSize.height;
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
	
	// set the window height and width
	NSWindow* window = [parentView window];
	NSRect frame = [window frame];
	frame.size = NSMakeSize(subView.frame.size.width + _offset.width,subView.frame.size.height + _offset.height);
	[window setFrame:frame display:NO];

//	NSLog(@"window offsize => %@",NSStringFromSize(_offset));
//	NSLog(@"set window size => %@",NSStringFromSize(frame.size));
//	NSLog(@"window size => %@",NSStringFromSize([window frame].size));
	
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark IBActions
////////////////////////////////////////////////////////////////////////////////

/**
 *  This method is called when an action button is pressed (OK/Cancel/etc)
 */
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

/**
 *  Call this method to initiate the loading of the NIB file. This is necessary
 *  in order to use the windows or dialog views.
 */
-(void)load {
	[super loadWindow];
}

-(void)beginCustomSheetWithParameters:(NSDictionary* )parameters view:(PGDialogView* )view parentWindow:(NSWindow* )parentWindow whenDone:(void(^)(NSModalResponse response)) callback {
	NSParameterAssert(view);
	NSParameterAssert(parentWindow);
	NSParameterAssert(callback);

	// check to ensure NIB is loaded
	if([self window]==nil) {
		[self load];
		NSParameterAssert([self window] != nil);
	}

	// set parameters for the view
	[view setViewParameters:parameters];
	
	// set view and add constraints
	[self setView:[view view] parentView:[self ibBackgroundView]];

	// set view delegate
	[view setDelegate:self];

	// set window title and description from view
	if([self windowTitle]==nil) {
		[self setWindowTitle:[view windowTitle]];
		[self setWindowDescription:[view windowDescription]];
	}

	// start sheet
	[parentWindow beginSheet:[self window] completionHandler:^(NSModalResponse returnValue) {
		// cleanup the view
		[view viewDidEnd];
		// set view delegate to nil
		[view setDelegate:nil];
		// set window title and description to nil
		[self setWindowTitle:nil];
		[self setWindowDescription:nil];
		// callback
		callback(returnValue);
	}];
}

-(void)beginNetworkConnectionSheetWithURL:(NSURL* )url comment:(NSString* )comment parentWindow:(NSWindow* )parentWindow whenDone:(void(^)(NSURL* url,NSString* comment)) callback {
	NSParameterAssert(parentWindow);
	NSParameterAssert(url==nil || [url isRemoteHostURL]	);
	PGDialogNetworkConnectionView* view = (PGDialogNetworkConnectionView* )[self ibNetworkConnectionView];
	NSParameterAssert(view);

	// get parameters
	NSDictionary* parameters = [url postgresqlParameters];
	if(parameters==nil) {
		parameters = [[[self class] defaultNetworkURL] postgresqlParameters];
	}
	
	[self beginCustomSheetWithParameters:parameters view:view parentWindow:parentWindow whenDone:^(NSModalResponse response) {
		if(response==NSModalResponseOK) {
			callback([view url],[view comment]);
		} else {
			callback(nil,nil);
		}
	}];
}

-(void)beginFileConnectionSheetWithURL:(NSURL* )url comment:(NSString* )comment parentWindow:(NSWindow* )parentWindow whenDone:(void(^)(NSURL* url,NSString* comment)) callback {
	NSParameterAssert(parentWindow);
	NSParameterAssert(url==nil || [url isRemoteHostURL]	);
	PGDialogFileConnectionView* view = (PGDialogFileConnectionView* )[self ibFileConnectionView];
	NSParameterAssert(view);
	// get parameters
	NSDictionary* parameters = [url postgresqlParameters];
	if(parameters==nil) {
		parameters = [[[self class] defaultFileURL] postgresqlParameters];
	}
	[self beginCustomSheetWithParameters:parameters view:view parentWindow:parentWindow whenDone:^(NSModalResponse response) {
		if(response==NSModalResponseOK) {
			callback([view url],[view comment]);
		} else {
			callback(nil,nil);
		}
	}];
}

-(void)beginConnectionSheetWithURL:(NSURL* )url comment:(NSString* )comment parentWindow:(NSWindow* )parentWindow whenDone:(void(^)(NSURL* url,NSString* comment)) callback {
	NSParameterAssert(parentWindow);
	NSParameterAssert(callback);
	if([url isSocketPathURL]) {
		[self beginFileConnectionSheetWithURL:url comment:comment parentWindow:parentWindow whenDone:callback];
	} else {
		[self beginNetworkConnectionSheetWithURL:url comment:comment parentWindow:parentWindow whenDone:callback];
	}
}

-(void)beginCreateRoleSheetWithParameters:(NSDictionary* )parameters parentWindow:(NSWindow* )parentWindow whenDone:(void(^)(PGQuery* query)) callback {
	NSParameterAssert(parentWindow);
	NSParameterAssert(callback);
	PGDialogCreateRoleView* view = (PGDialogCreateRoleView* )[self ibCreateRoleView];
	NSParameterAssert(view);
	// get parameters
	[self beginCustomSheetWithParameters:parameters view:view parentWindow:parentWindow whenDone:^(NSModalResponse response) {
		if(response==NSModalResponseOK) {
			callback([view query]);
		} else {
			callback(nil);
		}
	}];
}

-(void)beginCreateSchemaSheetWithParameters:(NSDictionary* )parameters parentWindow:(NSWindow* )parentWindow whenDone:(void(^)(PGQuery* query)) callback {
	NSParameterAssert(parentWindow);
	NSParameterAssert(callback);
	PGDialogCreateSchemaView* view = (PGDialogCreateSchemaView* )[self ibCreateSchemaView];
	NSParameterAssert(view);
	// get parameters
	[self beginCustomSheetWithParameters:parameters view:view parentWindow:parentWindow whenDone:^(NSModalResponse response) {
		if(response==NSModalResponseOK) {
			callback([view query]);
		} else {
			callback(nil);
		}
	}];
}

-(void)beginCreateDatabaseSheetWithParameters:(NSDictionary* )parameters parentWindow:(NSWindow* )parentWindow whenDone:(void(^)(PGQuery* query)) callback {
	NSParameterAssert(parentWindow);
	NSParameterAssert(callback);
	PGDialogCreateDatabaseView* view = (PGDialogCreateDatabaseView* )[self ibCreateDatabaseView];
	NSParameterAssert(view);
	// get parameters
	[self beginCustomSheetWithParameters:parameters view:view parentWindow:parentWindow whenDone:^(NSModalResponse response) {
		if(response==NSModalResponseOK) {
			callback([view query]);
		} else {
			callback(nil);
		}
	}];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark PGDialogDelegate implementation
////////////////////////////////////////////////////////////////////////////////

-(void)view:(PGDialogView* )view setFlags:(int)flags description:(NSString* )description {
	NSLog(@"flags=%d description=%@",flags,description);
}



@end
