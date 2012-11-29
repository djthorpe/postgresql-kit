
#import "PGClientKit.h"
#import "PGClientKit+Private.h"

NSString* PGConnectionSchemes = @"pgsql pgsqls postgresql postgresqls";
NSString* PGConnectionDefaultEncoding = @"utf8";
NSString* PGConnectionBonjourServiceType = @"_postgresql._tcp";

void PGConnectionNoticeProcessor(void* arg,const char* cString);

NSString* PGClientErrorDomain = @"PGClientDomain";

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

////////////////////////////////////////////////////////////////////////////////

@implementation PGConnection
@dynamic user, database, status;

////////////////////////////////////////////////////////////////////////////////
// initialization

-(id)init {
	self = [super init];
	if(self) {
		_connection = nil;
		// call the initializer
		_pgresult_cache_init_pgconnection();
	}
	
	return self;
}

-(void)dealloc {
	if(self) {
		// call the destroyer
		_pgresult_cache_destroy_pgconnection();
	}
	[self disconnect];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

+(NSDictionary* )_extractParametersFromURL:(NSURL* )theURL {
	// extract parameters
	// see here for format of URI
	// http://www.postgresql.org/docs/9.2/static/libpq-connect.html#LIBPQ-CONNSTRING
	
	// check URL
	if(theURL==nil) {
		return nil;
	}
	// create a mutable dictionary
	NSMutableDictionary* theParameters = [[NSMutableDictionary alloc] init];
	
	// check possible schemes. if ends in an 's' then require SSL mode
	NSArray* allowedSchemes = [PGConnectionSchemes componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if([allowedSchemes containsObject:[theURL scheme]] != YES) {
		return nil;
	}
	if([[theURL scheme] hasSuffix:@"s"]) {
		[theParameters setValue:@"require" forKey:@"sslmode"];
	} else {
		[theParameters setValue:@"prefer" forKey:@"sslmode"];
	}

	// set username
	if([theURL user]) {
		[theParameters setValue:[theURL user] forKey:@"user"];
	}
	// set password
	if([theURL password]) {
		[theParameters setValue:[theURL password] forKey:@"password"];
	}
	// set host and/or hostaddr
	if([theURL host]) {
		// if host is in square brackets, then use as hostaddress instead
		if([[theURL host] hasPrefix:@"["] && [[theURL host] hasSuffix:@"]"]) {
			NSString* theAddress = [[theURL host] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]];
			[theParameters setValue:theAddress forKey:@"hostaddr"];
		} else {
			[theParameters setValue:[theURL host] forKey:@"host"];
		}
	}
	// set port
	if([theURL port]) {
		[theParameters setValue:[theURL port] forKey:@"port"];
	}
	// set database name
	if([theURL path]) {
		NSString* thePath = [[theURL path] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
		if([thePath length]) {
			[theParameters setValue:thePath forKey:@"dbname"];
		}
	}

	// extract other parameters from URI
	NSArray* additionalParameters = [[theURL query] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&;"]];
	for(NSString* additionalParameter in additionalParameters) {
		NSArray* theKeyValue = [additionalParameter componentsSeparatedByString:@"="];
		if([theKeyValue count] != 2) {
			// we require a key/value pair for any additional parameter
			return nil;
		}
		NSString* theKey = [[theKeyValue objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSString* theValue = [[theKeyValue objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		
		// insert into theParameters, allow override of sslmode
		if([theParameters objectForKey:theKey]==nil || [theKey isEqual:@"sslmode"]) {
			[theParameters setValue:theValue forKey:theKey];
		} else {
			// key already exists or not modifiable, return error
			return nil;
		}
	}
	
	// return the parameters
	return theParameters;
}

-(PGconn* )_connectWithParameters:(NSDictionary* )theParameters {
	PGKVPairs* pairs = makeKVPairs(theParameters);
	if(pairs==nil) {
		return nil;
	}
	PGconn* theConnection = PQconnectdbParams(pairs->keywords,pairs->values,0);
	freeKVPairs(pairs);
	return theConnection;
}

-(void)_pollWithParametersThread:(void(^)(PGConnectionStatus status,NSError* error)) callback {
	@autoreleasepool {
		PGConnectionStatus returnStatus;
		PostgresPollingStatusType status;
		do {
			status = PQconnectPoll(_connection);
			int socket = PQsocket(_connection);
			fd_set fd;
			switch(status) {
				case PGRES_POLLING_READING:
				case PGRES_POLLING_WRITING: /* wait for polling */
					returnStatus = PGConnectionStatusConnecting;
					FD_ZERO(&fd);
					FD_SET(socket, &fd);
					select(socket+1,status == PGRES_POLLING_READING ? &fd : NULL,status == PGRES_POLLING_WRITING ? &fd : NULL,NULL, NULL);
					break;
				case PGRES_POLLING_OK:
					returnStatus = PGConnectionStatusConnected;
					break;
				case PGRES_POLLING_FAILED:
					returnStatus = PGConnectionStatusDisconnected;
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
		} while(status != PGRES_POLLING_OK && status!= PGRES_POLLING_FAILED);
		
		NSError* theError = nil;
		if(returnStatus==PGConnectionStatusConnected) {
// TODO PQsetNoticeProcessor(_connection,PGConnectionNoticeProcessor,_connection);
		} else {
			PQfinish(_connection);
			_connection = nil;
			theError = [self _raiseError:PGClientErrorConnectionError reason:@"Connection error" error:nil];
		}
				
		// callback - should this be done on the main thread?
		callback(returnStatus,theError);
	}
}

-(PGconn* )_connectInBackgroundWithParameters:(NSDictionary* )theParameters whenDone:(void(^)(PGConnectionStatus status,NSError* error)) callback {
	PGKVPairs* pairs = makeKVPairs(theParameters);
	if(pairs==nil) {
		return nil;
	}
	PGconn* theConnection = PQconnectStartParams(pairs->keywords,pairs->values,0);
	freeKVPairs(pairs);
	if(theConnection != nil) {
		// create a background thread
		[NSThread detachNewThreadSelector:@selector(_pollWithParametersThread:) toTarget:self withObject:(id)callback];
	}
	return theConnection;
}

-(PGPing)_pingWithParameters:(NSDictionary* )theParameters {
	PGKVPairs* pairs = makeKVPairs(theParameters);
	if(pairs==nil) {
		return PQPING_NO_ATTEMPT;
	}
	PGPing theStatus = PQpingParams(pairs->keywords,pairs->values,0);
	freeKVPairs(pairs);
	return theStatus;
}

////////////////////////////////////////////////////////////////////////////////
// static methods

+(NSString* )defaultURLScheme {
	NSArray* allSchemes = [PGConnectionSchemes componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSParameterAssert([allSchemes count]);
	return [allSchemes objectAtIndex:0];
}

////////////////////////////////////////////////////////////////////////////////
// connection

-(NSDictionary* )_connectionParametersForURL:(NSURL* )theURL timeout:(NSUInteger)timeout {
	// make parameters from the URL
	NSMutableDictionary* theParameters = [[PGConnection _extractParametersFromURL:theURL] mutableCopy];
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
	
	// Retrieve password from delegate
	if([theParameters objectForKey:@"password"]==nil && [[self delegate] respondsToSelector:@selector(connectionPasswordForParameters:)]) {
		NSString* thePassword = [[self delegate] connectionPasswordForParameters:theParameters];
		if(thePassword) {
			[theParameters setValue:thePassword forKey:@"password"];
		}
	}
	
	// TODO: retrieve SSL parameters from delegate if necessary
	
	return theParameters;
}

-(BOOL)connectWithURL:(NSURL* )theURL error:(NSError** )error {
	return [self connectWithURL:theURL timeout:0 error:error];
}

-(BOOL)connectWithURL:(NSURL* )theURL timeout:(NSUInteger)timeout error:(NSError** )error {
	// set empty error
	if(error) {
		(*error) = nil;
	}
	
	// check for existing connection
	if(_connection) {
		[self _raiseError:PGClientErrorConnectionStateMismatch reason:@"Connected" error:error];
		return NO;
	}
	
	NSDictionary* theParameters = [self _connectionParametersForURL:theURL timeout:timeout];
	if(theParameters==nil) {
		[self _raiseError:PGClientErrorParameterError reason:@"Bad parameters" error:error];
		return NO;
	}
	
	// make the connection
	@synchronized(_connection) {
		PGconn* theConnection = [self _connectWithParameters:theParameters];
		if(theConnection==nil || PQstatus(theConnection) != CONNECTION_OK) {
			[self _raiseError:PGClientErrorConnectionError reason:@"Connection error" error:error];
			return NO;
		}
		_connection = theConnection;
	}

	// set up the connection
	// TODO PQsetNoticeProcessor(_connection,PGConnectionNoticeProcessor,_connection);

	// return success
	return YES;
}

-(BOOL)connectInBackgroundWithURL:(NSURL* )theURL whenDone:(void(^)(PGConnectionStatus status,NSError* error)) callback {
	return [self connectInBackgroundWithURL:theURL timeout:0 whenDone:callback];
}

-(BOOL)connectInBackgroundWithURL:(NSURL* )theURL timeout:(NSUInteger)timeout whenDone:(void(^)(PGConnectionStatus status,NSError* error)) callback {
	// check for existing connection
	if(_connection) {
		// if there is already a connection, raise an error
		NSError* theError = [self _raiseError:PGClientErrorConnectionStateMismatch reason:@"Connected" error:nil];
		callback(PGConnectionStatusDisconnected,theError);
		return NO;
	}
	// get parmeters for connection
	NSDictionary* theParameters = [self _connectionParametersForURL:theURL timeout:timeout];
	if(theParameters==nil) {
		NSError* theError = [self _raiseError:PGClientErrorParameterError reason:@"Bad parameters" error:nil];
		callback(PGConnectionStatusDisconnected,theError);
		return NO;
	}
	
	// make the connection (with blocking)
	@synchronized(_connection) {
		PGconn* theConnection = [self _connectInBackgroundWithParameters:theParameters whenDone:callback];
		if(theConnection==nil) {
			NSError* theError = [self _raiseError:PGClientErrorConnectionError reason:@"Connection error" error:nil];
			callback(PGConnectionStatusDisconnected,theError);
			return NO;
		}
		_connection = theConnection;
	}
	
	// return success
	return YES;
}

-(BOOL)pingWithURL:(NSURL* )theURL error:(NSError** )error {
	return [self pingWithURL:theURL timeout:0 error:error];
}

-(BOOL)pingWithURL:(NSURL* )theURL timeout:(NSUInteger)timeout error:(NSError** )error {
	// see if a connection is possible to a remote server, and return YES if successful
	// set empty error
	if(error) {
		(*error) = nil;
	}

	// make parameters from the URL
	NSMutableDictionary* theParameters = [[PGConnection _extractParametersFromURL:theURL] mutableCopy];
	if(theParameters==nil) {
		[self _raiseError:PGClientErrorParameterError reason:@"Bad parameters" error:error];
		return NO;
	}
	if(timeout) {
		[theParameters setValue:[NSNumber numberWithUnsignedInteger:timeout] forKey:@"connect_timeout"];
	}
	
	// TODO: retrieve SSL parameters from delegate if necessary
	
	// make the ping
	PGPing status = [self _pingWithParameters:theParameters];
	switch(status) {
		case PQPING_OK:
			return YES;
		case PQPING_REJECT:
			[self _raiseError:PGClientErrorRejectionError reason:@"Rejected connection" error:error];
			return NO;
		case PQPING_NO_ATTEMPT:
			[self _raiseError:PGClientErrorParameterError reason:@"Bad parameters" error:error];
			return NO;
		default:
			[self _raiseError:PGClientErrorConnectionError reason:@"Connection error" error:error];
			return NO;
	}
}

-(BOOL)disconnect {
	if(_connection==nil) {
		return NO;
	}
	PQfinish(_connection);
	_connection = nil;
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// properties

-(NSString* )user {
	if(_connection==nil) {
		return nil;
	}
	return [NSString stringWithUTF8String:PQuser(_connection)];
}

-(NSString* )database {
	if(_connection==nil) {
		return nil;
	}
	return [NSString stringWithUTF8String:PQdb(_connection)];	
}

-(PGConnectionStatus)status {
	if(_connection==nil) {
		return PGConnectionStatusDisconnected;
	}
	if(PQstatus(_connection) != CONNECTION_OK) {
		return PGConnectionStatusBad;
	}
	// TODO: Try and ping the server
	return PGConnectionStatusConnected;
}

////////////////////////////////////////////////////////////////////////////////
// process notices, raise errors

-(void)_noticeProcess:(const char* )cString {
	if([[self delegate] respondsToSelector:@selector(connectionNotice:)]) {
		[[self delegate] connectionNotice:[NSString stringWithUTF8String:cString]];
	}
}

-(NSError* )_raiseError:(PGClientErrorDomainCode)code reason:(NSString* )reason error:(NSError** )error {
	NSDictionary* userInfo = nil;
	if(reason) {
		userInfo = [NSDictionary dictionaryWithObjectsAndKeys:reason,NSLocalizedFailureReasonErrorKey,nil];
	}
	NSError* theError = [NSError errorWithDomain:PGClientErrorDomain code:code userInfo:userInfo];
	if(error) {
		(*error) = theError;
	}
	if([[self delegate] respondsToSelector:@selector(connectionError:)]) {
		// perform selector on main thread
		[(NSObject* )[self delegate] performSelector:@selector(connectionError:) onThread:[NSThread mainThread] withObject:theError waitUntilDone:NO];
	}
	return theError;
}

////////////////////////////////////////////////////////////////////////////////
// underlying execute method with parameters

-(PGResult* )_execute:(NSString* )query format:(PGClientTupleFormat)format values:(NSArray* )values error:(NSError** )error {
	NSParameterAssert(query && [query isKindOfClass:[NSString class]]);
	NSParameterAssert(format==PGClientTupleFormatBinary || format==PGClientTupleFormatText);
	// clear error
	if(error) {
		(*error) = nil;
	}
	// check for existing connection
	if(_connection==nil) {
		[self _raiseError:PGClientErrorConnectionStateMismatch reason:@"Disconnected" error:error];
		return nil;
	}
	// call delegate
	if([[self delegate] respondsToSelector:@selector(connectionWillExecute:values:)]) {
		[[self delegate] connectionWillExecute:query values:values];
	}
	// create parameters
	PGClientParams* params = _paramAllocForValues(values);
	if(params==nil) {
		[self _raiseError:PGClientErrorParameterError reason:@"Bad parameters" error:error];
		return nil;
	}
	for(NSUInteger i = 0; i < [values count]; i++) {
		id obj = [values objectAtIndex:i];
		if([obj isKindOfClass:[NSNull class]]) {
			_paramSetNull(params,i);
			continue;
		}
		// TODO
		_paramSetNull(params,i);
	}
	// check number of parameters
	if(params->size > INT_MAX) {
		[self _raiseError:PGClientErrorParameterError reason:@"Bad parameters" error:error];
		return nil;		
	}
	// execute the command, free parameters
	int resultFormat = (format==PGClientTupleFormatBinary) ? 1 : 0;
	PGresult* theResult = PQexecParams(_connection,[query UTF8String],(int)params->size,params->types,params->values,params->lengths,params->formats,resultFormat);
	_paramFree(params);	
	if(theResult==nil) {
		[self _raiseError:PGClientErrorExecutionError reason:@"Execution Error" error:error];
		return nil;
	}
	// check for connection errors
	if(PQresultStatus(theResult)==PGRES_EMPTY_QUERY) {
		[self _raiseError:PGClientErrorExecutionError reason:@"Empty Query" error:error];
		PQclear(theResult);
		return nil;
	}
	if(PQresultStatus(theResult)==PGRES_BAD_RESPONSE || PQresultStatus(theResult)==PGRES_FATAL_ERROR) {
		[self _raiseError:PGClientErrorExecutionError reason:[NSString stringWithUTF8String:PQresultErrorMessage(theResult)] error:error];
		PQclear(theResult);
		return nil;
	}
	// return resultset
	return [[PGResult alloc] initWithResult:theResult format:format];
}

////////////////////////////////////////////////////////////////////////////////
// execute statements - return results in text or binary

-(PGResult* )execute:(NSString* )query format:(PGClientTupleFormat)format values:(NSArray* )values error:(NSError** )error {
	return [self _execute:query format:format values:values error:error];
}

-(PGResult* )execute:(NSString* )query format:(PGClientTupleFormat)format error:(NSError** )error {
	return [self _execute:query format:format values:nil error:error];
}

@end

////////////////////////////////////////////////////////////////////////////////

/*void PGConnectionNoticeProcessor(void* arg,const char* cString) {
	PGConnection* theConnection = [[PGConnectionPool sharedConnectionPool] connectionForHandle:arg];
	[theConnection _noticeProcess:cString];
}
*/


