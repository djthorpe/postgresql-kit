
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
extern NSString* PGClientNotificationServerStatusChange;

@interface PGClientApplication : NSObject <NSApplicationDelegate, PGServerDelegate> {
	PGServer* _internalServer;
	PGConnectionController* _connections;
	BOOL _terminationRequested;
}

// properties
@property (assign) IBOutlet NSWindow* window;
@property (assign) IBOutlet NSView* ibGrabberView;
@property (assign) IBOutlet NSTabView* ibTabView;
@property (assign) IBOutlet LocalConnectionWindowController* ibLocalConnectionWindowController;
@property (assign) IBOutlet RemoteConnectionWindowController* ibRemoteConnectionWindowController;
@property (assign) IBOutlet PGSidebarViewController* ibSidebarViewController;
@property (readonly) PGConnectionController* connections;
@property (readonly) PGServer* internalServer;
@property BOOL terminationRequested;

// IBActions
-(IBAction)doAddLocalConnection:(id)sender;
-(IBAction)doAddRemoteConnection:(id)sender;

@end
