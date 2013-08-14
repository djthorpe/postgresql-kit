
#import <Foundation/Foundation.h>
#import "TypeTests+NSString.h"

@implementation TypeTests
@synthesize database;

////////////////////////////////////////////////////////////////////////////////

-(void)setUp {
	NSURL* theURL = [NSURL URLWithString:@"pgsql://postgres@localhost/postgres"];
	FLXPostgresConnection* theConnection = [FLXPostgresConnection connectionWithURL:theURL];
	STAssertNotNil(theConnection,@"Create a connection object");
	STAssertNoThrow([theConnection connect],@"Connect to database");
	STAssertTrue([theConnection connected],@"Connection not made");	
	[self setDatabase:theConnection];
}	

-(void)tearDown {
	STAssertNoThrow([[self database] disconnect],@"Connect to database");
	STAssertTrue([[self database] connected]==NO,@"Connection still active");
	[self setDatabase:nil];
}

////////////////////////////////////////////////////////////////////////////////

-(void)test001_Ping {
	FLXPostgresResult* theResult = [[self database] execute:@"SELECT 'ping'"];
	STAssertNotNil(theResult,@"No result");	
	STAssertTrue([theResult isDataReturned],@"No data returned");	
	STAssertEquals((NSUInteger)1,[theResult affectedRows],@"Requires one row returned");
	STAssertEquals((NSUInteger)1,[theResult numberOfColumns],@"Requires one column returned");
	
	NSString* theValue = [[theResult fetchRowAsArray] objectAtIndex:0];
	STAssertNotNil(theValue,@"Cell should not be nil");	
	STAssertEqualObjects([NSString stringWithString:@"ping"],theValue,@"String should be 'ping' but is %@",theValue);	
}

-(void)test002_CreateTable {
	NSString* theSchema = @"public";
	NSString* theTable = @"test";
	NSArray* theTypes = [NSArray arrayWithObjects:
						 [NSArray arrayWithObjects:@"text",@"NSString",@"stringValueForRow:",nil],						 
						 [NSArray arrayWithObjects:@"char(80)",@"NSString",@"charValueForRow:",nil],
						 [NSArray arrayWithObjects:@"varchar(80)",@"NSString",@"varcharValueForRow:",nil],
						 [NSArray arrayWithObjects:@"name",@"NSString",@"nameValueForRow:",nil],nil];
	
	// iterate through the types
	for(NSUInteger i = 0; i < [theTypes count]; i++) {
		NSArray* theTypeArray = [theTypes objectAtIndex:i];
		NSString* thePostgresType = [theTypeArray objectAtIndex:0];
		Class theObjectClass = NSClassFromString([theTypeArray objectAtIndex:1]);
		SEL theValueSelector = NSSelectorFromString([theTypeArray objectAtIndex:2]);
		NSParameterAssert(theObjectClass);
		NSParameterAssert(theValueSelector);
		
		// delete existing table		
		if([[[self database] tablesInSchema:theSchema] containsObject:theTable]) {
			[[self database] executeWithFormat:@"DROP TABLE %@.%@",theSchema,theTable];
		}
		
		// create a new table
		[[self database] executeWithFormat:@"CREATE TABLE %@.%@ (id SERIAL PRIMARY KEY,value %@)",theSchema,theTable,thePostgresType];	
	}
}

@end
