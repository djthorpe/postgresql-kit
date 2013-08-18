
#import <Cocoa/Cocoa.h>
#import "PGSidebarNode.h"

@interface PGSidebarViewController : NSObject <NSOutlineViewDelegate> {
	NSMutableArray* _nodes;
	PGSidebarNode* _servers;
	PGSidebarNode* _selectedNode;
}

// properties
@property (readonly) NSMutableArray* nodes;
@property (readonly) PGSidebarNode* servers;
@property (readonly) PGSidebarNode* selectedNode;

// methods
-(void)applicationDidFinishLaunching:(NSNotification* )aNotification;

// ibactions
-(IBAction)doOpen:(id)sender;
-(IBAction)doClose:(id)sender;

@end
