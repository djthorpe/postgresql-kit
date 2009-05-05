
#import "Application.h"
#import <PostgresClientKit/PostgresClientKit.h>


@implementation Application
@synthesize connection;

-(id)initWithURL:(NSURL* )theURL {
	self = [super init];
	if (self != nil) {
		FLXPostgresConnection* theConnection = [FLXPostgresConnection connectionWithURL:theURL];
		if(theConnection==nil) {
			[self release];
			return nil;
		}
		[theConnection setDelegate:self];
		[self setConnection:theConnection];
	}
	return self;
}

-(void)dealloc {
	[self setConnection:nil];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////

-(void)doWork {
	NSString* theSchema = @"public";
	NSString* theTable = @"test";
	NSUInteger numberOfRows = 1000;
	NSArray* thePostgresTypes = [NSArray arrayWithObjects:@"text",@"int2",@"int4",@"int8",@"float4",@"float8",nil];
	NSArray* theObjectTypes = [NSArray arrayWithObjects:@"NSString",@"NSNumber",@"NSNumber",@"NSNumber",@"NSNumber",@"NSNumber",nil];

	// connect to database
	[[self connection] connect];
	
	// iterate through the types
	for(NSString* thePostgresType in thePostgresTypes) {
		
		// delete existing table		
		if([[[self connection] tablesInSchema:theSchema] containsObject:theTable]) {
			[[self connection] executeWithFormat:@"DROP TABLE %@.%@",theSchema,theTable];
		}
		
		// create a new table
		[[self connection] executeWithFormat:@"CREATE TABLE %@.%@ (a %@)",theSchema,theTable,thePostgresType];	

		// insert data into the table
		for(NSUInteger row = 0; row < numberOfRows; row++) {
			
		}
	}
	
	// disconnect from database
	[[self connection] disconnect];
}

////////////////////////////////////////////////////////////////////////////

-(void)connection:(FLXPostgresConnection* )theConnection notice:(NSString* )theNotice {
	NSLog(@"Notice: %@",theNotice);
}

-(void)connection:(FLXPostgresConnection* )theConnection willExecute:(NSObject* )theQuery values:(NSArray* )theValues {
	NSLog(@"Query: %@",theQuery);
}

@end
