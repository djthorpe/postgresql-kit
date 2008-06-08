
#import "main.h"
#import "Controller.h"
#import "OutlineNode.h"

@interface Controller (Private)
-(NSString* )selectedDatabaseName;
-(void)addRootItem:(OutlineNode* )theNode;
-(void)replaceChildrenForNode:(OutlineNode* )theNode with:(NSArray* )theArray;
@end

@implementation Controller

///////////////////////////////////////////////////////////////////////////////

-(id)init {
	self = [super init];
	if (self != nil) {
		m_theConnection = [[FLXPostgresConnection alloc] init];
		m_theTimer = nil;
		m_theDatabases = [[NSArray alloc] init];
		m_theTables = [[OutlineNode nodeWithName:@"TABLES"] retain];
		m_theSchemas = [[OutlineNode nodeWithName:@"SCHEMAS"] retain];
		m_theQueries = [[OutlineNode nodeWithName:@"QUERIES"] retain];
		m_theSelectedDatabases = [[NSIndexSet alloc] init];
	}
	return self;
}

-(void)dealloc {
	[m_theDatabases release];
	[m_theTables release];
	[m_theSchemas release];
	[m_theQueries release];
	[m_theSelectedDatabases release];
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

-(BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)theItem {
	// don't allow root nodes to be selected
	OutlineNode* theNode = [theItem representedObject];
	if([theNode isEqual:[self schemas]] || [theNode isEqual:[self tables]] || [theNode isEqual:[self queries]]) {
		return NO;
	}
	// or else allow selection
	return YES;
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
	NSLog(@"drop database %@",theNotification);	
}

-(void)selectDatabase:(NSNotification* )theNotification {
	NSString* theDatabase = [theNotification object];
	NSParameterAssert([theDatabase isKindOfClass:[NSString class]]);

	[self _selectDatabase:[theNotification object]];
	
	// populate schemas
	[self replaceChildrenForNode:[self schemas] with:[[self connection] schemas]];
	[self replaceChildrenForNode:[self tables] with:[[self connection] tables]];
}


///////////////////////////////////////////////////////////////////////////////
// NSTreeController support

-(void)addRootItem:(OutlineNode* )theNode {
	NSIndexPath* thePath = [NSIndexPath indexPathWithIndex:[[[self outline] content] count]];
	[[self outline] insertObject:theNode atArrangedObjectIndexPath:thePath];
}

-(void)replaceChildrenForNode:(OutlineNode* )theRootNode with:(NSArray* )theArray {
	// remove existing children
	[[theRootNode children] removeAllObjects];
	// add new ones
	for(NSString* theName in theArray) {
		OutlineNode* theNode = [OutlineNode nodeWithName:theName];
		[[theRootNode children] addObject:theNode];
	}

	NSLog(@"node = %@, children = %@",theRootNode,[theRootNode children]);
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

