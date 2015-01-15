
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

#import "PGClientKit.h"
#import "PGClientKit+Private.h"
#include <pg_config.h>

NSString* PGConnectionSchemes = @"pgsql pgsqls postgresql postgres postgresqls";
NSString* PGConnectionDefaultEncoding = @"utf8";
NSString* PGConnectionBonjourServiceType = @"_postgresql._tcp";
NSString* PGClientErrorDomain = @"PGClient";
NSString* PGClientErrorURLKey = @"PGClientErrorURL";
NSUInteger PGClientDefaultPort = DEF_PGPORT;
NSUInteger PGClientMaximumPort = 65535;

////////////////////////////////////////////////////////////////////////////////

typedef struct {
	const char** keywords;
	const char** values;
} PGKVPairs;

void freeKVPairs(PGKVPairs* pairs) {
	if(pairs) {
		free(pairs->keywords);
		free(pairs->values);
		free(pairs);
	}
}

PGKVPairs* allocKVPairs(NSUInteger size) {
	PGKVPairs* pairs = malloc(sizeof(PGKVPairs));
	if(pairs==nil) {
		return nil;
	}
	pairs->keywords = malloc(sizeof(const char* ) * (size+1));
	pairs->values = malloc(sizeof(const char* ) * (size+1));
	if(pairs->keywords==nil || pairs->values==nil) {
		freeKVPairs(pairs);
		return nil;
	}
	return pairs;
}

PGKVPairs* makeKVPairs(NSDictionary* dict) {
	PGKVPairs* pairs = allocKVPairs([dict count]);	
	NSUInteger i = 0;
	for(NSString* theKey in dict) {
		pairs->keywords[i] = [theKey UTF8String];
		pairs->values[i] = [[[dict valueForKey:theKey] description] UTF8String];
		i++;
	}
	pairs->keywords[i] = '\0';
	pairs->values[i] = '\0';
	return pairs;
}

void PGConnectionNoticeProcessor(void* arg,const char* cString) {
	NSLog(@"TODO: PGConnectionNoticeProcessor: %s",cString);
}

@implementation PGConnection

////////////////////////////////////////////////////////////////////////////////
// static methods

+(NSArray* )allURLSchemes {
	return [PGConnectionSchemes componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

+(NSString* )defaultURLScheme {
	return [[self allURLSchemes] objectAtIndex:0];
}

////////////////////////////////////////////////////////////////////////////////
// initialization

-(id)init {
	self = [super init];
	if(self) {
		_connection = nil;
		_lock = [[NSLock alloc] init];
		_status = PGConnectionStatusDisconnected;
		pgdata2obj_init();
	}
	
	return self;
}

-(void)dealloc {
	if(self) {
		// call the destroyer
		pgdata2obj_destroy();
	}
	[self disconnect];
}

+(PGConnection* )connectionWithURL:(NSURL* )url error:(NSError** )error {
	PGConnection* connection = [[PGConnection alloc] init];
	if([connection connectWithURL:url error:error]==NO) {
		return nil;
	} else {
		return connection;
	}
}

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic user, database, status, serverProcessID;

-(PGConnectionStatus)status {
	if(_connection==nil) {
		return PGConnectionStatusDisconnected;
	}
	switch(PQstatus(_connection)) {
		case CONNECTION_OK:
			return PGConnectionStatusConnected;
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
// Private methods - error handling

+(NSString* )_stringForErrorCode:(PGClientErrorDomainCode)code {
	switch(code) {
		case PGClientErrorState:
			return @"Connection State Mismatch";
		case PGClientErrorParameters:
			return @"Invalid parameters";
		case PGClientErrorNeedsPassword:
			return @"Connection requires authentication";
		case PGClientErrorInvalidPassword:
			return @"Password authentication failed";
		case PGClientErrorRejected:
			return @"Connection was rejected";
		case PGClientErrorExecute:
			return @"Execution error";
		case PGClientErrorUnknown:
		default:
			return @"Unknown error";
	}
}

+(NSError* )createError:(NSError** )error code:(PGClientErrorDomainCode)code url:(NSURL* )url reason:(NSString* )format,... {
	// format the reason
	NSString* reason = nil;
	if(format) {
		va_list args;
		va_start(args,format);
		reason = [[NSString alloc] initWithFormat:format arguments:args];
		va_end(args);
	}
	NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
	if(reason) {
		[userInfo setObject:reason forKey:NSLocalizedDescriptionKey];
	} else {
		[userInfo setObject:[PGConnection _stringForErrorCode:code] forKey:NSLocalizedDescriptionKey];
	}
	if(url) {
		[userInfo setObject:url forKey:PGClientErrorURLKey];
	}
	NSError* theError = [NSError errorWithDomain:PGClientErrorDomain code:code userInfo:userInfo];
	if(error) {
		(*error) = theError;
	}
	return theError;
}

-(NSError* )_raiseError:(NSError** )error code:(PGClientErrorDomainCode)code url:(NSURL* )url formattedReason:(NSString* )reason {
	NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
	if(reason) {
		[userInfo setObject:reason forKey:NSLocalizedDescriptionKey];
	} else {
		[userInfo setObject:[PGConnection _stringForErrorCode:code] forKey:NSLocalizedDescriptionKey];
	}
	if(url) {
		[userInfo setObject:url forKey:PGClientErrorURLKey];
	}
	NSError* theError = [NSError errorWithDomain:PGClientErrorDomain code:code userInfo:userInfo];
	if(error) {
		(*error) = theError;
	}
	// perform selector
	if([[self delegate] respondsToSelector:@selector(connection:error:)] && code != PGClientErrorNone) {
		[[self delegate] connection:self error:theError];
	}
	// return the error
	return theError;
}

-(NSError* )raiseError:(NSError** )error code:(PGClientErrorDomainCode)code url:(NSURL* )url reason:(NSString* )format,...  {
	// format the reason
	NSString* reason = nil;
	if(format) {
		va_list args;
		va_start(args,format);
		reason = [[NSString alloc] initWithFormat:format arguments:args];
		va_end(args);
	}
	// return the error
	return [self _raiseError:error code:code url:url formattedReason:reason];
}

-(NSError* )raiseError:(NSError** )error code:(PGClientErrorDomainCode)code reason:(NSString* )format,...  {
	// format the reason
	NSString* reason = nil;
	if(format) {
		va_list args;
		va_start(args,format);
		reason = [[NSString alloc] initWithFormat:format arguments:args];
		va_end(args);
	}
	// return the error
	return [self _raiseError:error code:code url:nil formattedReason:reason];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(NSDictionary* )_connectionParametersForURL:(NSURL* )theURL timeout:(NSUInteger)timeout {
	// make parameters from the URL
	NSMutableDictionary* theParameters = [[theURL postgresqlParameters] mutableCopy];
	if(theParameters==nil) {
		return nil;
	}
	if(timeout) {
		[theParameters setValue:[NSNumber numberWithUnsignedInteger:timeout] forKey:@"connect_timeout"];
	}
	// set client encoding and application name if not already set
	if([theParameters objectForKey:@"client_encoding"]==nil) {
		[theParameters setValue:PGConnectionDefaultEncoding forKey:@"client_encoding"];
	}
	if([theParameters objectForKey:@"application_name"]==nil) {
		[theParameters setValue:[[NSProcessInfo processInfo] processName] forKey:@"application_name"];
	}
	// Allow delegate to deal with parameters
	if([[self delegate] respondsToSelector:@selector(connection:willOpenWithParameters:)]) {
		[[self delegate] connection:self willOpenWithParameters:theParameters];
	}
	return theParameters;
}

-(void)_pollUnlock:(NSArray* )parameters {
	NSParameterAssert(parameters && [parameters isKindOfClass:[NSArray class]] && [parameters count]==2);
	void(^callback)(NSError* error) = [parameters objectAtIndex:0];
	NSError* error = [parameters objectAtIndex:1];
	[_lock unlock];
	if([error code]==PGClientErrorNone) {
		callback(nil);
	} else {
		callback(error);
	}
}

-(void)_connectPollWithParametersThread:(NSArray* )parameters {
	NSParameterAssert(parameters && [parameters isKindOfClass:[NSArray class]] && [parameters count]==3);
	NSThread* mainThread = [parameters objectAtIndex:0];
	PGconn* connection = [(NSValue* )[parameters objectAtIndex:1] pointerValue];
	void(^callback)(NSError* error) = [parameters objectAtIndex:2];
	
	@autoreleasepool {
		PostgresPollingStatusType status;
		do {
			status = PQconnectPoll(connection);
			int socket = PQsocket(connection);
			fd_set fd;
			switch(status) {
				case PGRES_POLLING_READING:
				case PGRES_POLLING_WRITING:
					// still connecting
					FD_ZERO(&fd);
					FD_SET(socket, &fd);
					select(socket+1,status == PGRES_POLLING_READING ? &fd : NULL,status == PGRES_POLLING_WRITING ? &fd : NULL,NULL, NULL);
					break;
				case PGRES_POLLING_OK:
					// connected
					break;
				case PGRES_POLLING_FAILED:
					// connection failed
					break;
				default:
					break;
			}
#ifdef DEBUG
			switch(PQstatus(connection)) {
				case CONNECTION_STARTED:
					NSLog(@"CONNECTION_STARTED");
					break;
				case CONNECTION_MADE:
					NSLog(@"CONNECTION_MADE");
					break;
				case CONNECTION_AWAITING_RESPONSE:
					NSLog(@"CONNECTION_AWAITING_RESPONSE");
					break;
				case CONNECTION_AUTH_OK:
					NSLog(@"CONNECTION_AUTH_OK");
					break;
				case CONNECTION_SSL_STARTUP:
					NSLog(@"CONNECTION_SSL_STARTUP");
					break;
				case CONNECTION_SETENV:
					NSLog(@"CONNECTION_SETENV");
					break;
				case CONNECTION_OK:
					NSLog(@"CONNECTION_OK");
					break;
				case CONNECTION_BAD:
					NSLog(@"CONNECTION_BAD");
					break;
				default:
					NSLog(@"CONNECTION_UNKNOWN");
					break;
			}
#endif
			[self _setStatus:PGConnectionStatusConnecting];
		} while(status != PGRES_POLLING_OK && status != PGRES_POLLING_FAILED);

		[self _setStatus:[self status]];

		NSError* error = nil;
		if(status==PGRES_POLLING_OK) {
			// TODO PQsetNoticeProcessor(_connection,PGConnectionNoticeProcessor,_connection);
			_connection = connection;
			error = [self raiseError:nil code:PGClientErrorNone reason:nil];
			[self _setStatus:PGConnectionStatusConnected];
		} else {
			if(PQconnectionNeedsPassword(connection)) {
				error = [self raiseError:nil code:PGClientErrorNeedsPassword reason:nil];
			} else if(PQconnectionUsedPassword(connection)) {
				error = [self raiseError:nil code:PGClientErrorInvalidPassword reason:nil];
			} else {
				error = [self raiseError:nil code:PGClientErrorRejected reason:@"%s",PQerrorMessage(connection)];
			}
			PQfinish(connection);
			_connection = nil;
			[self _setStatus:PGConnectionStatusRejected];
		}
		// unlock and callback on the main thread
		[self performSelector:@selector(_pollUnlock:) onThread:mainThread withObject:@[ callback, error ] waitUntilDone:NO];
	}
}

-(void)_resetPollWithParametersThread:(NSArray* )parameters {
	NSParameterAssert(parameters && [parameters isKindOfClass:[NSArray class]] && [parameters count]==2);
	NSThread* mainThread = [parameters objectAtIndex:0];
	void(^callback)(NSError* error) = [parameters objectAtIndex:1];
	
	@autoreleasepool {
		PostgresPollingStatusType status;
		do {
			status = PQresetPoll(_connection);
			int socket = PQsocket(_connection);
			fd_set fd;
			switch(status) {
				case PGRES_POLLING_READING:
				case PGRES_POLLING_WRITING:
					// still connecting
					FD_ZERO(&fd);
					FD_SET(socket, &fd);
					select(socket+1,status == PGRES_POLLING_READING ? &fd : NULL,status == PGRES_POLLING_WRITING ? &fd : NULL,NULL, NULL);
					break;
				case PGRES_POLLING_OK:
					// reset
					break;
				case PGRES_POLLING_FAILED:
					// reset failed
					break;
				default:
					break;
			}
#ifdef DEBUG
			switch(PQstatus(_connection)) {
				case CONNECTION_STARTED:
					NSLog(@"CONNECTION_STARTED");
					break;
				case CONNECTION_MADE:
					NSLog(@"CONNECTION_MADE");
					break;
				case CONNECTION_AWAITING_RESPONSE:
					NSLog(@"CONNECTION_AWAITING_RESPONSE");
					break;
				case CONNECTION_AUTH_OK:
					NSLog(@"CONNECTION_AUTH_OK");
					break;
				case CONNECTION_SSL_STARTUP:
					NSLog(@"CONNECTION_SSL_STARTUP");
					break;
				case CONNECTION_SETENV:
					NSLog(@"CONNECTION_SETENV");
					break;
				case CONNECTION_OK:
					NSLog(@"CONNECTION_OK");
					break;
				case CONNECTION_BAD:
					NSLog(@"CONNECTION_BAD");
					break;
				default:
					NSLog(@"CONNECTION_UNKNOWN");
					break;
			}
#endif
		} while(status != PGRES_POLLING_OK && status != PGRES_POLLING_FAILED);
		
		NSError* error = nil;
		if(status==PGRES_POLLING_OK) {
			PQsetNoticeProcessor(_connection,PGConnectionNoticeProcessor,_connection);
			error = [self raiseError:nil code:PGClientErrorNone reason:nil];
		} else if(PQconnectionNeedsPassword(_connection)) {
			error = [self raiseError:nil code:PGClientErrorNeedsPassword reason:nil];
		} else if(PQconnectionUsedPassword(_connection)) {
			error = [self raiseError:nil code:PGClientErrorInvalidPassword reason:nil];
		} else {
			error = [self raiseError:nil code:PGClientErrorRejected reason:@"%s",PQerrorMessage(_connection)];
		}
		// unlock and callback on the main thread
		[self performSelector:@selector(_pollUnlock:) onThread:mainThread withObject:@[ callback, error ] waitUntilDone:NO];
	}
}

////////////////////////////////////////////////////////////////////////////////
// Private methods - status change

-(void)_setStatus:(PGConnectionStatus)status {
	if(_status==status) {
		return;
	}
	if([[self delegate] respondsToSelector:@selector(connection:statusChange:)]) {
		[[self delegate] connection:self statusChange:status];
	}
	_status = status;
}

////////////////////////////////////////////////////////////////////////////////
// connection

-(BOOL)connectWithURL:(NSURL* )url error:(NSError** )error {
	if([_lock tryLock]==NO) {
		[self raiseError:error code:PGClientErrorState url:url reason:@"Cannot obtain lock"];
		return NO;
	}
	if(_connection != nil) {
		[_lock unlock];
		[self raiseError:error code:PGClientErrorState url:url reason:@"Connection already established"];
		return NO;
	}
	// extract parameters
	NSDictionary* parameters = [self _connectionParametersForURL:url timeout:0];
	if(parameters==nil) {
		[_lock unlock];
		[self raiseError:error code:PGClientErrorParameters url:url reason:nil];
		return NO;
	}

	// set connecting status
	[self _setStatus:PGConnectionStatusConnecting];

	// make the connection
	PGKVPairs* pairs = makeKVPairs(parameters);
	BOOL returnValue = NO;
	PGconn* connection = nil;
	if(pairs != nil) {
		connection = PQconnectdbParams(pairs->keywords,pairs->values,0);
		freeKVPairs(pairs);
	}
	
	if(connection==nil) {
		[self raiseError:error code:PGClientErrorParameters url:url reason:nil];
		[self _setStatus:PGConnectionStatusRejected];
	} else if(PQstatus(connection) == CONNECTION_OK) {
		// set up the connection
		// TODO PQsetNoticeProcessor(connection,PGConnectionNoticeProcessor,connection);
		// return success
		_connection = connection;
		returnValue = YES;
		[self _setStatus:PGConnectionStatusConnected];
	} else {
		if(PQconnectionNeedsPassword(connection)) {
			[self raiseError:error code:PGClientErrorNeedsPassword url:url reason:nil];
		} else if(PQconnectionUsedPassword(connection)) {
			[self raiseError:error code:PGClientErrorInvalidPassword url:url reason:nil];
		} else {
			[self raiseError:error code:PGClientErrorRejected url:url reason:@"%s",PQerrorMessage(connection)];
		}
		[self _setStatus:PGConnectionStatusRejected];
	}
	[_lock unlock];
	return returnValue;
}

-(BOOL)connectInBackgroundWithURL:(NSURL* )url whenDone:(void(^)(NSError* error)) callback {

	[self _setStatus:PGConnectionStatusConnecting];

	if([_lock tryLock]==NO) {
		callback([self raiseError:nil code:PGClientErrorState url:url reason:@"Cannot obtain lock"]);
		return NO;
	}
	if(_connection != nil) {
		[_lock unlock];
		callback([self raiseError:nil code:PGClientErrorState url:url reason:@"Connection already established"]);
		return NO;
	}
	// extract parameters
	NSDictionary* parameters = [self _connectionParametersForURL:url timeout:0];
	if(parameters==nil) {
		[_lock unlock];
		callback([self raiseError:nil code:PGClientErrorParameters url:url reason:nil]);
		return NO;
	}
	// make the connection
	PGKVPairs* pairs = makeKVPairs(parameters);
	PGconn* connection = nil;
	if(pairs != nil) {
		connection = PQconnectStartParams(pairs->keywords,pairs->values,0);
		freeKVPairs(pairs);
	}
	if(connection==nil) {
		[_lock unlock];
		callback([self raiseError:nil code:PGClientErrorParameters url:url reason:nil]);
		return NO;
	}
	// set fake status
	[NSThread detachNewThreadSelector:@selector(_connectPollWithParametersThread:) toTarget:self withObject:@[ [NSThread currentThread],[NSValue valueWithPointer:connection],callback ]];
	return YES;
}

-(BOOL)pingWithURL:(NSURL* )url error:(NSError** )error {
	// extract parameters
	NSDictionary* parameters = [self _connectionParametersForURL:url timeout:0];
	if(parameters==nil) {
		[self raiseError:error code:PGClientErrorParameters url:url reason:nil];
		return NO;
	}
	PGKVPairs* pairs = makeKVPairs(parameters);
	if(pairs==nil) {
		[self raiseError:error code:PGClientErrorParameters url:url reason:nil];
		return NO;
	}
	PGPing status = PQpingParams(pairs->keywords,pairs->values,0);
	freeKVPairs(pairs);
	switch(status) {
		case PQPING_OK:
			return YES;
		case PQPING_REJECT:
			[self raiseError:error code:PGClientErrorRejected url:url reason:nil];
			return NO;
		case PQPING_NO_ATTEMPT:
			[self raiseError:error code:PGClientErrorParameters url:url reason:nil];
			return NO;
		default:
			[self raiseError:error code:PGClientErrorUnknown url:url reason:nil];
			return NO;
	}
}

-(BOOL)disconnect {
	if([_lock tryLock]==NO) {
		[self raiseError:nil code:PGClientErrorState reason:nil];
		return NO;
	}
	if(_connection != nil) {
		PQfinish(_connection);
		_connection = nil;
		
		// check for changed status
		[self _setStatus:PGConnectionStatusDisconnected];

	}
	[_lock unlock];
	return YES;
}

-(BOOL)reset {
	if([_lock tryLock]==NO) {
		[self raiseError:nil code:PGClientErrorState reason:nil];
		return NO;
	}
	if(_connection==nil) {
		[_lock unlock];
		[self raiseError:nil code:PGClientErrorState reason:nil];
		return NO;
	} else {
		PQreset(_connection);
		[_lock unlock];

		// check for changed status
		[self _setStatus:[self status]];

		return YES;
	}
}

-(BOOL)resetInBackgroundWhenDone:(void(^)(NSError* error)) callback {
	if([_lock tryLock]==NO) {
		[self raiseError:nil code:PGClientErrorState reason:nil];
		return NO;
	}
	if(_connection == nil) {
		callback([self raiseError:nil code:PGClientErrorState reason:nil]);
		[_lock unlock];
		return NO;
	}
	if(PQresetStart(_connection) != 1) {
		callback([self raiseError:nil code:PGClientErrorUnknown reason:nil]);
		[_lock unlock];
		return NO;
	}
	[NSThread detachNewThreadSelector:@selector(_resetPollWithParametersThread:) toTarget:self withObject:@[ [NSThread currentThread],callback ]];
	return YES;
}

-(BOOL)connectionUsedPassword {
	return PQconnectionUsedPassword(_connection) ? YES : NO;
}

////////////////////////////////////////////////////////////////////////////////
// underlying execute method with parameters

-(PGResult* )_execute:(NSString* )query format:(PGClientTupleFormat)format values:(NSArray* )values error:(NSError** )error {
	NSParameterAssert(query && [query isKindOfClass:[NSString class]]);
	NSParameterAssert(format==PGClientTupleFormatBinary || format==PGClientTupleFormatText);
	if(_connection==nil) {
		[self raiseError:error code:PGClientErrorState reason:@"No connection"];
		return nil;
	}
	// try to obtain lock
	if([_lock tryLock]==NO) {
		[self raiseError:error code:PGClientErrorState reason:@"Cannot obtain lock"];
		return nil;
	}
	// call delegate
	if([[self delegate] respondsToSelector:@selector(connection:willExecute:values:)]) {
		[[self delegate] connection:self willExecute:query values:values];
	}
	// create parameters
	PGClientParams* params = _paramAllocForValues(values);
	if(params==nil) {
		[self raiseError:error code:PGClientErrorParameters reason:nil];
		[_lock unlock];
		return nil;
	}
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
		[self raiseError:error code:PGClientErrorParameters reason:nil];
		[_lock unlock];
		return nil;
	}
	// execute the command, free parameters
	int resultFormat = (format==PGClientTupleFormatBinary) ? 1 : 0;
	PGresult* theResult = PQexecParams(_connection,[query UTF8String],(int)params->size,params->types,(const char** )params->values,params->lengths,params->formats,resultFormat);
	_paramFree(params);	
	if(theResult==nil) {
		[self raiseError:error code:PGClientErrorExecute reason:nil];
		[_lock unlock];
		return nil;
	}
	// check for connection errors
	if(PQresultStatus(theResult)==PGRES_EMPTY_QUERY) {
		[self raiseError:error code:PGClientErrorExecute reason:@"Empty Query"];
		PQclear(theResult);
		[_lock unlock];
		return nil;
	}
	if(PQresultStatus(theResult)==PGRES_BAD_RESPONSE || PQresultStatus(theResult)==PGRES_FATAL_ERROR) {
		[self raiseError:error code:PGClientErrorExecute reason:[NSString stringWithUTF8String:PQresultErrorMessage(theResult)]];
		PQclear(theResult);
		[_lock unlock];
		return nil;
	}
	// return resultset
	PGResult* r = [[PGResult alloc] initWithResult:theResult format:format];
	[_lock unlock];
	return r;
}

////////////////////////////////////////////////////////////////////////////////
// execute statements - return results in text or binary

-(PGResult* )execute:(NSString* )query format:(PGClientTupleFormat)format values:(NSArray* )values error:(NSError** )error {
	return [self _execute:query format:format values:values error:error];
}

-(PGResult* )execute:(NSString* )query format:(PGClientTupleFormat)format value:(id)value error:(NSError** )error {
	return [self _execute:query format:format values:[NSArray arrayWithObject:value] error:error];
}

-(PGResult* )execute:(NSString* )query format:(PGClientTupleFormat)format error:(NSError** )error {
	return [self _execute:query format:format values:nil error:error];
}

-(PGResult* )execute:(NSString* )query error:(NSError** )error {
	return [self _execute:query format:PGClientTupleFormatBinary values:nil error:error];
}

-(PGResult* )execute:(NSString* )query values:(NSArray* )values error:(NSError** )error {
	return [self _execute:query format:PGClientTupleFormatBinary values:values error:error];
}

-(PGResult* )execute:(NSString* )query value:(id)value error:(NSError** )error {
	return [self _execute:query format:PGClientTupleFormatBinary values:[NSArray arrayWithObject:value] error:error];	
}

@end

