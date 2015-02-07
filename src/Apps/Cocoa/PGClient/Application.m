
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
		_connections = [PGConnectionPool new];
		_splitView = [PGSplitViewController new];
		_sourceView = [PGSourceViewController new];
		_tabView = [PGTabViewController new];
		_helpWindow = [PGHelpWindowController new];
		_connectionWindow = [PGConnectionWindowController new];
		NSParameterAssert(_connections);
		NSParameterAssert(_splitView && _sourceView);
		NSParameterAssert(_helpWindow && _connectionWindow);
		[_connections setDelegate:self];
		[_sourceView setDelegate:self];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize connections = _connections;
@synthesize splitView = _splitView;
@synthesize sourceView = _sourceView;
@synthesize tabView = _tabView;
@synthesize helpWindow = _helpWindow;
@synthesize connectionWindow = _connectionWindow;
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
	NSMenuItem* menuItem1 = [[NSMenuItem alloc] initWithTitle:@"New Network Connection..." action:@selector(doNewNetworkConnection:) keyEquivalent:@""];
	[[self splitView] addMenuItem:menuItem1];

	NSMenuItem* menuItem2 = [[NSMenuItem alloc] initWithTitle:@"New Socket Connection..." action:@selector(doNewSocketConnection:) keyEquivalent:@""];
	[[self splitView] addMenuItem:menuItem2];


	NSMenuItem* menuItem3 = [[NSMenuItem alloc] initWithTitle:@"Connect" action:@selector(doConnect:) keyEquivalent:@""];
	[[self splitView] addMenuItem:menuItem3];

	NSMenuItem* menuItem4 = [[NSMenuItem alloc] initWithTitle:@"Disconnect" action:@selector(doDisconnect:) keyEquivalent:@""];
	[[self splitView] addMenuItem:menuItem4];
/*
	NSMenuItem* menuItem4 = [[NSMenuItem alloc] initWithTitle:@"New Query..." action:@selector(doNewQuery:) keyEquivalent:@""];
	[[self splitView] addMenuItem:menuItem4];
*/

	NSMenuItem* menuItem5 = [[NSMenuItem alloc] initWithTitle:@"Reset Source View" action:@selector(doResetSourceView:) keyEquivalent:@""];
	[[self splitView] addMenuItem:menuItem5];
	
	// set autosave name and set minimum split view width
	[[self splitView] setAutosaveName:@"PGSplitView"];
	[[self splitView] setMinimumSize:75.0];

}

-(void)_newConnectionWithURL:(NSURL* )url {
	// create a node
	PGSourceViewNode* node = [PGSourceViewNode connectionWithURL:url];
	// add node
	[[self sourceView] addNode:node parent:[self databases]];
	// connect
	NSParameterAssert([node isKindOfClass:[PGSourceViewConnection class]]);
	[self _connectNode:(PGSourceViewConnection* )node];
}

-(void)_connectNode:(PGSourceViewConnection* )node {
	// get tag node from source view
	NSInteger tag = [[self sourceView] tagForNode:node];
	NSParameterAssert(tag);

	// set connection in the pool
	if([[self connections] URLForTag:tag]) {
		[[self connections] disconnectWithTag:tag];
		[[self connections] setURL:[node URL] forTag:tag];
	} else {
		[[self connections] createConnectionWithURL:[node URL] tag:tag];
	}

	// display the node which is going to be connected
	[[self sourceView] expandNode:[self databases]];
	[[self sourceView] selectNode:node];

	// perform connection
	[[self connections] connectWithTag:tag whenDone:^(NSError* error) {
		if([error domain]==PGClientErrorDomain && [error code]==PGClientErrorNeedsPassword) {
			[self _connectWithPasswordNode:node];
		} else if(error) {
			[self _displayError:error node:node];
		}
	}];
}

-(void)_disconnectNode:(PGSourceViewConnection* )node {
	NSLog(@"TODO: disconnect node %@",node);
}

-(void)_connectWithPasswordNode:(PGSourceViewConnection* )node {
	[[self connectionWindow] beginPasswordSheetWithParentWindow:[self window] whenDone:^(NSString* password,BOOL useKeychain) {
		if(password) {
			// TODO: store password with connection pool
			[self _connectNode:node];
		}
	}];
}

-(void)_displayError:(NSError* )error node:(PGSourceViewConnection* )node {
	NSParameterAssert(error);
	NSParameterAssert(node);
	NSLog(@"display the error sheet with %@",error);
	[[self connectionWindow] beginErrorSheetWithError:error parentWindow:[self window] whenDone:^(NSModalResponse returnValue) {
		NSLog(@"error sheet ended, returnValue = %ld",returnValue);
		if(returnValue==NSModalResponseContinue) {
			// try again
			[self _connectNode:node];
		}
	}];
}

-(void)_reloadNode:(PGSourceViewNode* )node {
	[[self sourceView] reloadNode:node];
}

////////////////////////////////////////////////////////////////////////////////
// IBActions

-(IBAction)doNewNetworkConnection:(id)sender {
	// connect to remote server
	NSURL* defaultURL = [PGConnectionWindowController defaultNetworkURL];
	[[self connectionWindow] beginConnectionSheetWithURL:defaultURL parentWindow:[self window] whenDone:^(NSURL* url) {
		if(url) {
			[self _newConnectionWithURL:url];
		}
	}];
}

-(IBAction)doNewSocketConnection:(id)sender {
	// connect to remote server
	NSURL* defaultURL = [PGConnectionWindowController defaultSocketURL];
	[[self connectionWindow] beginConnectionSheetWithURL:defaultURL parentWindow:[self window] whenDone:^(NSURL* url) {
		if(url) {
			[self _newConnectionWithURL:url];
		}
	}];
}

-(IBAction)doNewQuery:(id)sender {
	// add new query...
}

-(IBAction)doResetSourceView:(id)sender {
	// disconnect any existing connections
	[[self connections] removeAll];
	
	// connect to remote server
	[self resetSourceView];
}

-(IBAction)doConnect:(id)sender {
	PGSourceViewNode* connection = [[self sourceView] selectedNode];
	if([connection isKindOfClass:[PGSourceViewConnection class]]) {
		[self _connectNode:(PGSourceViewConnection* )connection];
	}
}

-(IBAction)doDisconnect:(id)sender {
	PGSourceViewNode* connection = [[self sourceView] selectedNode];
	if([connection isKindOfClass:[PGSourceViewConnection class]]) {
		[self _disconnectNode:(PGSourceViewConnection* )connection];
	}
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
		[[self connectionWindow] beginConnectionSheetWithURL:[(PGSourceViewConnection* )node URL] parentWindow:[self window] whenDone:^(NSURL* url) {
			// update the connection details
			if(url) {
				NSInteger tag = [[self sourceView] tagForNode:node];
				NSLog(@"TODO: update URL to %@ for tag %ld",url,tag);
			}
		}];
	} else {
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
		[self doNewNetworkConnection:nil];
	}
}

-(void)applicationWillTerminate:(NSNotification *)aNotification {
	// disconnect from remote servers
	[[self connections] removeAll];
	// save user defaults
	[[self sourceView] saveToUserDefaults];
}

////////////////////////////////////////////////////////////////////////////////
// ConnectionPoolDelegate implementation

-(void)connectionPool:(PGConnectionPool *)pool tag:(NSInteger)tag statusChanged:(PGConnectionStatus)status {
	PGSourceViewNode* node = [[self sourceView] nodeForTag:tag];
	NSParameterAssert([node isKindOfClass:[PGSourceViewConnection class]]);
	
	switch(status) {
		case PGConnectionStatusConnected:
			NSLog(@"PGConnectionPool tag = %ld, status = connected",tag);
			[(PGSourceViewConnection* )node setIconStatus:PGSourceViewConnectionIconConnected];
			[self performSelectorOnMainThread:@selector(_reloadNode:) withObject:node waitUntilDone:YES];
			break;
		case PGConnectionStatusConnecting:
			NSLog(@"PGConnectionPool tag = %ld, status = connecting",tag);
			[(PGSourceViewConnection* )node setIconStatus:PGSourceViewConnectionIconConnecting];
			[self performSelectorOnMainThread:@selector(_reloadNode:) withObject:node waitUntilDone:YES];
			break;
		case PGConnectionStatusDisconnected:
			NSLog(@"PGConnectionPool tag = %ld, status = disconnected",tag);
			[(PGSourceViewConnection* )node setIconStatus:PGSourceViewConnectionIconDisconnected];
			[self performSelectorOnMainThread:@selector(_reloadNode:) withObject:node waitUntilDone:YES];
			break;
		case PGConnectionStatusRejected:
			NSLog(@"PGConnectionPool tag = %ld, status = rejected",tag);
			[(PGSourceViewConnection* )node setIconStatus:PGSourceViewConnectionIconRejected];
			[self performSelectorOnMainThread:@selector(_reloadNode:) withObject:node waitUntilDone:YES];
			break;
		default:
			NSLog(@"PGConnectionPool tag = %ld, status = other",tag);
			[(PGSourceViewConnection* )node setIconStatus:PGSourceViewConnectionIconDisconnected];
			[self performSelectorOnMainThread:@selector(_reloadNode:) withObject:node waitUntilDone:YES];
			break;
	}
}

-(void)connectionPool:(PGConnectionPool *)pool tag:(NSInteger)tag error:(NSError *)error {
	NSLog(@"PGClient error tag %ld %@",tag,[error localizedDescription]);
}

@end
