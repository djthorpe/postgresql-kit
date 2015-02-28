
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

#import "PGFoundationClient2.h"

@implementation PGFoundationClient2

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	self = [super init];
	if(self) {
		_db = [PGConnection2 new];
		[_db setDelegate:self];
		_term = [Terminal new];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize db = _db;
@synthesize term = _term;
@dynamic url;
@dynamic prompt;

-(NSURL* )url {
	return [NSURL URLWithString:@"postgres://pttnkktdoyjfyc:9Ftu1oLNncy1Qgtt6OLxw_BHc2@ec2-54-227-255-156.compute-1.amazonaws.com:5432/dej7aj0jp668p5"];
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
	[[self term] printf:@"connection:willOpenWithParameters:%@",dictionary];
}

-(void)connection:(PGConnection* )connection statusChange:(PGConnectionStatus)status {
	[[self term] printf:@"connection:statusChange:%d",status];
	
	// disconnected
	if(status==PGConnectionStatusDisconnected) {
		// indicate server connection has been shutdown
		[self stop];
	}
}

-(void)connection:(PGConnection* )connection error:(NSError* )theError {
	[[self term] printf:@"connection:error: %@ (%@/%ld)",[theError localizedDescription],[theError domain],[theError code]];
}

-(void)connection:(PGConnection *)connection notificationOnChannel:(NSString* )channelName payload:(NSString* )payload {
	[[self term] printf:@"connection:notification: %@ payload: %@",channelName,payload];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(void)connect:(NSURL* )url {
	[[self db] connectWithURL:url whenDone:^(BOOL usedPassword, NSError* error) {
		[[self term] printf:@"connectWithURL finished, usedPassword=%d error=%@",usedPassword,error];
	}];
}

-(void)execute:(NSString* )query {
	[[self db] execute:query whenDone:^(PGResult* result, NSError* error) {
		if(error) {
			[[self term] printf:@"Error: %@ (%@/%ld)",[error localizedDescription],[error domain],[error code]];
		}
		if(result) {
			[self displayResult:result];
			[[self term] addHistory:query];
		}
	}];
}

-(void)command:(NSString* )command {
/*	if([command isEqualToString:@"reset"]) {
		[[self db] resetWhenDone:^(NSError *error) {
			[[self term] printf:@"resetWhenDone finished, error=%@",error];
		}];
		return;
	}*/
	[[self term] printf:@"Unknown command: %@",command];
}

-(void)displayResult:(PGResult* )result {
	NSParameterAssert(result);
	if([result dataReturned]) {
		NSString* table = [result tableWithWidth:80];
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
// background thread to read commands

-(void)readlineThread:(id)anObject {
	@autoreleasepool {
		BOOL isRunning = YES;
		while(isRunning) {
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
				// run a command
				NSString* command = [[line substringFromIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
				[self command:command];
			} else {
				// execute a statement
				[self execute:line];
			}
		}
	}
	
	// signal end to main thread
	[self performSelectorOnMainThread:@selector(stop) withObject:nil waitUntilDone:NO];
}

-(void)setup {
	// start connection
	[self connect:[self url]];
	
	// set up a separate thread to deal with input
	[NSThread detachNewThreadSelector:@selector(readlineThread:) toTarget:self withObject:nil];
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
		returnValue = [(PGFoundationApp* )[PGFoundationClient2 sharedApp] run];
	}
    return returnValue;
}


