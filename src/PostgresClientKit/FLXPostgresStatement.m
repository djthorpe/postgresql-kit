
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"

@implementation FLXPostgresStatement

@synthesize name;

-(id)initWithName:(NSString* )theName {
	NSParameterAssert(theName);
	self = [super init];
	if (self != nil) {
		[self setName:theName];
	}
	return self;
}

-(void)dealloc {
	[self setName:nil];
	[super dealloc];
}

-(const char* )UTF8String {
	return [[self name] UTF8String];
}

-(NSString* )description {
	return [NSString stringWithFormat:@"<FLXPostgresStatement %@>",[self name]];
}

@end
