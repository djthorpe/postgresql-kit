
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

-(NSObject* )valueForType:(NSString* )theType row:(NSUInteger)row {
	if([theType isEqual:@"int2"]) {
		return [NSNumber numberWithShort:row];
	} else {
		return [NSNull null];
	}
}

////////////////////////////////////////////////////////////////////////////

-(void)doWork {
	NSString* theSchema = @"public";
	NSString* theTable = @"test";
	NSUInteger numberOfRows = 1000;
	NSArray* thePostgresTypes = [NSArray arrayWithObjects:@"text",@"int2",@"int4",@"int8",@"float4",@"float8",nil];
	NSArray* theObjectClasses = [NSArray arrayWithObjects:@"NSString",@"NSNumber",@"NSNumber",@"NSNumber",@"NSNumber",@"NSNumber",nil];

	// connect to database
	[[self connection] connect];
	
	// iterate through the types
	for(NSUInteger i = 0; i < [thePostgresTypes count]; i++) {
		NSString* thePostgresType = [thePostgresTypes objectAtIndex:i];
		Class theObjectClass = NSClassFromString([theObjectClasses objectAtIndex:i]);
		NSParameterAssert(theObjectClass);
		
		// delete existing table		
		if([[[self connection] tablesInSchema:theSchema] containsObject:theTable]) {
			[[self connection] executeWithFormat:@"DROP TABLE %@.%@",theSchema,theTable];
		}
		
		// create a new table
		[[self connection] executeWithFormat:@"CREATE TABLE %@.%@ (id SERIAL PRIMARY KEY,value %@)",theSchema,theTable,thePostgresType];	

		// generate data
		NSMutableArray* theData = [[NSMutableArray alloc] initWithCapacity:numberOfRows];
		for(NSUInteger row = 0; row < numberOfRows; row++) {
			NSObject* theValue = [self valueForType:thePostgresType row:row];
			NSParameterAssert([theValue isKindOfClass:[NSNull class]] || [theValue isKindOfClass:theObjectClass]);
			[theData addObject:theValue];			
		}

		// prepare statement
		FLXPostgresStatement* theInsert = [[self connection] prepareWithFormat:@"INSERT INTO %@.%@ (value) VALUES ($1)",theSchema,theTable];
		
		// insert data into the table
		for(NSUInteger row = 0; row < numberOfRows; row++) {
			[[self connection] executePrepared:theInsert value:[theData objectAtIndex:row]];
		}
		
		// read data back from table and compare to original data
		
		// release data
		[theData release];							  
	}
	
	// disconnect from database
	[[self connection] disconnect];
}

////////////////////////////////////////////////////////////////////////////

-(void)connection:(FLXPostgresConnection* )theConnection notice:(NSString* )theNotice {
	NSLog(@"Notice: %@",theNotice);
}

-(void)connection:(FLXPostgresConnection* )theConnection willExecute:(NSObject* )theQuery values:(NSArray* )theValues {
	if([theQuery isKindOfClass:[FLXPostgresStatement class]]) {
		NSLog(@"Query: %@",[(FLXPostgresStatement* )theQuery statement]);
	} else {
		NSLog(@"Query: %@",theQuery);		
	}
}

@end
