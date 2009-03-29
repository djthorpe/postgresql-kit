
#import "PostgresDataKit.h"

@implementation FLXPostgresDataObject

////////////////////////////////////////////////////////////////////////////////

@synthesize values;
@synthesize modified;

////////////////////////////////////////////////////////////////////////////////

-(id)init {
	self = [super init];
	if (self != nil) {
		[self setValues:[[NSMutableDictionary alloc] init]];
		[self setModified:NO];
	}
	return self;
}

-(void)dealloc {
	[self setValues:nil];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// methods which need to be overridden

+(NSString* )tableName {
	return nil;
}

+(NSArray* )tableColumns {
	return nil;
}

@end
