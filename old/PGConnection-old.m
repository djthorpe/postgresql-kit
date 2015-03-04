
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
#include <pg_config.h>

NSString* PGConnectionSchemes = @"pgsql pgsqls postgresql postgres postgresqls";
NSString* PGConnectionDefaultEncoding = @"utf8";
NSString* PGConnectionBonjourServiceType = @"_postgresql._tcp";
NSString* PGClientErrorDomain = @"PGClient";
NSString* PGClientErrorURLKey = @"PGClientErrorURL";
NSUInteger PGClientDefaultPort = DEF_PGPORT;
NSUInteger PGClientMaximumPort = 65535;

@implementation PGConnection

////////////////////////////////////////////////////////////////////////////////
#pragma mark Static Methods

+(NSArray* )allURLSchemes {
	return [PGConnectionSchemes componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

+(NSString* )defaultURLScheme {
	return [[self allURLSchemes] objectAtIndex:0];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructor and Destructor

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
	PGConnection* connection = [PGConnection new];
	__block BOOL returnValue = YES;
	[connection connectWithURL:url whenDone:^(BOOL usedPassword, NSError* connectionError) {
		if(connectionError) {
			returnValue = NO;
		}
		if(error) {
			(*error) = connectionError;
		}
	}];
	if(returnValue==NO) {
		connection = nil;
	}
	return connection;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Properties

@dynamic user, database, status, serverProcessID;
@synthesize tag;
@synthesize timeout;

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
#pragma mark Error Handling

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

/*
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
*/

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
#pragma mark Notifications

/*
-(void)_pollBackgroundThreadSleep {
	if(_connection==nil) {
		// if no connection, then return immediately
		return;
	}
	// sleep in background until there is data on the connection
	int sock = PQsocket(_connection);
	fd_set input_mask;
	if(sock < 0) {
		// invalid socket
		return;
	}

	FD_ZERO(&input_mask);
	FD_SET(sock, &input_mask);
	if(select(sock+1,&input_mask, NULL, NULL, NULL) < 0) {
		// select failed
		return;
	}
	// consume input
	PQconsumeInput(_connection);
	// check for notifications
	[self _pollNotification];
}
*/

-(void)_pollNotification {
	if(_connection==nil) {
		return;
	}
	// attempt to acquire lock
	if([_lock tryLock]==NO) {
		return;
	}
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
	// unlock
	[_lock unlock];
}

-(BOOL)_executeObserverCommand:(NSString* )command channel:(NSString* )channelName {
	NSParameterAssert(command);
	NSParameterAssert(channelName);
	if([channelName length]==0) {
		return NO;
	}
	if(_connection==nil) {
		return NO;
	}
	// try to obtain lock
	if([_lock tryLock]==NO) {
		[self raiseError:nil code:PGClientErrorState reason:@"Cannot obtain lock"];
		return NO;
	}
	const char* quoted_identifier = PQescapeIdentifier(_connection,[channelName UTF8String],[channelName lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
	if(quoted_identifier==nil) {
		[_lock unlock];
		[self raiseError:nil code:PGClientErrorExecute reason:nil];
		return NO;
	}
	NSString* query = [NSString stringWithFormat:@"%@ %s",command,quoted_identifier];
	PQfreemem((void* )quoted_identifier);
	PGresult* theResult = PQexec(_connection,[query UTF8String]);
	if(theResult==nil) {
		[_lock unlock];
		[self raiseError:nil code:PGClientErrorExecute reason:nil];
		return NO;
	}
	if(PQresultStatus(theResult)==PGRES_BAD_RESPONSE || PQresultStatus(theResult)==PGRES_FATAL_ERROR) {
		PQclear(theResult);
		[_lock unlock];
		[self raiseError:nil code:PGClientErrorExecute reason:[NSString stringWithUTF8String:PQresultErrorMessage(theResult)]];
		return nil;
	}
	PQclear(theResult);
	[_lock unlock];
	return YES;
}

-(BOOL)addObserver:(NSString* )channelName {
	return [self _executeObserverCommand:@"LISTEN" channel:channelName];
}

-(BOOL)removeObserver:(NSString* )channelName {
	return [self _executeObserverCommand:@"UNLISTEN" channel:channelName];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Connecting

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
	// Allow delegate to deal with parameters
	if([[self delegate] respondsToSelector:@selector(connection:willOpenWithParameters:)]) {
		[[self delegate] connection:self willOpenWithParameters:theParameters];
	}
	return theParameters;
}

-(void)_connectPollUnlock:(NSArray* )parameters {
	// Method to complete the background connection on the main thread
	// arguments are @[ callback, NSNumber* didUsePassword, NSError* error ]
	NSParameterAssert(parameters && [parameters isKindOfClass:[NSArray class]] && [parameters count]==3);
	void(^callback)(BOOL usedPassword,NSError* error) = [parameters objectAtIndex:0];
	NSNumber* didUsePassword = [parameters objectAtIndex:1];
	NSError* error = [parameters objectAtIndex:2];
	NSParameterAssert(callback && [didUsePassword isKindOfClass:[NSNumber class]]);
	NSParameterAssert([error isKindOfClass:[NSError class]]);
	[_lock unlock];
	if([[error domain] isEqualToString:PGClientErrorDomain] && [error code]==PGClientErrorNone) {
		error = nil;
	}
	callback([didUsePassword boolValue],error);
}

-(void)_connectPollWithParametersThread:(NSArray* )parameters {
	// Method to initiate the background connection on a new thread
	// arguments are @[ PGConn* connection, callback, NSURL* url ]
	NSParameterAssert(parameters && [parameters isKindOfClass:[NSArray class]] && [parameters count]==3);
	PGconn* connection = [(NSValue* )[parameters objectAtIndex:0] pointerValue];
	void(^callback)(BOOL usedPassword,NSError* error) = [parameters objectAtIndex:1];
	NSURL* url = [parameters objectAtIndex:2];
	NSParameterAssert(callback && connection);
	NSParameterAssert([url isKindOfClass:[NSURL class]]);

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

		//[self _setStatus:[self status]];

		int errorCode = 0;
		if(status==PGRES_POLLING_OK) {
			// success condition
			PQsetNoticeProcessor(connection,PGConnectionNoticeProcessor,connection);
			_connection = connection;
			[self _setStatus:PGConnectionStatusConnected];
		} else if(PQconnectionNeedsPassword(connection)) {
			// connection was rejected - needs password to continue
			errorCode = PGClientErrorNeedsPassword;
		} else if(PQconnectionUsedPassword(connection)) {
			// connection was rejected - invalid password
			errorCode = PGClientErrorInvalidPassword;
		} else {
			// connection was rejected - other reason
			errorCode = PGClientErrorRejected;
		}
		
		// cleanup on error condition
		NSError* error = nil;
		if(errorCode) {
			[self _setStatus:PGConnectionStatusRejected];
			PQfinish(connection);
			_connection = nil;
			error = [self raiseError:nil code:errorCode url:url reason:@"%s",PQerrorMessage(connection)];
		} else {
			error = [self raiseError:nil code:PGClientErrorNone reason:nil];
		}

		// unlock and callback on the main thread
		[self performSelector:@selector(_connectPollUnlock:) onThread:[NSThread mainThread] withObject:@[
			callback,
			[self _connectionUsedPassword] ? @YES : @NO,
			error
		] waitUntilDone:NO];
	}
}


-(void)connectWithURL:(NSURL* )url whenDone:(void(^)(BOOL usedPassword,NSError* error)) callback {

	// attempt to acquire lock
	if([_lock tryLock]==NO) {
		callback(NO,[self raiseError:nil code:PGClientErrorState url:url reason:@"Cannot obtain lock"]);
		return;
	}

	// check for existing connection
	if(_connection != nil) {
		[_lock unlock];
		callback(NO,[self raiseError:nil code:PGClientErrorState url:url reason:@"Connection already established"]);
		return;
	}

	// extract connection parameters
	NSDictionary* parameters = [self _connectionParametersForURL:url];
	if(parameters==nil) {
		[_lock unlock];
		callback(NO,[self raiseError:nil code:PGClientErrorParameters url:url reason:nil]);
		return;
	}

	// set connecting status
	[self _setStatus:PGConnectionStatusConnecting];

	// make the connection
	PGKVPairs* pairs = makeKVPairs(parameters);
	PGconn* connection = nil;
	if(pairs != nil) {
		connection = PQconnectdbParams(pairs->keywords,pairs->values,0);
		freeKVPairs(pairs);
	}

	// connection cannot be made - bad parameters
	if(pairs==nil || connection==nil) {
		[self _setStatus:PGConnectionStatusRejected];
		[_lock unlock];
		callback(NO,[self raiseError:nil code:PGClientErrorParameters url:url reason:nil]);
		return;
	}

	// connection was success
	if(PQstatus(connection) == CONNECTION_OK) {
		// set up the connection
		PQsetNoticeProcessor(connection,PGConnectionNoticeProcessor,connection);
		_connection = connection;
		[self _setStatus:PGConnectionStatusConnected];
		[_lock unlock];
		// return success
		callback([self _connectionUsedPassword],nil);
		return;
	}

	// connection was rejected
	// either it needs a password, or credentials were rejected
	int errorCode = PQconnectionNeedsPassword(connection) ? PGClientErrorNeedsPassword : PGClientErrorInvalidPassword;
	[self _setStatus:PGConnectionStatusRejected];
	PQfinish(connection);
	[_lock unlock];
	callback([self _connectionUsedPassword],[self raiseError:nil code:errorCode url:url reason:@"%s",PQerrorMessage(connection)]);
}

-(void)connectInBackgroundWithURL:(NSURL* )url whenDone:(void(^)(BOOL usedPassword,NSError* error)) callback {

	// attempt to acquire lock
	if([_lock tryLock]==NO) {
		callback(NO,[self raiseError:nil code:PGClientErrorState url:url reason:@"Cannot obtain lock"]);
		return;
	}

	// check for existing connection
	if(_connection != nil) {
		[_lock unlock];
		callback(NO,[self raiseError:nil code:PGClientErrorState url:url reason:@"Connection already established"]);
		return;
	}

	// extract connection parameters
	NSDictionary* parameters = [self _connectionParametersForURL:url];
	if(parameters==nil) {
		[_lock unlock];
		callback(NO,[self raiseError:nil code:PGClientErrorParameters url:url reason:nil]);
		return;
	}

	// set connecting status
	[self _setStatus:PGConnectionStatusConnecting];

	// make the connection in background
	PGKVPairs* pairs = makeKVPairs(parameters);
	PGconn* connection = nil;
	if(pairs != nil) {
		connection = PQconnectdbParams(pairs->keywords,pairs->values,0);
		freeKVPairs(pairs);
	}

	// connection cannot be made - bad parameters
	if(pairs==nil || connection==nil) {
		[self _setStatus:PGConnectionStatusRejected];
		[_lock unlock];
		callback(NO,[self raiseError:nil code:PGClientErrorParameters url:url reason:nil]);
		return;
	}
	
	// begin background polling for connection
	[NSThread detachNewThreadSelector:@selector(_connectPollWithParametersThread:) toTarget:self withObject:@[
		[NSValue valueWithPointer:connection],
		callback,
		url
	]];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Ping methods

-(void)_pingOnMainThread:(NSArray* )parameters {
	// Method to complete the background ping on the main thread
	// arguments are @[ callback, NSError* error ]
	NSParameterAssert(parameters && [parameters isKindOfClass:[NSArray class]] && [parameters count]==2);
	void(^callback)(NSError* error) = [parameters objectAtIndex:0];
	NSError* error = [parameters objectAtIndex:1];
	NSParameterAssert(callback);
	NSParameterAssert([error isKindOfClass:[NSError class]]);
	if([[error domain] isEqualToString:PGClientErrorDomain] && [error code]==PGClientErrorNone) {
		error = nil;
	}
	callback(error);
}

-(void)_pingWithParametersThread:(NSArray* )parameters {
	// Method to initiate the background connection on a new thread
	// arguments are @[ NSDictionary* dictionary, callback, NSURL* url ]
	NSParameterAssert(parameters && [parameters isKindOfClass:[NSArray class]] && [parameters count]==3);
	NSDictionary* dictionary = [parameters objectAtIndex:0];
	void(^callback)(NSError* error) = [parameters objectAtIndex:1];
	NSURL* url = [parameters objectAtIndex:2];
	NSParameterAssert([dictionary isKindOfClass:[NSDictionary class]]);
	NSParameterAssert(callback);
	NSParameterAssert([url isKindOfClass:[NSURL class]]);

	@autoreleasepool {
		// make the key value pairs
		PGKVPairs* pairs = makeKVPairs(dictionary);
		NSError* error = nil;
		if(pairs==nil) {
			error = [self raiseError:nil code:PGClientErrorParameters url:url reason:nil];
		} else {
			// perform the ping
			PGPing status = PQpingParams(pairs->keywords,pairs->values,0);
			freeKVPairs(pairs);
			switch(status) {
			case PQPING_OK:
				error = [self raiseError:nil code:PGClientErrorNone reason:nil];
				break;
			case PQPING_REJECT:
				error = [self raiseError:nil code:PGClientErrorRejected url:url reason:nil];
				break;
			case PQPING_NO_ATTEMPT:
				error = [self raiseError:nil code:PGClientErrorParameters url:url reason:nil];
				break;
			default:
				error = [self raiseError:nil code:PGClientErrorUnknown url:url reason:nil];
				break;
			}
		}
		
		// perform callback on main thread
		[self performSelector:@selector(_pingOnMainThread:) onThread:[NSThread mainThread] withObject:@[
			callback,
			error
		] waitUntilDone:NO];
	}
}

-(void)pingWithURL:(NSURL* )url whenDone:(void(^)(NSError* error)) callback {
	// extract parameters from the URL
	NSDictionary* parameters = [self _connectionParametersForURL:url];
	if(parameters==nil) {
		callback([self raiseError:nil code:PGClientErrorParameters url:url reason:nil]);
		return;
	}
	// make the key value pairs
	PGKVPairs* pairs = makeKVPairs(parameters);
	if(pairs==nil) {
		callback([self raiseError:nil code:PGClientErrorParameters url:url reason:nil]);
		return;
	}
	// perform the ping
	PGPing status = PQpingParams(pairs->keywords,pairs->values,0);
	freeKVPairs(pairs);
	// check the status
	NSError* error = nil;
	switch(status) {
	case PQPING_OK:
		break;
	case PQPING_REJECT:
		error = [self raiseError:nil code:PGClientErrorRejected url:url reason:nil];
		break;
	case PQPING_NO_ATTEMPT:
		error = [self raiseError:nil code:PGClientErrorParameters url:url reason:nil];
		break;
	default:
		error = [self raiseError:nil code:PGClientErrorUnknown url:url reason:nil];
		break;
	}
	callback(error);
}

-(void)pingInBackgroundWithURL:(NSURL* )url whenDone:(void(^)(NSError* error)) callback {
	// extract parameters from the URL
	NSDictionary* parameters = [self _connectionParametersForURL:url];
	if(parameters==nil) {
		callback([self raiseError:nil code:PGClientErrorParameters url:url reason:nil]);
		return;
	}

	// begin background ping for connection
	[NSThread detachNewThreadSelector:@selector(_pingWithParametersThread:) toTarget:self withObject:@[
		parameters,
		callback,
		url
	]];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Reset methods

-(void)resetWhenDone:(void(^)(NSError* error)) callback {
	if([_lock tryLock]==NO) {
		callback([self raiseError:nil code:PGClientErrorState reason:@"Cannot obtain lock"]);
		return;
	}
	// check for existing connection
	if(_connection==nil) {
		[_lock unlock];
		callback([self raiseError:nil code:PGClientErrorState reason:@"Connection not established"]);
		return;
	}
	// perform the reset
	PQreset(_connection);
	[_lock unlock];

	// check for changed status
	[self _setStatus:[self status]];
	// perform callback
	callback(nil);
}

-(void)resetInBackgroundWhenDone:(void(^)(NSError* error)) callback {
	// attempt to acquire lock
	if([_lock tryLock]==NO) {
		callback([self raiseError:nil code:PGClientErrorState reason:@"Cannot obtain lock"]);
		return;
	}

	// check for existing connection
	if(_connection == nil) {
		[_lock unlock];
		callback([self raiseError:nil code:PGClientErrorState reason:@"Connection already established"]);
		return;
	}

	// start the reset
	if(PQresetStart(_connection) != 1) {
		callback([self raiseError:nil code:PGClientErrorUnknown reason:nil]);
		[_lock unlock];
		return;
	}
	
	// set connecting status
	[self _setStatus:PGConnectionStatusConnecting];
	
	// begin background polling for connection
	[NSThread detachNewThreadSelector:@selector(_resetPollInBackgroundThread:) toTarget:self withObject:@[
		callback
	]];
}

/*
-(void)_resetPollWithParametersThread:(NSArray* )parameters {
	NSParameterAssert(parameters && [parameters isKindOfClass:[NSArray class]] && [parameters count]==1);
	void(^callback)(NSError* error) = [parameters objectAtIndex:0];
	NSParameterAssert(callback);
	
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
			PQsetNoticeProcessor(connection,PGConnectionNoticeProcessor,connection);
			error = [self raiseError:nil code:PGClientErrorNone reason:nil];
		} else if(PQconnectionNeedsPassword(_connection)) {
			error = [self raiseError:nil code:PGClientErrorNeedsPassword reason:nil];
		} else if(PQconnectionUsedPassword(_connection)) {
			error = [self raiseError:nil code:PGClientErrorInvalidPassword reason:nil];
		} else {
			error = [self raiseError:nil code:PGClientErrorRejected reason:@"%s",PQerrorMessage(_connection)];
		}
		// unlock and callback on the main thread
		[self performSelector:@selector(_pollUnlock:) onThread:[NSThread mainThread] withObject:@[ callback, error ] waitUntilDone:NO];
	}
}
*/

////////////////////////////////////////////////////////////////////////////////
#pragma mark Status changes

-(BOOL)_connectionUsedPassword {
	return PQconnectionUsedPassword(_connection) ? YES : NO;
}

-(void)_setStatusMainThread:(NSNumber* )status {
	NSParameterAssert(status);
	[[self delegate] connection:self statusChange:(PGConnectionStatus)[status intValue]];
}

-(void)_setStatus:(PGConnectionStatus)status {
	if(_status==status) {
		return;
	}
	_status = status;
	if([[self delegate] respondsToSelector:@selector(connection:statusChange:)]) {
		[self performSelectorOnMainThread:@selector(_setStatusMainThread:) withObject:[NSNumber numberWithInt:status] waitUntilDone:YES];
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Disconnection

-(void)disconnect {
	if([_lock tryLock]==NO) {
		[self raiseError:nil code:PGClientErrorState reason:@"Cannot obtain lock"];
		return;
	}
	if(_connection != nil) {
		PQfinish(_connection);
		_connection = nil;
		// check for changed status
		[self _setStatus:PGConnectionStatusDisconnected];
	}
	[_lock unlock];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Statement execution methods

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
	
	// poll for notifications
	[self _pollNotification];
	
	return r;
}

////////////////////////////////////////////////////////////////////////////////
// prepare query

/*
-(PGQuery* )prepare:(id)query error:(NSError** )error {
	NSParameterAssert([query isKindOfClass:[NSString class]] || [query isKindOfClass:[PGQuery class]]);
	PGQuery* q = nil;
	if([query isKindOfClass:[NSString class]]) {
		q = [PGQuery queryWithString:query];
	}
	if([query isKindOfClass:[PGQuery class]]) {
		q = query;
	}
	if([q isPrepared]==NO) {
		// prepare statement
		PQresult* r = PQprepare(_connection,[q identifier],[q query],0,NULL);
	}
	return q;
}
*/

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

