
#import <Cocoa/Cocoa.h>
#import <PGClientKit/PGClientKit.h>
#import <PGServerKit/PGServerKit.h>

#import "LocalConnectionWindowController.h"
#import "RemoteConnectionWindowController.h"
#import "PGSidebarViewController.h"
#import "PGConnectionController.h"

// notifications
extern NSString* PGClientAddConnectionURL;
extern NSString* PGClientNotificationOpenConnection;
extern NSString* PGClientNotificationCloseConnection;
extern NSString* PGClientNotificationDeleteConnection;

@interface PGClientApplication : NSObject <NSApplicationDelegate, PGServerDelegate> {
	PGServer* _internalServer;
	PGConnectionController* _connections;
	BOOL _terminationRequested;
}

// properties
@property IBOutlet NSWindow* window;
@property IBOutlet NSView* ibGrabberView;
@property IBOutlet LocalConnectionWindowController* ibLocalConnectionWindowController;
@property IBOutlet RemoteConnectionWindowController* ibRemoteConnectionWindowController;
@property IBOutlet PGSidebarViewController* ibSidebarViewController;
@property (readonly) PGConnectionController* connections;
@property (readonly) PGServer* internalServer;
@property BOOL terminationRequested;

// IBActions
-(IBAction)doAddLocalConnection:(id)sender;
-(IBAction)doAddRemoteConnection:(id)sender;

@end
