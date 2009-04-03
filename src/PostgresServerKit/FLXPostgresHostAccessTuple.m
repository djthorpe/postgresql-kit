
#import "PostgresServerKit.h"

@implementation FLXPostgresHostAccessTuple

////////////////////////////////////////////////////////////////////////////////

@synthesize type;
@synthesize database;
@synthesize user;
@synthesize address;
@synthesize method;
@synthesize option;
@synthesize comment;

////////////////////////////////////////////////////////////////////////////////

-(id)init {
	self = [super init];
	if (self != nil) {
		[self setType:@"local"];
		[self setDatabase:@"all"];
		[self setUser:@"all"];
		[self setAddress:@"127.0.0.1"];
		[self setMethod:@"reject"];
		[self setOption:nil];		
		[self setComment:nil];
	}
	return self;
}

-(void)dealloc {
	[self setType:nil];
	[self setDatabase:nil];
	[self setUser:nil];
	[self setAddress:nil];
	[self setMethod:nil];
	[self setOption:nil];
	[self setComment:nil];
	[super dealloc];
}

-(NSString* )stringValue {
	NSMutableString* theString = [NSMutableString string];
	// add comment line
	if([self comment]) {
		[theString appendFormat:@"# %@\n",[[self comment] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	}
	// add type - local, host, hostssl, hostnossl
	[theString appendString:[[self type] stringByPaddingToLength:10 withString:@" " startingAtIndex:0]];
	[theString appendString:@" "];
	// add database
	[theString appendString:[[self database] stringByPaddingToLength:20 withString:@" " startingAtIndex:0]];
	[theString appendString:@" "];
	// add user
	[theString appendString:[[self user] stringByPaddingToLength:20 withString:@" " startingAtIndex:0]];
	[theString appendString:@" "];
	// add address
	[theString appendString:[[self address] stringByPaddingToLength:20 withString:@" " startingAtIndex:0]];
	[theString appendString:@" "];
	// add method
	[theString appendString:[[self method] stringByPaddingToLength:10 withString:@" " startingAtIndex:0]];
	[theString appendString:@" "];
	if([self option]) {
		// add option
		[theString appendString:[[self option] stringByPaddingToLength:20 withString:@" " startingAtIndex:0]];
	}
	[theString appendString:@"\n"];
	// return the string
	return theString;
}

-(NSString* )description {
	return [self stringValue];
}


////////////////////////////////////////////////////////////////////////////////


@end
