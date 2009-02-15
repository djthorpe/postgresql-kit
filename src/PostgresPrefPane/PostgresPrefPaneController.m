
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
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// properties

-(PostgresServerApp* )serverApp {
	return (PostgresServerApp* )[[self connection] rootProxy];
}

-(void)mainViewDidLoad {
	// add in the notification
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(doNotifyStatusChanged:) name:PostgresServerAppNotifyStatusChanged object:nil];
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

////////////////////////////////////////////////////////////////////////////////
// Notifications

-(void)doNotifyStatusChanged:(NSNotification* )theNotification {
	[ibStatus setStringValue:[theNotification object]];
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
		NSLog(@"authorized  - install");
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
