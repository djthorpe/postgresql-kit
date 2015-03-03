
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

#import <PGClientKit/PGClientKit.h>
#import <PGClientKit/PGClientKit+Private.h>

@implementation PGConnection (Reset)

-(void)resetWhenDone:(void(^)(NSError* error)) callback {
	NSParameterAssert(callback);
	// check to ensure connection
	if(_connection==nil || _state != PGConnectionStateNone) {
		callback([self raiseError:nil code:PGClientErrorState]);
		return;
	}
	// not yet implemented!
	callback([self raiseError:nil code:PGClientErrorUnknown reason:@"resetWhenDone: not yet implemented"]);
}

/*
	// remove existing socket from the runloop
	[self _socketDisconnect];

	// start the reset
	NSLog(@" 1 socket = %d",PQsocket(_connection));
	int returnCode = PQresetStart(_connection);
	NSLog(@" 12 socket = %d",PQsocket(_connection));
	if(returnCode==0) {
		PQfinish(_connection);
        _connection = nil;
		[self _updateStatus];
		callback([self _errorWithCode:PGClientErrorRejected url:nil]);
		return;
	}

	// add the new socket to the run loop
	[self _socketConnect:PGConnectionStateReset];
	
	// set callback
	//NSParameterAssert(_callback==nil);
	//_callback = (__bridge_retained void* )[callback copy];

	// call PGresetpoll until we have a new socket
	PostgresPollingStatusType pqstatus = PGRES_POLLING_ACTIVE;
	int socket = PQsocket(_connection);
//	struct timeval timeout = {.tv_sec = 15, .tv_usec = 0};
	fd_set mask = {};
	FD_ZERO (&mask);
	FD_SET (socket, &mask);
	while(1) {
		NSLog(@" 2 socket = %d",PQsocket(_connection));
		pqstatus = PQresetPoll(_connection);
		NSLog(@"pqstatus=%d socket=%d",pqstatus,socket);
		switch(pqstatus) {
			case PGRES_POLLING_READING:
				NSLog(@"READING");
				select(socket + 1,&mask,NULL,NULL,NULL);
				break;
			case PGRES_POLLING_WRITING:
				NSLog(@"WRITING");
				select(socket + 1,NULL,&mask,NULL,NULL);
				break;
			case PGRES_POLLING_OK:
				break;
			default:
				break;
		}
		if(pqstatus==PGRES_POLLING_OK|| pqstatus==PGRES_POLLING_FAILED) {
			break;
		}
	}
	NSLog(@" 3 socket = %d",PQsocket(_connection));
	if(pqstatus==PGRES_POLLING_OK) {
		callback(nil);
		[self setState:PGConnectionStateNone];
		[self _socketDisconnect];
		[self _socketConnect:PGConnectionStateNone];
	} else {
		callback([self _errorWithCode:PGClientErrorRejected url:nil reason:@"Reset rejected"]);
		[self disconnect];
	}
}
*/

@end


