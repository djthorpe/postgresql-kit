
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

#define DEBUG2

////////////////////////////////////////////////////////////////////////////////
#pragma mark C callback functions
////////////////////////////////////////////////////////////////////////////////

/**
 *  This method is called from the run loop upon new data being available to read
 *  on the socket, or the socket being able to write more data to the socket
 */
void _socketCallback(CFSocketRef s, CFSocketCallBackType callBackType,CFDataRef address,const void* data,void* self) {
	[(__bridge PGConnection* )self _socketCallback:callBackType];
}

/**
 *  Notice processor callback which is called when there is a NOTICE message from
 *  the libpq library
 */
void _noticeProcessor(void* arg,const char* cString) {
	NSString* notice = [NSString stringWithUTF8String:cString];
	PGConnection* connection = (__bridge PGConnection* )arg;
	NSCParameterAssert(connection && [connection isKindOfClass:[PGConnection class]]);
	if([[connection delegate] respondsToSelector:@selector(connection:notice:)]) {
		[[connection delegate] connection:connection notice:notice];
	}
}


@implementation PGConnection (Callbacks)

////////////////////////////////////////////////////////////////////////////////
#pragma mark private methods - socket connect/disconnect
////////////////////////////////////////////////////////////////////////////////

-(void)_socketConnect:(PGConnectionState)state {
	NSParameterAssert(_state==PGConnectionStateNone);
	NSParameterAssert(state==PGConnectionStateConnect || state==PGConnectionStateReset || state==PGConnectionStateNone);
	NSParameterAssert(_connection);
	NSParameterAssert(_socket==nil && _runloopsource==nil);
	
	// create socket object
	CFSocketContext context = {0, (__bridge void* )(self), NULL, NULL, NULL};
	_socket = CFSocketCreateWithNative(NULL,PQsocket(_connection),kCFSocketReadCallBack | kCFSocketWriteCallBack,&_socketCallback,&context);
	NSParameterAssert(_socket && CFSocketIsValid(_socket));
	// let libpq do the socket closing
	CFSocketSetSocketFlags(_socket,~kCFSocketCloseOnInvalidate & CFSocketGetSocketFlags(_socket));
	
	// set state
	[self setState:state];
	[self _updateStatus];
	
	// add to run loop to begin polling
	_runloopsource = CFSocketCreateRunLoopSource(NULL,_socket,0);
	NSParameterAssert(_runloopsource && CFRunLoopSourceIsValid(_runloopsource));
	CFRunLoopAddSource(CFRunLoopGetCurrent(),_runloopsource,(CFStringRef)kCFRunLoopCommonModes);
}

-(void)_socketDisconnect {
	if(_runloopsource) {
		CFRunLoopSourceInvalidate(_runloopsource);
		CFRelease(_runloopsource);
		_runloopsource = nil;
	}
	if(_socket) {
		CFSocketInvalidate(_socket);
		CFRelease(_socket);
		_socket = nil;
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark private methods - socket callbacks
////////////////////////////////////////////////////////////////////////////////

-(void)_socketCallbackNotification {
	NSParameterAssert(_connection);
	// consume input
	PQconsumeInput(_connection);
	// loop for notifications
	PGnotify* notify = nil;
	while((notify = PQnotifies(_connection)) != nil) {
		if([[self delegate] respondsToSelector:@selector(connection:notificationOnChannel:payload:)]) {
			NSString* channel = [NSString stringWithUTF8String:notify->relname];
			NSString* payload = [NSString stringWithUTF8String:notify->extra];
			[[self delegate] connection:self notificationOnChannel:channel payload:payload];
        }
		PQfreemem(notify);
	}
}

-(void)_socketCallbackConnectEndedWithStatus:(PostgresPollingStatusType)pqstatus {
	NSParameterAssert(_callback);
	void (^callback)(BOOL usedPassword,NSError* error) = (__bridge void (^)(BOOL,NSError* ))(_callback);

	// update the status
	[self setState:PGConnectionStateNone];
	[self _updateStatus]; // this also calls disconnect when rejected

	// callback
	if(pqstatus==PGRES_POLLING_OK) {
		// set up notice processor, set success condition
		PQsetNoticeProcessor(_connection,_noticeProcessor,(__bridge void *)(self));
		callback(PQconnectionUsedPassword(_connection) ? YES : NO,nil);
	} else if(PQconnectionNeedsPassword(_connection)) {
		// error callback - connection not made, needs password
		callback(NO,[self raiseError:nil code:PGClientErrorNeedsPassword]);
	} else if(PQconnectionUsedPassword(_connection)) {
		// error callback - connection not made, password was invalid
		callback(YES,[self raiseError:nil code:PGClientErrorInvalidPassword]);
	} else {
		// error callback - connection not made, some other kind of rejection
		callback(YES,[self raiseError:nil code:PGClientErrorRejected]);
	}
	_callback = nil;
}


-(void)_socketCallbackResetEndedWithStatus:(PostgresPollingStatusType)pqstatus {
	NSParameterAssert(_callback);
	void (^callback)(NSError* error) = (__bridge void (^)(NSError* ))(_callback);
	if(pqstatus==PGRES_POLLING_OK) {
		callback(nil);
	} else {
		callback([self raiseError:nil code:PGClientErrorRejected]);
	}
	_callback = nil;
	[self setState:PGConnectionStateNone];
	[self _updateStatus]; // this also calls disconnect when rejected
}

/**
 *  The connect callback will continue to poll the connection for new data. When
 *  the poll status is either OK or FAILED, the application's callback block is
 *  run.
 */
-(void)_socketCallbackConnect {
	NSParameterAssert(_connection);

	PostgresPollingStatusType pqstatus = PQconnectPoll(_connection);
	switch(pqstatus) {
		case PGRES_POLLING_READING:
		case PGRES_POLLING_WRITING:
			// still connecting - call poll again
			PQconnectPoll(_connection);
			break;
		case PGRES_POLLING_OK:
		case PGRES_POLLING_FAILED:
			// finished connecting
			[self _socketCallbackConnectEndedWithStatus:pqstatus];
			break;
		default:
			break;
	}
}

/**
 *  The reset callback is very similar to the connect callback, and could probably
 *  be merged with that one.
 */
-(void)_socketCallbackReset {
	NSParameterAssert(_connection);

	PostgresPollingStatusType pqstatus = PQresetPoll(_connection);
	switch(pqstatus) {
		case PGRES_POLLING_READING:
		case PGRES_POLLING_WRITING:
			// still connecting - call poll again
			PQresetPoll(_connection);
			break;
		case PGRES_POLLING_OK:
		case PGRES_POLLING_FAILED:
			// finished connecting
			[self _socketCallbackResetEndedWithStatus:pqstatus];
			break;
		default:
			break;
	}
}

/**
 *  In the case of a query being processed, this method will consume any input
 *  then any results from the server
 */
-(void)_socketCallbackQueryRead {
	NSParameterAssert(_connection);

	PQconsumeInput(_connection);

	/* it seems that we don't really need to check for busy and it seems to
	 * create some issues, so ignore for now
	// check for busy, return if more to do
	if(PQisBusy(_connection)) {
		return;
	}
	*/

	// consume results
	PGresult* result = nil;
	while(1) {
		result = PQgetResult(_connection);
		if(result==nil) {
			break;
		}
		NSError* error = nil;
		PGResult* r = nil;
		// check for connection errors
		if(PQresultStatus(result)==PGRES_EMPTY_QUERY) {
			// callback empty query
			error = [self raiseError:nil code:PGClientErrorQuery reason:@"Empty query"];
			PQclear(result);
		} else if(PQresultStatus(result)==PGRES_BAD_RESPONSE || PQresultStatus(result)==PGRES_FATAL_ERROR) {
			error = [self raiseError:nil code:PGClientErrorExecute reason:[NSString stringWithUTF8String:PQresultErrorMessage(result)]];
			PQclear(result);
		} else {
			r = [[PGResult alloc] initWithResult:result format:PGClientTupleFormatText];
		}
		if(r || error) {
			NSParameterAssert(_callback);
			void (^callback)(PGResult* result,NSError* error) = (__bridge void (^)(PGResult* ,NSError* ))(_callback);
			callback(r,error);
		}
	}
	
	// all results consumed - update state
	[self setState:PGConnectionStateNone];
	_callback = nil; // release the callback
	[self _updateStatus];
}

/**
 *  In the case of a query being processed, this method will consume any input
 *  flush the connection and consume any results which are being processed.
 */
-(void)_socketCallbackQueryWrite {
	NSParameterAssert(_connection);
	// flush
	NSLog(@"=>PQflush");
	int returnCode = PQflush(_connection);
	NSLog(@"<=PQflush");
	if(returnCode==-1) {
		// callback with error
		NSParameterAssert(_callback);
		void (^callback)(PGResult* result,NSError* error) = (__bridge void (^)(PGResult* ,NSError* ))(_callback);
		NSError* error = [self raiseError:nil code:PGClientErrorState reason:@"Data flush failed during query"];
		callback(nil,error);
	}
}

/**
 *  This method is called from _socketCallback and depending on the
 *  current state of the connection, it will call the connect, reset, query
 *  or notification socket callback
 */
-(void)_socketCallback:(CFSocketCallBackType)callBackType {
#ifdef DEBUG2
	switch(callBackType) {
		case kCFSocketReadCallBack:
			NSLog(@"kCFSocketReadCallBack");
			break;
		case kCFSocketAcceptCallBack:
			NSLog(@"kCFSocketAcceptCallBack");
			break;
		case kCFSocketDataCallBack:
			NSLog(@"kCFSocketDataCallBack");
			break;
		case kCFSocketConnectCallBack:
			NSLog(@"kCFSocketConnectCallBack");
			break;
		case kCFSocketWriteCallBack:
			NSLog(@"kCFSocketWriteCallBack");
			break;
		default:
			NSLog(@"CFSocketCallBackType OTHER");
			break;
	}
#endif
	switch([self state]) {
		case PGConnectionStateConnect:
			[self _socketCallbackConnect];
			break;
		case PGConnectionStateReset:
			[self _socketCallbackReset];
			break;
		case PGConnectionStateQuery:
			if(callBackType==kCFSocketReadCallBack) {
				[self _socketCallbackQueryRead];
				[self _socketCallbackNotification];
			} else if(callBackType==kCFSocketWriteCallBack) {
				[self _socketCallbackQueryWrite];
			}
			break;
		default:
			[self _socketCallbackNotification];
			break;
	}
	
	[self _updateStatus];
}

@end



