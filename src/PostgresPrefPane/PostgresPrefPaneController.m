
#import <Security/Security.h>
#import "PostgresPrefPaneController.h"
#import "PostgresServerApp.h"
#import "PostgresPrefPaneShared.h"

@implementation PostgresPrefPaneController

@synthesize connection;
@synthesize timer;
@synthesize serverState;

const NSTimeInterval PostgresPrefPaneSlowInterval = 5.0;
const NSTimeInterval PostgresPrefPaneFastInterval = 0.5;

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

	if([[self connection] isValid]) {
		// set remote access
		if([[self serverApp] isRemoteAccess]) {
			[ibRemoteAccessCheckbox setState:NSOnState];
		} else {
			[ibRemoteAccessCheckbox setState:NSOffState];			
		}
		[self doRemoteAccessCheckbox:nil];
	}
	
}

-(void)_setServerVersion {
	if([[self connection] isValid]) {
		NSString* serverVersion = [[self serverApp] serverVersion];
		[ibVersionNumber setStringValue:[NSString stringWithFormat:@"Version: %@",serverVersion]];
	} else {
		[ibVersionNumber setStringValue:@""];		
	}
}

-(void)_updateStatusImageReady:(BOOL)isReady {
	if(isReady) {
		[ibStatusImage setImage:[ibGreenballImage image]];
	} else {
		[ibStatusImage setImage:[ibRedballImage image]];
	}		
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
			[self _updateStatusImageReady:YES];
		} else {
			[self _updateStatusImageReady:NO];
		}
		// update the "stop" button state
		if([self serverState]==FLXServerStateStarted) {
			// enable stop button
			[ibStopButton setEnabled:YES];
		} else {
			[ibStopButton setEnabled:NO];
			[ibRemoteAccessCheckbox setEnabled:YES];
		}
		// update the "start" button state
		if([self serverState]==FLXServerStateStopped || [self serverState]==FLXServerStateUnknown  || [self serverState]==FLXServerStateStartingError) {
			[ibStartButton setEnabled:YES];			
			[ibInstallButton setEnabled:NO];
			[ibUninstallButton setEnabled:YES];
		} else {
			[ibStartButton setEnabled:NO];
			[ibRemoteAccessCheckbox setEnabled:NO];
			[ibInstallButton setEnabled:NO];
			[ibUninstallButton setEnabled:NO];
		}
	} else {
		[ibStatus setStringValue:@"Server is not installed"];
		[self setServerState:0];
		[ibStopButton setEnabled:NO];
		[ibStartButton setEnabled:NO];
		[ibInstallButton setEnabled:YES];
		[ibUninstallButton setEnabled:NO];
		[self _updateStatusImageReady:NO];
		[ibRemoteAccessCheckbox setEnabled:NO];
		[self doRemoteAccessCheckbox:nil];
	}		
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

-(void)timerDidFire:(id)theTimer {

	// vary the NSTimer between fast and slow depending on whether there is a connection
	// to the server object or not
	if([self connection]==nil && [[self timer] timeInterval] != PostgresPrefPaneSlowInterval) {			
		NSLog(@"lowering rate of connection to app");
		[[self timer] invalidate];
		[self setTimer:[NSTimer scheduledTimerWithTimeInterval:PostgresPrefPaneSlowInterval target:self selector:@selector(timerDidFire:) userInfo:nil repeats:YES]];
	} else if([[self timer] timeInterval] != PostgresPrefPaneFastInterval) {
		NSLog(@"raising rate of connection to app");
		[[self timer] invalidate];
		[self setTimer:[NSTimer scheduledTimerWithTimeInterval:PostgresPrefPaneFastInterval target:self selector:@selector(timerDidFire:) userInfo:nil repeats:YES]];
	}	

	// create or destroy the connection object
	if([self connection]==nil) {
		NSLog(@"connecting to server app....");
		[self _startConnection];		
		[self _setServerVersion];
	} else if([[self connection] isValid]==NO) {
		NSLog(@"reconnecting to server app....");
		[self setConnection:nil];
		[self _startConnection];
		[self _setServerVersion];
	}

	// update the status
	[self _updateStatus];
}

-(void)mainViewDidLoad {	
	// fire the timer
	[self timerDidFire:nil];
	// set the tab view
	if([self serverState]==0) {
		// set tab to install/uninstall
		[ibTabView selectTabViewItemAtIndex:1];
	} else {
		// set tab to start/stop
		[ibTabView selectTabViewItemAtIndex:0];
	}	
}

////////////////////////////////////////////////////////////////////////////////
// IBActions

-(IBAction)doStartServer:(id)sender {
	// TODO: set server port
	if([ibRemoteAccessCheckbox state]==NSOnState) {
		[[self serverApp] setIsRemoteAccess:YES];
	} else {
		[[self serverApp] setIsRemoteAccess:NO];		
	}
	[[self serverApp] startServer];
}

-(IBAction)doStopServer:(id)sender {
	[[self serverApp] stopServer];
}

-(IBAction)doRemoteAccessCheckbox:(id)sender {
	if([ibRemoteAccessCheckbox state]==NSOnState) {
		[ibPortMatrix setEnabled:YES];
		[ibPortText setEnabled:YES];
	} else {
		[ibPortMatrix setEnabled:NO];
		[ibPortText setEnabled:NO];
	}
}

-(IBAction)doPortMatrix:(id)sender {
	if([ibPortMatrix selectedCell]==ibDefaultPortCheckbox) {
		[ibPortText setStringValue:[NSString stringWithFormat:@"%d",[[self serverApp] defaultServerPort]]];
		[ibPortText setEnabled:NO];
	} else if([ibPortMatrix selectedCell]==ibOtherPortCheckbox) {
		[ibPortText setEnabled:YES];
		if([[ibPortText stringValue] length]==0) {
			[ibPortText setStringValue:[NSString stringWithFormat:@"%d",[[self serverApp] defaultServerPort]]];			
		}
	}
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
