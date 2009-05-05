
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"

@implementation FLXPostgresStatement

@synthesize name;
@synthesize statement;

-(id)initWithStatement:(NSString* )theStatement {
	NSParameterAssert(theStatement);
	self = [super init];
	if (self != nil) {
		[self setStatement:theStatement];
		[self setName:nil];
	}
	return self;
}

-(void)dealloc {
	[self setName:nil];
	[self setStatement:nil];
	[super dealloc];
}

-(const char* )UTF8Name {
	return [[self name] UTF8String];
}

-(const char* )UTF8Statement {
	return [[self statement] UTF8String];	
}

-(NSString* )description {
	if([self name]) {
		return [NSString stringWithFormat:@"<FLXPostgresStatement %@>",[self name]];
	} else {
		return [NSString stringWithFormat:@"<FLXPostgresStatement>"];
	}		
}

@end
