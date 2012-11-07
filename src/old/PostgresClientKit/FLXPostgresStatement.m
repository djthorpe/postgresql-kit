
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

////////////////////////////////////////////////////////////////////////////////
/*
-(void)_parseQueryForTypes:(NSObject* )theQuery {
	NSParameterAssert(theQuery);
	NSParameterAssert([theQuery isKindOfClass:[NSString class]] || [theQuery isKindOfClass:[FLXPostgresStatement class]]);
	
	// get statement
	NSString* theStatement = nil;
	if([theQuery isKindOfClass:[NSString class]]) {
		theStatement = (NSString* )theQuery;
	} else if([theQuery isKindOfClass:[FLXPostgresStatement class]]) {
		theStatement = [(FLXPostgresStatement* )theQuery statement];
	}
	
	// parse statement
	NSScanner* theScanner = [NSScanner scannerWithString:theStatement];
	NSParameterAssert(theScanner);
	enum { State0,StateQuote } theState = State0;
	while([theScanner isAtEnd]==NO) {
		// TODO
		// skip until we reach quote ' or parameter $
	}
	
}
*/

@end
