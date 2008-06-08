
#import "main.h"
#import "Controller.h"
#import "OutlineNode.h"

// forward declarations of private methods
@interface Controller (Private)
-(NSString* )selectedDatabaseName;
-(void)addRootItem:(OutlineNode* )theNode;
-(void)replaceChildrenForRootNode:(OutlineNode* )theNode with:(NSArray* )theArray;
@end

@implementation Controller

///////////////////////////////////////////////////////////////////////////////

-(id)init {
	self = [super init];
	if (self != nil) {
		m_theConnection = [[FLXPostgresConnection alloc] init];
		m_theTimer = nil;
		m_theDatabases = [[NSArray alloc] init];
		m_theTables = [[OutlineNode rootNodeWithName:@"TABLES"] retain];
		m_theSchemas = [[OutlineNode rootNodeWithName:@"SCHEMAS"] retain];
		m_theQueries = [[OutlineNode rootNodeWithName:@"QUERIES"] retain];
		m_theSelectedDatabases = [[NSIndexSet alloc] init];
		m_theSelectedSchemas = [[NSArray alloc] init];
	}
	return self;
}

-(void)dealloc {
	[m_theDatabases release];
	[m_theTables release];
	[m_theSchemas release];
	[m_theQueries release];
	[m_theSelectedDatabases release];
	[m_theSelectedSchemas release];
	[m_theTimer invalidate];
	[m_theTimer release];
	[m_theConnection release];
	[super dealloc];
}

///////////////////////////////////////////////////////////////////////////////
// outlets

-(ServerController* )serverController {
	return m_theServerController;
}

-(CreateDropDatabaseController* )createDropDatabaseController {
	return m_theCreateDropDatabaseController;
}

-(NSWindow* )window {
	return m_theWindow;
}

-(NSView* )resizeView {
	return m_theResizeView;
}

-(NSSplitView* )splitView {
	return m_theSplitView;
}

///////////////////////////////////////////////////////////////////////////////
// bound properties

-(NSArray* )databases {	
	return m_theDatabases;
}

-(NSTreeController* )outline {
	return m_theOutline;
}

-(void)setDatabases:(NSArray* )theDatabases {
	[theDatabases retain];
	[m_theDatabases release];
	m_theDatabases = theDatabases;	
}

-(NSIndexSet* )selectedDatabases {
	return m_theSelectedDatabases;
}

-(void)setSelectedDatabases:(NSIndexSet* )theIndexSet {
	// determine if new index set is different from the old one
	BOOL isNotify = ([theIndexSet isEqual:m_theSelectedDatabases] ? NO : YES);
	// retain the new index set
	[theIndexSet retain];
	[m_theSelectedDatabases release];
	m_theSelectedDatabases = theIndexSet;
	// perform the notification if index changes
	if(isNotify) {
		[[NSNotificationCenter defaultCenter] postNotificationName:FLXSelectDatabaseNotification object:[self selectedDatabaseName]];
	}
}

-(NSArray* )selectedSchemas {
	return m_theSelectedSchemas;
}

-(void)setSelectedSchemas:(NSArray* )theSchemas {
	// determine if new index set is different from the old one
	BOOL isNotify = ([theSchemas isEqual:m_theSelectedSchemas] ? NO : YES);
	// retain the new index set
	[theSchemas retain];
	[m_theSelectedSchemas release];
	m_theSelectedSchemas = theSchemas;
	// perform the notification if index changes
	if(isNotify) {
		[[NSNotificationCenter defaultCenter] postNotificationName:FLXSelectSchemaNotification object:[self selectedSchemas]];
	}
}

///////////////////////////////////////////////////////////////////////////////
// other properties

-(FLXPostgresConnection* )connection {
	return m_theConnection;
}

-(NSTimer* )timer {
	return m_theTimer;
}

-(OutlineNode* )tables {	
	return m_theTables;
}

-(OutlineNode* )schemas {	
	return m_theSchemas;
}

-(OutlineNode* )queries {	
	return m_theQueries;
}

-(void)setTimer:(NSTimer* )theTimer {
	[theTimer retain];
	[m_theTimer release];
	m_theTimer = theTimer;
}

-(NSString* )selectedDatabaseName {
	if([[self selectedDatabases] count]==0) return nil;
	// get the first index
	NSUInteger theFirstIndex = [[self selectedDatabases] firstIndex];
	if(theFirstIndex==NSNotFound) return nil;
	// return the database name for this index
	return [[self databases] objectAtIndex:theFirstIndex];
}

///////////////////////////////////////////////////////////////////////////////
// start and stop server

-(void)_connectToServer {
	NSParameterAssert([[self connection] connected]==NO);
	[[self connection] setPort:9001];
	[[self connection] setDatabase:@"postgres"];
	[[self connection] connect];
	NSParameterAssert([[self connection] connected]);
	NSParameterAssert([[self connection] database]);
	NSParameterAssert([[[self connection] database] isEqual:@"postgres"]);
}

-(void)_disconnectFromServer {
 [[self connection] disconnect];
 [[self timer] invalidate];
}

-(void)_reloadDatabases {
	// remove all objects and then re-add them
	[self setDatabases:[[self connection] databases]];
}

-(void)_selectDatabase:(NSString* )theDatabase {
	NSParameterAssert([[self connection] connected]);
	[[self connection] disconnect];
	[[self connection] setDatabase:theDatabase];
	[[self connection] connect];
	NSParameterAssert([[self connection] connected]);
}

///////////////////////////////////////////////////////////////////////////////
// awakeFromNib methods

-(void)awakeFromNibOutlineView {
	// Add the root items
	[self addRootItem:[self queries]];
	[self addRootItem:[self schemas]];
	[self addRootItem:[self tables]];
}

-(void)awakeFromNib {	
	// set the application delegate
	[[NSApplication sharedApplication] setDelegate:self];

	// set split view delegate
	[[self splitView] setDelegate:self];
	
	// notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createDatabase:) name:FLXCreateDatabaseNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropDatabase:) name:FLXDropDatabaseNotification object:nil];	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectDatabase:) name:FLXSelectDatabaseNotification object:nil];		
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectSchema:) name:FLXSelectSchemaNotification object:nil];		
	
	// set-up the outline view
	[self awakeFromNibOutlineView];
	
    // schedule a timer to do stuff
	[self setTimer:[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(fireTimer:) userInfo:nil repeats:YES]];	
}

////////////////////////////////////////////////////////////////////////////////
// NSSplitView delegate messages

-(NSRect)splitView:(NSSplitView *)splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex {
	return [[self resizeView] convertRect:[[self resizeView] bounds] toView:splitView]; 
}

////////////////////////////////////////////////////////////////////////////////
// NSApplication delegate messages

-(void)applicationWillTerminate:(NSNotification *)aNotification {
	if([[self serverController] isStarted]) {
		[self _disconnectFromServer];
		[[self serverController] stopServerWithWindow:[self window]];		
	}
}

-(BOOL)applicationShouldHandleReopen:(NSApplication*)application hasVisibleWindows:(BOOL)visibleWindows {
	[[self window] makeKeyAndOrderFront:nil];
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// NSOutlineView delegate messages

-(BOOL)outlineView:(NSOutlineView* )outlineView shouldSelectItem:(id)theItem {
	// don't allow root nodes to be selected
	OutlineNode* theNode = [theItem representedObject];
	if([theNode isRootNode]) {
		return NO;
	}
	// or else allow selection
	return YES;
}

-(void)outlineViewSelectionDidChange:(NSNotification* )notification {	
	// determine new set of schemas
	NSMutableArray* theSchemas = [NSMutableArray array];
	for(OutlineNode* theNode in [[self outline] selectedObjects]) {
		if([theNode isSchemaNode]) {
			[theSchemas addObject:theNode];
		}
	}
	[self setSelectedSchemas:theSchemas];
}

-(BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item {
	// no items are collapsable
	return NO;
}

-(BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)theItem {
	// root nodes displayed as group items
	OutlineNode* theNode = [theItem representedObject];
	return [theNode isRootNode];
}

///////////////////////////////////////////////////////////////////////////////
// IBAction to create a new database or drop an existing one

-(IBAction)doCreateDatabase:(id)sender {	
	[[self createDropDatabaseController] beginCreateDatabaseWithWindow:[self window]];
}

-(IBAction)doDropDatabase:(id)sender {
	// retrieve currently selected database
	NSString* theCurrentDatabase = [self selectedDatabaseName];
	NSParameterAssert(theCurrentDatabase);
	// start the drop
	[[self createDropDatabaseController] setDatabase:theCurrentDatabase];
	[[self createDropDatabaseController] beginDropDatabaseWithWindow:[self window]];		
}

///////////////////////////////////////////////////////////////////////////////
// Notifications

-(void)createDatabase:(NSNotification* )theNotification {
	NSString* theDatabase = (NSString* )[theNotification object];
	NSParameterAssert([theDatabase isKindOfClass:[NSString class]]);
	BOOL isSuccess = [[self connection] createDatabase:theDatabase];
	if(isSuccess==NO) {
		NSAlert* theAlert = [NSAlert alertWithMessageText:@"Unable to create database" defaultButton:@"OK" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"La la la"];
		[theAlert runModal];
	}
	[self _reloadDatabases];
}

-(void)dropDatabase:(NSNotification* )theNotification {
	// TODO
	NSLog(@"drop database %@",theNotification);	
}

-(void)selectDatabase:(NSNotification* )theNotification {
	NSString* theDatabase = [theNotification object];
	NSParameterAssert([theDatabase isKindOfClass:[NSString class]]);

	[self _selectDatabase:[theNotification object]];
	
	// populate schemas
	NSMutableArray* theSchemas = [NSMutableArray array];
	[theSchemas addObject:[OutlineNode schemaNodeAll]];
	for(NSString* theName in [[self connection] schemas]) {
		[theSchemas addObject:[OutlineNode schemaNodeWithName:theName]];
	}
	[self replaceChildrenForRootNode:[self schemas] with:theSchemas];

	// TODO: select the All schema
}

-(void)selectSchema:(NSNotification* )theNotification {
	NSArray* theSelectedSchemas = [theNotification object];
	NSParameterAssert([theSelectedSchemas isKindOfClass:[NSArray class]]);
	
	// munge the schema names...
	// if one parameter 'All' we fetch all tables except for the system ones
	// if more than one parameter we ignore the 'All' one
	NSArray* theTableNames = nil;
	if([theSelectedSchemas count]==0) {
		theTableNames = [[self connection] tables];
	} else if([theSelectedSchemas count]==1 && [[theSelectedSchemas objectAtIndex:0] isSchemaAllNode]) {
		theTableNames = [[self connection] tables];
	} else if([theSelectedSchemas count]==1) {
		theTableNames = [[self connection] tablesForSchema:[[theSelectedSchemas objectAtIndex:0] name]];
	} else {
		NSMutableArray* theSchemaNames = [NSMutableArray array];
		for(OutlineNode* theNode in theSelectedSchemas) {
			if([theNode isSchemaAllNode]) continue;
			[theSchemaNames addObject:[theNode name]];			
		}
		theTableNames = [[self connection] tablesForSchemas:theSchemaNames];
	}
	
	// populate tables for these schemas
	NSMutableArray* theTables = [NSMutableArray array];
	for(NSString* theName in theTableNames) {
		[theTables addObject:[OutlineNode tableNodeWithName:theName]];
	}
	[self replaceChildrenForRootNode:[self tables] with:theTables];
	
	// TODO: reselect the schemas
}

///////////////////////////////////////////////////////////////////////////////
// NSTreeController support

-(void)addRootItem:(OutlineNode* )theNode {
	NSIndexPath* thePath = [NSIndexPath indexPathWithIndex:[[[self outline] content] count]];
	[[self outline] insertObject:theNode atArrangedObjectIndexPath:thePath];
}

-(void)replaceChildrenForRootNode:(OutlineNode* )theRootNode with:(NSArray* )theArray {
	// find out the index path of the root node
	NSUInteger theIndex = [[[self outline] content] indexOfObject:theRootNode];
	NSParameterAssert(theIndex != NSNotFound);
	// remove the children
	NSIndexPath* theRootNodeIndexPath = [NSIndexPath indexPathWithIndex:theIndex];
	for(NSUInteger i = [[theRootNode children] count]; i > 0; i--) {
		[[self outline] removeObjectAtArrangedObjectIndexPath:[theRootNodeIndexPath indexPathByAddingIndex:(i-1)]];
	}
	// add the new children
	for(OutlineNode* theNode in theArray) {
		[[self outline] insertObject:theNode atArrangedObjectIndexPath:[theRootNodeIndexPath indexPathByAddingIndex:[[theRootNode children] count]]];
	}
}

///////////////////////////////////////////////////////////////////////////////

-(void)fireTimer:(id)sender {
	// don't allow timer to do anything unless server is running
	if([[self serverController] isStarted]==NO) {
		[[self serverController] startServerWithWindow:[self window]];
		return;
	}
	// connect
	if([[self serverController] isReady]==YES && [[self connection] connected]==NO) {
		[self _connectToServer];
		[self _reloadDatabases];
		return;
	}
}

@end

