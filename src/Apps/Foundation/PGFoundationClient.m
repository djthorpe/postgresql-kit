
#import "PGFoundationClient.h"

@implementation PGFoundationClient

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	self = [super init];
	if(self) {
		_db = [[PGConnection alloc] init];
		_term = [[Terminal alloc] init];
		NSParameterAssert(_db);
		NSParameterAssert(_term);
		[_db setDelegate:self];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize db = _db;
@synthesize term = _term;
@dynamic prompt;

-(NSString* )prompt {
	// set prompt
	NSString* databaseName = [[self db] database];
	if(databaseName) {
		return [NSString stringWithFormat:@"%@> ",databaseName];
	} else {
		NSProcessInfo* process = [NSProcessInfo processInfo];
		return [NSString stringWithFormat:@"%@> ",[process processName]];
	}
}

////////////////////////////////////////////////////////////////////////////////
// PGConnectionDelegate delegate implementation

-(void)connection:(PGConnection* )connection willOpenWithParameters:(NSMutableDictionary* )dictionary {
	for(NSString* key in dictionary) {
		if([key isEqualToString:@"password"]) {
			continue;
		}
		[[self term] printf:@"%@: %@",key,[dictionary objectForKey:key]];
	}
}

-(void)connection:(PGConnection* )connection willExecute:(NSString* )theQuery values:(NSArray* )values {
	// TODO
}

-(void)connection:(PGConnection* )connection error:(NSError* )theError {
	[[self term] printf:@"Error: %@ (%@/%d)",[theError localizedDescription],[theError domain],[theError code]];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(NSString* )translate:(NSString* )statement {
	if([statement isEqualToString:@"\\dd"]) {
		return @"SELECT d.datname as \"Name\",pg_catalog.pg_get_userbyid(d.datdba) as \"Owner\",pg_catalog.pg_encoding_to_char(d.encoding) as \"Encoding\" FROM pg_catalog.pg_database d ORDER BY 1;";
	}
	if([statement isEqualToString:@"\\dt"]) {
		return @"SELECT n.nspname as \"Schema\",c.relname as \"Name\",CASE c.relkind WHEN 'r' THEN 'table' WHEN 'v' THEN 'view' WHEN 'i' THEN 'index' WHEN 'S' THEN 'sequence' WHEN 's' THEN 'special' WHEN 'f' THEN 'foreign table' END as \"Type\",pg_catalog.pg_get_userbyid(c.relowner) as \"Owner\" FROM pg_catalog.pg_class c LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE c.relkind IN ('r','') AND n.nspname <> 'pg_catalog' AND n.nspname <> 'information_schema' AND n.nspname !~ '^pg_toast' AND pg_catalog.pg_table_is_visible(c.oid) ORDER BY 1,2;";
	}
	if([statement isEqualToString:@"\\?"]) {
		return @"SHOW ALL";
	}
	return nil;
}

-(NSString* )execute:(NSString* )statement {
	NSError* error = nil;
	// trim
	statement = [statement stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if(![statement length]) {
		return nil;
	}
	
	// check for "special commands"
	if([statement hasPrefix:@"\\"]) {
		NSString* statement2 = [self translate:statement];
		if(!statement2) {
			[[self term] printf:@"Error: Unknown command, %@",statement];
			return nil;
		}
		statement = statement2;
	}
	
	// execute
	PGResult* r = [[self db] execute:statement error:&error];
	if(!r) {
		return nil;
	}
	if([r dataReturned]==NO) {
		return [NSString stringWithFormat:@"Affected Rows: %ld",[r affectedRows]];
	} else {
		return [r tableWithWidth:[[self term] columns]];
	}
}

-(BOOL)connect:(NSURL* )url inBackground:(BOOL)inBackground error:(NSError** )error {

	// in the case of connecting in the foreground...
	if(inBackground==NO) {
		return [[self db] connectWithURL:url error:error];
	}
	
	// if we are in the process of connecting, wait a while
	if([[self db] status]==PGConnectionStatusConnecting) {
		[NSThread sleepForTimeInterval:0.5];
		return YES;
	}

	NSLog(@"status = %d",[[self db] status]);

	// connect in background
	return [[self db] connectInBackgroundWithURL:url whenDone:^(NSError* error) {
		NSLog(@"Got error, code=%ld",[error code]);
		if([error code]==PGClientErrorNeedsPassword) {
			[[self term] printf:@"TODO: Ask for password"];
		} else if([error code]) {
			[self connection:[self db] error:error];
			[self setSignal:-1];
		}
	}];

}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(int)run {
	NSProcessInfo* process = [NSProcessInfo processInfo];
	NSArray* arguments = [process arguments];
	NSParameterAssert([arguments count]);
	
	if([arguments count] < 2) {
		[[self term] printf:@"Error: missing URL argument"];
		return -1;
	}
	
	// connection URL
	NSURL* url = [NSURL URLWithString:[arguments objectAtIndex:1]];
	NSError* error = nil;
	
	while(![self signal]) {
		// if we are not connected yet, then continue to connect
		if([[self db] status] != PGConnectionStatusConnected) {
			[[self term] printf:@"Connecting..."];
			[self connect:url inBackground:YES error:&error];
			continue;
		}
		
		// set prompt, read command
		[[self term] setPrompt:[self prompt]];
		NSString* line = [[self term] readline];

		// deal with the CTRL+D case
		if(!line) {
			[self setSignal:-1];
			[[self term] printf:@""];
			continue;
		}
		
		// execute a statement
		NSString* result = [self execute:line];

		// display result
		if(result) {
			// add statement to history
			[[self term] addHistory:line];
			// display result
			[[self term] printf:result];
		}
	}
	
	// disconnect from database
	if([[self db] status]==PGConnectionStatusConnected) {
		[[self db] disconnect];
	}
	
	return 0;
}

@end
