
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
#import "LogController.h"

////////////////////////////////////////////////////////////////////////////////

NSInteger PGDatabasesTag = -100;
NSInteger PGQueriesTag = -200;

////////////////////////////////////////////////////////////////////////////////

@interface Application ()
@property (weak) IBOutlet NSWindow* window;
@property (weak) IBOutlet LogController* log;
@property (retain) PGSourceViewNode* databases;
@property (retain) PGSourceViewNode* queries;
@property (retain) PGResultTableView* tableView;
@end

@implementation Application

////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructor
////////////////////////////////////////////////////////////////////////////////

-(id)init {
	self = [super init];
	if(self) {
		// set up dialog window
		_dialogWindow = [PGDialogWindow new];
		NSParameterAssert(_dialogWindow);
	
		// set up tab view
		_splitView = [PGSplitViewController new];
		NSParameterAssert(_splitView);

		// set up source view
		_sourceView = [PGSourceViewController new];
		NSParameterAssert(_sourceView);
		[_sourceView setDelegate:self];
		
		// set up state
		_state = [NSMutableDictionary new];
		NSParameterAssert(_state);
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Properties
////////////////////////////////////////////////////////////////////////////////

@synthesize splitView = _splitView;
@synthesize sourceView = _sourceView;
@synthesize state = _state;
@synthesize databases;
@synthesize queries;
@dynamic pool;
@synthesize tableView;

-(PGConnectionPool* )pool {
	return [PGConnectionPool sharedPool];
}


/*
@property (weak) IBOutlet NSWindow* ibDeleteDatabaseSheet;
@property (weak) IBOutlet NSMenu* ibConnectionContextMenu;
@property (retain) NSString* ibDeleteDatabaseSheetNodeName;
*/

/*
		_tabView = [PGTabViewController new];
		_helpWindow = [PGHelpWindowController new];
		_buffers = [ConsoleBuffer new];
		NSParameterAssert(_buffers);
		NSParameterAssert(_helpWindow);
		[_tabView setDelegate:self];
*/
/*
@synthesize tabView = _tabView;
@synthesize helpWindow = _helpWindow;
*/

////////////////////////////////////////////////////////////////////////////////
#pragma mark Private methods
////////////////////////////////////////////////////////////////////////////////

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
	NSDictionary* views = NSDictionaryOfVariableBindings(splitView);
	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[splitView]|" options:0 metrics:nil views:views]];
	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[splitView]|" options:0 metrics:nil views:views]];

	// add left and right views
	[[self splitView] setLeftView:[self sourceView]];

/*
	[[self splitView] setRightView:[self tabView]];

	// add menu items to split view
	NSMenuItem* menuItem1 = [[NSMenuItem alloc] initWithTitle:@"New Network Connection..." action:@selector(doNewNetworkConnection:) keyEquivalent:@""];
	[[self splitView] addMenuItem:menuItem1];

	NSMenuItem* menuItem2 = [[NSMenuItem alloc] initWithTitle:@"New Socket Connection..." action:@selector(doNewSocketConnection:) keyEquivalent:@""];
	[[self splitView] addMenuItem:menuItem2];

	NSMenuItem* menuItem5 = [[NSMenuItem alloc] initWithTitle:@"Reset Source View" action:@selector(doResetSourceView:) keyEquivalent:@""];
	[[self splitView] addMenuItem:menuItem5];
*/

	// set autosave name and set minimum split view width
	[[self splitView] setAutosaveName:@"PGSplitView"];
	[[self splitView] setMinimumSize:75.0];

}

-(void)createRoleForNode:(PGSourceViewConnection* )node {
	NSParameterAssert(node);
	PGDialogWindow* dialog = [self dialogWindow];
	NSParameterAssert(dialog);

	// get tag node from source view
	NSInteger tag = [[self sourceView] tagForNode:node];
	NSParameterAssert(tag);

	// get connection
	PGConnection* connection = [[self pool] connectionForTag:tag];
	NSParameterAssert(connection);

	[dialog beginRoleSheetWithParameters:nil connection:connection parentWindow:[self window] whenDone:^(PGTransaction* transaction) {
		if(transaction==nil) {
			return;
		}
		[[self pool] execute:transaction forTag:tag whenDone:^(PGResult* result,NSError *error) {
			if(error==nil) {
				[self listRolesForNode:node];
			} else {
				[self beginSheetForError:error];
			}
		}];
	}];
}

-(void)createSchemaForNode:(PGSourceViewConnection* )node {
	NSParameterAssert(node);
	PGDialogWindow* dialog = [self dialogWindow];
	NSParameterAssert(dialog);

	// get tag node from source view
	NSInteger tag = [[self sourceView] tagForNode:node];
	NSParameterAssert(tag);

	// get connection
	PGConnection* connection = [[self pool] connectionForTag:tag];
	NSParameterAssert(connection);

	[dialog beginSchemaSheetWithParameters:nil connection:connection parentWindow:[self window] whenDone:^(PGTransaction* transaction) {
		if(transaction==nil) {
			return;
		}
		[[self pool] execute:transaction forTag:tag whenDone:^(PGResult* result,NSError *error) {
			if(error==nil) {
				[self listSchemasForNode:node];
			} else {
				[self beginSheetForError:error];
			}
		}];
	}];
}

-(void)createDatabaseForNode:(PGSourceViewConnection* )node {
	NSParameterAssert(node);
	PGDialogWindow* dialog = [self dialogWindow];
	NSParameterAssert(dialog);

	// get tag node from source view
	NSInteger tag = [[self sourceView] tagForNode:node];
	NSParameterAssert(tag);

	// get connection
	PGConnection* connection = [[self pool] connectionForTag:tag];
	NSParameterAssert(connection);

	[dialog beginDatabaseSheetWithParameters:nil connection:connection parentWindow:[self window] whenDone:^(PGTransaction* transaction) {
		if(transaction==nil) {
			return;
		}
		[[self pool] execute:transaction forTag:tag whenDone:^(PGResult* result,NSError *error) {
			if(error==nil) {
				[self listDatabasesForNode:node];
			} else {
				[self beginSheetForError:error];
			}
		}];
	}];
}

-(void)listRolesForNode:(PGSourceViewConnection* )node {
	NSParameterAssert(node);

	// get tag node from source view
	NSInteger tag = [[self sourceView] tagForNode:node];
	NSParameterAssert(tag);

	// create transaction, and execute it
	PGTransaction* transaction = [PGTransaction transactionWithQuery:[PGQueryRole listWithOptions:PGQueryOptionListExtended]];
	[transaction setTransactional:NO];
	[[self pool] execute:transaction forTag:tag whenDone:^(PGResult* result,NSError *error) {
		if(result) {
			[[[self tableView] view] removeFromSuperview];
			[self setTableView:[[PGResultTableView alloc] initWithDataSource:result]];
			[[self splitView] setRightView:[[self tableView] view]];
		}
		if(error) {
			[self beginSheetForError:error];
		}
	}];
}

-(void)listDatabasesForNode:(PGSourceViewConnection* )node {
	NSParameterAssert(node);

	// get tag node from source view
	NSInteger tag = [[self sourceView] tagForNode:node];
	NSParameterAssert(tag);

	// create transaction, and execute it
	PGTransaction* transaction = [PGTransaction transactionWithQuery:[PGQueryDatabase listWithOptions:PGQueryOptionListExtended]];
	[transaction setTransactional:NO];
	[[self pool] execute:transaction forTag:tag whenDone:^(PGResult* result,NSError *error) {
		if(result) {
			[[[self tableView] view] removeFromSuperview];
			[self setTableView:[[PGResultTableView alloc] initWithDataSource:result]];
			[[self splitView] setRightView:[[self tableView] view]];
		}
		if(error) {
			[self beginSheetForError:error];
		}
	}];
}

-(void)listSchemasForNode:(PGSourceViewConnection* )node {
	NSParameterAssert(node);

	// get tag node from source view
	NSInteger tag = [[self sourceView] tagForNode:node];
	NSParameterAssert(tag);

	// create transaction, and execute it
	PGTransaction* transaction = [PGTransaction transactionWithQuery:[PGQuerySchema listWithOptions:PGQueryOptionListExtended]];
	[transaction setTransactional:NO];
	[[self pool] execute:transaction forTag:tag whenDone:^(PGResult* result,NSError *error) {
		if(result) {
			[[[self tableView] view] removeFromSuperview];
			[self setTableView:[[PGResultTableView alloc] initWithDataSource:result]];
			[[self splitView] setRightView:[[self tableView] view]];
		}
		if(error) {
			[self beginSheetForError:error];
		}
	}];
}

-(void)createConnectionWithURL:(NSURL* )url comment:(NSString* )comment {
	// create a node
	PGSourceViewNode* node = [PGSourceViewNode connectionWithURL:url];
	// add node
	[[self sourceView] addNode:node parent:[self databases]];
	// connect
	NSParameterAssert([node isKindOfClass:[PGSourceViewConnection class]]);
	[self connectNode:(PGSourceViewConnection* )node];
}

-(void)connectWithPasswordForNode:(PGSourceViewConnection* )node {
	NSParameterAssert(node);
	PGDialogWindow* dialog = [self dialogWindow];
	NSParameterAssert(dialog);

	// get tag node from source view
	NSInteger tag = [[self sourceView] tagForNode:node];
	NSParameterAssert(tag);

	[dialog beginPasswordSheetSaveInKeychain:YES parentWindow:[self window] whenDone:^(NSString* password,BOOL saveInKeychain) {
		if(password) {
			[[self pool] setPassword:password forTag:tag saveInKeychain:saveInKeychain];
			[self connectNode:node];
		}
	}];
}

-(void)connectNode:(PGSourceViewConnection* )node {
	NSParameterAssert(node && [node isKindOfClass:[PGSourceViewConnection class]]);

	// get tag node from source view
	NSInteger tag = [[self sourceView] tagForNode:node];
	NSParameterAssert(tag);

	// set connection in the pool
	if([[self pool] URLForTag:tag]) {
		[[self pool] removeForTag:tag];
	}
	if([[self pool] createConnectionWithURL:[node URL] tag:tag]) {
		// display the node which is going to be connected
		[[self sourceView] expandNode:[self databases]];
		[[self sourceView] selectNode:node];
	}

	// perform connection
	[[self pool] connectForTag:tag whenDone:^(NSError* error) {
		if([error isNeedsPassword]) {
			[self connectWithPasswordForNode:node];
		} else if([error isBadPassword]) {
			[self beginConnectionErrorSheetForNode:node error:error];
		} else if(error) {
			[self beginConnectionErrorSheetForNode:node error:error];
		}
	}];
}

-(void)disconnectNode:(PGSourceViewConnection* )node {
	// get tag node from source view
	NSInteger tag = [[self sourceView] tagForNode:node];
	NSParameterAssert(tag);
	// perform disconnection
	[[self pool] disconnectForTag:tag];
}


-(void)beginSheetForError:(NSError* )error {
	NSParameterAssert(error);

	// create alert sheet
	NSAlert* alertSheet = [NSAlert alertWithError:error];
	
	// do the error sheet
	[alertSheet beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse returnCode) {
		return;
	}];
}

-(void)beginConnectionErrorSheetForNode:(PGSourceViewConnection* )node error:(NSError* )error {
	NSParameterAssert(node);
	NSParameterAssert(error);

	// create alert sheet
	NSAlert* alertSheet = [NSAlert alertWithError:error];

	// add a "try again" dialog
	if([error isBadPassword]) {
		NSButton* tryAgainButton = [alertSheet addButtonWithTitle:@"Try again"];
		[tryAgainButton setTag:NSModalResponseContinue];
	}

	// add Cancel button
	[alertSheet addButtonWithTitle:@"Cancel"];
	
	// do the error sheet
	[alertSheet beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse returnCode) {
		if(returnCode==NSModalResponseContinue) {
			[self connectWithPasswordForNode:node];
		}
	}];
}

-(void)reloadNode:(PGSourceViewNode* )node {
	[[self sourceView] reloadNode:node];
}

-(void)setState:(BOOL)value forKey:(NSString* )key {
	[[self state] setValue:(value ? @YES : @NO) forKey:key];
}

-(void)updateStateForNode:(PGSourceViewNode* )node {

	// get tag node from source view
	NSInteger tag = [[self sourceView] tagForNode:node];
	NSParameterAssert(tag);

	if([node isKindOfClass:[PGSourceViewConnection class]]) {
		[self setState:YES forKey:@"can_edit_connection"];
		
		// get status of the connection
		PGConnectionStatus status = [[self pool] statusForTag:tag];
		[self setState:(status==PGConnectionStatusDisconnected || status==PGConnectionStatusRejected) forKey:@"can_connect"];
		[self setState:(status==PGConnectionStatusConnected) forKey:@"can_disconnect"];
		[self setState:(status==PGConnectionStatusConnected) forKey:@"can_query"];
		
	} else {
		[self setState:NO forKey:@"can_edit_connection"];
		[self setState:NO forKey:@"can_connect"];
		[self setState:NO forKey:@"can_disconnect"];
		[self setState:NO forKey:@"can_query"];
	}
}

-(void)deleteConnectionNode:(PGSourceViewConnection* )node {
	NSParameterAssert(node);

	// get tag node from source view
	NSInteger tag = [[self sourceView] tagForNode:node];
	NSParameterAssert(tag);

	// create alert sheet
	NSAlert* alertSheet = [NSAlert alertWithMessageText:@"Do you want to delete the connection?" defaultButton:@"Delete" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"This operation cannot be undone"];
	
	// do the sheet
	[alertSheet beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse returnCode) {
		if(returnCode==NSModalResponseOK) {
			[[self sourceView] removeNode:node];
			[[self pool] removeForTag:tag];
		}
	}];
}

/*
-(void)_showDatabasesForNode:(PGSourceViewConnection* )node {
	// execute query
	PGResult* result = [[self connections] execute:@"SELECT 1" forTag:tag];
	if(result) {
		NSLog(@"%@",[result tableWithWidth:80]);
		[self _appendConsoleString:[result tableWithWidth:80] forTag:tag];
	}
}


-(void)_appendConsoleString:(NSString* )string forTag:(NSInteger)tag {
	PGConsoleViewController* controller = (PGConsoleViewController* )[_tabView selectViewWithTag:tag];
	NSParameterAssert([controller isKindOfClass:[PGConsoleViewController class]]);

	PGConsoleViewBuffer* buffer = [controller dataSource];
	NSParameterAssert(buffer);
	
	[buffer appendString:string];
	[controller reloadData];
	[controller scrollToBottom];
}
*/

////////////////////////////////////////////////////////////////////////////////
#pragma mark IBActions
////////////////////////////////////////////////////////////////////////////////

-(IBAction)doNewRemoteConnection:(id)sender {
	PGDialogWindow* dialog = [self dialogWindow];
	NSParameterAssert(dialog);
	[dialog beginConnectionSheetWithURL:[PGDialogWindow defaultNetworkURL] comment:nil parentWindow:[self window] whenDone:^(NSURL* url, NSString* comment) {
		if(url) {
			[self createConnectionWithURL:url comment:comment];
		}
	}];
}

-(IBAction)doNewLocalConnection:(id)sender {
	PGDialogWindow* dialog = [self dialogWindow];
	NSParameterAssert(dialog);
	[dialog beginConnectionSheetWithURL:[PGDialogWindow defaultFileURL] comment:nil parentWindow:[self window] whenDone:^(NSURL* url, NSString* comment) {
		if(url) {
			[self createConnectionWithURL:url comment:comment];
		}
	}];
}

-(IBAction)doEditConnection:(id)sender {
	PGDialogWindow* dialog = [self dialogWindow];
	NSParameterAssert(dialog);
	PGSourceViewConnection* node = (PGSourceViewConnection* )[[self sourceView] selectedNode];
	if(node==nil) {
		return;
	}
	NSParameterAssert(node && [node isKindOfClass:[PGSourceViewConnection class]]);
	[dialog beginConnectionSheetWithURL:[node URL] comment:[node name] parentWindow:[self window] whenDone:^(NSURL* url, NSString* comment) {
		if(url==nil) {
			return;
		}
		NSInteger tag = [[self sourceView] tagForNode:node];
		NSParameterAssert(tag);

		// remove connection from pool
		[[self pool] removeForTag:tag];

		// change node information, and reload
		[node setURL:url];
		if([comment length]) {
			[node setName:comment];
		} else {
			[node setNameFromURL];
		}
		[self reloadNode:node];
		
	}];
}

-(IBAction)doConnect:(id)sender {
	PGSourceViewNode* connection = [[self sourceView] selectedNode];
	if([connection isKindOfClass:[PGSourceViewConnection class]]) {
		[self connectNode:(PGSourceViewConnection* )connection];
	}
}

-(IBAction)doDisconnect:(id)sender {
	PGSourceViewNode* connection = [[self sourceView] selectedNode];
	if([connection isKindOfClass:[PGSourceViewConnection class]]) {
		[self disconnectNode:(PGSourceViewConnection* )connection];
	}
}

-(IBAction)doCreateDatabase:(id)sender {
	PGSourceViewNode* connection = [[self sourceView] selectedNode];
	if([connection isKindOfClass:[PGSourceViewConnection class]]) {
		[self createDatabaseForNode:(PGSourceViewConnection* )connection];
	}
}

-(IBAction)doCreateSchema:(id)sender {
	PGSourceViewNode* connection = [[self sourceView] selectedNode];
	if([connection isKindOfClass:[PGSourceViewConnection class]]) {
		[self createSchemaForNode:(PGSourceViewConnection* )connection];
	}
}

-(IBAction)doCreateRole:(id)sender {
	PGSourceViewNode* connection = [[self sourceView] selectedNode];
	if([connection isKindOfClass:[PGSourceViewConnection class]]) {
		[self createRoleForNode:(PGSourceViewConnection* )connection];
	}
}

-(IBAction)doListRoles:(id)sender {
	PGSourceViewNode* connection = [[self sourceView] selectedNode];
	if([connection isKindOfClass:[PGSourceViewConnection class]]) {
		[self listRolesForNode:(PGSourceViewConnection* )connection];
	}
}

-(IBAction)doListDatabases:(id)sender {
	PGSourceViewNode* connection = [[self sourceView] selectedNode];
	if([connection isKindOfClass:[PGSourceViewConnection class]]) {
		[self listDatabasesForNode:(PGSourceViewConnection* )connection];
	}
}

-(IBAction)doListSchemas:(id)sender {
	PGSourceViewNode* connection = [[self sourceView] selectedNode];
	if([connection isKindOfClass:[PGSourceViewConnection class]]) {
		[self listSchemasForNode:(PGSourceViewConnection* )connection];
	}
}

-(IBAction)doShowLogWindow:(id)sender {
	[[self log] showHideWindow:sender];
}

/*
-(IBAction)doResetSourceView:(id)sender {
	// disconnect any existing connections
	[[self connections] removeAll];
	
	// connect to remote server
	[self resetSourceView];
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

-(IBAction)doShowDatabases:(id)sender {
	PGSourceViewNode* connection = [[self sourceView] selectedNode];
	if([connection isKindOfClass:[PGSourceViewConnection class]]) {
		[self _showDatabasesForNode:(PGSourceViewConnection* )connection];
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
*/

////////////////////////////////////////////////////////////////////////////////
#pragma mark PGSourceViewDelegate
////////////////////////////////////////////////////////////////////////////////

-(void)sourceView:(PGSourceViewController* )sourceView selectedNode:(PGSourceViewNode* )node {
	NSParameterAssert(sourceView==[self sourceView]);
	NSParameterAssert(node);

	// get tag node from source view
	NSInteger tag = [[self sourceView] tagForNode:node];
	NSParameterAssert(tag);

	// update state
	[self updateStateForNode:node];

	// select view
	//[[self tabView] selectViewWithTag:tag];
}

-(void)sourceView:(PGSourceViewController* )sourceView doubleClickedNode:(PGSourceViewNode* )node {
	NSParameterAssert(sourceView==[self sourceView]);
	NSParameterAssert(node);

	// get tag node from source view
	NSInteger tag = [[self sourceView] tagForNode:node];
	NSParameterAssert(tag);

	if([node isKindOfClass:[PGSourceViewConnection class]]) {
		PGConnectionStatus status = [[self pool] statusForTag:tag];
		if(status != PGConnectionStatusConnected) {
			[self connectNode:(PGSourceViewConnection* )node];
		}
	} else {
		NSLog(@"double clicked node = %@",node);
	}
}

-(void)sourceView:(PGSourceViewController* )sourceView deleteNode:(PGSourceViewNode* )node {
	NSParameterAssert(sourceView==[self sourceView]);
	NSParameterAssert(node);

	if([node isKindOfClass:[PGSourceViewConnection class]]) {
		[self deleteConnectionNode:(PGSourceViewConnection *)node];
	} else {
		NSLog(@"TODO: delete other kind of node");
	}
}

/*
-(NSMenu* )sourceView:(PGSourceViewController* )sourceView menuForNode:(PGSourceViewNode* )node {
	if([node isKindOfClass:[PGSourceViewNode class]]) {
		[[self sourceView] selectNode:node];
		return [self ibConnectionContextMenu];
	}
	return nil;
}
*/

////////////////////////////////////////////////////////////////////////////////
#pragma mark PGTabViewDelegate implementation
////////////////////////////////////////////////////////////////////////////////

/*
-(NSViewController* )tabView:(PGTabViewController* )tabView newViewForTag:(NSInteger)tag {
	PGSourceViewNode* node = [[self sourceView] nodeForTag:tag];
	NSParameterAssert(node);
	
	// create a new console buffer
	PGConsoleViewBuffer* buffer = [PGConsoleViewBuffer new];
	NSParameterAssert(buffer);

	// create a console view
	PGConsoleViewController* controller = [PGConsoleViewController new];
	NSParameterAssert(controller);

	// tie up
	[controller setTitle:[node name]];
	[controller setDataSource:buffer];
	[controller setDelegate:self];
	[controller setEditable:YES];
	[controller setTag:tag];
	[_buffers setBuffer:buffer forTag:tag];
	[_buffers appendString:[node name] forTag:tag];
	
	// return controller
	return controller;
}

////////////////////////////////////////////////////////////////////////////////
// PGConsoleViewDelegate implementation

-(void)consoleView:(PGConsoleViewController* )consoleView append:(NSString* )string {
	NSInteger tag = [consoleView tag];
	NSParameterAssert(tag);
	
	// append line
	[self _appendConsoleString:string forTag:tag];
	// execute query
	PGResult* result = [[self connections] execute:string forTag:tag];
	if(result) {
		NSString* table = [result tableWithWidth:[consoleView textWidth]];
		if(table) {
			[self _appendConsoleString:table forTag:tag];
		}
		if([result affectedRows]) {
			[self _appendConsoleString:[NSString stringWithFormat:@"%ld affected row(s)",[result affectedRows]] forTag:tag];
		}
	}
}
*/

////////////////////////////////////////////////////////////////////////////////
#pragma mark NSApplicationDelegate implementation
////////////////////////////////////////////////////////////////////////////////

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {

	// get connection pool
	PGConnectionPool* pool = [self pool];
	[pool setDelegate:self];
	
	// load dialog window nib
	[[self dialogWindow] load];

	// add PGSplitView to the content view
	[self addSplitView];

	// load connections from user defaults, or "new" dialog
	if([self loadSourceView]==NO) {
		[self doNewRemoteConnection:nil];
	}
	
/*
	// load help from resource folder
	NSError* error = nil;
	[[self helpWindow] addPath:@"help" bundle:[NSBundle mainBundle] error:&error];
	[[self helpWindow] addResource:@"NOTICE" bundle:[NSBundle mainBundle] error:&error];
	
*/
}

-(void)applicationWillTerminate:(NSNotification *)aNotification {
	// disconnect from remote servers
	[[self pool] removeAll];

	// save user defaults
	[[self sourceView] saveToUserDefaults];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark ConnectionPoolDelegate implementation
////////////////////////////////////////////////////////////////////////////////

-(void)connectionForTag:(NSInteger)tag statusChanged:(PGConnectionStatus)status description:(NSString* )description {
	PGSourceViewConnection* node = (PGSourceViewConnection* )[[self sourceView] nodeForTag:tag];
	NSParameterAssert([node isKindOfClass:[PGSourceViewConnection class]]);

	switch(status) {
	case PGConnectionStatusConnected:
		[(PGSourceViewConnection* )node setIconStatus:PGSourceViewConnectionIconConnected];
		[self reloadNode:node];
		break;
	case PGConnectionStatusConnecting:
	case PGConnectionStatusBusy:
		[(PGSourceViewConnection* )node setIconStatus:PGSourceViewConnectionIconConnecting];
		[self reloadNode:node];
		break;
	case PGConnectionStatusRejected:
		[(PGSourceViewConnection* )node setIconStatus:PGSourceViewConnectionIconRejected];
		[self reloadNode:node];
		break;
	case PGConnectionStatusDisconnected:
	default:
		[(PGSourceViewConnection* )node setIconStatus:PGSourceViewConnectionIconDisconnected];
		[self reloadNode:node];
		break;
	}

	[self updateStateForNode:node];
	if(description) {
		[[self log] appendLog:description];
	}
}

-(void)connectionForTag:(NSInteger)tag willExecute:(NSString* )query {
	[[self log] appendLog:[NSString stringWithFormat:@"EXEC: %@",query]];
}

-(void)connectionForTag:(NSInteger)tag notice:(NSString* )notice {
	NSUserNotification* notification = [NSUserNotification new];
	[notification setTitle:@"NOTICE"];
	[notification setInformativeText:notice];
	[[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
	
	[[self log] appendLog:notice];
}

-(void)connectionForTag:(NSInteger)tag error:(NSError* )error {
	NSUserNotification* notification = [NSUserNotification new];
	[notification setTitle:@"ERROR"];
	[notification setInformativeText:[error localizedDescription]];
	[[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
	
	[[self log] appendLog:[error localizedDescription]];
}

-(void)connectionForTag:(NSInteger)tag notificationOnChannel:(NSString *)channelName payload:(NSString *)payload {
	NSUserNotification* notification = [NSUserNotification new];
	[notification setTitle:@"NOTIFICATION"];
	[notification setSubtitle:channelName];
	if(payload) {
		[notification setInformativeText:payload];
	}
	[[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];

	[[self log] appendLog:[NSString stringWithFormat:@"NOTIFICATION: %@ <%@>",channelName,payload]];
}

@end
