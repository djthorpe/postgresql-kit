
#import <Foundation/Foundation.h>
#import <PostgresServerKit/PostgresServerKit.h>
#import <PostgresClientKit/PostgresClientKit.h>
#import <PostgresDataKit/PostgresDataKit.h>
#import "Name.h"


void doWork(FLXPostgresConnection* connection,FLXPostgresDataCache* cache) {
	
	// create 'name' table		
	NSArray* theTables = [connection tablesInSchema:@"public"];
	if([theTables containsObject:@"name"]) {
		[connection execute:@"DROP TABLE public.Name"];
	}
	[connection execute:@"CREATE TABLE public.Name (id INTEGER PRIMARY KEY,name VARCHAR(80),email VARCHAR(80),male BOOL)"];
	
	// create a new 'Name' object
	Name* theName1 = [cache newObjectForClass:[Name class]];
	
	// fill in the name object
	theName1.name = @"David Thorpe";
	theName1.email = @"djt@mutablelogic.com";
	
	// commit changes to database
	[cache saveObject:theName1];		
	
	NSLog(@"name = %@",theName1);
	
}

int main(int argc, char *argv[]) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	FLXPostgresConnection* connection = [[FLXPostgresConnection alloc] init];
	FLXPostgresDataCache* cache = [FLXPostgresDataCache sharedCache];

	////////////////////////////////////////////////////////////////////////////

	[connection setUser:@"postgres"];
	[connection setDatabase:@"postgres"];
	[cache setConnection:connection];
	[cache setSchema:@"public"];
	
	////////////////////////////////////////////////////////////////////////////

	@try {
		[connection connect];
		doWork(connection,cache);		
		[connection disconnect];
	} @catch(NSException* theException) {
		NSLog(@"Exception caught: %@",theException);
	}

	////////////////////////////////////////////////////////////////////////////

	[cache setConnection:nil];		
	[connection release];
	[pool release];
	return 0;
}
