
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
		[connection execute:@"CREATE TABLE name (id INTEGER PRIMARY KEY,name VARCHAR(80))"];
		
		// data cache
		[[FLXPostgresDataCache sharedCache] setConnection:connection];

		// get context
		FLXPostgresDataObjectContext* theContext = [[FLXPostgresDataCache sharedCache] objectContextForClass:[Name class]];
		
		NSLog(@"context = %@",theContext);
		
		// unset connection
		[[FLXPostgresDataCache sharedCache] setConnection:nil];		
		
	} @catch(NSException* theException) {
		NSLog(@"Error: %@",theException);
	}

	////////////////////////////////////////////////////////////////////////////

	[connection release];
	[pool release];
	return 0;
}
