
#import <Cocoa/Cocoa.h>
#import <PGClientKit/PGClientKit.h>
#import <PGServerKit/PGServerKit.h>

#import "LocalConnectionWindowController.h"
#import "RemoteConnectionWindowController.h"
#import "PGSidebarViewController.h"

// notifications
extern NSString* PGClientAddConnectionURL;
extern NSString* PGClientNotificationOpenConnection;
extern NSString* PGClientNotificationCloseConnection;

@interface PGClientApplication : NSObject <NSApplicationDelegate, PGServerDelegate> {
	PGServer* _internalServer;
}

// properties
@property IBOutlet NSWindow* window;
@property IBOutlet NSView* ibGrabberView;
@property IBOutlet LocalConnectionWindowController* ibLocalConnectionWindowController;
@property IBOutlet RemoteConnectionWindowController* ibRemoteConnectionWindowController;
@property IBOutlet PGSidebarViewController* ibSidebarViewController;
@property (readonly) PGServer* internalServer;

// IBActions
-(IBAction)doAddLocalConnection:(id)sender;
-(IBAction)doAddRemoteConnection:(id)sender;

@end
