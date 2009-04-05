
#import <Foundation/Foundation.h>
#import <PostgresServerKit/PostgresServerKit.h>
#import <PostgresClientKit/PostgresClientKit.h>
#import <PostgresDataKit/PostgresDataKit.h>
#import "Name.h"


int main(int argc, char *argv[]) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	FLXPostgresConnection* connection = [[FLXPostgresConnection alloc] init];

	[connection setUser:@"postgres"];
	[connection setDatabase:@"postgres"];
	
	@try {
		FLXPostgresDataCache* theCache = [FLXPostgresDataCache sharedCache];
		// set data cache connection, and connect
		[theCache setConnection:connection];
		[connection connect];

		// create 'name' table		
		NSArray* theTables = [connection tablesInSchema:@"public"];
		if([theTables containsObject:@"name"]) {
			[connection execute:@"DROP TABLE name"];
		}
		
		// create table
		[connection execute:@"CREATE TABLE name (id INTEGER PRIMARY KEY,name VARCHAR(80),email VARCHAR(80),male BOOL)"];

		// create a new name object
		Name* theName1 = [theCache newObjectForClass:[Name class]];
		
		theName1.name = @"David Thorpe";
		theName1.email = @"djt@mutablelogic.com";
		theName1.male = YES;
		theName1.id = 100;
				
		// commit changes to database
		[theCache saveObject:theName1];		
		
		// fetch single object from database
		//Name* theObject = [theCache fetchObjectForClass:[Name class] withPrimaryValue:[NSNumber numberWithInt:100]];
		
		NSLog(@"names = %@ %@",theName1);
		
		// unset connection
		[theCache setConnection:nil];		
		
	} @catch(NSException* theException) {
		NSLog(@"Error: %@",theException);
	}

	////////////////////////////////////////////////////////////////////////////

	[connection release];
	[pool release];
	return 0;
}
