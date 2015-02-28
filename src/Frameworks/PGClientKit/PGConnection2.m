
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

////////////////////////////////////////////////////////////////////////////////
// forward declarations

@interface PGConnection2 ()

// properties
@property (atomic) PGConnectionState state;

// methods
-(void)socketCallback:(CFSocketCallBackType)callBackType;

@end

////////////////////////////////////////////////////////////////////////////////
// C callbacks

void SocketCallback(CFSocketRef s, CFSocketCallBackType callBackType,CFDataRef address,const void* data,void* self) {
	[(__bridge PGConnection2* )self socketCallback:callBackType];
}

////////////////////////////////////////////////////////////////////////////////

@implementation PGConnection2

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
// properties

@dynamic status;
@dynamic user;
@dynamic database;
@dynamic serverProcessID;
@synthesize timeout = _timeout;
@synthesize state = _state;

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
// error handling

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
// status update

-(void)_updateStatus {
	static PGConnectionStatus oldStatus = PGConnectionStatusDisconnected;
	if([self status] == oldStatus) {
		return;
	}
	oldStatus = [self status];
	if([[self delegate] respondsToSelector:@selector(connection:statusChange:)]) {
		[[self delegate] connection:self statusChange:[self status]];
	}
	
	// if connection is rejected, then call disconnect
	if(oldStatus==PGConnectionStatusRejected) {
		[self disconnect];
	}
	
}

////////////////////////////////////////////////////////////////////////////////
// callbacks

-(void)socketCallbackNotification {
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

-(void)socketCallbackConnectEndedWithStatus:(PostgresPollingStatusType)pqstatus {
	// callback
	NSParameterAssert(_callback);
	void (^callback)(BOOL usedPassword,NSError* error) = (__bridge void (^)(BOOL,NSError* ))(_callback);
	if(pqstatus==PGRES_POLLING_OK) {
		// success condition
		//TODOPQsetNoticeProcessor(connection,PGConnectionNoticeProcessor,connection);
		callback(PQconnectionUsedPassword(_connection) ? YES : NO,nil);
	} else if(PQconnectionNeedsPassword(_connection)) {
		callback(NO,[self _errorWithCode:PGClientErrorNeedsPassword url:nil]);
	} else if(PQconnectionUsedPassword(_connection)) {
		callback(YES,[self _errorWithCode:PGClientErrorInvalidPassword url:nil]);
	} else {
		callback(YES,[self _errorWithCode:PGClientErrorRejected url:nil]);
	}
	_callback = nil;
	[self setState:PGConnectionStateNone];
	[self _updateStatus];
}

-(void)socketCallbackConnect {
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
			[self socketCallbackConnectEndedWithStatus:pqstatus];
		default:
			break;
	}
}

-(void)socketCallbackQuery {
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

-(void)socketCallback:(CFSocketCallBackType)callBackType {
/*	switch(callBackType) {
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
	}*/
	switch([self state]) {
		case PGConnectionStateConnect:
			[self socketCallbackConnect];
			break;
		case PGConnectionStateQuery:
			[self socketCallbackQuery];
			[self socketCallbackNotification];
			break;
		default:
			[self socketCallbackNotification];
			break;
	}
	
	[self _updateStatus];
}

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
	
	// create socket object
	CFSocketContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
	_socket = CFSocketCreateWithNative(NULL,PQsocket(_connection),kCFSocketReadCallBack | kCFSocketWriteCallBack,&SocketCallback,&context);
	NSParameterAssert(_socket && CFSocketIsValid(_socket));

	// set state
	[self setState:PGConnectionStateConnect];
	[self _updateStatus];
	NSParameterAssert(_callback==nil);
	_callback = (__bridge_retained void* )[callback copy];

	// add to run loop to begin polling
	_runloopsource = CFSocketCreateRunLoopSource(NULL,_socket,0);
	NSParameterAssert(_runloopsource && CFRunLoopSourceIsValid(_runloopsource));
	CFRunLoopAddSource(CFRunLoopGetCurrent(),_runloopsource,(CFStringRef)kCFRunLoopCommonModes);
}

////////////////////////////////////////////////////////////////////////////////

-(void)disconnect {
	if(_connection) {
		PQfinish(_connection);
        _connection = nil;
	}
	if(_runloopsource) {
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(),_runloopsource,(CFStringRef)kCFRunLoopCommonModes);
		CFRelease(_runloopsource);
		_runloopsource = nil;
	}
	if(_socket) {
		CFSocketInvalidate(_socket);
		CFRelease(_socket);
		_socket = nil;
	}
	[self _updateStatus];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Statement execution methods
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

-(void)execute:(id)query whenDone:(void(^)(PGResult* result,NSError* error)) callback {
	[self _execute:query format:PGClientTupleFormatText values:nil whenDone:callback];
}

@end
