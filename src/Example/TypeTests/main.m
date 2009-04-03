
#import <Foundation/Foundation.h>
#import <PostgresClientKit/PostgresClientKit.h>
#import <PostgresDataKit/PostgresDataKit.h>
#import "Name.h"

int main(int argc, char *argv[]) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	FLXPostgresConnection* connection = [[FLXPostgresConnection alloc] init];

	[connection setUser:@"postgres"];
	[connection setDatabase:@"postgres"];
	
	@try {
		[connection connect];

		NSArray* theTables = [connection tablesForSchema:@"public"];
		if([theTables containsObject:@"name"]) {
			[connection execute:@"DROP TABLE name"];
		}
		
		// create table
		[connection execute:@"CREATE TABLE name (id INTEGER PRIMARY KEY,name VARCHAR(80),email VARCHAR(80))"];
		
		FLXPostgresDataCache* theCache = [FLXPostgresDataCache sharedCache];

		// data cache
		[theCache setConnection:connection];

		// create a new name object
		Name* theName = [theCache newObjectForClass:[Name class]];
		
		[theName setValue:@"David Thorpe" forKey:@"name"];
		
		NSLog(@"name = %@",theName);
		
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
