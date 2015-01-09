
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
@dynamic url;

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

-(NSURL* )url {
	NSProcessInfo* process = [NSProcessInfo processInfo];
	NSArray* arguments = [process arguments];
	if([arguments count] < 2) {
		return nil;
	}
	return [NSURL URLWithString:[arguments objectAtIndex:1]];
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

-(void)connection:(PGConnection* )connection statusChange:(PGConnectionStatus)status {
	if([self stopping] && status==PGConnectionStatusDisconnected) {
		// indicate server connection has been shutdown
		[self stoppedWithReturnValue:0];
	}
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
	// connect in background
	return [[self db] connectInBackgroundWithURL:url whenDone:^(NSError* error) {
		if([error code]==PGClientErrorNeedsPassword) {
			[[self term] printf:@"TODO: Ask for password"];
		} else if([error code]) {
			[self connection:[self db] error:error];
			[self stop];
		}
	}];
}

////////////////////////////////////////////////////////////////////////////////
// background thread to read commands

-(void)readlineThread:(id)anObject {
	@autoreleasepool {
		BOOL isRunning = YES;
		while(isRunning) {
			if([[self db] status] != PGConnectionStatusConnected) {
				[NSThread sleepForTimeInterval:0.1];
				continue;
			}
			// set prompt, read command
			[[self term] setPrompt:[self prompt]];
			NSString* line = [[self term] readline];
			
			// deal with CTRL+D
			if(line==nil) {
				isRunning = NO;
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
	}
	[self performSelectorOnMainThread:@selector(readlineThreadEnded:) withObject:nil waitUntilDone:YES];
#ifdef DEBUG
	NSLog(@"Background thread ended");
#endif
}

-(void)readlineThreadEnded:(id)sender {
	[self stop];
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(void)setup {
	NSError* error = nil;
	if([self url]==nil) {
		[[self term] printf:@"Error: missing URL argument"];
		[self stop];
	}
	BOOL isSuccess = [self connect:[self url] inBackground:NO error:&error];
	if(isSuccess==NO) {
		[self stop];
	}
	
	// set up a separate thread to deal with input
	[NSThread detachNewThreadSelector:@selector(readlineThread:) toTarget:self withObject:nil];
}

-(void)stop {
	[super stop];

	if([[self db] status]==PGConnectionStatusConnected) {
		[[self term] printf:@"Disconnecting"];
		[[self db] disconnect];
	} else {
		// no tear-down to be performed, so indicate stopped
		[self stoppedWithReturnValue:0];
	}
}

@end

////////////////////////////////////////////////////////////////////////////////
// main()

int main (int argc, const char* argv[]) {
	int returnValue = 0;
	@autoreleasepool {
		returnValue = [(PGFoundationApp* )[PGFoundationClient sharedApp] run];
	}
    return returnValue;
}


