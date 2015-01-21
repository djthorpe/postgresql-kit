
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

////////////////////////////////////////////////////////////////////////////////

NSInteger PGDatabasesTag = -100;
NSInteger PGQueriesTag = -200;

////////////////////////////////////////////////////////////////////////////////

@interface Application ()
@property (weak) IBOutlet NSWindow* window;
@property (retain) PGSourceViewNode* databases;
@property (retain) PGSourceViewNode* queries;
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
@synthesize databases;
@synthesize queries;

////////////////////////////////////////////////////////////////////////////////
// private methods

-(void)resetSourceView {
	[self setDatabases:[PGSourceViewNode headingWithName:@"DATABASES" tag:PGDatabasesTag]];
	[self setQueries:[PGSourceViewNode headingWithName:@"QUERIES" tag:PGQueriesTag]];
	NSParameterAssert([self databases] && [self queries]);
	[[self sourceView] removeAllNodes];
	[[self sourceView] addNode:[self databases] parent:nil];
	[[self sourceView] addNode:[self queries] parent:nil];
	NSParameterAssert([[self sourceView] count]==2);
	[[self sourceView] saveToUserDefaults];
}

-(BOOL)loadSourceView {
	[[self sourceView] loadFromUserDefaults];
	if([[self sourceView] count]==0) {
		[self resetSourceView];
	} else {
		// TODO: set databases & queries nodes
	}
	if([[self sourceView] count]==2) {
		// the two headings are CONNECTIONS and QUERIES
		return NO;
	}
	return YES;
}

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

	// add menu items
	NSMenuItem* menuItem1 = [[NSMenuItem alloc] initWithTitle:@"New Connection..." action:@selector(doNewConnection:) keyEquivalent:@""];
	[[self splitView] addMenuItem:menuItem1];

	NSMenuItem* menuItem2 = [[NSMenuItem alloc] initWithTitle:@"Connect" action:@selector(doConnect:) keyEquivalent:@""];
	[[self splitView] addMenuItem:menuItem2];

	NSMenuItem* menuItem3 = [[NSMenuItem alloc] initWithTitle:@"Disconnect" action:@selector(doDisconnect:) keyEquivalent:@""];
	[[self splitView] addMenuItem:menuItem3];

	NSMenuItem* menuItem4 = [[NSMenuItem alloc] initWithTitle:@"Reset Source View" action:@selector(doResetSourceView:) keyEquivalent:@""];
	[[self splitView] addMenuItem:menuItem4];

}

-(void)_selectConnectionWithURL:(NSURL* )url {
	NSLog(@"selecting: %@",url);
	PGSourceViewNode* node = [PGSourceViewNode connectionWithURL:url];
	[[self sourceView] addNode:node parent:[self databases]];
	[[self sourceView] expandNode:[self databases]];
	[[self sourceView] selectNode:node];
}

////////////////////////////////////////////////////////////////////////////////
// IBActions

-(IBAction)doNewConnection:(id)sender {
	// connect to remote server
	[[self connection] loginSheetWithWindow:[self window]];
}

-(IBAction)doResetSourceView:(id)sender {
	// disconnect any existing connection
	[[self connection] disconnect];
	
	// connect to remote server
	[self resetSourceView];
}

-(IBAction)doConnect:(id)sender {
	NSLog(@"connect");
}

-(IBAction)doDisconnect:(id)sender {
	NSLog(@"disconnect");
}

////////////////////////////////////////////////////////////////////////////////
// NSApplicationDelegate implementation

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// add PGSplitView to the content view
	[self addSplitView];
	// load connections from user defaults
	if([self loadSourceView]==NO) {
		[self doNewConnection:nil];
	}
}

-(void)applicationWillTerminate:(NSNotification *)aNotification {
	// disconnect from remote server
	[[self connection] disconnect];
	// save user defaults
	[[self sourceView] saveToUserDefaults];
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
			[self _selectConnectionWithURL:url];
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
