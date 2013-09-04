
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
	PGSidebarNodeKeyServerGroup = 1,
	PGSidebarNodeKeyDatabaseGroup = 2,
	PGSidebarNodeKeyQueryGroup = 3,
	PGSidebarNodeKeyInternalServer = 4,
	PGSidebarNodeKeyMaximum = 5
} PGSidebarNodeKeyType;

@interface PGSidebarNode : NSObject {
	PGSidebarNodeStatusType _status;
	PGSidebarNodeTypeType _type;
	NSMutableArray* _children;
	NSMutableDictionary* _properties;
}

// constructor
-(id)initAsGroupWithKey:(NSUInteger)key name:(NSString* )name;
-(id)initAsServerWithKey:(NSUInteger)key name:(NSString* )name;
-(id)initAsDatabaseWithKey:(NSUInteger)theKey serverKey:(NSUInteger)theServerKey name:(NSString* )name;
-(id)initAsQueryWithKey:(NSUInteger)key name:(NSString* )name;
-(id)initWithUserDefaults:(NSDictionary* )dictionary;

// properties
@property NSUInteger key;
@property NSUInteger parentKey;
@property NSString* name;
@property (readonly) NSNumber* keyObject;
@property (readonly) NSNumber* parentKeyObject;
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

// user defaults
-(NSDictionary* )userDefaults;

@end
