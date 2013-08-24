
#import "PGSidebarNode.h"

@implementation PGSidebarNode

////////////////////////////////////////////////////////////////////////////////
// constructors

-(id)init {
	self = [super init];
	if(self) {
		_key = 0;
		_name = nil;
		_children = [NSMutableArray array];
		_properties = [NSMutableDictionary dictionary];
		_status = PGSidebarNodeStatusGrey;
		_type = PGSidebarNodeTypeGroup;
	}
	return self;
}

-(id)initAsGroupWithKey:(NSUInteger)key name:(NSString* )name {
	self = [self init];
	if(self) {
		_type = PGSidebarNodeTypeGroup;
		_name = name;
		_key = key;
	}
	return self;
}

-(id)initAsServerWithKey:(NSUInteger)key name:(NSString* )name {
	self = [self init];
	if(self) {
		_type = PGSidebarNodeTypeServer;
		_name = name;
		_key = key;
	}
	return self;	
}

-(id)initAsDatabaseWithKey:(NSUInteger)key name:(NSString* )name {
	self = [self init];
	if(self) {
		_type = PGSidebarNodeTypeDatabase;
		_name = name;
		_key = key;
	}
	return self;
}

-(id)initAsQueryWithKey:(NSUInteger)key name:(NSString* )name {
	self = [self init];
	if(self) {
		_type = PGSidebarNodeTypeQuery;
		_name = name;
		_key = key;
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize key = _key;
@synthesize properties = _properties;
@synthesize children = _children;
@synthesize name = _name;
@synthesize status = _status;
@synthesize type = _type;
@dynamic URL;
@dynamic keyObject;

-(NSURL* )URL {
	return [_properties objectForKey:@"URL"];
}

-(void)setURL:(NSURL* )value {
	return [_properties setObject:value forKey:@"URL"];
}

-(NSNumber* )keyObject {
	return [NSNumber numberWithUnsignedInteger:[self key]];
}

////////////////////////////////////////////////////////////////////////////////
// methods

-(NSInteger)numberOfChildren {
	return [[self children] count];
}

-(PGSidebarNode* )childAtIndex:(NSInteger)index {
	return [[self children] objectAtIndex:index];
}

-(void)addChild:(PGSidebarNode* )child {
	[[self children] addObject:child];
}

-(void)insertChild:(PGSidebarNode* )child atIndex:(NSUInteger)index {
	NSInteger oldIndex = [[self children] indexOfObject:child];
	if(oldIndex >= 0) {
		[[self children] removeObject:child];
	}
	[[self children] insertObject:child atIndex:index];
}

-(BOOL)canContainNode:(PGSidebarNode* )node {
	// only allow groups to contain nodes
	if([self type] != PGSidebarNodeTypeGroup) {
		return NO;
	}
	switch([node type]) {
	case PGSidebarNodeTypeGroup:
		return NO;
	case PGSidebarNodeTypeServer:
		return [self key]==PGSidebarNodeKeyServerGroup;
	case PGSidebarNodeTypeDatabase:
		return [self key]==PGSidebarNodeKeyDatabaseGroup;
	case PGSidebarNodeTypeQuery:
		return [self key]==PGSidebarNodeKeyQueryGroup;
	default:
		return NO;
	}
}

@end
