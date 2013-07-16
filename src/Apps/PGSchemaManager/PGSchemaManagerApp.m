
#import "PGSchemaManagerApp.h"

@implementation PGSchemaManagerApp

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	self = [super init];
	if(self) {
		_connection = [[PGConnection alloc] init];
		_logincontroller = [[PGLoginController alloc] init];
		_schema = [[PGSchema alloc] initWithConnection:_connection name:nil];
	}
	return self;
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSError* error = nil;
	NSString* schemaPath = [[NSBundle mainBundle] resourcePath];
	[[self schema] addSchemaSearchPath:schemaPath error:&error];
	if(error) {
		NSLog(@"Error: %@",[error localizedDescription]);
		return;
	}
	
	// set login controller
	[[self logincontroller] setDelegate:self];

	NSLog(@"Schema = %@",[[self schema] schemas]);
	
	// perform login
	[self doLogin:self];
	
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize connection = _connection;
@synthesize schema = _schema;
@synthesize logincontroller = _logincontroller;

////////////////////////////////////////////////////////////////////////////////
// actions

-(IBAction)doLogin:(id)sender {
	if([[[self logincontroller] connection] status] == PGConnectionStatusConnected) {
		[[[self logincontroller] connection] disconnect];
	}
	[[self logincontroller] beginLoginSheetForWindow:[self window]];
}

////////////////////////////////////////////////////////////////////////////////
// PGLoginDelegate methods

-(void)loginCompleted:(NSInteger)returnCode {
	NSLog(@"Login done, return code = %ld",returnCode);
}

@end
