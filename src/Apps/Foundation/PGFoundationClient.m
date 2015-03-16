
// Copyright 2009-2015 David Thorpe
// https://github.com/djthorpe/postgresql-kit
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

#import "PGFoundationClient.h"

@implementation PGFoundationClient

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	self = [super init];
	if(self) {
		_db = [PGConnection new];
		[_db setDelegate:self];
		_term = [Terminal new];
		_passwordstore = [PGPasswordStore new];
		NSParameterAssert(_db);
		NSParameterAssert(_term);
		NSParameterAssert(_passwordstore);
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize db = _db;
@synthesize term = _term;
@synthesize passwordstore = _passwordstore;
@dynamic url;
@dynamic prompt;

-(NSURL* )url {
	NSArray* arguments = [[self settings] arguments];
	if([arguments count] != 1) {
		return nil;
	}
	NSString* url = [arguments objectAtIndex:0];
	if([url length]==0) {
		return nil;
	}
	return [NSURL URLWithString:url];
}

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
#ifdef DEBUG2
	[[self term] printf:@"connection:willOpenWithParameters:%@",dictionary];
#endif
	// if there is a password in the parameters, then store it
	NSString* password = [dictionary objectForKey:@"password"];
	if(!password) {
		password = [[self passwordstore] passwordForURL:[self url]];
	}
	if(password) {
		[self setPassword:password];
		[dictionary setObject:password forKey:@"password"];
	}
}

-(void)connection:(PGConnection* )connection willExecute:(NSString *)query {
	[[self term] printf:query];
}

-(void)connection:(PGConnection* )connection statusChange:(PGConnectionStatus)status description:(NSString *)description {
#ifdef DEBUG2
	[[self term] printf:@"StatusChange: %@ (%d)",description,status];
#endif
	// disconnected
	if(status==PGConnectionStatusDisconnected) {
		// indicate server connection has been shutdown
		[self stop];
	}
}

-(void)connection:(PGConnection* )connection error:(NSError* )error {
	[[self term] printf:@"Error: %@ (%@/%ld)",[error localizedDescription],[error domain],[error code]];
}

-(void)connection:(PGConnection* )connection notice:(NSString* )notice {
	[[self term] printf:@"Notice: %@",notice];
}

-(void)connection:(PGConnection *)connection notificationOnChannel:(NSString* )channelName payload:(NSString* )payload {
	[[self term] printf:@"Notification: %@ Payload: %@",channelName,payload];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(void)connect:(NSURL* )url {
	[[self db] connectWithURL:url whenDone:^(BOOL usedPassword, NSError* error) {
#ifdef DEBUG
		[[self term] printf:@"connectWithURL finished, usedPassword=%d error=%@",usedPassword,error];
#endif
		// if used password and no error, then store the password
		if(error==nil && usedPassword) {
			[[self passwordstore] setPassword:[self password] forURL:url saveToKeychain:YES];
		}
		
	}];
}

-(void)execute:(id)query {
	[[self db] executeQuery:query whenDone:^(PGResult* result, NSError* error) {
		if(error) {
			[[self term] printf:@"Error: %@ (%@/%ld)",[error localizedDescription],[error domain],[error code]];
		}
		if(result) {
			[self displayResult:result];
			[[self term] addHistory:query];
		}
	}];
}

-(void)command:(NSString* )command args:(NSArray* )args {
	if([command isEqualToString:@"ping"]) {
		[[self db] pingWithURL:[self url] whenDone:^(NSError *error) {
			[[self term] printf:@"pingWithURL finished, error=%@",error];
		}];
		return;
	}

	if([command isEqualToString:@"disconnect"]) {
		[[self db] disconnect];
		return;
	}

	if([command isEqualToString:@"reset"]) {
		[[self db] resetWhenDone:^(NSError *error) {
			[[self term] printf:@"resetWhenDone finished, error=%@",error];
		}];
		return;
	}

	if([command isEqualToString:@"listen"]) {
		if([args count] != 1) {
			[[self term] printf:@"error: listen: bad arguments"];
		} else {
			NSString* channel = [args objectAtIndex:0];
			[[self db] addNotificationObserver:channel];
		}
		return;
	}

	if([command isEqualToString:@"unlisten"]) {
		if([args count] != 1) {
			[[self term] printf:@"error: unlisten: bad arguments"];
		} else {
			NSString* channel = [args objectAtIndex:0];
			[[self db] removeNotificationObserver:channel];
		}
		return;
	}

	if([command isEqualToString:@"processes"]) {
		if([args count]) {
			[[self term] printf:@"error: tables: too many arguments"];
		} else {
			PGQueryObject* query = [PGQuery queryWithString:@"SELECT datname AS database,pid AS pid,query AS query,usename AS username,client_hostname AS remotehost,application_name,query_start,waiting FROM pg_stat_activity WHERE pid <> pg_backend_pid()"];
			[[self db] executeQuery:query whenDone:^(PGResult* result, NSError* error) {
				if(result) {
					[self displayResult:result];
				}
				if(error) {
					[[self term] printf:@"error: %@",error];
				}
			}];
		}
		return;
	}

	if([command isEqualToString:@"cancel"]) {
		if([args count]) {
			[[self term] printf:@"error: cancel: too many arguments"];
		} else {
			[[self db] cancelWhenDone:^(NSError *error) {
				[[self term] printf:@"cancelQueryWhenDone:error: %@",error];
			}];
		}
		return;
	}

	if([command isEqualToString:@"table"]) {
		NSString* tableName = nil;
		NSString* schemaName = nil;
		if([args count]==1) {
			tableName = [args objectAtIndex:0];
		} else if([args count]==2) {
			schemaName = [args objectAtIndex:0];
			tableName = [args objectAtIndex:1];
		} else {
			[[self term] printf:@"error: table: not enough arguments"];
			return;
		}
		PGQueryObject* query = [PGQuerySelect select:[PGQuerySource sourceWithTable:tableName schema:schemaName alias:nil] options:0];
		NSParameterAssert(query);
		[[self db] executeQuery:query whenDone:^(PGResult* result, NSError* error) {
			if(result) {
				[self displayResult:result];
			}
			if(error) {
				[[self term] printf:@"error: %@",error];
			}
		}];
		return;
	}
	
	if([command isEqualToString:@"createrole"]) {
		NSString* roleName = nil;
		if([args count]==1) {
			roleName = [args objectAtIndex:0];
		} else {
			[[self term] printf:@"createrole: not enough arguments"];
			return;
		}
		PGQuery* query = [PGQueryRole create:roleName options:0];
		NSParameterAssert(query);
		[[self db] executeQuery:query whenDone:^(PGResult* result, NSError* error) {
			if(result) {
				[self displayResult:result];
			}
			if(error) {
				[[self term] printf:@"error: %@",error];
			}
		}];
		return;
	}

	if([command isEqualToString:@"droprole"]) {
		NSString* roleName = nil;
		if([args count]==1) {
			roleName = [args objectAtIndex:0];
		} else {
			[[self term] printf:@"droprole: not enough arguments"];
			return;
		}
		PGQuery* query = [PGQueryRole drop:roleName options:0];
		NSParameterAssert(query);
		[[self db] executeQuery:query whenDone:^(PGResult* result, NSError* error) {
			if(result) {
				[self displayResult:result];
			}
			if(error) {
				[[self term] printf:@"error: %@",error];
			}
		}];
		return;
	}

	if([command isEqualToString:@"createdb"]) {
		NSString* databaseName = nil;
		if([args count]==1) {
			databaseName = [args objectAtIndex:0];
		} else {
			[[self term] printf:@"createdb: not enough arguments"];
			return;
		}
		PGQuery* query = [PGQueryDatabase create:databaseName options:0];
		NSParameterAssert(query);
		[[self db] executeQuery:query whenDone:^(PGResult* result, NSError* error) {
			if(result) {
				[self displayResult:result];
			}
			if(error) {
				[[self term] printf:@"error: %@",error];
			}
		}];
		return;
	}

	if([command isEqualToString:@"dropdb"]) {
		NSString* databaseName = nil;
		if([args count]==1) {
			databaseName = [args objectAtIndex:0];
		} else {
			[[self term] printf:@"dropdb: not enough arguments"];
			return;
		}
		PGQuery* query = [PGQueryDatabase drop:databaseName options:0];
		NSParameterAssert(query);
		[[self db] executeQuery:query whenDone:^(PGResult* result, NSError* error) {
			if(result) {
				[self displayResult:result];
			}
			if(error) {
				[[self term] printf:@"error: %@",error];
			}
		}];
		return;
	}

	if([command isEqualToString:@"createschema"]) {
		NSString* schemaName = nil;
		if([args count]==1) {
			schemaName = [args objectAtIndex:0];
		} else {
			[[self term] printf:@"createschema: not enough arguments"];
			return;
		}
		PGQuery* query = [PGQuerySchema create:schemaName options:0];
		NSParameterAssert(query);
		[[self db] executeQuery:query whenDone:^(PGResult* result, NSError* error) {
			if(result) {
				[self displayResult:result];
			}
			if(error) {
				[[self term] printf:@"error: %@",error];
			}
		}];
		return;
	}

	if([command isEqualToString:@"dropschema"]) {
		NSString* schemaName = nil;
		if([args count]==1) {
			schemaName = [args objectAtIndex:0];
		} else {
			[[self term] printf:@"dropschema: not enough arguments"];
			return;
		}
		PGQuery* query = [PGQuerySchema drop:schemaName options:0];
		NSParameterAssert(query);
		[[self db] executeQuery:query whenDone:^(PGResult* result, NSError* error) {
			if(result) {
				[self displayResult:result];
			}
			if(error) {
				[[self term] printf:@"error: %@",error];
			}
		}];
		return;
	}

	if([command isEqualToString:@"listschemas"]) {
		PGQuery* query = [PGQuerySchema listWithOptions:0];
		NSParameterAssert(query);
		[[self db] executeQuery:query whenDone:^(PGResult* result, NSError* error) {
			if(result) {
				[self displayResult:result];
			}
			if(error) {
				[[self term] printf:@"error: %@",error];
			}
		}];
		return;
	}

	if([command isEqualToString:@"listroles"]) {
		PGQuery* query = [PGQueryRole listWithOptions:0];
		NSParameterAssert(query);
		[[self db] executeQuery:query whenDone:^(PGResult* result, NSError* error) {
			if(result) {
				[self displayResult:result];
			}
			if(error) {
				[[self term] printf:@"error: %@",error];
			}
		}];
		return;
	}

	if([command isEqualToString:@"select"]) {
		NSString* tableName = [args objectAtIndex:0];
		PGQuerySelect* query = [PGQuerySelect select:tableName options:0];
		[query addColumn:@"x" alias:@"col1"];
		[query addColumn:@"y" alias:@"col2"];
		
		NSParameterAssert(query);
		[[self db] executeQuery:query whenDone:^(PGResult* result, NSError* error) {
			if(result) {
				[self displayResult:result];
			}
			if(error) {
				[[self term] printf:@"error: %@",error];
			}
		}];
		return;
	}

	[[self term] printf:@"Unknown command: %@",command];
}

-(void)displayResult:(PGResult* )result {
	NSParameterAssert(result);
	if([result dataReturned]) {
		NSString* table = [result tableWithWidth:[[self term] columns]];
		if(table) {
			[[self term] printf:table];
		} else {
			[[self term] printf:@"Empty result"];
		}
	} else {
		[[self term] printf:@"Affected Rows: %ld",[result affectedRows]];
	}
}

////////////////////////////////////////////////////////////////////////////////
// register command line options

-(void)registerCommandLineOptionsWithParser:(GBCommandLineParser* )parser {
	[super registerCommandLineOptionsWithParser:parser];
	// add a --password option for entering a password
	[parser registerOption:@"password" shortcut:'p' requirement:GBValueNone];
}

////////////////////////////////////////////////////////////////////////////////
// background thread to read commands

-(void)readlineThread:(id)anObject {
	@autoreleasepool {
		BOOL isRunning = YES;
		while(isRunning) {
			if([[self db] status]==PGConnectionStatusDisconnected) {
				isRunning = NO;
				continue;
			}
			
			if([[self db] status] != PGConnectionStatusConnected && [[self db] status] != PGConnectionStatusBusy) {
				[NSThread sleepForTimeInterval:0.1];
				continue;
			}
			
			// check for idle
			if([[self db] status] != PGConnectionStatusConnected) {
				continue;
			}

			[[self term] setPrompt:[self prompt]];
			NSString* line = [[self term] readline];
			// deal with CTRL+D
			if(line==nil) {
				isRunning = NO;
				continue;
			}
			if([line hasPrefix:@"\\"]) {
				// parse a command into arguments
				NSArray* commandargs = [[line substringFromIndex:1] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
				NSString* command = nil;
				NSMutableArray* args = [NSMutableArray new];
				for(NSString* arg in commandargs) {
					if([arg length]==0) {
						continue;
					}
					if(command==nil) {
						command = arg;
						continue;
					} else {
						[args addObject:arg];
					}
				}
				// run the command
				[self command:command args:args];
			} else {
				// execute a statement
				[self execute:line];
			}
		}
	}
	
	// signal end to main thread
	[self performSelectorOnMainThread:@selector(stop) withObject:nil waitUntilDone:NO];
}

-(BOOL)setup {
	if([self url]==nil) {
		[[self term] printf:@"Error: missing URL parameter"];
		return NO;
	}

	// Enter password
	if([[self settings] boolForKey:@"password"]) {
		// check for password entry
		[[self term] setPrompt:@"Password: "];
		NSString* password = [[self term] readline];
		if([password length]) {
			[[self passwordstore] setPassword:password forURL:[self url] saveToKeychain:YES];
		}
	}

	// start connection
	[self connect:[self url]];
	
	// set up a separate thread to deal with input
	[NSThread detachNewThreadSelector:@selector(readlineThread:) toTarget:self withObject:nil];
	
	// return success
	return YES;
}

-(void)stop {
	[super stop];
	[[self db] disconnect];
}

@end

////////////////////////////////////////////////////////////////////////////////
// main()

int main (int argc, const char* argv[]) {
	int returnValue = 0;
	@autoreleasepool {
		PGFoundationApp* app = (PGFoundationApp* )[PGFoundationClient sharedApp];
		NSError* error = nil;
		if([app parseOptionsWithArguments:argv count:argc error:&error]==NO) {
			returnValue = -1;
		} else {
			returnValue = [app run];
		}
	}
    return returnValue;
}


