
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
#include <libpq-fe.h>

// define DEBUG2 for extra debugging output on NSLog
#define DEBUG2

////////////////////////////////////////////////////////////////////////////////
// forward declarations

@interface PGConnection2 ()

// properties
@property (atomic) PGConnectionState state;
@property PGconn* pqconn;

// methods
-(void)_socketCallback:(CFSocketCallBackType)callBackType;

@end

////////////////////////////////////////////////////////////////////////////////
// C callbacks

void _socketCallback(CFSocketRef s, CFSocketCallBackType callBackType,CFDataRef address,const void* data,void* self) {
	[(__bridge PGConnection2* )self _socketCallback:callBackType];
}

void _noticeProcessor(void* arg,const char* cString) {
	NSString* notice = [NSString stringWithUTF8String:cString];
	PGConnection2* connection = (__bridge PGConnection2* )arg;
	NSCParameterAssert(connection && [connection isKindOfClass:[PGConnection2 class]]);
	if([[connection delegate] respondsToSelector:@selector(connection:notice:)]) {
		[[connection delegate] connection:connection notice:notice];
	}
}

////////////////////////////////////////////////////////////////////////////////

@implementation PGConnection2

////////////////////////////////////////////////////////////////////////////////
#pragma mark constructor and destructors
////////////////////////////////////////////////////////////////////////////////


-(instancetype)init {
    self = [super init];
    if(self) {
		_connection = nil;
		_timeout = 0;
		_state = PGConnectionStateNone;
		pgdata2obj_init();
    }
    return self;
}

-(void)finalize {
	[self disconnect];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

@dynamic status;
@dynamic user;
@dynamic database;
@dynamic serverProcessID;
@synthesize timeout = _timeout;
@synthesize state = _state;
@synthesize pqconn = _connection;

-(PGConnectionStatus)status {
	if(_connection==nil) {
		return PGConnectionStatusDisconnected;
	}
	switch(PQstatus(_connection)) {
		case CONNECTION_OK:
			return [self state]==PGConnectionStateNone ? PGConnectionStatusConnected : PGConnectionStatusBusy;
		case CONNECTION_STARTED:
		case CONNECTION_MADE:
		case CONNECTION_AWAITING_RESPONSE:
		case CONNECTION_AUTH_OK:
		case CONNECTION_SSL_STARTUP:
		case CONNECTION_SETENV:
			return PGConnectionStatusConnecting;
		default:
			return PGConnectionStatusRejected;
	}
}

-(NSString* )user {
	if(_connection==nil || PQstatus(_connection) != CONNECTION_OK) {
		return nil;
	}
	return [NSString stringWithUTF8String:PQuser(_connection)];
}

-(NSString* )database {
	if(_connection==nil || PQstatus(_connection) != CONNECTION_OK) {
		return nil;
	}
	return [NSString stringWithUTF8String:PQdb(_connection)];
}

-(int)serverProcessID {
	if(_connection==nil || PQstatus(_connection) != CONNECTION_OK) {
		return 0;
	}
	return PQbackendPID(_connection);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark private methods - error handling
////////////////////////////////////////////////////////////////////////////////

NSDictionary* PGClientErrorDomainCodeDescription = nil;

-(NSError* )_errorWithCode:(int)errorCode url:(NSURL* )url reason:(NSString* )format,... {
	static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        // Do some work that happens once
		PGClientErrorDomainCodeDescription = @{
			[NSNumber numberWithInt:PGClientErrorNone]: @"No Error",
			[NSNumber numberWithInt:PGClientErrorState]: @"Connection State Mismatch",
			[NSNumber numberWithInt:PGClientErrorParameters]: @"Invalid connection parameters",
			[NSNumber numberWithInt:PGClientErrorNeedsPassword]: @"Connection requires authentication",
			[NSNumber numberWithInt:PGClientErrorInvalidPassword]: @"Password authentication failed",
			[NSNumber numberWithInt:PGClientErrorRejected]: @"Connection was rejected",
			[NSNumber numberWithInt:PGClientErrorExecute]: @"Execution error",
			[NSNumber numberWithInt:PGClientErrorEmptyQuery]: @"Empty query",
			[NSNumber numberWithInt:PGClientErrorUnknown]: @"Unknown or internal error"
		};
    });
	NSString* reason = nil;
	if(format) {
		va_list args;
		va_start(args,format);
		reason = [[NSString alloc] initWithFormat:format arguments:args];
		va_end(args);
	}
	NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
	if(reason==nil) {
		reason = [PGClientErrorDomainCodeDescription objectForKey:[NSNumber numberWithInt:errorCode]];
	}
	if(reason==nil) {
		reason = [PGClientErrorDomainCodeDescription objectForKey:[NSNumber numberWithInt:PGClientErrorUnknown]];
	}
	NSParameterAssert(reason);
	[userInfo setObject:reason forKey:NSLocalizedDescriptionKey];
	if(url) {
		[userInfo setObject:url forKey:PGClientErrorURLKey];
	}
	return [NSError errorWithDomain:PGClientErrorDomain code:errorCode userInfo:userInfo];
}

-(NSError* )_errorWithCode:(int)errorCode url:(NSURL* )url {
	return [self _errorWithCode:errorCode url:url reason:nil];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark private methods - status update
////////////////////////////////////////////////////////////////////////////////

NSDictionary* PGConnectionStatusDescription = nil;

-(void)_updateStatus {
	static PGConnectionStatus oldStatus = PGConnectionStatusDisconnected;
	static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        // Do some work that happens once
		PGConnectionStatusDescription = @{
			[NSNumber numberWithInt:PGConnectionStatusBusy]: @"Busy",
			[NSNumber numberWithInt:PGConnectionStatusConnected]: @"Idle",
			[NSNumber numberWithInt:PGConnectionStatusConnecting]: @"Connecting",
			[NSNumber numberWithInt:PGConnectionStatusDisconnected]: @"Disconnected",
			[NSNumber numberWithInt:PGConnectionStatusRejected]: @"Rejected"
		};
    });
	if([self status] == oldStatus) {
		return;
	}
	oldStatus = [self status];
	if([[self delegate] respondsToSelector:@selector(connection:statusChange:description:)]) {
		[[self delegate] connection:self statusChange:[self status] description:[PGConnectionStatusDescription objectForKey:[NSNumber numberWithInt:[self status]]]];
	}
	
	// if connection is rejected, then call disconnect
	if(oldStatus==PGConnectionStatusRejected) {
		[self disconnect];
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
	if(pqstatus==PGRES_POLLING_OK) {
		// set up notice processor, set success condition
		PQsetNoticeProcessor(_connection,_noticeProcessor,(__bridge void *)(self));
		callback(PQconnectionUsedPassword(_connection) ? YES : NO,nil);
	} else if(PQconnectionNeedsPassword(_connection)) {
		// error callback - connection not made, needs password
		callback(NO,[self _errorWithCode:PGClientErrorNeedsPassword url:nil]);
	} else if(PQconnectionUsedPassword(_connection)) {
		// error callback - connection not made, password was invalid
		callback(YES,[self _errorWithCode:PGClientErrorInvalidPassword url:nil]);
	} else {
		// error callback - connection not made, some other kind of rejection
		callback(YES,[self _errorWithCode:PGClientErrorRejected url:nil]);
	}
	_callback = nil;
	[self setState:PGConnectionStateNone];
	[self _updateStatus]; // this also calls disconnect when rejected
}


-(void)_socketCallbackResetEndedWithStatus:(PostgresPollingStatusType)pqstatus {
	NSParameterAssert(_callback);
	void (^callback)(NSError* error) = (__bridge void (^)(NSError* ))(_callback);
	if(pqstatus==PGRES_POLLING_OK) {
		callback(nil);
	} else {
		callback([self _errorWithCode:PGClientErrorRejected url:nil]);
	}
	_callback = nil;
	[self setState:PGConnectionStateNone];
	[self _updateStatus]; // this also calls disconnect when rejected
}

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

-(void)_socketCallbackQuery {
	NSParameterAssert(_connection);

	// consume input
	PQconsumeInput(_connection);

	// flush
	int returnCode = PQflush(_connection);
	if(returnCode==1) {
		// not able to send all the data yet
		return;
	} else if(returnCode==-1) {
		// callback with error
		NSParameterAssert(_callback);
		void (^callback)(PGResult* result,NSError* error) = (__bridge void (^)(PGResult* ,NSError* ))(_callback);
		NSError* error = [self _errorWithCode:PGClientErrorState url:nil reason:@"Flush failed"];
		callback(nil,error);
	}

	// check for busy, return if more to do
	if(PQisBusy(_connection)) {
		return;
	}

	// consume results
	PGresult* result = nil;
	while((result = PQgetResult(_connection))) {
		NSError* error = nil;
		PGResult* r = nil;
		// check for connection errors
		if(PQresultStatus(result)==PGRES_EMPTY_QUERY) {
			// callback empty query
			error = [self _errorWithCode:PGClientErrorEmptyQuery url:nil];
			PQclear(result);
		} else if(PQresultStatus(result)==PGRES_BAD_RESPONSE || PQresultStatus(result)==PGRES_FATAL_ERROR) {
			error = [self _errorWithCode:PGClientErrorExecute url:nil reason:[NSString stringWithUTF8String:PQresultErrorMessage(result)]];
			PQclear(result);
		} else {
			r = [[PGResult alloc] initWithResult:result format:PGClientTupleFormatText];
		}
		if(r || error) {
			NSParameterAssert(_callback);
			void (^callback)(PGResult* result,NSError* error) = (__bridge void (^)(PGResult* ,NSError* ))(_callback);
			callback(r,error);
		}
		PQconsumeInput(_connection);
	}
	// all results consumed - update state
	[self setState:PGConnectionStateNone];
	_callback = nil; // release the callback
	[self _updateStatus];
}

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
			[self _socketCallbackQuery];
			[self _socketCallbackNotification];
			break;
		default:
			[self _socketCallbackNotification];
			break;
	}
	
	[self _updateStatus];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark private methods - connections
////////////////////////////////////////////////////////////////////////////////

-(NSDictionary* )_connectionParametersForURL:(NSURL* )theURL {
	// make parameters from the URL
	NSMutableDictionary* theParameters = [[theURL postgresqlParameters] mutableCopy];
	if(theParameters==nil) {
		return nil;
	}
	if([self timeout]) {
		[theParameters setValue:[NSNumber numberWithUnsignedInteger:[self timeout]] forKey:@"connect_timeout"];
	}
	// set client encoding and application name if not already set
	if([theParameters objectForKey:@"client_encoding"]==nil) {
		[theParameters setValue:PGConnectionDefaultEncoding forKey:@"client_encoding"];
	}
	if([theParameters objectForKey:@"application_name"]==nil) {
		[theParameters setValue:[[NSProcessInfo processInfo] processName] forKey:@"application_name"];
	}
	// Allow delegate to make changes to the parameters
	if([[self delegate] respondsToSelector:@selector(connection:willOpenWithParameters:)]) {
		[[self delegate] connection:self willOpenWithParameters:theParameters];
	}
	return theParameters;
}

-(void)_pingInBackgroundCallback:(NSArray* )parameters {
	NSParameterAssert(parameters && [parameters count]==2);
	void(^callback)(NSError* error) = [parameters objectAtIndex:0];
	NSParameterAssert(callback);
	NSError* error = [parameters objectAtIndex:1];
	NSParameterAssert([error isKindOfClass:[NSError class]]);
	NSParameterAssert([[error domain] isEqualToString:PGClientErrorDomain]);
	if([error code]==PGClientErrorNone) {
		callback(nil);
	} else {
		callback(error);
	}
}

-(void)_pingInBackground:(NSArray* )parameters {
	NSParameterAssert(parameters && [parameters count]==4);
	NSThread* callbackThread = [parameters objectAtIndex:0];
	NSParameterAssert([callbackThread isKindOfClass:[NSThread class]]);
	NSDictionary* dictionary = [parameters objectAtIndex:1];
	NSParameterAssert([dictionary isKindOfClass:[NSDictionary class]]);
	void(^callback)(NSError* error) = [parameters objectAtIndex:2];
	NSParameterAssert(callback);
	NSURL* url = [parameters objectAtIndex:3];
	NSParameterAssert([url isKindOfClass:[NSURL class]]);

	@autoreleasepool {
		// make the key value pairs
		PGKVPairs* pairs = makeKVPairs(dictionary);
		NSError* error = nil;
		PGPing status = PQPING_NO_ATTEMPT;
		if(pairs != nil) {
			status = PQpingParams(pairs->keywords,pairs->values,0);
			freeKVPairs(pairs);
		}
		switch(status) {
			case PQPING_OK:
				error = [self _errorWithCode:PGClientErrorNone url:url];
				break;
			case PQPING_REJECT:
				error = [self _errorWithCode:PGClientErrorRejected url:url reason:@"Remote server is not accepting connections"];
				break;
			case PQPING_NO_ATTEMPT:
				error = [self _errorWithCode:PGClientErrorParameters url:url];
				break;
			case PQPING_NO_RESPONSE:
				error = [self _errorWithCode:PGClientErrorRejected url:url reason:@"No response from remote server"];
				break;
			default:
				error = [self _errorWithCode:PGClientErrorUnknown url:url reason:@"Unknown ping error (%d)",status];
				break;
		}
		
		// perform callback on main thread
		[self performSelector:@selector(_pingInBackgroundCallback:) onThread:[NSThread mainThread] withObject:@[ callback, error ] waitUntilDone:NO];
	}
}

-(void)_socketConnect:(PGConnectionState)state {
	NSParameterAssert(_state==PGConnectionStateNone);
	NSParameterAssert(state==PGConnectionStateConnect || state==PGConnectionStateReset || state==PGConnectionStateNone);
	NSParameterAssert(_connection);
	NSParameterAssert(_socket==nil && _runloopsource==nil);
	
	// create socket object
	CFSocketContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
	_socket = CFSocketCreateWithNative(NULL,PQsocket(_connection),kCFSocketReadCallBack | kCFSocketWriteCallBack,&_socketCallback,&context);
	NSParameterAssert(_socket && CFSocketIsValid(_socket));
	// let libpq do the closing
	CFSocketSetSocketFlags(_socket, ~kCFSocketCloseOnInvalidate & CFSocketGetSocketFlags(_socket));
	
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
#pragma mark private methods - notifications
////////////////////////////////////////////////////////////////////////////////

-(BOOL)_executeObserverCommand:(NSString* )command channel:(NSString* )channelName {
	NSParameterAssert(command);
	NSParameterAssert(channelName);

	NSString* query = [NSString stringWithFormat:@"%@ %@",command,[self quote:channelName]];
	PGresult* theResult = PQexec(_connection,[query UTF8String]);
	if(theResult==nil) {
		return NO;
	}
	if(PQresultStatus(theResult)==PGRES_BAD_RESPONSE || PQresultStatus(theResult)==PGRES_FATAL_ERROR) {
		PQclear(theResult);
		return NO;
	}
	PQclear(theResult);
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark public methods - connections
////////////////////////////////////////////////////////////////////////////////

-(void)connectWithURL:(NSURL* )url whenDone:(void(^)(BOOL usedPassword,NSError* error)) callback {
	NSParameterAssert(url);
	NSParameterAssert(callback);

	// check for bad initial state
	if(_connection != nil) {
		callback(NO,[self _errorWithCode:PGClientErrorState url:nil]);
		return;
	}
	if(_state != PGConnectionStateNone) {
		callback(NO,[self _errorWithCode:PGClientErrorState url:nil]);
		return;
	}

	// check other internal variable consistency
	NSParameterAssert(_connection==nil);
	NSParameterAssert(_socket==nil);
	NSParameterAssert(_runloopsource==nil);

	// extract connection parameters
	NSDictionary* parameters = [self _connectionParametersForURL:url];
	if(parameters==nil) {
		callback(NO,[self _errorWithCode:PGClientErrorParameters url:url]);
		return;
	}

	// update the status as necessary
	[self _updateStatus];
	
	// create parameter pairs
	PGKVPairs* pairs = makeKVPairs(parameters);
	if(pairs==nil) {
		callback(NO,[self _errorWithCode:PGClientErrorParameters url:url]);
		return;
	}

	// create connection
	_connection = PQconnectStartParams(pairs->keywords,pairs->values,0);
	freeKVPairs(pairs);
	if(_connection==nil) {
		callback(NO,[self _errorWithCode:PGClientErrorParameters url:url]);
		return;
	}
	
	// check for initial bad connection status
	if(PQstatus(_connection)==CONNECTION_BAD) {
		PQfinish(_connection);
        _connection = nil;
		[self _updateStatus];
		callback(NO,[self _errorWithCode:PGClientErrorParameters url:url]);
		return;
	}

	// add socket to run loop
	[self _socketConnect:PGConnectionStateConnect];
	
	// set callback
	NSParameterAssert(_callback==nil);
	_callback = (__bridge_retained void* )[callback copy];
}

-(void)pingWithURL:(NSURL* )url whenDone:(void(^)(NSError* error)) callback {
	NSParameterAssert(url);
	NSParameterAssert(callback);

	// extract connection parameters
	NSDictionary* parameters = [self _connectionParametersForURL:url];
	if(parameters==nil) {
		callback([self _errorWithCode:PGClientErrorParameters url:url]);
		return;
	}

	// in the background, perform the ping
	[self performSelectorInBackground:@selector(_pingInBackground:) withObject:@[
		[NSThread currentThread],parameters,callback,url
	]];
}

-(void)disconnect {
	if(_connection) {
		PQfinish(_connection);
        _connection = nil;
	}
	[self _socketDisconnect];
	[self _updateStatus];
}

-(void)resetWhenDone:(void(^)(NSError* error)) callback {
	NSParameterAssert(callback);

	// check to ensure connection
	if(_connection==nil || _state != PGConnectionStateNone) {
		callback([self _errorWithCode:PGClientErrorState url:nil]);
		return;
	}

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

////////////////////////////////////////////////////////////////////////////////
#pragma mark public methods - quoting
////////////////////////////////////////////////////////////////////////////////

-(NSString* )quote:(NSString* )string {
	if(_connection==nil) {
		return nil;
	}
	const char* quoted_identifier = PQescapeIdentifier(_connection,[string UTF8String],[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
	if(quoted_identifier==nil) {
		return nil;
	}
	NSString* quoted = [NSString stringWithUTF8String:quoted_identifier];
	PQfreemem((void* )quoted_identifier);
	return quoted;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark public methods - notifications
////////////////////////////////////////////////////////////////////////////////

-(BOOL)addNotificationObserver:(NSString* )channelName {
	if(_connection == nil || _state != PGConnectionStateNone) {
		return NO;
	}
	return [self _executeObserverCommand:@"LISTEN" channel:channelName];
}

-(BOOL)removeNotificationObserver:(NSString* )channelName {
	if(_connection == nil || _state != PGConnectionStateNone) {
		return NO;
	}
	return [self _executeObserverCommand:@"UNLISTEN" channel:channelName];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark private methods - statement execution
////////////////////////////////////////////////////////////////////////////////

-(void)_execute:(NSString* )query format:(PGClientTupleFormat)format values:(NSArray* )values whenDone:(void(^)(PGResult* result,NSError* error)) callback {
	NSParameterAssert(query && [query isKindOfClass:[NSString class]]);
	NSParameterAssert(format==PGClientTupleFormatBinary || format==PGClientTupleFormatText);
	if(_connection==nil) {
		callback(nil,[self _errorWithCode:PGClientErrorState url:nil]);
		return;
	}
	if([self state] != PGConnectionStateNone) {
		callback(nil,[self _errorWithCode:PGClientErrorState url:nil]);
		return;
	}
	// create parameters object
	PGClientParams* params = _paramAllocForValues(values);
	if(params==nil) {
		callback(nil,[self _errorWithCode:PGClientErrorParameters url:nil]);
		return;
	}
	// convert parameters
	for(NSUInteger i = 0; i < [values count]; i++) {
		id obj = [values objectAtIndex:i];
		if([obj isKindOfClass:[NSNull class]]) {
			_paramSetNull(params,i);
			continue;
		}
		if([obj isKindOfClass:[NSString class]]) {
			NSData* data = [(NSString* )obj dataUsingEncoding:NSUTF8StringEncoding];
			_paramSetBinary(params,i,data,(Oid)25);
			continue;
		}
		// TODO - other kinds of parameters
		NSLog(@"TODO: Turn %@ into arg",[obj class]);		
		_paramSetNull(params,i);
	}
	// check number of parameters
	if(params->size > INT_MAX) {
		_paramFree(params);
		callback(nil,[self _errorWithCode:PGClientErrorParameters url:nil]);
		return;
	}
	
	// execute the command, free parameters
	int resultFormat = (format==PGClientTupleFormatBinary) ? 1 : 0;
	int returnCode = PQsendQueryParams(_connection,[query UTF8String],(int)params->size,params->types,(const char** )params->values,params->lengths,params->formats,resultFormat);
	_paramFree(params);
	if(!returnCode) {
		callback(nil,[self _errorWithCode:PGClientErrorExecute url:nil reason:[NSString stringWithUTF8String:PQerrorMessage(_connection)]]);
		return;
	}
	
	// set state, update status
	[self setState:PGConnectionStateQuery];
	[self _updateStatus];
	NSParameterAssert(_callback==nil);
	_callback = (__bridge_retained void* )[callback copy];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark public methods - statement execution
////////////////////////////////////////////////////////////////////////////////

-(void)execute:(id)query whenDone:(void(^)(PGResult* result,NSError* error)) callback {
	NSParameterAssert([query isKindOfClass:[NSString class]] || [query isKindOfClass:[PGQuery class]]);
	NSParameterAssert(callback);
	if([query isKindOfClass:[PGQuery class]]) {
		NSString* queryString = [(PGQuery* )query statementForConnection:self];
		[self _execute:queryString format:PGClientTupleFormatText values:nil whenDone:callback];
	} else {
		NSParameterAssert([query isKindOfClass:[NSString class]]);
		[self _execute:query format:PGClientTupleFormatText values:nil whenDone:callback];
	}
}

@end
