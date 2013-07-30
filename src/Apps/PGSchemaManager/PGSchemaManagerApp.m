
#import "PGSchemaManagerApp.h"

@implementation PGSchemaManagerApp

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	self = [super init];
	if(self) {
		_logincontroller = [[PGLoginController alloc] init];
		_schema = [[PGSchemaManager alloc] initWithConnection:[_logincontroller connection] userSchema:nil];
		_selected = nil;
	}
	return self;
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {

	// set login controller
	[[self logincontroller] setDelegate:self];

	// perform login
	[self doLogin:self];
	
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize schema = _schema;
@synthesize logincontroller = _logincontroller;
@synthesize selected = _selected;
@dynamic schemas, ibCanLogin, ibCanLogout;

-(BOOL)ibCanLogin {
	return ([[[self logincontroller] connection] status] != PGConnectionStatusConnected);
}

-(BOOL)ibCanLogout {
	return ([[[self logincontroller] connection] status] == PGConnectionStatusConnected);
}

-(NSArray* )schemas {
	return [[self schema] products];
}

////////////////////////////////////////////////////////////////////////////////
// methods

-(void)addSchemaPath:(NSString* )path {
	NSError* error = nil;
	
	[self willChangeValueForKey:@"schemas"];
	[self willChangeValueForKey:@"selected"];
	[[self schema] addSearchPath:path error:&error];
	[self didChangeValueForKey:@"schemas"];
	[self didChangeValueForKey:@"selected"];

	if(error) {
		NSLog(@"Error: %@",[error localizedDescription]);
		return;
	}
}

////////////////////////////////////////////////////////////////////////////////
// actions

-(IBAction)doLogin:(id)sender {
	if([[[self logincontroller] connection] status] == PGConnectionStatusConnected) {
		[[[self logincontroller] connection] disconnect];
	}
	[[self logincontroller] beginLoginSheetForWindow:[self window]];
}

-(IBAction)doLogout:(id)sender {
	[[[self logincontroller] connection] disconnect];
}

-(IBAction)doCreate:(id)sender {
	PGSchemaProduct* product = [self selected];
	NSError* error = nil;
	if([[self schema] create:product dryrun:YES error:&error]==NO) {
		NSLog(@"Cannot create product: %@",error);
		return;
	}
	if([[self schema] create:product dryrun:NO error:&error]==NO) {
		NSLog(@"Cannot create product: %@",error);
		return;
	}
}

-(IBAction)doDrop:(id)sender {
	PGSchemaProduct* product = [self selected];
	NSError* error = nil;
	if([[self schema] drop:product dryrun:YES error:&error]==NO) {
		NSLog(@"Cannot drop product: %@",error);
		return;
	}
	if([[self schema] drop:product dryrun:NO error:&error]==NO) {
		NSLog(@"Cannot drop product: %@",error);
		return;
	}	
}

-(IBAction)doAddSearchPath:(id)sender {
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	[panel setCanChooseDirectories:YES];
	[panel setCanChooseFiles:NO];
	[panel setCanCreateDirectories:NO];
	[panel setAllowsMultipleSelection:NO];
	[panel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
		if(result == NSFileHandlingPanelOKButton) {
			NSURL* thePath = [[panel URLs] objectAtIndex:0];
			[self addSchemaPath:[thePath path]];
		}
	}];
}

////////////////////////////////////////////////////////////////////////////////
// PGLoginDelegate methods

-(void)loginCompleted:(NSInteger)returnCode {
	NSLog(@"Login done, return code = %ld",returnCode);

	// add standard products
	[self addSchemaPath:[[NSBundle mainBundle] resourcePath]];
}

////////////////////////////////////////////////////////////////////////////////
// NSTableViewDelegate methods

-(void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	NSTableView* theTableView = [aNotification object];
	NSIndexSet* indexSet = [theTableView selectedRowIndexes];
	if([[theTableView identifier] isEqualToString:@"available"]) {
		if([indexSet count]==1) {
			PGSchemaProduct* product = [[self schemas] objectAtIndex:[indexSet firstIndex]];
			[self setSelected:product];
		}
	} else {
		[self setSelected:nil];
	}
}

@end
