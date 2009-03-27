
#import "Controller.h"

@interface Controller (Private) 
-(void)_startServer;
@end

@implementation Controller
@synthesize server;
@synthesize client;
@synthesize bindings;

////////////////////////////////////////////////////////////////////////////////

-(void)dealloc {
	[self setClient:nil];
	[self setServer:nil];
	[self setBindings:nil];	
	[super dealloc];
}

-(void)close {
	[[self client] disconnect];
	[[self server] stop];
	[self setClient:nil];
	[self setServer:nil];	
}

-(void)awakeFromNib {
	// create the server object
	[self setServer:[FLXPostgresServer sharedServer]];
	NSParameterAssert([self server]);
	// create the client object
	[self setClient:[[[FLXPostgresConnection alloc] init] autorelease]];
	
	// set server delegate
	[[self server] setDelegate:self];

	// set the application delegate
	[[NSApplication sharedApplication] setDelegate:self];
	
	// clear output
	[bindings clearOutput];
	
	// start the server
	[self _startServer];
}

///////////////////////////////////////////////////////////////////////////////
// server: start and stop server

-(NSString* )_dataPath {
	NSArray* theIdent = [[[NSBundle mainBundle] bundleIdentifier] componentsSeparatedByString:@"."];
	NSArray* theApplicationSupportDirectory = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask, YES);
	NSParameterAssert([theApplicationSupportDirectory count]);
	NSParameterAssert([theIdent count]);
	return [[theApplicationSupportDirectory objectAtIndex:0] stringByAppendingPathComponent:[theIdent objectAtIndex:([theIdent count]-1)]];
}

-(void)_startServer {
	// start the server
	
	// create application support path
	BOOL isDirectory = NO;
	if([[NSFileManager defaultManager] fileExistsAtPath:[self _dataPath] isDirectory:&isDirectory]==NO) {
		[[NSFileManager defaultManager] createDirectoryAtPath:[self _dataPath] attributes:nil];
	}
	
	// initialize the data directory if nesessary
	NSString* theDataDirectory = [[self _dataPath] stringByAppendingPathComponent:@"data"];
	if([[self server] startWithDataPath:theDataDirectory]==NO) {
		// starting failed, possibly because a server is already running
		if([[self server] state]==FLXServerStateAlreadyRunning) {
			[[self server] stop];
		}
	}    	
}

-(void)_stopServer {
	[[self server] stop];
}

///////////////////////////////////////////////////////////////////////////////
// client: connect and disconnect from server

-(void)_connectToServer {
	NSParameterAssert([[self client] connected]==NO);
	[[self client] setDatabase:[FLXPostgresServer superUsername]];
	[[self client] setUser:[FLXPostgresServer superUsername]];
	[[self client] connect];
	NSParameterAssert([[self client] connected]);
	NSParameterAssert([[self client] database]);
	NSParameterAssert([[[self client] database] isEqual:[FLXPostgresServer superUsername]]);
}

-(void)_disconnectFromServer {
	[[self client] disconnect];
}

-(void)_selectDatabase:(NSString* )theDatabase {
	NSParameterAssert([[self client] connected]);
	[[self client] disconnect];
	[[self client] setDatabase:theDatabase];
	[[self client] connect];
	NSParameterAssert([[self client] connected]);
}

-(FLXPostgresResult* )_executeQuery:(NSString* )theQuery {
	FLXPostgresResult* theResult = nil;
	@try {
		theResult = [[self client] execute:theQuery];
	} @catch(NSException* theException) {
		[bindings appendOutputString:[theException description] color:[NSColor redColor] bold:NO];
		theResult = nil;
	}
	return theResult;
}	

-(NSString* )_formattedRow:(NSArray* )theRow widths:(NSUInteger* )columnWidths {
	NSMutableString* theLine = [NSMutableString string];
	[theLine appendString:@"|"];
	for(NSUInteger i = 0; i < [theRow count]; i++) {
		NSString* theValue = [[theRow objectAtIndex:i] description];
		NSUInteger theWidth = columnWidths[i];
		if(theValue==nil) {
			[theLine appendString:@"nil"];
		} else {
			[theLine appendString:[theValue stringByPaddingToLength:theWidth withString:@" " startingAtIndex:0]];
		}
		[theLine appendString:@"|"];
	}
	return theLine;
}

-(void)_outputResult:(FLXPostgresResult* )theResult {
	NSUInteger numberOfColumns = [theResult numberOfColumns];
	NSUInteger* columnWidths = malloc(sizeof(NSUInteger) * numberOfColumns);
	// determine width of headers
	for(NSUInteger i = 0; i < numberOfColumns; i++) {
		columnWidths[i] = [[[theResult columns] objectAtIndex:i] length];		
	}
	// determine width of cells
	NSArray* theRow;
	while(theRow = [theResult fetchRowAsArray]) {
		for(NSUInteger i = 0; i < [theRow count]; i++) {
			NSString* theValue = [[theRow objectAtIndex:i] description];
			NSUInteger theWidth = [[theValue description] length];
			if(theWidth < 40 && theWidth > columnWidths[i]) {
				columnWidths[i] = theWidth;
			}
		}
	}
	[theResult dataSeek:0];
	NSUInteger totalColumnWidth = 0;
	for(NSUInteger i = 0; i < numberOfColumns; i++) {
		totalColumnWidth += columnWidths[i];
	}
	totalColumnWidth += (numberOfColumns + 1);
	
	// output column header
	NSString* theHorizonalLine = [[NSString string] stringByPaddingToLength:totalColumnWidth withString:@"-" startingAtIndex:0];
	[bindings appendOutputString:theHorizonalLine color:nil bold:NO];
	// output header
	NSString* theLine = [self _formattedRow:[theResult columns] widths:columnWidths];
	[bindings appendOutputString:theLine color:nil bold:NO];
	[bindings appendOutputString:theHorizonalLine color:nil bold:NO];
	// output data
	while(theRow = [theResult fetchRowAsArray]) {
		NSString* theLine = [self _formattedRow:theRow widths:columnWidths];		
		[bindings appendOutputString:theLine color:nil bold:NO];		
	}
	[bindings appendOutputString:theHorizonalLine color:nil bold:NO];
	free(columnWidths);		
}


////////////////////////////////////////////////////////////////////////////////
// IBActions

-(IBAction)doStartServer:(id)sender {
	if([[self server] isRunning]==NO) {
		[self _startServer];
	}
}

-(IBAction)doStopServer:(id)sender {
	if([[self server] isRunning]==YES) {
		[self _stopServer];
	} 		
}

-(IBAction)doBackupServer:(id)sender {
	if([[self server] isRunning]==YES) {
		NSOpenPanel* thePanel = [NSOpenPanel openPanel];
		[thePanel setCanChooseFiles:NO];
		[thePanel setCanChooseDirectories:YES];
		[thePanel setAllowsMultipleSelection:NO];
		[thePanel beginSheetForDirectory:nil file:nil types:nil modalForWindow:[bindings mainWindow] modalDelegate:self didEndSelector:@selector(backupPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
	}
}

-(IBAction)doExecuteCommand:(id)sender {
	if([[self server] isRunning]==NO) return;
	NSString* theCommand = [bindings inputString];
	if([theCommand length]==0) return;
	[bindings appendOutputString:theCommand color:[NSColor grayColor] bold:YES];
	[bindings setInputString:@""];
	FLXPostgresResult* theResult = [self _executeQuery:theCommand];	
	if(theResult==nil) return;
	if([theResult isDataReturned]==NO) {
		// output OK
		[bindings appendOutputString:[NSString stringWithFormat:@"OK, %u rows affected",[theResult affectedRows]] color:[NSColor grayColor] bold:YES];		
	} else {
		[self _outputResult:theResult];
		[bindings appendOutputString:[NSString stringWithFormat:@"%u rows returned",[theResult affectedRows]] color:[NSColor grayColor] bold:YES];	
	}
}

-(IBAction)doSelectDatabase:(id)sender {	
	if([[self client] connected]==NO) return;
	
	// set databases
	NSArray* theDatabases = [[self client] databases];
	NSUInteger theRow = 0;
	for(NSString* theDatabase in theDatabases) {
		if([theDatabase isEqual:theDatabases]==NO) continue;
		[bindings setSelectedDatabaseIndex:[NSIndexSet indexSetWithIndex:theRow]];
		theRow++;
	}	
	[bindings setDatabases:theDatabases];
	
	if([[self server] isRunning]==YES) {		
		[NSApp beginSheet:[bindings selectWindow] modalForWindow:[bindings mainWindow] modalDelegate:self didEndSelector:@selector(selectSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
	}
}

-(IBAction)doEndSelectDatabase:(id)sender {
	[NSApp endSheet:[bindings selectWindow] returnCode:NSOKButton];
}

-(IBAction)doClearOutput:(id)sender {
	[bindings clearOutput];
}

////////////////////////////////////////////////////////////////////////////////
// NSApplication delegate messages

-(void)applicationWillTerminate:(NSNotification *)aNotification {
	if([[self client] connected]) {
		[self _disconnectFromServer];
	}
	if([[self server] isRunning]) {
		[self _stopServer];
	}
}

-(BOOL)applicationShouldHandleReopen:(NSApplication*)application hasVisibleWindows:(BOOL)visibleWindows {
	[[bindings mainWindow] makeKeyAndOrderFront:nil];
	return YES;
}

////////////////////////////////////////////////////////////////////////////////

-(void)selectSheetDidEnd:(NSWindow* )sheet returnCode:(int)returnCode  contextInfo:(void* )contextInfo {
	[sheet orderOut:self];
	if(returnCode==NSOKButton) {
		NSString* theDatabase = [[bindings databases] objectAtIndex:[[bindings selectedDatabaseIndex] firstIndex]];
		if([[[self client] databases] containsObject:theDatabase]) {
			@try {
				[self _selectDatabase:theDatabase];
			} @catch(NSException* theException) {
				[bindings appendOutputString:[theException description] color:[NSColor redColor] bold:NO];
				return;
			}
			[bindings appendOutputString:[NSString stringWithFormat:@"Selected database: %@",theDatabase] color:[NSColor grayColor] bold:YES];	
		}
	}
}

-(void)backupPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo {
	if(returnCode==NSOKButton) {
		NSParameterAssert([[panel filenames] count]==1);
		NSString* theBackupPath = [[panel filenames] objectAtIndex:0];
		[[self server] backupInBackgroundToFolderPath:theBackupPath superPassword:nil];
	}
}
	
////////////////////////////////////////////////////////////////////////////////
// FLXServer delegate messages

-(void)serverMessage:(NSString* )theMessage {
	// message from the server
	[bindings appendOutputString:theMessage color:nil bold:YES];
}

-(void)serverStateDidChange:(NSString* )theMessage {
	[bindings appendOutputString:[NSString stringWithFormat:@"Server state: %@",theMessage] color:[NSColor grayColor] bold:YES];

	// only enable the input when server status is running
	[bindings setInputEnabled:([[self server] state]==FLXServerStateStarted) ? YES : NO];
	
	// connect client to server, or disconnect...wait for 1 second after server becomes ready
	if([[self server] state]==FLXServerStateStarted) {
		[self performSelector:@selector(_connectToServer) withObject:self afterDelay:1.0];
	} else if([[self server] state]==FLXServerStateStopping) {
		[self _disconnectFromServer];
	}
		
}

@end
