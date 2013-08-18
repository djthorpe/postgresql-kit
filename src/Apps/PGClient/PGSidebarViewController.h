
#import <Cocoa/Cocoa.h>
#import "PGSidebarNode.h"

@interface PGSidebarViewController : NSObject <NSOutlineViewDelegate> {
	NSMutableArray* _nodes;
	PGSidebarNode* _servers;
}

// properties
@property (readonly) NSMutableArray* nodes;
@property (readonly) PGSidebarNode* servers;

// methods
-(void)applicationDidFinishLaunching:(NSNotification* )aNotification;

@end
