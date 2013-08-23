
#import <Cocoa/Cocoa.h>

typedef enum {
	PGSidebarNodeStatusGrey,
	PGSidebarNodeStatusGreen,
	PGSidebarNodeStatusOrange,
	PGSidebarNodeStatusRed
} PGSidebarNodeStatusType;

typedef enum {
	PGSidebarNodeTypeGroup,
	PGSidebarNodeTypeServer,
	PGSidebarNodeTypeDatabase,
	PGSidebarNodeTypeQuery
} PGSidebarNodeTypeType;

@interface PGSidebarNode : NSObject {
	NSString* _name;
	PGSidebarNodeStatusType _status;
	PGSidebarNodeTypeType _type;
	NSMutableArray* _children;
	NSMutableDictionary* _properties;
}

// constructor
-(id)initAsGroup:(NSString* )name;
-(id)initAsServer:(NSString* )name;
-(id)initAsDatabase:(NSString* )name;
-(id)initAsQuery:(NSString* )name;

// properties
@property NSString* name;
@property PGSidebarNodeStatusType status;
@property PGSidebarNodeTypeType type;
@property (readonly) NSMutableArray* children;
@property (readonly) NSMutableDictionary* properties;
@property NSURL* URL;

// methods
-(NSInteger)numberOfChildren;
-(PGSidebarNode* )childAtIndex:(NSInteger)index;
-(void)addChild:(PGSidebarNode* )child;

@end
