
#import "PGSchemaManagerApp.h"

@implementation PGSchemaManagerApp

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	self = [super init];
	if(self) {
		_logincontroller = [[PGLoginController alloc] init];
		_schema = [[PGSchema alloc] initWithConnection:[_logincontroller connection] name:nil];
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
@dynamic schemas, selected, ibCanLogin, ibCanLogout;

-(BOOL)ibCanLogin {
	return ([[[self logincontroller] connection] status] != PGConnectionStatusConnected);
}

-(BOOL)ibCanLogout {
	return ([[[self logincontroller] connection] status] == PGConnectionStatusConnected);
}

-(NSArray* )schemas {
	return [[self schema] products];
}

-(PGSchemaProduct* )selected {
	if([[self schemas] count]==0) {
		return nil;
	} else {
		return [[self schemas] objectAtIndex:0];
	}
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
	NSLog(@"tableViewSelectionDidChange: %@",theTableView);
}

@end
