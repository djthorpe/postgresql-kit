
#import "Controller.h"
#import "main.h"

@implementation Controller

///////////////////////////////////////////////////////////////////////////////

-(id)init {
	self = [super init];
	if (self != nil) {
		m_theConnection = [[FLXPostgresConnection alloc] init];
		m_theTimer = nil;
		m_theSelectedDatabases = [[NSIndexSet alloc] init];
	}
	return self;
}

-(void)dealloc {
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


-(NSArrayController* )databases {	
	return m_theDatabases;
}

-(NSIndexSet* )selectedDatabases {
	return m_theSelectedDatabases;
}

-(void)setSelectedDatabases:(NSIndexSet* )theIndexSet {
	BOOL shouldNotify = [theIndexSet isEqual:m_theSelectedDatabases] ? NO : YES;

	// retain the new index set
	[theIndexSet retain];
	[m_theSelectedDatabases release];
	m_theSelectedDatabases = theIndexSet;
	
	// send notification of new selected database
	if(shouldNotify) {
		NSArray* theSelectedDatabases = [[self databases] selectedObjects];
		if([theSelectedDatabases count]==0) {
			[[NSNotificationCenter defaultCenter] postNotificationName:FLXSelectDatabaseNotification object:nil];								
		} else {
			[[NSNotificationCenter defaultCenter] postNotificationName:FLXSelectDatabaseNotification object:[theSelectedDatabases objectAtIndex:0]];											
		}
	}
}

///////////////////////////////////////////////////////////////////////////////
// properties

-(FLXPostgresConnection* )connection {
	return m_theConnection;
}

-(NSTimer* )timer {
	return m_theTimer;
}

-(void)setTimer:(NSTimer* )theTimer {
	[theTimer retain];
	[m_theTimer release];
	m_theTimer = theTimer;
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
	NSLog(@"reload databases = %@",[[self connection] databases]);
	[[self databases] addObjects:[[self connection] databases]];
}

-(void)_selectDatabase:(NSString* )theDatabase {
	NSParameterAssert([[self connection] connected]);
	[[self connection] disconnect];
	[[self connection] setDatabase:theDatabase];
	[[self connection] connect];
	NSParameterAssert([[self connection] connected]);
}

///////////////////////////////////////////////////////////////////////////////

-(void)awakeFromNib {	
	// set the application delegate
	[[NSApplication sharedApplication] setDelegate:self];

	// set split view delegate
	[[self splitView] setDelegate:self];
	
	// notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createDatabase:) name:FLXCreateDatabaseNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropDatabase:) name:FLXDropDatabaseNotification object:nil];	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectDatabase:) name:FLXSelectDatabaseNotification object:nil];		
	
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

///////////////////////////////////////////////////////////////////////////////
// IBAction to create a new database

-(IBAction)doCreateDatabase:(id)sender {	
	[[self createDropDatabaseController] beginCreateDatabaseWithWindow:[self window]];
}

-(IBAction)doDropDatabase:(id)sender {
	// retrieve currently selected database
	NSArray* theSelectedObjects = [[self databases] selectedObjects];
	if([theSelectedObjects count]) {
		[[self createDropDatabaseController] setDatabase:[theSelectedObjects objectAtIndex:0]];
		[[self createDropDatabaseController] beginDropDatabaseWithWindow:[self window]];		
	}
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
	
	NSLog(@"tables = %@",[[self connection] tables]);
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

