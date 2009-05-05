
#import <Foundation/Foundation.h>
#import <PostgresClientKit/PostgresClientKit.h>

void doWork(FLXPostgresConnection* server) {
	NSString* theSchema = @"public";
	NSString* theTable = @"test";
	

	// types
	NSArray* thePostgresTypes = [NSArray arrayWithObjects:@"text",@"int2",@"int4",@"int8",@"float4",@"float8"];
	for(NSString* thePostgresType in thePostgresTypes) {
		// delete existing table		
		if([[server tablesInSchema:theSchema] containsObject:theTable]) {
			[server executeWithFormat:@"DROP TABLE %@.%@",theSchema,theTable];
		}
		// create a new table
		[server executeWithFormat:@"CREATE TABLE %@.%@ (a %@)",theSchema,theTable,thePostgresType];		
	}
	
}

int main(int argc, char *argv[]) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	////////////////////////////////////////////////////////////////////////////

	NSURL* theURL = [NSURL URLWithString:@"pgsql://postgres@/postgres"];
	FLXPostgresConnection* server = [FLXPostgresConnection connectionWithURL:theURL];
	
	////////////////////////////////////////////////////////////////////////////

	@try {
		[server connect];
		doWork(server);		
		[server disconnect];
	} @catch(NSException* theException) {
		NSLog(@"Exception caught: %@",theException);
	}

	////////////////////////////////////////////////////////////////////////////

	[pool release];
	return 0;
}
