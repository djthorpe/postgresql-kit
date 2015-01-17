
#import "PGSidebarNode.h"

@interface PGSidebarNode (Private)
-(BOOL)_initFromUserDefaults:(NSDictionary* )dictionary;
@end

@implementation PGSidebarNode

////////////////////////////////////////////////////////////////////////////////
// constructors

-(id)init {
	self = [super init];
	if(self) {
		[self setKey:0];
		[self setParentKey:0];
		[self setName:nil];
		_children = [NSMutableArray array];
		_properties = [NSMutableDictionary dictionary];
		_status = PGSidebarNodeStatusGrey;
		_type = PGSidebarNodeTypeGroup;
	}
	return self;
}

-(id)initWithUserDefaults:(NSDictionary* )dictionary {
	NSParameterAssert(dictionary);
	self = [self init];
	if(self) {
		if(![self _initFromUserDefaults:dictionary]) {
			return nil;
		}
	}
	return self;
}

-(id)initAsGroupWithKey:(NSUInteger)theKey name:(NSString* )theName {
	NSParameterAssert(theKey);
	NSParameterAssert(theName);
	self = [self init];
	if(self) {
		_type = PGSidebarNodeTypeGroup;
		[self setName:theName];
		[self setKey:theKey];
	}
	return self;
}

-(id)initAsServerWithKey:(NSUInteger)theKey name:(NSString* )theName {
	NSParameterAssert(theKey);
	NSParameterAssert(theName);
	self = [self init];
	if(self) {
		_type = PGSidebarNodeTypeServer;
		[self setName:theName];
		[self setKey:theKey];
	}
	return self;	
}

-(id)initAsDatabaseWithKey:(NSUInteger)theKey serverKey:(NSUInteger)theServerKey name:(NSString* )theName {
	NSParameterAssert(theKey);
	NSParameterAssert(theServerKey);
	NSParameterAssert(theName);
	self = [self init];
	if(self) {
		_type = PGSidebarNodeTypeDatabase;
		[self setName:theName];
		[self setKey:theKey];
		[self setParentKey:theServerKey];
	}
	return self;
}

-(id)initAsQueryWithKey:(NSUInteger)theKey name:(NSString* )theName {
	self = [self init];
	if(self) {
		_type = PGSidebarNodeTypeQuery;
		[self setName:theName];
		[self setKey:theKey];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize key;
@synthesize parentKey;
@synthesize name;
@synthesize properties = _properties;
@synthesize children = _children;
@synthesize status = _status;
@synthesize type = _type;
@dynamic keyObject;
@dynamic parentKeyObject;
@dynamic URL;

-(NSURL* )URL {
	return [NSURL URLWithString:[_properties objectForKey:@"URL"]];
}

-(void)setURL:(NSURL* )value {
	return [_properties setObject:[value absoluteString] forKey:@"URL"];
}

-(NSNumber* )keyObject {
	return [NSNumber numberWithUnsignedInteger:[self key]];
}

-(NSNumber* )parentKeyObject {
	return [NSNumber numberWithUnsignedInteger:[self parentKey]];
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

-(BOOL)removeChild:(PGSidebarNode *)child {
	if([[self children] containsObject:child]==NO) {
		return NO;
	}
	[[self children] removeObject:child];
	return YES;
}

-(NSString* )description {
	return [NSString stringWithFormat:@"<%@ %lu %@>",NSStringFromClass([self class]),[self key],[self name]];
}

-(NSDictionary* )userDefaults {
	NSMutableDictionary* defaults = [NSMutableDictionary dictionaryWithCapacity:5];
	NSMutableArray* children = [NSMutableArray arrayWithCapacity:[[self children] count]];
	[defaults setObject:[self keyObject] forKey:@"key"];
	[defaults setObject:[self parentKeyObject] forKey:@"parentKey"];
	[defaults setObject:[NSNumber numberWithInt:[self type]] forKey:@"type"];
	[defaults setObject:[self name] forKey:@"name"];
	[defaults setObject:children forKey:@"children"];
	[defaults setObject:[self properties] forKey:@"properties"];
	for(PGSidebarNode* node in [self children]) {
		[children addObject:[node userDefaults]];
	}
	return defaults;
}

-(BOOL)_initFromUserDefaults:(NSDictionary* )dictionary {
	NSParameterAssert(dictionary);
	NSNumber* keyObject = [dictionary objectForKey:@"key"];
	if([keyObject isKindOfClass:[NSNumber class]]==NO) {
		return NO;
	} else {
		[self setKey:[keyObject unsignedIntegerValue]];
	}
	NSNumber* parentKeyObject = [dictionary objectForKey:@"parentKey"];
	if([parentKeyObject isKindOfClass:[NSNumber class]]==NO) {
		return NO;
	} else {
		[self setParentKey:[parentKeyObject unsignedIntegerValue]];
	}
	NSString* theName = [dictionary objectForKey:@"name"];
	if([theName isKindOfClass:[NSString class]]==NO) {
		return NO;
	} else {
		[self setName:theName];
	}
	NSNumber* typeObject = [dictionary objectForKey:@"type"];
	if([typeObject isKindOfClass:[NSNumber class]]==NO) {
		return NO;
	} else {
		_type = [typeObject intValue];
	}
	NSDictionary* dictObject = [dictionary objectForKey:@"properties"];
	if([dictObject isKindOfClass:[NSDictionary class]]==NO) {
		return NO;
	} else {
		[_properties addEntriesFromDictionary:dictObject];
	}
	NSArray* childrenObject = [dictionary objectForKey:@"children"];
	if([childrenObject isKindOfClass:[NSArray class]]==NO) {
		return NO;
	}
	for(NSUInteger i = 0; i < [childrenObject count]; i++) {
		PGSidebarNode* node = [[PGSidebarNode alloc] initWithUserDefaults:[childrenObject objectAtIndex:i]];
		if(node) {
			[[self children] addObject:node];
		} else {
			return NO;
		}
	}
	return YES;
}

@end
