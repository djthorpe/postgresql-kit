//
//  TestDelegate.m
//  postgresql
//
//  Created by David Thorpe on 04/05/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TestDelegate.h"

@implementation TestDelegate

-(id)init {
	self = [super init];
	if (self != nil) {
		m_theConnection = [[FLXPostgresConnection alloc] init];
		m_theTest = 0;
		m_theTimer = nil;
		m_isStopped = NO;
	}
	return self;
}

-(void)dealloc {
	[m_theConnection release];
	[super dealloc];
}

-(FLXPostgresConnection* )connection {
	return m_theConnection;
}

-(void)setTest:(NSUInteger)theTest {
	m_theTest = theTest;
}

-(NSUInteger)test {
	return m_theTest;
}

/////////////////////////////////

-(BOOL)awakeThread {  
	// set up server parameters
	[[FLXServer sharedServer] setDelegate:self];
	[[FLXServer sharedServer] setPort:9001];

	// set up connection parameters
	[[self connection] setPort:9001];
	
    // schedule a timer
	m_theTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(fireTimer:) userInfo:nil repeats:YES];
	[m_theTimer fire];
	
	return YES;
}

-(BOOL)stopped {
	return m_isStopped;
}

-(void)stop {  
	[[self connection] disconnect];
	[[FLXServer sharedServer] stop];
	[m_theTimer invalidate];
	m_isStopped = YES;
}

-(NSString* )_dataPath {
	return [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"PostgresServerKit"];
}

-(void)_startServer {	
	// initialize the data directory if nesessary
	if([[FLXServer sharedServer] startWithDataPath:[[self _dataPath] stringByAppendingPathComponent:@"data"]]==NO) {
		// starting failed, possibly because a server is already running
		if([[FLXServer sharedServer] state]==FLXServerStateAlreadyRunning) {
			[[FLXServer sharedServer] stop];
		}
	}    	
}
 
-(void)_connectToServer {
	[[self connection] setDatabase:@"postgres"];
	[[self connection] connect];
	NSParameterAssert([[self connection] connected]);
	NSParameterAssert([[self connection] database]);
	NSParameterAssert([[[self connection] database] isEqual:@"postgres"]);
}

-(void)_disconnectFromServer {
	[[self connection] disconnect];	
	NSParameterAssert([[self connection] connected]==NO);
}

-(void)_selectPing {
	[[self connection] execute:@"SELECT 1"];
}

-(NSArray* )_selectDatabases {
	FLXPostgresResult* theResult = [[self connection] execute:@"SELECT datname FROM pg_database WHERE datistemplate=false"];
	NSParameterAssert(theResult);
	NSParameterAssert([theResult affectedRows]);
	
	// enumerate databases
	NSMutableArray* theDatabases = [NSMutableArray arrayWithCapacity:[theResult affectedRows]];
	NSArray* theRow = nil;
	while(theRow = [theResult fetchRowAsArray]) {
		NSParameterAssert([theRow count] >= 1);
		NSParameterAssert([[theRow objectAtIndex:0] isKindOfClass:[NSString class]]);
		[theDatabases addObject:[theRow objectAtIndex:0]];
	}
	NSParameterAssert([theDatabases containsObject:@"postgres"]);
	return theDatabases;
}

-(NSArray* )_listTables {
	FLXPostgresResult* theResult = [[self connection] execute:@"SELECT tablename FROM pg_tables WHERE schemaname NOT IN ('pg_catalog','information_schema')"];
	NSParameterAssert(theResult);
	
	// enumerate tables
	NSMutableArray* theTables = [NSMutableArray arrayWithCapacity:[theResult affectedRows]];
	NSArray* theRow = nil;
	while(theRow = [theResult fetchRowAsArray]) {
		NSParameterAssert([theRow count] >= 1);
		NSParameterAssert([[theRow objectAtIndex:0] isKindOfClass:[NSString class]]);
		[theTables addObject:[theRow objectAtIndex:0]];
	}
	return theTables;      
}

-(void)_dropDatabase {
	NSArray* theDatabases = [self _selectDatabases];
	NSParameterAssert([theDatabases containsObject:@"test"]);
	[[self connection] execute:@"DROP DATABASE test"];
	theDatabases = [self _selectDatabases];
	NSParameterAssert([theDatabases containsObject:@"test"]==NO);	
}

-(void)_createDatabase {
	NSArray* theDatabases = [self _selectDatabases];
	if([theDatabases containsObject:@"test"]) {
		[self _dropDatabase];
	}
	[[self connection] execute:@"CREATE DATABASE test"];
	theDatabases = [self _selectDatabases];
	NSParameterAssert([theDatabases containsObject:@"test"]);		
}

-(void)_selectDatabaseTest {
	[[self connection] disconnect];
	[[self connection] setDatabase:@"test"];
	[[self connection] connect];
}

-(void)_dropTable {
	NSArray* theTables = [self _listTables];
	NSParameterAssert([theTables containsObject:@"test"]);
	[[self connection] execute:@"DROP TABLE test"];
	theTables = [self _listTables];
	NSParameterAssert([theTables containsObject:@"test"]==NO);
}

-(void)_createTable {
	NSArray* theTables = [self _listTables];
	NSParameterAssert([theTables containsObject:@"test"]==NO);
	[[self connection] execute:@"CREATE TABLE test ()"];
	theTables = [self _listTables];
	NSParameterAssert([theTables containsObject:@"test"]);
}

-(void)_insertIntegers {
	[[self connection] execute:@"CREATE TABLE test (id INTEGER NOT NULL,number INTEGER NOT NULL)"];
	NSMutableArray* theIntegers = [NSMutableArray array];
	NSUInteger theLength = 1000;
	// insert data
	for(NSUInteger i = 0; i < theLength; i++) {
		NSNumber* theInteger = [NSNumber numberWithInt:(rand() * INT_MAX)];
		[theIntegers addObject:theInteger];
		[[self connection] execute:[NSString stringWithFormat:@"INSERT INTO test (id,number) VALUES (%u,%@)",i,theInteger]];
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


///////////////////////////////////

-(void)fireTimer:(id)sender {
	if([[FLXServer sharedServer] isRunning]==NO) {
		// start the server
		[self setTest:0];
		[self _startServer];
	}
	
	switch([self test]) {
		case 0:
			// server has not yet been started
			break;
		case 1:
			NSLog(@"Testing 1: Connecting to the server");			
			[self _connectToServer];
			[self setTest:([self test] + 1)];
			break;
		case 2:
			NSLog(@"Testing 2: Disconnecting from the server");			
			[self _disconnectFromServer];
			[self setTest:([self test] + 1)];
			break;
		case 3:
			NSLog(@"Testing 3: Ping");			
			[self _connectToServer];
			[self _selectPing];
			[self setTest:([self test] + 1)];
			break;
		case 4:
			NSLog(@"Testing 4: Databases");			
			[self _selectDatabases];
			[self setTest:([self test] + 1)];
			break;
		case 5:
			NSLog(@"Testing 5: Create Database");			
			[self _createDatabase];
			[self setTest:([self test] + 1)];
			break;
		case 6:
			NSLog(@"Testing 6: Drop Database");			
			[self _dropDatabase];
			[self setTest:([self test] + 1)];
			break;
		case 7:
			NSLog(@"Testing 7: Create Table");					
			[self _createDatabase];
			[self _selectDatabaseTest];
			[self _createTable];
			[self setTest:([self test] + 1)];
			break;
		case 8:
			NSLog(@"Testing 8: Drop Table");			
			[self _dropTable];
			[self setTest:([self test] + 1)];
			break;
		case 9:
			NSLog(@"Testing 9: Date");			
			[self _insertDate];
			[self setTest:([self test] + 1)];
			break;			
		case 10:
			NSLog(@"Testing 10: Time");			
			[self _insertTime];
			[self setTest:([self test] + 1)];
			break;			
		case 11:
			NSLog(@"Testing 9: Integers");			
			[self _insertIntegers];
			[self setTest:([self test] + 1)];
			break;
		case 12:
			NSLog(@"Testing 10: Integers with bindings");			
			[self _insertIntegersWithBindings];
			[self setTest:([self test] + 1)];
			break;
		case 13:
			NSLog(@"Testing 11: Booleans");			
			[self _insertBooleans];
			[self setTest:([self test] + 1)];
			break;
		case 14:
			NSLog(@"Testing 12: Float4");			
			[self _insertFloat4];
			[self setTest:([self test] + 1)];
			break;
		case 15:
			NSLog(@"Testing 13: Float8");			
			[self _insertFloat8];
			[self setTest:([self test] + 1)];
			break;
		case 16:
			NSLog(@"Testing 14: Strings");			
			[self _insertStrings];
			[self setTest:([self test] + 1)];
			break;
		case 17:
			NSLog(@"Testing 15: Strings (UTF8)");			
			[self _insertStrings2];
			[self setTest:([self test] + 1)];
			break;
		case 18:
			NSLog(@"Testing 16: Text");			
			[self _insertText];
			[self setTest:([self test] + 1)];
			break;
		case 19:
			NSLog(@"Testing 17: Data");			
			[self _insertData];
			[self setTest:([self test] + 1)];
			break;
		default:
			NSLog(@"Testing is complete");
			[self stop];
			break;
	}	
}

/////////////////////////
// delegate methods

-(void)serverMessage:(NSString* )theMessage {
	NSLog(@"M:%@",theMessage);
}

-(void)serverStateDidChange:(NSString* )theMessage {
	// check for server started
	if([[FLXServer sharedServer] state]==FLXServerStateStarted) {
		// initiate testing
		[self setTest:1];
	}
	NSLog(@"S:%@",theMessage);
}

@end
