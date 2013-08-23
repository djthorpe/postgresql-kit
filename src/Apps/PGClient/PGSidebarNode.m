
#import "PGSidebarNode.h"

@implementation PGSidebarNode

////////////////////////////////////////////////////////////////////////////////
// constructors

-(id)init {
	self = [super init];
	if(self) {
		_name = nil;
		_children = [NSMutableArray array];
		_properties = [NSMutableDictionary dictionary];
		_status = PGSidebarNodeStatusGrey;
		_type = PGSidebarNodeTypeGroup;
	}
	return self;
}

-(id)initAsGroup:(NSString* )name {
	self = [self init];
	if(self) {
		_type = PGSidebarNodeTypeGroup;
		_name = name;
	}
	return self;
}
-(id)initAsServer:(NSString* )name {
	self = [self init];
	if(self) {
		_type = PGSidebarNodeTypeServer;
		_name = name;
	}
	return self;	
}
-(id)initAsDatabase:(NSString* )name {
	self = [self init];
	if(self) {
		_type = PGSidebarNodeTypeDatabase;
		_name = name;
	}
	return self;
}
-(id)initAsQuery:(NSString* )name {
	self = [self init];
	if(self) {
		_type = PGSidebarNodeTypeQuery;
		_name = name;
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize properties = _properties;
@synthesize children = _children;
@synthesize name = _name;
@synthesize status = _status;
@synthesize type = _type;
@dynamic URL;

-(NSURL* )URL {
	return [_properties objectForKey:@"URL"];
}

-(void)setURL:(NSURL* )value {
	return [_properties setObject:value forKey:@"URL"];
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

@end
