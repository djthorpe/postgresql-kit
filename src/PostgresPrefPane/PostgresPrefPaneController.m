
#import <Security/Security.h>
#import "PostgresPrefPaneController.h"
#import "PostgresServerApp.h"
#import "PostgresPrefPaneShared.h"

@implementation PostgresPrefPaneController

@synthesize connection;

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)initWithBundle:(NSBundle *)bundle {
	self = [super initWithBundle:bundle];
    if(self) {
		[self setConnection:[NSConnection connectionWithRegisteredName:PostgresServerAppIdentifier host:nil]];
	}
	return self;
}

-(void)dealloc {
	[self setConnection:nil];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// properties

-(PostgresServerApp* )serverApp {
	return (PostgresServerApp* )[[self connection] rootProxy];
}

-(void)mainViewDidLoad {

	// set server version
	NSString* theVersion = [[self serverApp] serverVersion];
	if(theVersion) {
		[ibVersionNumber setStringValue:theVersion];
	} else {
		[ibVersionNumber setStringValue:@""];		
	}
	
	// set server state
	NSString* theState = [[self serverApp] serverState];
	if(theState) {
		[ibStatus setStringValue:theState];
	} else {
		[ibStatus setStringValue:@"Server is not installed"];
	}		
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(BOOL)_canInstall {
	// system can be installed if...
    // 0. communication to ServerApp is not working
	// 1. server is not already started
	// 2. launchctl does not have the particular identifier loaded
	// 2. startup item does not exist in the /Library/StartupItems folder
	// 3. preferences panel is installed system-wide rather than per-user
	// 4. the ServerApp exists and is executable
	// 5. the _mysql username exists
	return YES;
}

-(BOOL)_canUnInstall {
	// system can be uninstalled if 
    // 0. communication to ServerApp is working
	// 1. server is not started
	// 2. launchctl has the particular identifier loaded
	// 2. startup item exists in the /Library/StartupItems folder
	return NO;
}

-(AuthorizationRef)_authorizeUser {
	AuthorizationRef theAuthorization = nil;
	OSStatus theStatus = AuthorizationCreate(nil,kAuthorizationEmptyEnvironment,kAuthorizationFlagDefaults,&theAuthorization);	
	if(theStatus != errAuthorizationSuccess) {
		return nil;
	}
	
	AuthorizationItem theItems = {kAuthorizationRightExecute, 0, nil, 0};
	AuthorizationRights theRights = {1, &theItems};
	AuthorizationFlags theFlags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;
	theStatus = AuthorizationCopyRights(theAuthorization, &theRights, nil, theFlags, nil);	
	if(theStatus != errAuthorizationSuccess) {
		AuthorizationFree(theAuthorization, kAuthorizationFlagDefaults);
		return nil;
	}
	return theAuthorization;
}

-(NSString* )_execute:(NSString* )scriptName withAuthorization:(AuthorizationRef)theAuthorization withArguments:(NSArray* )theArguments {
	NSString* theScriptPath = [[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:scriptName];
	if(theScriptPath==nil) {
		return nil;
	}
	if([[NSFileManager defaultManager] isExecutableFileAtPath:theScriptPath]==NO) {
		return nil;
	}
	
	// create the set of arguments required
	const char** theArgs = malloc(sizeof(char* ) * ([theArguments count] + 1));
	if(theArgs==nil) {
		return nil;
	}

	NSUInteger i = 0;
	for(; i < [theArguments count]; i++) {
		NSString* theArgument = [theArguments objectAtIndex:i];
		NSParameterAssert([theArgument isKindOfClass:[NSString class]]);
		theArgs[i] = (const char* )[theArgument UTF8String];
	}
	theArgs[i] = nil;

	// execute the script
	FILE* thePipe = nil;
	OSStatus theStatus = AuthorizationExecuteWithPrivileges(theAuthorization,(char* )[theScriptPath UTF8String],kAuthorizationFlagDefaults,(char** )theArgs,&thePipe);	
	if(theStatus != errAuthorizationSuccess) {
		free(theArgs);
		return NO;
	}
	
	// read in data from the script
	NSFileHandle* theHandle = [[NSFileHandle alloc] initWithFileDescriptor:fileno(thePipe)];
	NSMutableData* theString = [NSMutableData data];
	NSData* theData = nil;
	while((theData = [theHandle availableData]) && [theData length]) {
		[theString appendData:theData];
	}
	
	// cleanup
	[theHandle closeFile];
	[theHandle release];
	free(theArgs);
	
	// return string based on data
	return [NSString stringWithCString:[theString bytes] length:[theString length]];
}

////////////////////////////////////////////////////////////////////////////////
// IBActions

-(IBAction)doStartServer:(id)sender {
	[[self serverApp] startServer];
}

-(IBAction)doStopServer:(id)sender {
	[[self serverApp] stopServer];
}

-(IBAction)doInstall:(id)sender {
	AuthorizationRef theAuthorization = [self _authorizeUser];
	if(theAuthorization) {
		NSString* theReturn = [self _execute:@"install-postgres-server-app.sh" withAuthorization:theAuthorization withArguments:[NSArray arrayWithObject:@"install"]];
		NSLog(@"return value = %@",theReturn);
		AuthorizationFree(theAuthorization,kAuthorizationFlagDefaults);
	}
}

-(IBAction)doUninstall:(id)sender {
	AuthorizationRef theAuthorization = [self _authorizeUser];
	if(theAuthorization) {
		NSLog(@"authorized - uninstall");
		AuthorizationFree(theAuthorization,kAuthorizationFlagDefaults);
	}
}

@end
