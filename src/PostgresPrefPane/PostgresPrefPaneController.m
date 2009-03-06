
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

-(void)dealloc {
	// invalidate timer
	[[self timer] invalidate];
	// release objects
	[self setTimer:nil];
	[self setConnection:nil];
	// subclass deallocate
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
		[bindings setBindIsRemoteAccess:[[self serverApp] isRemoteAccess]];
		[bindings setBindServerVersion:[[self serverApp] serverVersion]];
		[bindings setBindServerPort:[[self serverApp] serverPort]];
	} else {
		[bindings setBindServerVersion:@""];		
	}
}

-(NSImage* )_statusImageForState:(FLXServerState)theState {
	NSString* thePath = nil;
	if(theState==FLXServerStateStarted) {
		thePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"green" ofType:@"tiff"];
	} else if(theState==0 || theState==FLXServerStateStopped || theState==FLXServerStateUnknown || theState==FLXServerStateStartingError)  {
		thePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"red" ofType:@"tiff"];		
	} else {
		thePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"yellow" ofType:@"tiff"];				
	}
	return [[[NSImage alloc] initWithContentsOfFile:thePath] autorelease];
}

-(void)_updateDiskUsage {
	[bindings setBindDiskUsage:[NSString stringWithFormat:@"%@ free",[[self serverApp] dataSpaceFreeAsString]]];
}

-(void)_updateStatus {
	if([[self connection] isValid]==NO) {
		[bindings setBindServerStatus:@"Server is not installed"];
		[bindings setBindServerStatusImage:[self _statusImageForState:0]];
		[self setServerState:0];
		
		// update start/stop dialog
		[bindings setBindIsRemoteAccessEnabled:NO];
		[bindings setBindIsRemoteAccess:NO];

		// update install/uninstall buttons
		[ibInstallButton setEnabled:YES];
		[ibUninstallButton setEnabled:NO];

		// return 
		return;
	}
		
	// don't do anything if server state is the same
	FLXServerState theNewState = [[self serverApp] serverState];
	if(theNewState==[self serverState]) return;
	
	// update the server state
	[self setServerState:theNewState];
	[bindings setBindServerStatus:[[self serverApp] serverStateAsString]];
	[bindings setBindServerStatusImage:[self _statusImageForState:theNewState]];
	
	// update the "stop" button state
	if([self serverState]==FLXServerStateStarted) {
		[ibStopButton setEnabled:YES];		
	} else {
		[ibStopButton setEnabled:NO];		
	}
	
	// update the isremoteaccess dialog
	if([self serverState]==FLXServerStateStopped || [self serverState]==FLXServerStateUnknown  || [self serverState]==FLXServerStateStartingError) {
		[bindings setBindIsRemoteAccessEnabled:YES];
	} else {
		[bindings setBindIsRemoteAccessEnabled:NO];
	}
	
	// update the "install" and "uninstall" button states
	if([self serverState]==FLXServerStateStopped || [self serverState]==FLXServerStateUnknown  || [self serverState]==FLXServerStateStartingError) {
		[ibStartButton setEnabled:YES];			
		[ibInstallButton setEnabled:NO];
		[ibUninstallButton setEnabled:YES];
	} else {
		[ibStartButton setEnabled:NO];
		[ibInstallButton setEnabled:NO];
		[ibUninstallButton setEnabled:NO];
	}
	
	// update disk usage
	[self _updateDiskUsage];
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

	// connect to remote server app if not connected
	if([self connection]==nil || [[self connection] isValid]==NO) {
		[self _startConnection];		
	}
	
	// vary the NSTimer between fast and slow depending on whether there is a connection
	// to the server object or not, and we are in middle or starting or stopping
	if(([self connection]==nil || [self serverState]==FLXServerStateStarted || [self serverState]==FLXServerStateStopped)  && [[self timer] timeInterval] != PostgresPrefPaneSlowInterval) {			
		NSLog(@"lowering rate of connection to app");
		[[self timer] invalidate];
		[self setTimer:[NSTimer scheduledTimerWithTimeInterval:PostgresPrefPaneSlowInterval target:self selector:@selector(timerDidFire:) userInfo:nil repeats:YES]];
	} 
	
	if([self connection] && [self serverState] != FLXServerStateStarted && [self serverState] != FLXServerStateStopped && [[self timer] timeInterval] != PostgresPrefPaneFastInterval) {
		NSLog(@"raising rate of connection to app");
		[[self timer] invalidate];
		[self setTimer:[NSTimer scheduledTimerWithTimeInterval:PostgresPrefPaneFastInterval target:self selector:@selector(timerDidFire:) userInfo:nil repeats:YES]];
	}	

	// update the status if this method was called by timer
	if(theTimer != nil) {
		[self _updateStatus];
	}
}

-(void)mainViewDidLoad {
	// set state to minus one - so that status is always updated
	[self setServerState:-1];
	
	// fire the timer - will connect to remote application, set up the timer, etc.
	[self timerDidFire:nil];

	// key-value observing
	[bindings addObserver:self forKeyPath:@"bindIsRemoteAccess" options:NSKeyValueObservingOptionNew context:nil];
	[bindings addObserver:self forKeyPath:@"bindIsRemoteAccessEnabled" options:NSKeyValueObservingOptionNew context:nil];
	[bindings addObserver:self forKeyPath:@"bindPortMatrixEnabled" options:NSKeyValueObservingOptionNew context:nil];
	[bindings addObserver:self forKeyPath:@"bindPortMatrixIndex" options:NSKeyValueObservingOptionNew context:nil];
	[bindings addObserver:self forKeyPath:@"bindServerPort" options:NSKeyValueObservingOptionNew context:nil];
	[bindings addObserver:self forKeyPath:@"bindServerPortEnabled" options:NSKeyValueObservingOptionNew context:nil];
	[bindings addObserver:self forKeyPath:@"bindIsBackupEnabled" options:NSKeyValueObservingOptionNew context:nil];

	// set remote access checkbox, and port
	[bindings setBindIsRemoteAccess:[[self serverApp] isRemoteAccess]];
	[bindings setBindServerPort:[[self serverApp] serverPort]];
	[bindings setBindServerPortMinValue:1];
	[bindings setBindServerPortMaxValue:65535];
	[bindings setBindIsBackupEnabled:[[self serverApp] isBackupEnabled]];
	
	// set the tab view
	if([self serverState]==0) {
		// set tab to install/uninstall
		[bindings setBindTabViewIndex:1];
	} else {
		// set tab to start/stop
		[bindings setBindTabViewIndex:0];
	}	
		
	// update status
	[self _updateStatus];
}

////////////////////////////////////////////////////////////////////////////////
// Observe changes to UI, and update the UI
	
-(void)observeValueForKeyPath:(NSString* )keyPath ofObject:(id)object change:(NSDictionary* )change context:(void* )context {
	if([keyPath isEqualTo:@"bindIsRemoteAccess"] || [keyPath isEqualTo:@"bindIsRemoteAccessEnabled"]) {
		if([bindings bindIsRemoteAccess] && [bindings bindIsRemoteAccessEnabled]) {
			[bindings setBindPortMatrixEnabled:YES];			
		} else {			
			[bindings setBindPortMatrixEnabled:NO];
		}		
	}
	if([keyPath isEqualTo:@"bindPortMatrixIndex"] || [keyPath isEqualTo:@"bindPortMatrixEnabled"]) {
		if([bindings bindPortMatrixEnabled]==NO) {
			[bindings setBindServerPortEnabled:NO];			
		} else if([bindings bindPortMatrixIndex]==0) { // use default port
			[bindings setBindServerPortEnabled:NO];
			[bindings setBindServerPort:[[self serverApp] defaultServerPort]];
		} else { // use custom port
			[bindings setBindServerPortEnabled:YES];
		}		
	}
	if([keyPath isEqualTo:@"bindIsBackupEnabled"]) {
		[[self serverApp] setIsBackupEnabled:[bindings bindIsBackupEnabled]];	
		if([bindings bindIsBackupEnabled]) {
			[[self serverApp] fireBackupCycle];
		}
	}
}
	
////////////////////////////////////////////////////////////////////////////////
// IBActions

-(IBAction)doStartServer:(id)sender {
	[[self serverApp] setIsRemoteAccess:[bindings bindIsRemoteAccess]];
	[[self serverApp] setServerPort:[bindings bindServerPort]];
	[[self serverApp] startServer];
	// 'starting'
	[self setServerState:FLXServerStateStarting];
	[self timerDidFire:nil];
}

-(IBAction)doStopServer:(id)sender {
	[[self serverApp] stopServer];
	// 'stopping'
	[self setServerState:FLXServerStateStopping];
	[self timerDidFire:nil];
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
