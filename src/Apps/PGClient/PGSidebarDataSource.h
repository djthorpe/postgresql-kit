
#import <Cocoa/Cocoa.h>
#import "PGSidebarNode.h"

@interface PGSidebarDataSource : NSObject <NSOutlineViewDataSource> {
	NSMutableArray* _nodes;
}

// properties
@property (readonly) NSMutableArray* nodes;

// methods
-(void)addServer:(PGSidebarNode* )node;

@end


