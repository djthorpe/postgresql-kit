
#import <Security/Security.h>
#import "PostgresPrefPaneController.h"
#import "PostgresPrefPaneServerApp.h"
#import "PostgresPrefPaneShared.h"

@implementation PostgresPrefPaneController

@synthesize connection;

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)initWithBundle:(NSBundle *)bundle {
	self = [super initWithBundle:bundle];
    if(self) {
		[self setConnection:[NSConnection connectionWithRegisteredName:PostgresPrefPaneServerAppIdentifier host:nil]];
	}
	return self;
}

-(void)dealloc {
	[self setConnection:nil];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// properties

-(PostgresPrefPaneServerApp* )serverApp {
	return (PostgresPrefPaneServerApp* )[[self connection] rootProxy];
}

-(void)mainViewDidLoad {
	NSLog(@"loaded view, state = %d",[[self serverApp] serverState]);
}

////////////////////////////////////////////////////////////////////////////////

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
