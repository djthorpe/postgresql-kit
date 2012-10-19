
#import "PGClientKit.h"
#import "PGClientKit+Private.h"

NSString* PGConnectionSchemes = @"pgsql pgsqls postgresql postgresqls";
NSString* PGConnectionDefaultEncoding = @"utf8";
NSString* PGConnectionBonjourServiceType = @"_postgresql._tcp";

void PGConnectionNoticeProcessor(void* arg,const char* cString);

NSString* PGClientErrorDomain = @"PGClientDomain";

////////////////////////////////////////////////////////////////////////////////

@implementation PGConnection
@dynamic user, database, status;

////////////////////////////////////////////////////////////////////////////////
// initialization

-(id)init {
	self = [super init];
	if(self) {
		_connection = nil;
	}
	return self;
}

-(void)dealloc {
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
	const char** keywords = malloc(sizeof(const char* ) * ([theParameters count]+1));
	const char** values = malloc(sizeof(const char* ) * ([theParameters count]+1));
	if(keywords==nil || values==nil) {
		free(keywords);
		free(values);
		return nil;
	}
	int i = 0;
	for(NSString* theKey in theParameters) {
		keywords[i] = [theKey UTF8String];
		values[i] = [[[theParameters valueForKey:theKey] description] UTF8String];
		i++;
	}
	keywords[i] = '\0';
	values[i] = '\0';
	PGconn* theConnection = PQconnectdbParams(keywords,values,0);
	free(keywords);
	free(values);
	return theConnection;
}

-(PGPing)_pingWithParameters:(NSDictionary* )theParameters {
	const char** keywords = malloc(sizeof(const char* ) * ([theParameters count]+1));
	const char** values = malloc(sizeof(const char* ) * ([theParameters count]+1));
	if(keywords==nil || values==nil) {
		free(keywords);
		free(values);
		return PQPING_NO_ATTEMPT;
	}
	int i = 0;
	for(NSString* theKey in theParameters) {
		keywords[i] = [theKey UTF8String];
		values[i] = [[[theParameters valueForKey:theKey] description] UTF8String];
		i++;
	}
	keywords[i] = '\0';
	values[i] = '\0';
	PGPing theStatus = PQpingParams(keywords,values,0);
	free(keywords);
	free(values);
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
	// make parameters from the URL
	NSMutableDictionary* theParameters = [[PGConnection _extractParametersFromURL:theURL] mutableCopy];
	if(theParameters==nil) {
		[self _raiseError:PGClientErrorParameterError reason:@"Bad parameters" error:error];
		return NO;
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
	if([theParameters objectForKey:@"password"]==nil && [[self delegate] respondsToSelector:@selector(connection:passwordForParameters:)]) {
		NSString* thePassword = [[self delegate] connection:self passwordForParameters:theParameters];
		if(thePassword) {
			[theParameters setValue:thePassword forKey:@"password"];
		}
	}
	
	// TODO: retrieve SSL parameters from delegate if necessary
	
	// make the connection (with blocking)
	@synchronized(_connection) {
		PGconn* theConnection = [self _connectWithParameters:theParameters];
		if(theConnection==nil || PQstatus(theConnection) != CONNECTION_OK) {
			[self _raiseError:PGClientErrorConnectionError reason:@"Connection error" error:error];
			return NO;
		}
		_connection = theConnection;		
		[[PGConnectionPool sharedConnectionPool] addConnection:self forHandle:_connection];
	}

	// set the notice processor
	PQsetNoticeProcessor(_connection,PGConnectionNoticeProcessor,_connection);

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
	[[PGConnectionPool sharedConnectionPool] removeConnectionForHandle:_connection];
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
	if([[self delegate] respondsToSelector:@selector(connection:notice:)]) {
		[[self delegate] connection:self notice:[NSString stringWithUTF8String:cString]];
	}
}

-(void)_raiseError:(PGClientErrorDomainCode)code reason:(NSString* )reason error:(NSError** )error {
	NSDictionary* userInfo = nil;
	if(reason) {
		userInfo = [NSDictionary dictionaryWithObjectsAndKeys:reason,NSLocalizedFailureReasonErrorKey,nil];
	}
	NSError* theError = [NSError errorWithDomain:PGClientErrorDomain code:code userInfo:userInfo];
	if(error) {
		(*error) = theError;
	}
	if([[self delegate] respondsToSelector:@selector(connection:error:)]) {
		[[self delegate] connection:self error:theError];
	}
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
	if([[self delegate] respondsToSelector:@selector(connection:willExecute:values:)]) {
		[[self delegate] connection:self willExecute:query values:values];
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
		} else {
			_paramSetNull(params,i);
			continue;
		}
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
// execute simple statement - return results in text or binary

-(PGResult* )execute:(NSString* )query format:(PGClientTupleFormat)format values:(NSArray* )values error:(NSError** )error {
	return [self _execute:query format:format values:values error:error];
}

-(PGResult* )execute:(NSString* )query format:(PGClientTupleFormat)format error:(NSError** )error {
	return [self _execute:query format:format values:nil error:error];
}

@end

////////////////////////////////////////////////////////////////////////////////

void PGConnectionNoticeProcessor(void* arg,const char* cString) {
	PGConnection* theConnection = [[PGConnectionPool sharedConnectionPool] connectionForHandle:arg];
	[theConnection _noticeProcess:cString];
}


