
#import "Application.h"

@implementation Application

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

@synthesize db = _db;
@synthesize term = _term;

// methods
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

-(NSString* )execute:(NSString* )statement {
	NSError* error = nil;
	PGResult* r = [[self db] execute:statement error:&error];
	if(r) {
		return [r tableWithWidth:80];
	} else {
		[self connectionError:error];
		return nil;
	}
}

-(int)run {
	NSProcessInfo* process = [NSProcessInfo processInfo];
	NSArray* arguments = [process arguments];
	NSParameterAssert([arguments count]);
	
	if([arguments count] < 2) {
		[[self term] printf:@"Error: missing URL argument"];
		return -1;
	}
	
	// set prompt
	[[self term] setPrompt:[NSString stringWithFormat:@"%@> ",[process processName]]];
	
	// connect to database
	NSURL* url = [NSURL URLWithString:[arguments objectAtIndex:1]];
	NSError* error = nil;
	[[self db] connectWithURL:url error:&error];
	if(error) {
		[self connectionError:error];
		return -1;
	}

	while(![self signal]) {
		NSString* line = [[self term] readline];
		if(line) {
			NSString* result = [self execute:line];
			if(result) {
				[[self term] printf:result];
				[[self term] addHistory:line];
			}
		} else {
			[self setSignal:-1];
		}
	}
	
	// disconnect from database 
	[[self db] disconnect];
	
	return 0;
}

@end
