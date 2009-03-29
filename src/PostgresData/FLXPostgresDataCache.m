
#import "PostgresDataKit.h"

static FLXPostgresDataCache* FLXSharedCache = nil;

////////////////////////////////////////////////////////////////////////////////

@implementation FLXPostgresDataCache

@synthesize delegate;
@synthesize connection;
@synthesize context;

////////////////////////////////////////////////////////////////////////////////
// singleton design pattern
// see http://www.cocoadev.com/index.pl?SingletonDesignPattern

+(FLXPostgresDataCache* )sharedCache {
	@synchronized(self) {
		if (FLXSharedCache == nil) {
			[[self alloc] init]; // assignment not done here
		}
	}
	return FLXSharedCache;
}

+(id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
		if (FLXSharedCache == nil) {
			FLXSharedCache = [super allocWithZone:zone];
			return FLXSharedCache;  // assignment and return on first allocation
		}
	}
	return nil; //on subsequent allocation attempts return nil
}

-(id)copyWithZone:(NSZone *)zone {
	return self;
}

-(id)retain {
	return self;
}

-(unsigned)retainCount {
	return UINT_MAX;  //denotes an object that cannot be released
}

-(void)release {
	// do nothing
}

-(id)autorelease {
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// constructor and destructor

-(id)init {
	self = [super init];
	if(self) {
		[self setContext:[[NSMutableDictionary alloc] init]];
	}
	return self;
}

-(void)dealloc {
	[self setDelegate:nil];
	[self setConnection:nil];
	[self setContext:nil];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// get object context for class



-(NSString* )tableNameForClass:(Class)theClass {
	if([theClass isKindOfClass:[FLXPostgresDataObject class]]==NO) {
		return nil;
	}
	return [theClass tableName];
}

-(NSString* )primaryKeyForClass:(Class)theClass {
}

@end
