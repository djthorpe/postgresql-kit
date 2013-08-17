
#import <Cocoa/Cocoa.h>
#import <PGClientKit/PGClientKit.h>
#import <PGClientKit/PGClientKit+Cocoa.h>
#import "SocketWindowController.h"

@interface PGClientApplication : NSObject <NSApplicationDelegate> {
	NSMutableArray* _sidebarNodes;
}

// properties
@property IBOutlet NSWindow* window;
@property IBOutlet NSView* ibGrabberView;
@property IBOutlet SocketWindowController* ibSocketWindowController;

// IBActions
-(IBAction)doAddSocketConnection:(id)sender;

@end
