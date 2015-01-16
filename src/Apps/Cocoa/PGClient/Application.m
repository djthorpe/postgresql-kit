
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

#import "Application.h"

@interface Application ()
@property (weak) IBOutlet NSWindow* window;
@end

@implementation Application

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	self = [super init];
	if(self) {
		_connection = [Connection new];
		_splitView = [PGSplitViewController new];
		_sourceView = [PGSourceViewController new];
		NSParameterAssert(_connection && _splitView && _sourceView);
		[_connection setDelegate:self];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize connection = _connection;
@synthesize splitView = _splitView;
@synthesize sourceView = _sourceView;

////////////////////////////////////////////////////////////////////////////////
// private methods

-(void)addSplitView {
	NSView* contentView = [[self window] contentView];

	// add splitview to the content view
	NSView* splitView = [[self splitView] view];
	[contentView addSubview:splitView];
	[splitView setTranslatesAutoresizingMaskIntoConstraints:NO];

	// make it resize with the window
	NSDictionary *views = NSDictionaryOfVariableBindings(splitView);
	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[splitView]|" options:0 metrics:nil views:views]];
	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[splitView]|" options:0 metrics:nil views:views]];
	
	// add left and right views
	[[self splitView] setLeftView:[self sourceView]];
	
	// add headings
	[[self sourceView] addHeadingWithTitle:@"CONNECTIONS"];
	[[self sourceView] addHeadingWithTitle:@"QUERIES"];
	
	// add menu items
	NSMenuItem* menuItem = [[NSMenuItem alloc] initWithTitle:@"New Connection..." action:@selector(doNewConnection:) keyEquivalent:@""];
	[[self splitView] addMenuItem:menuItem];
}

////////////////////////////////////////////////////////////////////////////////
// IBActions

-(void)doNewConnection:(id)sender {
	// connect to remote server
	[[self connection] loginSheetWithWindow:[self window]];
}

////////////////////////////////////////////////////////////////////////////////
// NSApplicationDelegate implementation

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// add PGSplitView to the content view
	[self addSplitView];

}

-(void)applicationWillTerminate:(NSNotification *)aNotification {
	// disconnect from remote server
	[[self connection] disconnect];
}

////////////////////////////////////////////////////////////////////////////////
// ConnectionDelegate implementation

-(void)connection:(Connection* )connection status:(int)status url:(NSURL* )url {
	switch(status) {
		case ConnectionStatusCancelled:
			NSLog(@"PGClient cancelled %@",url);
			break;
		case ConnectionStatusConnecting:
			NSLog(@"PGClient connecting %@",url);
			break;
		case ConnectionStatusConnected:
			NSLog(@"PGClient connected %@",url);
			break;
		case ConnectionStatusDisconnected:
			NSLog(@"PGClient disconnected %@",url);
			break;
	}
}

-(void)connection:(Connection* )connection error:(NSError* )error {
	NSLog(@"PGClient error %@",[error localizedDescription]);
}

@end
