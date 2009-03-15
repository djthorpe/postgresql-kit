
#import "ClientConnection.h"

@implementation ClientConnection
@synthesize server;
@synthesize client;

////////////////////////////////////////////////////////////////////////////////

+(void)stopServer:(FLXPostgresServer* )theServer {	
	// stop the server
	BOOL isSuccess = YES;
	isSuccess = [theServer stop];
	if(isSuccess==NO) NSLog(@"Unable to initiate server stop");
//	NSParameterAssert(isSuccess);
	
	NSUInteger theClock = 0;
	while([theServer state] != FLXServerStateStopped && theClock < 5) {
		NSLog(@"server state = %@",[theServer stateAsString]);
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
		theClock++;
	}
	
	if([theServer state] != FLXServerStateStopped) {
		NSLog(@"Unable to stop server: %@",[theServer stateAsString]);
		//NSParameterAssert(NO);
	}	
}

+(void)startServer:(FLXPostgresServer* )theServer {
	NSLog(@"starting server....");
	
	// Path should be home directory
	NSString* theTempDirectory = NSTemporaryDirectory();
	NSString* theDataDirectory = [theTempDirectory stringByAppendingString:@"postgres-kit-test"];

	NSError* theError = nil;
	BOOL isSuccess = YES;

	NSLog(@"data directory = %@",theDataDirectory);
	
	// remove data directory
	if([[NSFileManager defaultManager] fileExistsAtPath:theDataDirectory]==YES) {	
		NSLog(@"stopping server....");
		[self stopServer:theServer];		
		NSLog(@"removing path %@",theDataDirectory);
		isSuccess = [[NSFileManager defaultManager] removeItemAtPath:theDataDirectory error:&theError];
		if(theError) NSLog(@"%@: %@",theDataDirectory,[theError localizedDescription]);
	}
	NSParameterAssert(isSuccess);

	// create data directory
	isSuccess = [[NSFileManager defaultManager] createDirectoryAtPath:theDataDirectory attributes:nil];
	if(isSuccess==NO) NSLog(@"%@: Unable to create directory",theDataDirectory);
	NSParameterAssert(isSuccess);

	NSLog(@"created directory = %@",theDataDirectory);
		
	// start the server
	isSuccess = [theServer startWithDataPath:theDataDirectory];
	if(isSuccess==NO) NSLog(@"Unable to initiate startWithDataPath");
	NSParameterAssert(isSuccess);

	NSUInteger theClock = 0;
	while([theServer state] != FLXServerStateStarted && theClock < 60) {
		
		NSLog(@"server state = %@",[theServer stateAsString]);
		
		if([theServer state]==FLXServerStateStopped || [theServer state]==FLXServerStateStartingError) {
			NSLog(@"Unable to start server: %@",[theServer stateAsString]);
			NSParameterAssert(NO);
		}
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
		theClock++;
	}

	if([theServer isRunning]==NO) {
		NSLog(@"Server could not be started");
		NSParameterAssert(NO);
	}			
}

+(void)tearDown {
	NSLog(@"doing teardown");
	
	[self stopServer:[FLXPostgresServer sharedServer]];
	
	// remove the data directory
	NSString* theDataDirectory = [[FLXPostgresServer sharedServer] dataPath];
	BOOL isSuccess = YES;
	NSError* theError = nil;	
	if([[NSFileManager defaultManager] fileExistsAtPath:theDataDirectory]==YES) {
		isSuccess = [[NSFileManager defaultManager] removeItemAtPath:theDataDirectory error:&theError];
		if(theError) NSLog(@"%@: %@",theDataDirectory,[theError localizedDescription]);
	}
	NSParameterAssert(isSuccess);
}	

-(void)setUp {
	
	//////// server
	[self setServer:[FLXPostgresServer sharedServer]];		
	if([[self server] isRunning]==NO) {
		[[self class] startServer:[self server]];
	}
	
	//////// client
	FLXPostgresConnection* theConnection = [[[FLXPostgresConnection alloc] init] autorelease];
	[theConnection setDatabase:@"postgres"];
	[theConnection setUser:[FLXPostgresServer superUsername]];
	STAssertNoThrow([theConnection connect],@"Connect to database");
	STAssertTrue([theConnection connected],@"Connection not made");	
	[self setClient:theConnection];
}	

-(void)tearDown {
	STAssertNoThrow([[self client] disconnect],@"Connect to database");
	STAssertTrue([[self client] connected]==NO,@"Connection still active");	
	[self setClient:nil];
}

////////////////////////////////////////////////////////////////////////////////

-(void)test001_Ping {
	FLXPostgresResult* theResult = [[self client] execute:@"SELECT 1"];
	STAssertNotNil(theResult,@"No result");	
	STAssertTrue([theResult isDataReturned],@"No data returned");	
	STAssertEquals((NSUInteger)1,[theResult affectedRows],@"Requires one row returned");
	STAssertEquals((NSUInteger)1,[theResult numberOfColumns],@"Requires one column returned");

	NSNumber* theValue = [[theResult fetchRowAsArray] objectAtIndex:0];
	STAssertNotNil(theValue,@"Cell should not be nil");	
	STAssertEqualObjects([NSNumber numberWithInt:1],theValue,@"Number should be 1 but is %@",theValue);	
}

-(void)test002_Integer2 {	
	NSArray* theNumbers = [NSArray arrayWithObjects:[NSNumber numberWithInteger:-32768],[NSNumber numberWithInteger:32767],nil];
	for(NSNumber* theNumber in theNumbers) {
		FLXPostgresResult* theResult = [[self client] execute:[NSString stringWithFormat:@"SELECT (%@)::int2",theNumber]];
		STAssertNotNil(theResult,@"No result");	
		STAssertTrue([theResult isDataReturned],@"No data returned");	
		STAssertEquals((NSUInteger)1,[theResult affectedRows],@"Requires one row returned");
		STAssertEquals((NSUInteger)1,[theResult numberOfColumns],@"Requires one column returned");	
		NSNumber* theValue = [[theResult fetchRowAsArray] objectAtIndex:0];
		STAssertNotNil(theValue,@"Cell should not be nil");	
		STAssertEqualObjects(theNumber,theValue,@"Number should be %@ but is %@",theNumber,theValue);	
	}
}

-(void)test003_Integer4 {	
	NSArray* theNumbers = [NSArray arrayWithObjects:[NSNumber numberWithInteger:-2147483648],[NSNumber numberWithInteger:2147483647],nil];
	for(NSNumber* theNumber in theNumbers) {
		FLXPostgresResult* theResult = [[self client] execute:[NSString stringWithFormat:@"SELECT (%@)::int4",theNumber]];
		STAssertNotNil(theResult,@"No result");	
		STAssertTrue([theResult isDataReturned],@"No data returned");	
		STAssertEquals((NSUInteger)1,[theResult affectedRows],@"Requires one row returned");
		STAssertEquals((NSUInteger)1,[theResult numberOfColumns],@"Requires one column returned");	
		NSNumber* theValue = [[theResult fetchRowAsArray] objectAtIndex:0];
		STAssertNotNil(theValue,@"Cell should not be nil");	
		STAssertEqualObjects(theNumber,theValue,@"Number should be %@ but is %@",theNumber,theValue);	
	}
}

-(void)test004_Integer8 {
	NSArray* theNumbers = [NSArray arrayWithObjects:[NSNumber numberWithLong:LONG_MIN],[NSNumber numberWithLong:LONG_MAX],nil];
	for(NSNumber* theNumber in theNumbers) {
		FLXPostgresResult* theResult = [[self client] execute:[NSString stringWithFormat:@"SELECT (%@)::int8",theNumber]];
		STAssertNotNil(theResult,@"No result");	
		STAssertTrue([theResult isDataReturned],@"No data returned");	
		STAssertEquals((NSUInteger)1,[theResult affectedRows],@"Requires one row returned");
		STAssertEquals((NSUInteger)1,[theResult numberOfColumns],@"Requires one column returned");	
		NSNumber* theValue = [[theResult fetchRowAsArray] objectAtIndex:0];
		STAssertNotNil(theValue,@"Cell should not be nil");	
		STAssertEqualObjects(theNumber,theValue,@"Number should be %@ but is %@",theNumber,theValue);	
	}
}

-(void)test005_Float4 {	
	for(double i = SHRT_MIN; i <= SHRT_MAX; i += 0.5) {	
		NSNumber* theNumber = [NSNumber numberWithDouble:i];
		FLXPostgresResult* theResult = [[self client] execute:[NSString stringWithFormat:@"SELECT (%@)::float4",theNumber]];
		STAssertNotNil(theResult,@"No result");	
		STAssertTrue([theResult isDataReturned],@"No data returned");	
		STAssertEquals((NSUInteger)1,[theResult affectedRows],@"Requires one row returned");
		STAssertEquals((NSUInteger)1,[theResult numberOfColumns],@"Requires one column returned");	
		NSNumber* theValue = [[theResult fetchRowAsArray] objectAtIndex:0];
		STAssertNotNil(theValue,@"Cell should not be nil");	
		STAssertEqualObjects(theNumber,theValue,@"Number should be %@ but is %@",theNumber,theValue);	
	}
}

-(void)test006_Float8 {	
	for(double i = SHRT_MIN; i <= SHRT_MAX; i += 0.5) {	
		NSNumber* theNumber = [NSNumber numberWithDouble:i];
		FLXPostgresResult* theResult = [[self client] execute:[NSString stringWithFormat:@"SELECT (%@)::float8",theNumber]];
		STAssertNotNil(theResult,@"No result");	
		STAssertTrue([theResult isDataReturned],@"No data returned");	
		STAssertEquals((NSUInteger)1,[theResult affectedRows],@"Requires one row returned");
		STAssertEquals((NSUInteger)1,[theResult numberOfColumns],@"Requires one column returned");	
		NSNumber* theValue = [[theResult fetchRowAsArray] objectAtIndex:0];
		STAssertNotNil(theValue,@"Cell should not be nil");	
		STAssertEqualObjects(theNumber,theValue,@"Number should be %@ but is %@",theNumber,theValue);	
	}
}

-(void)test007_Bytea {	
	NSURL* theURL = [NSURL URLWithString:@"http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/front_page/rss.xml"];
	NSData* theData = [NSData dataWithContentsOfURL:theURL];
	STAssertNotNil(theData,@"Cannot fetch RSS feed: %@",theURL);
	FLXPostgresResult* theResult = [[self client] execute:[NSString stringWithFormat:@"SELECT (%@)::bytea",[[self client] quote:theData]]];
	STAssertNotNil(theResult,@"No result");	
	STAssertTrue([theResult isDataReturned],@"No data returned");	
	STAssertEquals((NSUInteger)1,[theResult affectedRows],@"Requires one row returned");
	STAssertEquals((NSUInteger)1,[theResult numberOfColumns],@"Requires one column returned");	
	NSData* theValue = [[theResult fetchRowAsArray] objectAtIndex:0];
	STAssertNotNil(theValue,@"Cell should not be nil");	
	STAssertEqualObjects(theData,theValue,@"Number should be %@ but is %@",theData,theValue);	
}

-(void)test008_Boolean {	
	NSArray* theNumbers = [NSArray arrayWithObjects:[NSNumber numberWithBool:YES],[NSNumber numberWithBool:NO],nil];
	for(NSNumber* theNumber in theNumbers) {
		FLXPostgresResult* theResult = [[self client] execute:[NSString stringWithFormat:@"SELECT (%@)::bool",[[self client] quote:theNumber]]];
		STAssertNotNil(theResult,@"No result");	
		STAssertTrue([theResult isDataReturned],@"No data returned");	
		STAssertEquals((NSUInteger)1,[theResult affectedRows],@"Requires one row returned");
		STAssertEquals((NSUInteger)1,[theResult numberOfColumns],@"Requires one column returned");	
		NSNumber* theValue = [[theResult fetchRowAsArray] objectAtIndex:0];
		STAssertNotNil(theValue,@"Cell should not be nil");	
		STAssertEqualObjects(theNumber,theValue,@"Number should be %@ but is %@",theNumber,theValue);	
	}
}

////////////////////////////////////////////////////////////////////////////////

-(void)test100_Databases {	
	FLXPostgresResult* theResult = [[self client] execute:@"SELECT datname FROM pg_database WHERE datistemplate=false"];
	STAssertNotNil(theResult,@"No result");		
	STAssertTrue([theResult affectedRows] > 0,@"Number of rows");
	STAssertEquals((NSUInteger)1,[theResult numberOfColumns],@"Number of columns");
	// enumerate databases
	NSMutableArray* theDatabases = [NSMutableArray arrayWithCapacity:[theResult affectedRows]];
	NSArray* theRow = nil;
	while(theRow = [theResult fetchRowAsArray]) {
		STAssertEquals((NSUInteger)1,[theRow count],@"Number of columns");
		STAssertTrue([[theRow objectAtIndex:0] isKindOfClass:[NSString class]],@"Type of cell");
		[theDatabases addObject:[theRow objectAtIndex:0]];
	}
	STAssertTrue([theDatabases containsObject:@"postgres"],@"Contains postgres database");
}

-(void)test101_CreateDatabase {
	FLXPostgresResult* theResult = [[self client] execute:@"CREATE DATABASE test"];
	STAssertNotNil(theResult,@"No result");		
	STAssertFalseNoThrow([theResult isDataReturned],@"Data returned");	
	NSArray* theDatabases = [[self client] databases];
	STAssertTrue([theDatabases containsObject:@"test"],@"Test database created");		
}

-(void)test102_DropDatabase {
	FLXPostgresResult* theResult = [[self client] execute:@"DROP DATABASE test"];
	STAssertNotNil(theResult,@"No result");		
	STAssertFalseNoThrow([theResult isDataReturned],@"Data returned");	
	NSArray* theDatabases = [[self client] databases];
	STAssertFalseNoThrow([theDatabases containsObject:@"test"],@"Test database created");		
}

-(void)test103_SelectDatabase {
	[self test101_CreateDatabase];
	STAssertNoThrow([[self client] disconnect],@"disconnect");
	STAssertNoThrow([[self client] setDatabase:@"test"],@"set database");
	STAssertNoThrow([[self client] connect],@"connect");
}

-(void)test104_CreateDropTable {
	STAssertNoThrow([[self client] execute:@"CREATE TABLE test ()"],@"create table");
	STAssertNoThrow([[self client] execute:@"DROP TABLE test"],@"drop table");
}

////////////////////////////////////////////////////////////////////////////////

-(void)test200_InsertIntegers {
	// generate 1000 random numbers
	NSMutableArray* theData = [NSMutableArray array];
	for(NSUInteger i = 0; i < 1000; i++) {
		[theData addObject:[NSArray arrayWithObjects:[NSNumber numberWithInteger:i],[NSNumber numberWithInteger:(rand() * INT_MAX)],nil]];
	}
	// create the table
	STAssertNoThrow([[self client] execute:@"CREATE TABLE test (id INTEGER,number INTEGER)"],@"create table");
	// insert the data
	for(NSArray* theRow in theData) {
		NSString* theStatement = [NSString stringWithFormat:@"INSERT INTO test (id,number) VALUES (%@,%@)",[theRow objectAtIndex:0],[theRow objectAtIndex:1]];
		STAssertNoThrow([[self client] execute:theStatement],@"insert data");
	}
	// read back integers
	FLXPostgresResult* theResult;
	STAssertNoThrow(theResult = [[self client] execute:@"SELECT id,number FROM test ORDER BY id"],@"select");	
	STAssertNotNil(theResult,@"result not nil");
	STAssertTrue([theResult isDataReturned],@"is data returned");
	STAssertEquals((NSUInteger)1000,[theResult affectedRows],@"1000 rows returned");
	STAssertEquals((NSUInteger)2,[theResult numberOfColumns],@"number of columns");
	for(NSUInteger i = 0; i < 1000; i++) {
		NSArray* theOriginal = [theData objectAtIndex:i];
		NSArray* theValue = [theResult fetchRowAsArray];
		STAssertEqualObjects(theValue,theOriginal,@"Returned from database = %@ and original = %@",theValue,theOriginal);		
	}
}

-(void)test200_InsertIntegersBindings {
	// generate 1000 random numbers
	NSMutableArray* theData = [NSMutableArray array];
	for(NSUInteger i = 0; i < 1000; i++) {
		[theData addObject:[NSArray arrayWithObjects:[NSNumber numberWithInteger:i],[NSNumber numberWithInteger:(rand() * INT_MAX)],nil]];
	}
	// create the table
	STAssertNoThrow([[self client] execute:@"CREATE TABLE test (id INTEGER,number INTEGER)"],@"create table");
	// insert the data
	for(NSArray* theRow in theData) {
		NSString* theStatement = @"INSERT INTO test (id,number) VALUES ($1,$2)";
								  ,[theRow objectAtIndex:0],[theRow objectAtIndex:1]];
		STAssertNoThrow([[self client] execute:theStatement values:theRow types:],@"insert data");
	}
	// read back integers
	FLXPostgresResult* theResult;
	STAssertNoThrow(theResult = [[self client] execute:@"SELECT id,number FROM test ORDER BY id"],@"select");	
	STAssertNotNil(theResult,@"result not nil");
	STAssertTrue([theResult isDataReturned],@"is data returned");
	STAssertEquals((NSUInteger)1000,[theResult affectedRows],@"1000 rows returned");
	STAssertEquals((NSUInteger)2,[theResult numberOfColumns],@"number of columns");
	for(NSUInteger i = 0; i < 1000; i++) {
		NSArray* theOriginal = [theData objectAtIndex:i];
		NSArray* theValue = [theResult fetchRowAsArray];
		STAssertEqualObjects(theValue,theOriginal,@"Returned from database = %@ and original = %@",theValue,theOriginal);		
	}
}


/*

 -(void)_insertIntegersWithBindings {
 [[self connection] execute:@"CREATE TABLE test (id INTEGER NOT NULL,number INTEGER NOT NULL)"];
 NSMutableArray* theIntegers = [NSMutableArray array];
 NSUInteger theLength = 1000;
 // insert data
 for(NSUInteger i = 0; i < theLength; i++) {
 NSNumber* theInteger = [NSNumber numberWithInt:(rand() * INT_MAX)];
 [theIntegers addObject:theInteger];
 [[self connection] execute:@"INSERT INTO test (id,number) VALUES ($1,$2)" 
 values:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedInteger:i],theInteger,nil]
 types:[NSArray arrayWithObjects:[NSNumber numberWithInteger:FLXPostgresTypeInteger],[NSNumber numberWithInteger:FLXPostgresTypeInteger],nil]];
 }
 // retrieve data
 FLXPostgresResult* theResult = [[self connection] execute:@"SELECT number FROM test ORDER BY id"];
 NSParameterAssert(theResult);
 NSParameterAssert([theResult affectedRows]==theLength);
 for(NSUInteger i = 0; i < theLength; i++) {
 NSArray* theRow = [theResult fetchRowAsArray];
 NSParameterAssert([theRow count]==1);
 NSNumber* theCell = [theRow objectAtIndex:0];
 NSParameterAssert([theCell isKindOfClass:[NSNumber class]]);
 NSParameterAssert([theCell isEqual:[theIntegers objectAtIndex:i]]);
 }
 [self _dropTable];
 }
 
 -(void)_insertBooleans {
 [[self connection] execute:@"CREATE TABLE test (id INTEGER NOT NULL,number BOOL NOT NULL)"];
 NSMutableArray* theIntegers = [NSMutableArray array];
 NSUInteger theLength = 1000;
 // insert data
 for(NSUInteger i = 0; i < theLength; i++) {
 NSNumber* theInteger = ((rand() * INT_MAX) > 0 ? [NSNumber numberWithBool:YES] : [NSNumber numberWithBool:NO]);
 [theIntegers addObject:theInteger];
 [[self connection] execute:@"INSERT INTO test (id,number) VALUES ($1,$2)" 
 values:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedInteger:i],theInteger,nil]
 types:[NSArray arrayWithObjects:[NSNumber numberWithInteger:FLXPostgresTypeInteger],[NSNumber numberWithInteger:FLXPostgresTypeInteger],nil]];
 }
 // retrieve data
 FLXPostgresResult* theResult = [[self connection] execute:@"SELECT number FROM test ORDER BY id"];
 NSParameterAssert(theResult);
 NSParameterAssert([theResult affectedRows]==theLength);
 for(NSUInteger i = 0; i < theLength; i++) {
 NSArray* theRow = [theResult fetchRowAsArray];
 NSParameterAssert([theRow count]==1);
 NSNumber* theCell = [theRow objectAtIndex:0];
 NSParameterAssert([theCell isKindOfClass:[NSNumber class]]);
 NSParameterAssert([theCell isEqual:[theIntegers objectAtIndex:i]]);
 }
 [self _dropTable];
 }
 
 -(void)_insertFloat4 {
 [[self connection] execute:@"CREATE TABLE test (id INTEGER NOT NULL,number FLOAT4 NOT NULL)"];
 NSMutableArray* theNumbers = [NSMutableArray array];
 NSUInteger theLength = 1000;
 // insert data
 for(NSUInteger i = 0; i < theLength; i++) {
 NSNumber* theNumber = [NSNumber numberWithFloat:(rand() / 100000.0)];
 [theNumbers addObject:theNumber];
 [[self connection] execute:@"INSERT INTO test (id,number) VALUES ($1,$2)" 
 values:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedInteger:i],theNumber,nil]
 types:[NSArray arrayWithObjects:[NSNumber numberWithInteger:FLXPostgresTypeInteger],[NSNumber numberWithInteger:FLXPostgresTypeReal],nil]];
 }
 
 // retrieve data
 FLXPostgresResult* theResult = [[self connection] execute:@"SELECT number FROM test ORDER BY id"];
 NSParameterAssert(theResult);
 NSParameterAssert([theResult affectedRows]==theLength);
 for(NSUInteger i = 0; i < theLength; i++) {
 NSArray* theRow = [theResult fetchRowAsArray];
 NSParameterAssert([theRow count]==1);
 NSNumber* theCell = [theRow objectAtIndex:0];
 NSParameterAssert([theCell isKindOfClass:[NSNumber class]]);
 NSParameterAssert([[theCell stringValue] isEqual:[[theNumbers objectAtIndex:i] stringValue]]);
 }
 [self _dropTable];
 }
 
 -(void)_insertFloat8 {
 [[self connection] execute:@"CREATE TABLE test (id INTEGER NOT NULL,number FLOAT8 NOT NULL)"];
 NSMutableArray* theNumbers = [NSMutableArray array];
 NSUInteger theLength = 1000;
 // insert data
 for(NSUInteger i = 0; i < theLength; i++) {
 NSNumber* theNumber = [NSNumber numberWithDouble:(((double)rand() / (double)INT_MAX) + ((double)rand()))];
 [theNumbers addObject:theNumber];
 [[self connection] execute:@"INSERT INTO test (id,number) VALUES ($1,$2)" 
 values:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedInteger:i],theNumber,nil]
 types:[NSArray arrayWithObjects:[NSNumber numberWithInteger:FLXPostgresTypeInteger],[NSNumber numberWithInteger:FLXPostgresTypeReal],nil]];
 }	
 // retrieve data
 FLXPostgresResult* theResult = [[self connection] execute:@"SELECT number FROM test ORDER BY id"];
 NSParameterAssert(theResult);
 NSParameterAssert([theResult affectedRows]==theLength);
 for(NSUInteger i = 0; i < theLength; i++) {
 NSArray* theRow = [theResult fetchRowAsArray];
 NSParameterAssert([theRow count]==1);
 NSNumber* theCell = [theRow objectAtIndex:0];
 NSParameterAssert([theCell isKindOfClass:[NSNumber class]]);
 NSParameterAssert([[theCell stringValue] isEqual:[[theNumbers objectAtIndex:i] stringValue]]);
 }
 [self _dropTable];	
 }
 
 -(void)_insertStrings {
 [[self connection] execute:@"CREATE TABLE test (id INTEGER NOT NULL,string VARCHAR(80) NOT NULL)"];
 NSMutableArray* theValues = [NSMutableArray array];
 NSURL* theURL = [NSURL URLWithString:@"http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/front_page/rss.xml"];
 NSString* theData = [NSString stringWithContentsOfURL:theURL];
 NSUInteger theLength = [theData length] - 80;
 
 // insert data
 for(NSUInteger i = 0; i < theLength; i++) {
 // generate a string
 NSUInteger theStringLength = ((double)rand() * 80.0 / (double)RAND_MAX);
 NSString* theString = [theData substringWithRange:NSMakeRange(i, theStringLength)];
 // insert into database
 [theValues addObject:theString];
 [[self connection] execute:@"INSERT INTO test (id,string) VALUES ($1,$2)" 
 values:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedInteger:i],theString,nil]
 types:[NSArray arrayWithObjects:[NSNumber numberWithInteger:FLXPostgresTypeInteger],[NSNumber numberWithInteger:FLXPostgresTypeString],nil]];
 }
 // retrieve data
 FLXPostgresResult* theResult = [[self connection] execute:@"SELECT string FROM test ORDER BY id"];
 NSParameterAssert(theResult);
 NSParameterAssert([theResult affectedRows]==theLength);
 for(NSUInteger i = 0; i < theLength; i++) {
 NSArray* theRow = [theResult fetchRowAsArray];
 NSParameterAssert([theRow count]==1);
 NSString* theCell = [theRow objectAtIndex:0];
 NSParameterAssert([theCell isKindOfClass:[NSString class]]);
 NSParameterAssert([theCell isEqual:[theValues objectAtIndex:i]]);
 }
 [self _dropTable];
 }
 
 -(void)_insertStrings2 {
 [[self connection] execute:@"CREATE TABLE test (id INTEGER NOT NULL,string VARCHAR(80) NOT NULL)"];
 NSMutableArray* theValues = [NSMutableArray array];
 NSURL* theURL = [NSURL URLWithString:@"http://newsrss.bbc.co.uk/rss/arabic/news/rss.xml"];
 NSString* theData = [NSString stringWithContentsOfURL:theURL];
 NSUInteger theLength = [theData length] - 80;
 
 // insert data
 for(NSUInteger i = 0; i < theLength; i++) {
 // generate a string
 NSUInteger theStringLength = ((double)rand() * 80.0 / (double)RAND_MAX);
 NSString* theString = [theData substringWithRange:NSMakeRange(i, theStringLength)];
 // insert into database
 [theValues addObject:theString];
 [[self connection] execute:@"INSERT INTO test (id,string) VALUES ($1,$2)" 
 values:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedInteger:i],theString,nil]
 types:[NSArray arrayWithObjects:[NSNumber numberWithInteger:FLXPostgresTypeInteger],[NSNumber numberWithInteger:FLXPostgresTypeString],nil]];
 }
 // retrieve data
 FLXPostgresResult* theResult = [[self connection] execute:@"SELECT string FROM test ORDER BY id"];
 NSParameterAssert(theResult);
 NSParameterAssert([theResult affectedRows]==theLength);
 for(NSUInteger i = 0; i < theLength; i++) {
 NSArray* theRow = [theResult fetchRowAsArray];
 NSParameterAssert([theRow count]==1);
 NSString* theCell = [theRow objectAtIndex:0];
 NSParameterAssert([theCell isKindOfClass:[NSString class]]);
 NSParameterAssert([theCell isEqual:[theValues objectAtIndex:i]]);
 }
 [self _dropTable];
 }
 
 -(void)_insertText {
 [[self connection] execute:@"CREATE TABLE test (id INTEGER NOT NULL,string TEXT NOT NULL)"];
 NSMutableArray* theValues = [NSMutableArray array];
 NSURL* theURL = [NSURL URLWithString:@"http://newsrss.bbc.co.uk/rss/spanish/news/rss.xml"];
 NSString* theData = [NSString stringWithContentsOfURL:theURL];
 NSUInteger theLength = 1000;
 
 // insert data
 for(NSUInteger i = 0; i < theLength; i++) {
 // generate a string
 NSUInteger theStringStart =  ((double)rand() * (double)[theData length] / (double)RAND_MAX);
 NSUInteger theStringMaxLength = [theData length] - theStringStart;
 NSUInteger theStringLength = ((double)rand() * theStringMaxLength / (double)RAND_MAX);
 NSString* theString = [theData substringWithRange:NSMakeRange(theStringStart, theStringLength)];
 // insert into database
 [theValues addObject:theString];
 [[self connection] execute:@"INSERT INTO test (id,string) VALUES ($1,$2)" 
 values:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedInteger:i],theString,nil]
 types:[NSArray arrayWithObjects:[NSNumber numberWithInteger:FLXPostgresTypeInteger],[NSNumber numberWithInteger:FLXPostgresTypeString],nil]];
 }
 // retrieve data
 FLXPostgresResult* theResult = [[self connection] execute:@"SELECT string FROM test ORDER BY id"];
 NSParameterAssert(theResult);
 NSParameterAssert([theResult affectedRows]==theLength);
 for(NSUInteger i = 0; i < theLength; i++) {
 NSArray* theRow = [theResult fetchRowAsArray];
 NSParameterAssert([theRow count]==1);
 NSString* theCell = [theRow objectAtIndex:0];
 NSParameterAssert([theCell isKindOfClass:[NSString class]]);
 NSParameterAssert([theCell isEqual:[theValues objectAtIndex:i]]);
 }
 [self _dropTable];
 }
 
 -(void)_insertData {
 [[self connection] execute:@"CREATE TABLE test (id INTEGER NOT NULL,data BYTEA NOT NULL)"];
 NSMutableArray* theValues = [NSMutableArray array];
 
 // fetch filenames
 NSString* thePath = @"/usr/sbin";
 NSArray* theFilenames = [[NSFileManager defaultManager] directoryContentsAtPath:thePath];
 BOOL isDirectory = NO;
 NSUInteger i = 0;
 for(NSString* theFilename in theFilenames) {
 // filter filenames
 if([theFilename hasPrefix:@"."]) continue;
 NSString* theFilePath = [thePath stringByAppendingPathComponent:theFilename];
 if([[NSFileManager defaultManager] fileExistsAtPath:theFilePath isDirectory:&isDirectory]==NO || isDirectory==YES) continue;
 if([[NSFileManager defaultManager] isReadableFileAtPath:theFilePath]==NO) continue;
 // read in data
 NSData* theData = [NSData dataWithContentsOfFile:theFilePath];
 NSParameterAssert(theData);
 // make the data all 80 bytes long
 if([theData length] > 80) {
 theData = [theData subdataWithRange:NSMakeRange(0,80)];			
 }		
 // insert into database
 [theValues addObject:theData];
 [[self connection] execute:@"INSERT INTO test (id,data) VALUES ($1,$2)" 
 values:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedInteger:i],theData,nil]
 types:[NSArray arrayWithObjects:[NSNumber numberWithInteger:FLXPostgresTypeInteger],[NSNumber numberWithInteger:FLXPostgresTypeData],nil]];
 // increment i
 i++;
 }
 
 // read back the data
 FLXPostgresResult* theResult = [[self connection] execute:@"SELECT data FROM test ORDER BY id"];
 NSParameterAssert(theResult);
 for(NSUInteger i = 0; i < [theResult affectedRows]; i++) {
 NSArray* theRow = [theResult fetchRowAsArray];
 NSParameterAssert([theRow count]==1);
 NSData* theCell = [theRow objectAtIndex:0];
 NSParameterAssert([theCell isKindOfClass:[NSData class]]);
 NSParameterAssert([theCell isEqual:[theValues objectAtIndex:i]]);
 }
 [self _dropTable];	
 }
 
 -(void)_insertDate {
 [[self connection] execute:@"CREATE TABLE test (id INTEGER NOT NULL,date DATE NOT NULL)"];
 NSMutableArray* theValues = [NSMutableArray array];
 NSUInteger theLength = 1000;
 for(NSUInteger i = 0; i < theLength; i++) {
 NSCalendarDate* theDate = [NSCalendarDate dateWithTimeIntervalSinceNow:(NSTimeInterval)((double)rand() - (double)(INT_MAX / 2.0))];
 [theDate setCalendarFormat:@"%Y-%m-%d"];
 [theValues addObject:theDate];
 [[self connection] execute:@"INSERT INTO test (id,date) VALUES ($1,$2)" 
 values:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedInteger:i],theDate,nil]
 types:[NSArray arrayWithObjects:[NSNumber numberWithInteger:FLXPostgresTypeInteger],[NSNumber numberWithInteger:FLXPostgresTypeDate],nil]];
 }
 
 // read back the data
 FLXPostgresResult* theResult = [[self connection] execute:@"SELECT date FROM test ORDER BY id"];
 NSParameterAssert(theResult);
 for(NSUInteger i = 0; i < [theResult affectedRows]; i++) {
 NSArray* theRow = [theResult fetchRowAsArray];
 NSParameterAssert([theRow count]==1);
 NSDate* theCell = [theRow objectAtIndex:0];
 NSParameterAssert([theCell isKindOfClass:[NSDate class]]);
 NSParameterAssert([[theCell description] isEqual:[[theValues objectAtIndex:i] description]]);
 }
 
 [self _dropTable];	
 }
 
 -(void)_insertTime {
 [[self connection] execute:@"CREATE TABLE test (id INTEGER NOT NULL,time TIME NOT NULL)"];
 NSMutableArray* theValues = [NSMutableArray array];
 NSUInteger theLength = 1000;
 for(NSUInteger i = 0; i < theLength; i++) {
 NSCalendarDate* theTime = [NSCalendarDate dateWithTimeIntervalSinceNow:(NSTimeInterval)(((double)rand() - (double)(INT_MAX / 2.0)) / 100.0)];
 [theTime setCalendarFormat:@"%H:%M:%S.%F"];
 [theValues addObject:theTime];
 [[self connection] execute:@"INSERT INTO test (id,time) VALUES ($1,$2)" 
 values:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedInteger:i],theTime,nil]
 types:[NSArray arrayWithObjects:[NSNumber numberWithInteger:FLXPostgresTypeInteger],[NSNumber numberWithInteger:FLXPostgresTypeTime],nil]];
 }
 
 // read back the data
 FLXPostgresResult* theResult = [[self connection] execute:@"SELECT time FROM test ORDER BY id"];
 NSParameterAssert(theResult);
 for(NSUInteger i = 0; i < [theResult affectedRows]; i++) {
 NSArray* theRow = [theResult fetchRowAsArray];
 NSParameterAssert([theRow count]==1);
 NSDate* theCell = [theRow objectAtIndex:0];
 NSParameterAssert([theCell isKindOfClass:[NSDate class]]);
 NSLog(@"cell=%@ original=%@",theCell,[theValues objectAtIndex:i]);
 NSParameterAssert([[theCell description] isEqual:[[theValues objectAtIndex:i] description]]);
 }
 [self _dropTable];	
 }
 
 */

@end
