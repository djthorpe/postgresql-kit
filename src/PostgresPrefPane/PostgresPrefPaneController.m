
#import <Security/Security.h>
#import "PostgresPrefPaneController.h"
#import "PostgresServerApp.h"
#import "PostgresPrefPaneShared.h"

@implementation PostgresPrefPaneController

@synthesize connection;
@synthesize timer;
@synthesize serverState;

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)initWithBundle:(NSBundle *)bundle {
	self = [super initWithBundle:bundle];
	if(self) {
		[self setServerState:0];
		[self setConnection:nil];
		[self setTimer:nil];
	}
	return self;
}

-(void)dealloc {
	[[self timer] invalidate];
	[self setTimer:nil];
	[self setConnection:nil];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// properties

-(PostgresServerApp* )serverApp {
	return (PostgresServerApp* )[[self connection] rootProxy];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(void)_startConnection {
	[self setConnection:[NSConnection connectionWithRegisteredName:PostgresServerAppIdentifier host:nil]];
}

-(void)_updateStatus {
	if([[self connection] isValid]) {
		FLXServerState theNewState = [[self serverApp] serverState];
				
		// don't do anything if server state is the same
		if(theNewState==[self serverState]) {
			return;
		} else {
			[self setServerState:theNewState];
		}		
		// else update the server state
		[ibStatus setStringValue:[[self serverApp] serverStateAsString]];
		// update the image ball
		if([self serverState]==FLXServerStateStarted) {
			[ibStatusImage setImage:[ibGreenballImage image]];
		} else {
			[ibStatusImage setImage:[ibRedballImage image]];
		}
		// update the "stop" button state
		if([self serverState]==FLXServerStateStarted) {
			// enable stop button
			[ibStopButton setEnabled:YES];
		} else {
			[ibStopButton setEnabled:NO];
			[ibRemoteAccessCheckbox setEnabled:YES];
			[ibPortText setEnabled:YES];
			[ibPortMatrix setEnabled:YES];			
		}
		// updatr the "start" button state
		if([self serverState]==FLXServerStateStopped || [self serverState]==FLXServerStateUnknown  || [self serverState]==FLXServerStateStartingError) {
			[ibStartButton setEnabled:YES];			
		} else {
			[ibStartButton setEnabled:NO];
			[ibRemoteAccessCheckbox setEnabled:NO];
			[ibPortText setEnabled:NO];
			[ibPortMatrix setEnabled:NO];			
		}
	} else {
		[ibStatus setStringValue:@"Server is not installed"];
		[self setServerState:0];
		[ibStopButton setEnabled:NO];
		[ibStartButton setEnabled:NO];
	}		
}

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
	NSString* theScriptPath = [[[[NSBundle bundleForClass:[self class]] executablePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:scriptName];
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
	OSStatus theStatus = AuthorizationExecuteWithPrivileges(theAuthorization,[theScriptPath UTF8String],kAuthorizationFlagDefaults,(char** )theArgs,&thePipe);	
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
// Public methods

-(void)mainViewDidLoad {	
	// start the timer
	[self setTimer:[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timerDidFire:) userInfo:nil repeats:YES]];
}

-(void)timerDidFire:(id)theTimer {
	if([self connection]==nil) {
		NSLog(@"starting connection....");
		[self _startConnection];		
	} else if([[self connection] isValid]==NO) {
		[self setConnection:nil];
		[self _startConnection];
	}
	
	[self _updateStatus];
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
		[self _execute:@"PostgresInstallerApp" withAuthorization:theAuthorization withArguments:[NSArray arrayWithObject:@"install"]];
		AuthorizationFree(theAuthorization,kAuthorizationFlagDefaults);
	}
	[self _startConnection];
}

-(IBAction)doUninstall:(id)sender {
	AuthorizationRef theAuthorization = [self _authorizeUser];
	if(theAuthorization) {
		[self _execute:@"PostgresInstallerApp" withAuthorization:theAuthorization withArguments:[NSArray arrayWithObject:@"uninstall"]];
		AuthorizationFree(theAuthorization,kAuthorizationFlagDefaults);
	}
	
	[self setConnection:nil];
}

@end
