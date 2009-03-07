
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
	[bindings setBindDiskUsage:[NSString stringWithFormat:@"Data volume: %@ free (%u%% full)",[[self serverApp] dataSpaceFreeAsString],100 - [[self serverApp] dataSpaceFreeAsPercent]]];
}

-(void)_updateVersion {
	[bindings setBindServerVersion:[NSString stringWithFormat:@"Version: %@",[[self serverApp] serverVersion]]];	
}

-(void)_updateSettingsFromServer {	
	// set remote access checkbox, and port, etc from server app settings
	[bindings setBindIsRemoteAccess:[[self serverApp] isRemoteAccess]];
	[bindings setBindServerPort:[[self serverApp] serverPort]];
	[bindings setBindServerPortMinValue:1];
	[bindings setBindServerPortMaxValue:65535];
	[bindings setBindIsBackupEnabled:[[self serverApp] isBackupEnabled]];
	[bindings setBackupIntervalTagFromInterval:[[self serverApp] backupTimeInterval]];
	[bindings setBackupFreeSpaceTagFromPercent:[[self serverApp] backupFreeSpacePercent]];
}

-(void)_updatePasswordStatus {	
	// update label for password
	if([self serverState]==FLXServerStateStarted) {
		if([[self serverApp] hasSuperuserPassword]) {
			[bindings setBindPasswordMessage:@"Change the existing administative password"];
		} else {
			[bindings setBindPasswordMessage:@"Add a new administrative password"];			
		}
	} else {
		[bindings setBindPasswordMessage:@"Start the server to set administative password"];
	}	
}

-(void)_updateStatus {
	if([[self connection] isValid]==NO) {
		[bindings setBindServerStatus:@"Server is not installed"];
		[bindings setBindServerStatusImage:[self _statusImageForState:0]];
		[self setServerState:0];		
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
		[bindings setBindStopButtonEnabled:YES];
		[bindings setBindPasswordButtonEnabled:YES];
	} else {
		[bindings setBindStopButtonEnabled:NO];
		[bindings setBindPasswordButtonEnabled:NO];
	}

	// update password text
	[self _updatePasswordStatus];
	
	// update the isremoteaccess dialog
	if([self serverState]==FLXServerStateStopped || [self serverState]==FLXServerStateUnknown  || [self serverState]==FLXServerStateStartingError) {
		[bindings setBindIsRemoteAccessEnabled:YES];
	} else {
		[bindings setBindIsRemoteAccessEnabled:NO];
	}
	
	// update the "install" and "uninstall" button states
	if([self serverState]==FLXServerStateStopped || [self serverState]==FLXServerStateUnknown  || [self serverState]==FLXServerStateStartingError) {
		[bindings setBindStartButtonEnabled:YES];
		[bindings setBindInstallButtonEnabled:NO];
		[bindings setBindUninstallButtonEnabled:YES];
	} else {
		[bindings setBindStartButtonEnabled:NO];
		[bindings setBindInstallButtonEnabled:NO];
		[bindings setBindUninstallButtonEnabled:NO];
	}
}

-(void)_startConnection {
	[self setConnection:[NSConnection connectionWithRegisteredName:PostgresServerAppIdentifier host:nil]];
	if([[self connection] isValid]) {
		[self _updateSettingsFromServer];
		[self _updateDiskUsage];
		[self _updateVersion];
	} else {
		[bindings setBindServerVersion:@""];	
		[bindings setBindDiskUsage:@""];
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

-(void)_closePreferencePane {
	// discover the 'show all' item
	for(NSToolbarItem* theItem in [[[[self mainView] window] toolbar] items]) {
		NSString* theSelector = NSStringFromSelector([theItem action]);
		if([theSelector isEqual:@"showAllMenuAction:"]) {
			// perform selector
			[[theItem target] performSelector:[theItem action]];
		}
	}
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
		[[self timer] invalidate];
		[self setTimer:[NSTimer scheduledTimerWithTimeInterval:PostgresPrefPaneSlowInterval target:self selector:@selector(timerDidFire:) userInfo:nil repeats:YES]];
	} else if([self connection] && [self serverState] != FLXServerStateStarted && [self serverState] != FLXServerStateStopped && [[self timer] timeInterval] != PostgresPrefPaneFastInterval) {
		[[self timer] invalidate];
		[self setTimer:[NSTimer scheduledTimerWithTimeInterval:PostgresPrefPaneFastInterval target:self selector:@selector(timerDidFire:) userInfo:nil repeats:YES]];
	}	

	// update the status if this method was called by timer
	if(theTimer != nil) {
		[self _updateStatus];
	}
}

-(void)mainViewDidLoad {	
	// key-value observing
	[bindings addObserver:self forKeyPath:@"bindIsRemoteAccess" options:NSKeyValueObservingOptionNew context:nil];
	[bindings addObserver:self forKeyPath:@"bindIsRemoteAccessEnabled" options:NSKeyValueObservingOptionNew context:nil];
	[bindings addObserver:self forKeyPath:@"bindPortMatrixEnabled" options:NSKeyValueObservingOptionNew context:nil];
	[bindings addObserver:self forKeyPath:@"bindPortMatrixIndex" options:NSKeyValueObservingOptionNew context:nil];
	[bindings addObserver:self forKeyPath:@"bindServerPort" options:NSKeyValueObservingOptionNew context:nil];
	[bindings addObserver:self forKeyPath:@"bindServerPortEnabled" options:NSKeyValueObservingOptionNew context:nil];
	[bindings addObserver:self forKeyPath:@"bindIsBackupEnabled" options:NSKeyValueObservingOptionNew context:nil];
	[bindings addObserver:self forKeyPath:@"bindBackupIntervalTag" options:NSKeyValueObservingOptionNew context:nil];
	[bindings addObserver:self forKeyPath:@"bindBackupFreeSpaceTag" options:NSKeyValueObservingOptionNew context:nil];
	[bindings addObserver:self forKeyPath:@"bindNewPassword" options:NSKeyValueObservingOptionNew context:nil];
	[bindings addObserver:self forKeyPath:@"bindNewPassword2" options:NSKeyValueObservingOptionNew context:nil];
}

-(void)didSelect {
	// set state to minus one - so that status is always updated
	[self setServerState:-1];
	
	// fire the timer - will connect to remote application, set up the timer, etc.
	[self timerDidFire:nil];
	
	// notification center obsevrer	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionDidDie:) name:NSConnectionDidDieNotification object:nil];
	
	// update settings & status
	[self _updateSettingsFromServer];
	[self _updateStatus];
	
	// if server needs installed, show sheet
	if([self serverState]==0) {
		[NSApp beginSheet:ibInstallSheet modalForWindow:[[self mainView] window] modalDelegate:self didEndSelector:@selector(installSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
	}	
}

-(void)didUnselect {
	// stop the timer
	[[self timer] invalidate];
	[self setTimer:nil];
	// stop the connection
	[self setConnection:nil];
	// remove notification
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

////////////////////////////////////////////////////////////////////////////////
// Observe when connection dies

-(void)connectionDidDie:(NSNotification* )theNotification {
	// connection died, try to start again
	[self _startConnection];
}

////////////////////////////////////////////////////////////////////////////////
// Sheeets ended

-(void)passwordSheetDidEnd:(NSWindow *)theSheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	[theSheet orderOut:self];

	if(returnCode != NSOKButton) {
		return;
	}	
	if([bindings newPassword]==nil || [bindings existingPassword]==nil) {
		return;
	}	
	BOOL isSuccess = [[self serverApp] setSuperuserPassword:[bindings newPassword] existingPassword:[bindings existingPassword]];
	if(isSuccess) {
		[bindings setBindPasswordMessage:@"Password has been changed"];
	} else {
		[bindings setBindPasswordMessage:@"Password not set, an error occured"];
	}
}

-(void)installSheetDidEnd:(NSWindow *)theSheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	[theSheet orderOut:self];
	if(returnCode==NSOKButton) {		
		AuthorizationRef theAuthorization = [self _authorizeUser];
		if(theAuthorization) {
			[self _execute:@"PostgresInstallerApp" withAuthorization:theAuthorization withArguments:[NSArray arrayWithObject:@"install"]];
			AuthorizationFree(theAuthorization,kAuthorizationFlagDefaults);
		}
		[self _startConnection];
	} else {
		[self _closePreferencePane];
	}
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
			[bindings setBindBackupIntervalEnabled:YES];
			[bindings setBindBackupFreeSpaceEnabled:YES];
		} else {
			[bindings setBindBackupIntervalEnabled:NO];
			[bindings setBindBackupFreeSpaceEnabled:NO];
		}
	}
	if([keyPath isEqualTo:@"bindBackupIntervalTag"]) {
		NSTimeInterval theInterval = [bindings backupTimeIntervalFromTag];
		if(theInterval) {
			[[self serverApp] setBackupTimeInterval:theInterval];
		}
	}
	if([keyPath isEqualTo:@"bindBackupFreeSpaceTag"]) {
		[[self serverApp] setBackupFreeSpacePercent:[bindings backupFreeSpacePercentFromTag]];
	}
	if([keyPath isEqualTo:@"bindNewPassword"] || [keyPath isEqualTo:@"bindNewPassword2"]) {
		if([bindings newPassword] != nil) {
			[bindings setBindPasswordButtonEnabled:YES];
		} else {
			[bindings setBindPasswordButtonEnabled:NO];			
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

-(IBAction)doInstallEndSheet:(id)sender {
	NSButton* theButton = (NSButton* )sender;
	NSInteger returnCode = NSCancelButton;
	if([theButton isKindOfClass:[NSButton class]] && [[theButton title] isEqual:@"Install"]) {
		returnCode = NSOKButton;
	}
	[NSApp endSheet:ibInstallSheet returnCode:returnCode];
}

-(IBAction)doUninstall:(id)sender {
	AuthorizationRef theAuthorization = [self _authorizeUser];
	if(theAuthorization) {
		[self _execute:@"PostgresInstallerApp" withAuthorization:theAuthorization withArguments:[NSArray arrayWithObject:@"uninstall"]];
		AuthorizationFree(theAuthorization,kAuthorizationFlagDefaults);
	}	
	[self _closePreferencePane];
}

-(IBAction)doPassword:(id)sender {
	// set new password values to empty
	[bindings setBindExistingPassword:@""];
	[bindings setBindNewPassword:@""];
	[bindings setBindNewPassword2:@""];	
	// set focus on the current password
	[ibPasswordSheet makeFirstResponder:[ibPasswordSheet initialFirstResponder]];
	// open up the sheet for changing the password
	[NSApp beginSheet:ibPasswordSheet modalForWindow:[[self mainView] window] modalDelegate:self didEndSelector:@selector(passwordSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction)doPasswordEndSheet:(id)sender {
	NSButton* theButton = (NSButton* )sender;
	NSInteger returnCode = NSCancelButton;
	if([theButton isKindOfClass:[NSButton class]] && [[theButton title] isEqual:@"OK"]) {
		returnCode = NSOKButton;
	}
	[NSApp endSheet:ibPasswordSheet returnCode:returnCode];
}
 

@end
