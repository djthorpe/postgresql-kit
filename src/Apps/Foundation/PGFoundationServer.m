
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

#import "PGFoundationServer.h"

////////////////////////////////////////////////////////////////////////////////
// This example shows how to use the PGServerKit to create a server, as
// a foundation shell tool. When the server is started, any signal (TERM or KILL)
// is handled to stop the server gracefully

@implementation PGFoundationServer

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic dataPath;

-(NSString* )dataPath {
	NSString* theIdent = [[NSProcessInfo processInfo] processName];
	NSArray* theAppFolder = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask, YES);
	NSParameterAssert([theAppFolder count]);
	return [[theAppFolder objectAtIndex:0] stringByAppendingPathComponent:theIdent];
}

////////////////////////////////////////////////////////////////////////////////
// delegate methods

-(void)pgserver:(PGServer* )server message:(NSString* )message {
	printf("%s\n",[message UTF8String]);
}

-(void)pgserver:(PGServer* )server stateChange:(PGServerState)state {
	switch(state) {
		case PGServerStateAlreadyRunning:
		case PGServerStateRunning:
			printf("Server is ready to accept connections\n\n");
			printf("  Version = %s\n",[[[self server] version] UTF8String]);
			printf("  Data Path = %s\n",[[[self server] dataPath] UTF8String]);
			printf("  PID = %d\n",[server pid]);
			printf("  Port = %lu\n",[server port]);
			printf("  Hostname = %s\n",[[server hostname] UTF8String]);
			printf("  Socket path = %s\n",[[server socketPath] UTF8String]);
			printf("  Uptime = %lf seconds\n",[server uptime]);
			break;
		case PGServerStateError:
			// error occured, so program should quit with -1 return value
			printf("Server error, quitting\n");
			[super stop];
			[super stoppedWithReturnValue:-1];
			break;
		case PGServerStateStopped:
			// quit the application
			printf("Server stopped, ending application\n");
			[super stop];
			[super stoppedWithReturnValue:0];
			break;
		default:
			printf("Server state: %s\n",[[PGServer stateAsString:state] UTF8String]);
	}
}

////////////////////////////////////////////////////////////////////////////////
// methods

-(BOOL)setup {
	// get hostname and port
	NSString* hostname = [[self settings] objectForKey:@"hostname"];
	NSInteger port = [[self settings] integerForKey:@"port"];
	if(port < 1) {
		port = PGServerDefaultPort;
	}
	
	// create a server
	PGServer* server = [PGServer serverWithDataPath:[self dataPath]];

	// bind to server
	[self setServer:server];
	[[self server] setDelegate:self];

	// start server
	[[self server] startWithNetworkBinding:hostname port:port];
	
	// return success
	return YES;
}

-(void)stop {
	[super stop];
	[[self server] stop];
}

////////////////////////////////////////////////////////////////////////////////
// register command line options

-(void)registerCommandLineOptionsWithParser:(GBCommandLineParser* )parser {
	[super registerCommandLineOptionsWithParser:parser];
	// add a --hostname and --port options
	[parser registerOption:@"hostname" shortcut:"h" requirement:GBValueOptional];
	[parser registerOption:@"port" shortcut:"p" requirement:GBValueOptional];
}


@end

////////////////////////////////////////////////////////////////////////////////
// main()

int main (int argc, const char* argv[]) {
	int returnValue = 0;
	@autoreleasepool {
		returnValue = [(PGFoundationApp* )[PGFoundationServer sharedApp] run];
	}
    return returnValue;
}
