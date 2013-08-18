
#import <Cocoa/Cocoa.h>
#import <PGClientKit/PGClientKit.h>
#import <PGServerKit/PGServerKit.h>

#import "LocalConnectionWindowController.h"
#import "RemoteConnectionWindowController.h"
#import "PGSidebarViewController.h"

// notifications
extern NSString* PGClientAddConnectionURL;

@interface PGClientApplication : NSObject <NSApplicationDelegate> {
	NSMutableArray* _sidebarNodes;
}

// properties
@property IBOutlet NSWindow* window;
@property IBOutlet NSView* ibGrabberView;
@property IBOutlet LocalConnectionWindowController* ibLocalConnectionWindowController;
@property IBOutlet RemoteConnectionWindowController* ibRemoteConnectionWindowController;
@property IBOutlet PGSidebarViewController* ibSidebarViewController;

// IBActions
-(IBAction)doAddLocalConnection:(id)sender;
-(IBAction)doAddRemoteConnection:(id)sender;

@end
