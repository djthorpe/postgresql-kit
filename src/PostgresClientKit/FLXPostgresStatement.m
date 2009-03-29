
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

@end
