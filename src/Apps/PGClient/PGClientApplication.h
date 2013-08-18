
#import <Cocoa/Cocoa.h>
#import <PGClientKit/PGClientKit.h>
#import <PGClientKit/PGClientKit+Cocoa.h>

#import "LocalConnectionWindowController.h"
#import "RemoteConnectionWindowController.h"

@interface PGClientApplication : NSObject <NSApplicationDelegate> {
	NSMutableArray* _sidebarNodes;
}

// properties
@property IBOutlet NSWindow* window;
@property IBOutlet NSView* ibGrabberView;
@property IBOutlet LocalConnectionWindowController* ibLocalConnectionWindowController;
@property IBOutlet RemoteConnectionWindowController* ibRemoteConnectionWindowController;

// IBActions
-(IBAction)doAddLocalConnection:(id)sender;
-(IBAction)doAddRemoteConnection:(id)sender;

@end
