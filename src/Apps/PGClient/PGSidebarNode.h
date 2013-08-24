
#import <Cocoa/Cocoa.h>

// Enum for the status of the node
typedef enum {
	PGSidebarNodeStatusGrey,
	PGSidebarNodeStatusGreen,
	PGSidebarNodeStatusOrange,
	PGSidebarNodeStatusRed
} PGSidebarNodeStatusType;

// Enum for the type of the node
typedef enum {
	PGSidebarNodeTypeGroup,
	PGSidebarNodeTypeServer,
	PGSidebarNodeTypeDatabase,
	PGSidebarNodeTypeQuery
} PGSidebarNodeTypeType;

// Enum for the key of the node
typedef enum {
	PGSidebarNodeKeyServerGroup = 0,
	PGSidebarNodeKeyDatabaseGroup = 1,
	PGSidebarNodeKeyQueryGroup = 2,
	PGSidebarNodeKeyInternalServer = 3,
	PGSidebarNodeKeyMaximum = 4
} PGSidebarNodeKeyType;

@interface PGSidebarNode : NSObject {
	NSUInteger _key;
	NSString* _name;
	PGSidebarNodeStatusType _status;
	PGSidebarNodeTypeType _type;
	NSMutableArray* _children;
	NSMutableDictionary* _properties;
}

// constructor
-(id)initAsGroupWithKey:(NSUInteger)key name:(NSString* )name;
-(id)initAsServerWithKey:(NSUInteger)key name:(NSString* )name;
-(id)initAsDatabaseWithKey:(NSUInteger)key name:(NSString* )name;
-(id)initAsQueryWithKey:(NSUInteger)key name:(NSString* )name;

// properties
@property NSUInteger key;
@property (readonly) NSNumber* keyObject;
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
-(void)insertChild:(PGSidebarNode* )child atIndex:(NSUInteger)index;
-(BOOL)canContainNode:(PGSidebarNode* )node;
-(BOOL)removeChild:(PGSidebarNode* )child;

@end
