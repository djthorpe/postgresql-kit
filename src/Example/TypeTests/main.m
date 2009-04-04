
#import <Foundation/Foundation.h>
#import <PostgresServerKit/PostgresServerKit.h>
#import <PostgresClientKit/PostgresClientKit.h>
#import <PostgresDataKit/PostgresDataKit.h>
#import "Name.h"


int main(int argc, char *argv[]) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	FLXPostgresServer* theServer = [FLXPostgresServer sharedServer];
	
	[theServer setPort:9002];
	[theServer startWithDataPath:@"/Users/djt/test"];
	
	while([theServer state] != FLXServerStateStarted) {
		NSLog(@"State = %@",[theServer stateAsString]);
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
	 }

	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:2.0]];

	
	[theServer restart];
	
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:2.0]];
	
	
	
	[theServer stop];
	
	
	/*
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
		[connection execute:@"CREATE TABLE name (id INTEGER PRIMARY KEY,name VARCHAR(80),email VARCHAR(80))"];
		

		// create a new name object
		Name* theName = [theCache newObjectForClass:[Name class]];
		
		[theName setValue:@"David Thorpe" forKey:@"name"];
		
		// commit changes to database
		//[theCache commit];		
		
		NSLog(@"name = %@",theName);
		
		// unset connection
		[theCache setConnection:nil];		
		
	} @catch(NSException* theException) {
		NSLog(@"Error: %@",theException);
	}

	////////////////////////////////////////////////////////////////////////////

	[connection release];
	 
	 */
	
	
	
	
	[pool release];
	return 0;
}
