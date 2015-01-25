
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
@property (weak) IBOutlet NSWindow* ibDeleteDatabaseSheet;
@property (retain) NSString* ibDeleteDatabaseSheetNodeName;
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
		_tabView = [PGTabViewController new];
		_helpWindow = [PGHelpWindowController new];
		NSParameterAssert(_connection && _splitView && _sourceView && _helpWindow);
		[_connection setDelegate:self];
		[_sourceView setDelegate:self];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize connection = _connection;
@synthesize splitView = _splitView;
@synthesize sourceView = _sourceView;
@synthesize tabView = _tabView;
@synthesize helpWindow = _helpWindow;
@synthesize databases;
@synthesize queries;

////////////////////////////////////////////////////////////////////////////////
// private methods

-(void)resetSourceView {
	[self setDatabases:[PGSourceViewNode headingWithName:@"DATABASES"]];
	[self setQueries:[PGSourceViewNode headingWithName:@"QUERIES"]];
	NSParameterAssert([self databases] && [self queries]);
	
	[[self sourceView] removeAllNodes];
	[[self sourceView] addNode:[self databases] parent:nil tag:PGDatabasesTag];
	[[self sourceView] addNode:[self queries] parent:nil tag:PGQueriesTag];
	NSParameterAssert([[self sourceView] count]==2);
	[[self sourceView] saveToUserDefaults];
}

-(BOOL)loadSourceView {
	[[self sourceView] loadFromUserDefaults];
	PGSourceViewNode* d = [[self sourceView] nodeForTag:PGDatabasesTag];
	PGSourceViewNode* q = [[self sourceView] nodeForTag:PGQueriesTag];
	if(d==nil || q==nil) {
		[self resetSourceView];
	} else {
		[self setDatabases:d];
		[self setQueries:q];
	}
	
	// set the child classes we're willing to accept
	[[self databases] setChildClasses:@[ NSStringFromClass([PGSourceViewConnection class]) ]];
	[[self queries] setChildClasses:@[ ]];

	if([[self sourceView] count]==2) {
		// empty source view...only the headings
		return NO;
	}
	
	// show database view
	[[self sourceView] expandNode:[self databases]];
	
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
	[[self splitView] setRightView:[self tabView]];

	// add menu items to split view
	NSMenuItem* menuItem1 = [[NSMenuItem alloc] initWithTitle:@"New Connection..." action:@selector(doNewConnection:) keyEquivalent:@""];
	[[self splitView] addMenuItem:menuItem1];

	NSMenuItem* menuItem2 = [[NSMenuItem alloc] initWithTitle:@"Connect" action:@selector(doConnect:) keyEquivalent:@""];
	[[self splitView] addMenuItem:menuItem2];

	NSMenuItem* menuItem3 = [[NSMenuItem alloc] initWithTitle:@"Disconnect" action:@selector(doDisconnect:) keyEquivalent:@""];
	[[self splitView] addMenuItem:menuItem3];

	NSMenuItem* menuItem4 = [[NSMenuItem alloc] initWithTitle:@"New Query..." action:@selector(doNewQuery:) keyEquivalent:@""];
	[[self splitView] addMenuItem:menuItem4];


	NSMenuItem* menuItem5 = [[NSMenuItem alloc] initWithTitle:@"Reset Source View" action:@selector(doResetSourceView:) keyEquivalent:@""];
	[[self splitView] addMenuItem:menuItem5];
	
	// set autosave name and minimum width
	[[self splitView] setAutosaveName:@"PGSplitView"];
	[[self splitView] setMinimumSize:75.0];

}

-(void)_selectConnectionWithURL:(NSURL* )url {

	// create a node
	PGSourceViewNode* node = [PGSourceViewNode connectionWithURL:url];
	
	// set the tag
	NSInteger tag = [[self sourceView] addNode:node parent:[self databases]];
	[[self connection] setTag:tag];
	
	NSLog(@"creating: %@ => tag %ld",url,tag);
	
	[[self sourceView] expandNode:[self databases]];
	[[self sourceView] selectNode:node];
}

////////////////////////////////////////////////////////////////////////////////
// IBActions

-(IBAction)doNewConnection:(id)sender {
	// connect to remote server
	[[self connection] loginSheetWithWindow:[self window]];
}

-(IBAction)doNewQuery:(id)sender {
	// add new query...
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

-(IBAction)doHelp:(id)sender {
	// display the help window
	NSError* error = nil;
	if([[self helpWindow] displayHelpFromMarkdownResource:@"help/Introduction" bundle:[NSBundle mainBundle] error:&error]==NO) {
		NSLog(@"error: %@",error);
	}
}

-(IBAction)doAboutPanel:(id)sender {
	// display the help window
	NSError* error = nil;
	if([[self helpWindow] displayHelpFromMarkdownResource:@"NOTICE" bundle:[NSBundle mainBundle] error:&error]==NO) {
		NSLog(@"error: %@",error);
	}
}

-(IBAction)ibButtonClicked:(id)sender {
	NSParameterAssert([sender isKindOfClass:[NSButton class]]);
	NSWindow* theWindow = [(NSButton* )sender window];
	if([[(NSButton* )sender title] isEqualToString:@"Cancel"]) {
		[[self window] endSheet:theWindow returnCode:NSModalResponseCancel];
	} else if([[(NSButton* )sender title] isEqualToString:@"OK"]) {
		[[self window] endSheet:theWindow returnCode:NSModalResponseOK];
	} else {
		// Unknown button clicked
		NSLog(@"Button clicked, ignoring: %@",sender);
	}
}

////////////////////////////////////////////////////////////////////////////////
// methods - PGSourceView delegate

-(void)sourceView:(PGSourceViewController* )sourceView selectedNode:(PGSourceViewNode* )node {
//	NSLog(@"selected node = %@",node);
}

-(void)sourceView:(PGSourceViewController* )sourceView doubleClickedNode:(PGSourceViewNode* )node {
	// if node is a connection node, then connect
	if([node isKindOfClass:[PGSourceViewConnection class]]) {
		NSLog(@"double clicked node = %@",node);
	}
}

-(void)sourceView:(PGSourceViewController* )sourceView deleteNode:(PGSourceViewNode* )node {
	// display confirmation sheet
	[self setIbDeleteDatabaseSheetNodeName:[node name]];
	[[self window] beginSheet:[self ibDeleteDatabaseSheet] completionHandler:^(NSModalResponse returnCode) {
		if(returnCode==NSModalResponseOK) {
			[sourceView removeNode:node];
		}
	}];
}

////////////////////////////////////////////////////////////////////////////////
// NSApplicationDelegate implementation

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {

	// add PGSplitView to the content view
	[self addSplitView];

	// load help from resource folder
	NSError* error = nil;
	[[self helpWindow] addPath:@"help" bundle:[NSBundle mainBundle] error:&error];
	[[self helpWindow] addResource:@"NOTICE" bundle:[NSBundle mainBundle] error:&error];
	
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
			NSLog(@"PGClient cancelled %ld %@",[connection tag],url);
			break;
		case ConnectionStatusConnecting:
			NSLog(@"PGClient connecting %ld %@",[connection tag],url);
			[self _selectConnectionWithURL:url];
			break;
		case ConnectionStatusConnected:
			NSLog(@"PGClient connected %ld %@",[connection tag],url);
			break;
		case ConnectionStatusDisconnected:
			NSLog(@"PGClient disconnected %ld %@",[connection tag],url);
			break;
	}
}

-(void)connection:(Connection* )connection error:(NSError* )error {
	NSLog(@"PGClient error %@",[error localizedDescription]);
}

@end
