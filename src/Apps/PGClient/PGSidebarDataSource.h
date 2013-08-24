
#import <Cocoa/Cocoa.h>
#import "PGSidebarNode.h"

extern NSString* PGSidebarDragType;

@interface PGSidebarDataSource : NSObject <NSOutlineViewDataSource> {
	NSMutableArray* _nodes;
	NSMutableDictionary* _keys;
	NSUInteger _nextkey;
}

// properties
@property (readonly) NSArray* groups;

// methods
-(NSUInteger)nextKey;
-(PGSidebarNode* )nodeForKey:(NSUInteger)key;
-(BOOL)addGroup:(PGSidebarNode* )node;
-(BOOL)addServer:(PGSidebarNode* )node;
-(BOOL)addDatabase:(PGSidebarNode* )node;
-(BOOL)addQuery:(PGSidebarNode* )node;
-(BOOL)deleteNode:(PGSidebarNode* )node;

@end


