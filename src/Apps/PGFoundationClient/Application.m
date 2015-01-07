
#import "Application.h"

@implementation Application

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

-(NSString* )connectionPasswordForParameters:(NSDictionary* )theParameters{
	[[self term] printf:@"returning nil for password, parameters = %@",[theParameters description]];
	return nil;
}

-(void)connectionNotice:(NSString* )theMessage {
	[[self term] printf:@"Notice: %@",theMessage];
}

-(void)connectionError:(NSError *)theError {
	[[self term] printf:@"Error: %@ (%@/%d)",[theError localizedDescription],[theError domain],[theError code]];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(NSString* )translate:(NSString* )statement {
	if([statement isEqualToString:@"\\dd"]) {
		return @"SELECT datname AS Database FROM pg_database WHERE datistemplate = false;";
	}
	if([statement isEqualToString:@"\\dt"]) {
		return @"SELECT table_name AS Table FROM information_schema.tables WHERE table_schema = 'public';";
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
		[self connectionError:error];
		return nil;
	}
	if([r dataReturned]==NO) {
		return [NSString stringWithFormat:@"Affected Rows: %ld",[r affectedRows]];
	} else {
		return [r tableWithWidth:80];
	}
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
	
	// connect to database
	NSURL* url = [NSURL URLWithString:[arguments objectAtIndex:1]];
	NSError* error = nil;
	[[self db] connectWithURL:url error:&error];
	if(error) {
		[self connectionError:error];
		return -1;
	}

	while(![self signal]) {
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
	[[self db] disconnect];
	
	return 0;
}

@end
