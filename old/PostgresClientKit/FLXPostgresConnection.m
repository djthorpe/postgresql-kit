
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"

////////////////////////////////////////////////////////////////////////////////

void FLXPostgresConnectionNoticeProcessor(void* arg,const char* theMessage) {
	FLXPostgresConnection* theObject = (FLXPostgresConnection* )arg;
	if([theObject isKindOfClass:[FLXPostgresConnection class]]) {
		[theObject _noticeProcessorWithMessage:[NSString stringWithUTF8String:theMessage]];
	}
}

////////////////////////////////////////////////////////////////////////////////

NSString* FLXPostgresConnectionErrorDomain = @"FLXPostgresConnectionError";
NSString* FLXPostgresConnectionScheme = @"pgsql";

NSString* FLXPostgresParameterServerVersion = @"server_version";
NSString* FLXPostgresParameterServerPID = @"server_pid";
NSString* FLXPostgresParameterServerEncoding = @"server_encoding";
NSString* FLXPostgresParameterClientEncoding = @"client_encoding";
NSString* FLXPostgresParameterSuperUser = @"is_superuser";
NSString* FLXPostgresParameterSessionAuthorization = @"session_authorization";
NSString* FLXPostgresParameterDateStyle = @"DateStyle";
NSString* FLXPostgresParameterTimeZone = @"TimeZone";
NSString* FLXPostgresParameterIntegerDateTimes = @"integer_datetimes";
NSString* FLXPostgresParameterStandardConformingStrings = @"standard_conforming_strings";
NSString* FLXPostgresParameterProtocolVersion = @"protocol_version";

@implementation FLXPostgresConnection
@synthesize delegate;
@synthesize parameters = m_theParameters;
@synthesize timeout = m_theTimeout;
@synthesize port = m_thePort;
@synthesize host = m_theHost;
@synthesize user = m_theUser;
@synthesize database = m_theDatabase;

////////////////////////////////////////////////////////////////////////////////
// constructors

-(id)init {
	self = [super init];
	if (self != nil) {
		m_theConnection = nil;
		m_theTypeMap = [[NSMutableDictionary alloc] init];
	}
	return self;
}

-(void)dealloc {
	[m_theTypeMap release];
	[self disconnect];
	[self setHost:nil];
	[self setUser:nil];
	[self setDatabase:nil];
	[self setParameters:nil];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////

+(FLXPostgresConnection* )connectionWithURL:(NSURL* )theURL {
	// check URL
	if(theURL==nil || [[theURL scheme] isEqual:FLXPostgresConnectionScheme]==NO) {
		return nil;
	}
	FLXPostgresConnection* theConnection = [[[FLXPostgresConnection alloc] init] autorelease];
	if([theURL user]) [theConnection setUser:[theURL user]];
	if([theURL host]) [theConnection setHost:[theURL host]];
	if([theURL port]) [theConnection setPort:[[theURL port] unsignedIntegerValue]];
	if([theURL path]) {
		NSString* thePath = [[theURL path] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
		if([thePath length]) {
			[theConnection setDatabase:thePath];
		}
	}
	return theConnection;
}

////////////////////////////////////////////////////////////////////////////////
// properties

-(PGconn* )PGconn {
	return (PGconn* )m_theConnection;
}

+(NSString* )scheme {
	return FLXPostgresConnectionScheme;
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(BOOL)connected {
	if([self PGconn]==nil) return NO;
	ConnStatusType theStatus = PQstatus([self PGconn]);
	if(theStatus==CONNECTION_OK) return YES;
	return NO;
}

-(void)disconnect {
	if([self PGconn]==nil) return;
	PQfinish([self PGconn]);
	m_theConnection = nil;
	[self setParameters:nil];
}

-(void)connect {
	[self connectWithPassword:nil];
}

-(void)connectWithPassword:(NSString* )thePassword {
	if([self PGconn] != nil) {
		[FLXPostgresException raise:FLXPostgresConnectionErrorDomain reason:@"Connection is already made"];    
	}

	// set the username if not yet set
	if([[self user] length]==0) {
		[self setUser:NSUserName()];
	}
	
	// set the database name if not yet set
	if([[self database] length]==0) {
		[self setDatabase:[self user]];
	}
	
	// construct the parameters
	NSMutableString* theParameters = [NSMutableString string];
	if([[self host] length]) {
		[theParameters appendFormat:@"host='%@' ",[self host]];
		// if not hostname, it will default to socket on localhost
	}
	
	if([self port]) {
		[theParameters appendFormat:@"port=%u ",[self port]];
	}
	
	[theParameters appendFormat:@"user='%@' ",[self user]];
	[theParameters appendFormat:@"dbname='%@' ",[self database]];

	// set password
	if(thePassword != nil) {
		[theParameters appendFormat:@"password='%@' ",thePassword];
	}
	
	// set timeout
	if([self timeout]) {
		[theParameters appendFormat:@"connect_timeout=%d ",[self timeout]];    
	}
	
	// perform the connection
	PGconn* theConnection = PQconnectdb([theParameters UTF8String]);
	if(theConnection==nil || PQstatus(theConnection) != CONNECTION_OK) {
		[FLXPostgresException raise:FLXPostgresConnectionErrorDomain connection:theConnection];
	}
	
	// set the internal connection structure
	m_theConnection = theConnection;

	// set the notice processor
	PQsetNoticeProcessor(theConnection,FLXPostgresConnectionNoticeProcessor,self);
	
	// read the standard parameters
	NSArray* theKeys = [NSArray arrayWithObjects:FLXPostgresParameterServerVersion,FLXPostgresParameterServerEncoding,FLXPostgresParameterClientEncoding,FLXPostgresParameterSuperUser,FLXPostgresParameterSessionAuthorization,FLXPostgresParameterDateStyle,FLXPostgresParameterTimeZone,FLXPostgresParameterIntegerDateTimes,FLXPostgresParameterStandardConformingStrings,nil];
	NSMutableDictionary* theDictionary = [NSMutableDictionary dictionaryWithCapacity:[theKeys count]];
	for(NSString* theKey in theKeys) {
		const char* theValue = PQparameterStatus(theConnection, [theKey UTF8String]);
		if(theValue==nil) continue;
		NSString* theValue2 = [NSString stringWithUTF8String:theValue];
		if([theKey isEqual:FLXPostgresParameterSuperUser] || [theKey isEqual:FLXPostgresParameterIntegerDateTimes] || [theKey isEqual:FLXPostgresParameterStandardConformingStrings]) {
			// convert to boolean
			if([theValue2 isEqual:@"on"] || [theValue2 isEqual:@"yes"] || [theValue2 isEqual:@"true"]) {
				[theDictionary setObject:[NSNumber numberWithBool:YES] forKey:theKey];
			} else {
				[theDictionary setObject:[NSNumber numberWithBool:NO] forKey:theKey];
			}
		} else {
			[theDictionary setObject:theValue2 forKey:theKey];
		}
	}
	
	// add additional parameters
	[theDictionary setObject:[NSNumber numberWithInt:PQprotocolVersion(theConnection)] forKey:FLXPostgresParameterProtocolVersion];
	[theDictionary setObject:[NSNumber numberWithInt:PQbackendPID(theConnection)] forKey:FLXPostgresParameterServerPID];	
	
	// set parameters
	[self setParameters:theDictionary];
	
	// register types
	[self _registerStandardTypeHandlers];
}

-(void)reset {
	if([self PGconn]==nil) {
		[FLXPostgresException raise:FLXPostgresConnectionErrorDomain reason:@"Connection cannot be reset"];    
	}	
	// perform the reset
	PQreset([self PGconn]);	
}

////////////////////////////////////////////////////////////////////////////////
// prepare

-(FLXPostgresStatement* )prepare:(NSString* )theQuery {
	NSParameterAssert(theQuery);
	if([self PGconn]==nil) {
		[FLXPostgresException raise:FLXPostgresConnectionErrorDomain reason:@"No Connection"];        
	}
	return [[[FLXPostgresStatement alloc] initWithStatement:theQuery] autorelease];
}

-(FLXPostgresStatement* )prepareWithFormat:(NSString* )theQuery,... {
	NSParameterAssert(theQuery);	
	va_list argumentList;
	va_start(argumentList,theQuery);
	NSMutableString* theString = [[NSMutableString alloc] init];
	CFStringAppendFormatAndArguments((CFMutableStringRef)theString,(CFDictionaryRef)nil,(CFStringRef)theQuery,argumentList);
	va_end(argumentList);   
	FLXPostgresStatement* theStatement = [self prepare:theString];
	[theString release];
	return theStatement;
}

-(void)_prepare:(FLXPostgresStatement* )theStatement num:(NSUInteger)nParams types:(FLXPostgresOid* )paramTypes {
	NSParameterAssert(theStatement);
	NSParameterAssert([theStatement name]==nil);
	// generate a statement name
	NSString* theName = [[NSProcessInfo processInfo] globallyUniqueString];
	// prepare the statement
	PGresult* theResult = PQprepare([self PGconn],[theName UTF8String],[theStatement UTF8Statement],nParams,paramTypes);
	if(theResult==nil) {
		[FLXPostgresException raise:FLXPostgresConnectionErrorDomain connection:self];
	}
	// check returned result
	if(PQresultStatus(theResult)==PGRES_BAD_RESPONSE || PQresultStatus(theResult)==PGRES_FATAL_ERROR) {
		NSString* theMessage = [NSString stringWithUTF8String:PQresultErrorMessage(theResult)];
		PQclear(theResult);
		[FLXPostgresException raise:FLXPostgresConnectionErrorDomain reason:theMessage];
	}
	// free the result object
	PQclear(theResult);
	// set the name
	[theStatement setName:theName];
}

////////////////////////////////////////////////////////////////////////////////
// execute

-(FLXPostgresResult* )_execute:(NSObject* )theQuery values:(NSArray* )theValues {
	NSParameterAssert(theQuery);
	NSParameterAssert([theQuery isKindOfClass:[NSString class]] || [theQuery isKindOfClass:[FLXPostgresStatement class]]);
	if([self PGconn]==nil) {
		[FLXPostgresException raise:FLXPostgresConnectionErrorDomain reason:@"No Connection"];        
		return nil;
	}

	if([[self delegate] respondsToSelector:@selector(connection:willExecute:values:)]) {
		[[self delegate] connection:self willExecute:theQuery values:theValues];
	}
	
	//TODO:determine casts for statement
	//[FLXPostgresStatement _parseQueryForTypes:theQuery];
	
	// create values, lengths and format arrays
	NSUInteger nParams = theValues ? [theValues count] : 0;
	const void** paramValues = nil;	
	FLXPostgresOid* paramTypes = nil;
	int* paramLengths = nil;
	int* paramFormats = nil;
	if(nParams) {
		paramValues = malloc(sizeof(void*) * nParams);
		paramTypes = malloc(sizeof(FLXPostgresOid) * nParams);
		paramLengths = malloc(sizeof(int) * nParams);
		paramFormats = malloc(sizeof(int) * nParams);
		if(paramValues==nil || paramLengths==nil || paramFormats==nil) {
			free(paramValues);
			free(paramTypes);
			free(paramLengths);
			free(paramFormats);
			[FLXPostgresException raise:FLXPostgresConnectionErrorDomain reason:@"Memory allocation error"];
			return nil;
		}
	}
	// fill the data structures
	for(NSUInteger i = 0; i < nParams; i++) {
		id theNativeObject = [theValues objectAtIndex:i];
		NSParameterAssert(theNativeObject);

		// deterime if bound value is an NSNull
		if([theNativeObject isKindOfClass:[NSNull class]]) {
			paramValues[i] = nil;
			paramTypes[i] = 0;
			paramLengths[i] = 0;			
			paramFormats[i] = 0;
			continue;
		}
		
		// obtain correct handler for this class
		id<FLXPostgresTypeProtocol> theTypeHandler = [self _typeHandlerForClass:[theNativeObject class]];
		if(theTypeHandler==nil) {
			free(paramValues);
			free(paramTypes);
			free(paramLengths);
			free(paramFormats);			
			[FLXPostgresException raise:FLXPostgresConnectionErrorDomain reason:[NSString stringWithFormat:@"Parameter $%u unsupported class %@",(i+1),NSStringFromClass([theNativeObject class])]];
		}			
		FLXPostgresOid theType = 0;
		NSData* theData = [theTypeHandler remoteDataFromObject:theNativeObject type:&theType];
		if(theData==nil) {
			free(paramValues);
			free(paramTypes);
			free(paramLengths);
			free(paramFormats);			
			[FLXPostgresException raise:FLXPostgresConnectionErrorDomain reason:[NSString stringWithFormat:@"Parameter $%u cannot be converted into a bound value",(i+1)]];
			return nil;
		}			

		// check length of data
		if([theData length] > INT_MAX) {
			free(paramValues);
			free(paramTypes);
			free(paramLengths);
			free(paramFormats);
			[FLXPostgresException raise:FLXPostgresConnectionErrorDomain reason:[NSString stringWithFormat:@"Bound value $%u exceeds maximum size",(i+1)]];			
			return nil;
		}
				
		// assign data
		paramTypes[i] = theType;		
		if([theData length]==0) {
			// note: if data length is zero, we encode as text instead, as NSData returns 0 for
			// empty data, and it gets encoded as a NULL
			paramValues[i] = "";
			paramFormats[i] = 0;
			paramLengths[i] = 0;						
		} else {			
			// send as binary data
			paramValues[i] = [theData bytes];
			paramLengths[i] = (int)[theData length];			
			paramFormats[i] = 1;
		}
	}	

	// execute the command - return data in binary
	PGresult* theResult = nil;
	if([theQuery isKindOfClass:[NSString class]]) {
		NSString* theStatement = (NSString* )theQuery;
		theResult = PQexecParams([self PGconn],[theStatement UTF8String],nParams,paramTypes,(const char** )paramValues,(const int* )paramLengths,(const int* )paramFormats,1);
	} else if([theQuery isKindOfClass:[FLXPostgresStatement class]]) {
		FLXPostgresStatement* theStatement = (FLXPostgresStatement* )theQuery;
		if([theStatement name]==nil) {
			// statement has not been prepared yet, so we prepare the statement with the given parameter types
			[self _prepare:theStatement num:nParams types:paramTypes];
			NSParameterAssert([theStatement name]);
		}
		theResult = PQexecPrepared([self PGconn],[theStatement UTF8Name],nParams,(const char** )paramValues,(const int* )paramLengths,(const int* )paramFormats,1);		
	} else {
		NSParameterAssert(NO);
	}
		
	// free the data structures
	free(paramValues);
	free(paramTypes);
	free(paramLengths);
	free(paramFormats);	
	
	// check returned result
	if(theResult==nil) {
		[FLXPostgresException raise:FLXPostgresConnectionErrorDomain connection:[self PGconn]];
	}
	if(PQresultStatus(theResult)==PGRES_BAD_RESPONSE || PQresultStatus(theResult)==PGRES_FATAL_ERROR) {
		NSString* theMessage = [NSString stringWithUTF8String:PQresultErrorMessage(theResult)];
		PQclear(theResult);
		[FLXPostgresException raise:FLXPostgresConnectionErrorDomain reason:theMessage];
	}
	
	// return a result object
	return [[[FLXPostgresResult alloc] initWithResult:theResult connection:self] autorelease];
}

-(FLXPostgresResult* )execute:(NSString* )theQuery {
	return [self _execute:theQuery values:nil];
}

-(FLXPostgresResult* )executeWithFormat:(NSString* )theQuery,... {
	va_list argumentList;
	va_start(argumentList,theQuery);
	NSMutableString* theString = [[NSMutableString alloc] init];
	CFStringAppendFormatAndArguments((CFMutableStringRef)theString,(CFDictionaryRef)nil,(CFStringRef)theQuery,argumentList);
	va_end(argumentList);   
	FLXPostgresResult* theResult = [self _execute:theString values:nil];
	[theString release];
	return theResult;
}

-(FLXPostgresResult* )execute:(NSString* )theQuery value:(NSObject* )theValue {
	return [self _execute:theQuery values:[NSArray arrayWithObject:theValue]];
}

-(FLXPostgresResult* )executePrepared:(FLXPostgresStatement* )theStatement value:(NSObject* )theValue {
	return [self _execute:theStatement values:[NSArray arrayWithObject:theValue]];
}

-(FLXPostgresResult* )executePrepared:(FLXPostgresStatement* )theStatement {
	return [self _execute:theStatement values:nil];
}

-(FLXPostgresResult* )executePrepared:(FLXPostgresStatement* )theStatement values:(NSArray* )theValues {
	return [self _execute:theStatement values:theValues];
}

-(FLXPostgresResult* )execute:(NSString* )theQuery values:(NSArray* )theValues {
	return [self _execute:theQuery values:theValues];
}

////////////////////////////////////////////////////////////////////////////////
// quote

-(NSString* )quote:(NSObject* )theObject {	
	if(theObject==nil || [theObject isKindOfClass:[NSNull class]]) {
		return @"NULL";
	}
	id<FLXPostgresTypeProtocol> theHandler = [self _typeHandlerForClass:[theObject class]];
	if(theHandler==nil) {
		[FLXPostgresException raise:FLXPostgresConnectionErrorDomain reason:[NSString stringWithFormat:@"Unsupported class %@",NSStringFromClass([theObject class])]];
		return nil;
	}
	return [theHandler quotedStringFromObject:theObject];
}

////////////////////////////////////////////////////////////////////////////////
// delegates

-(void)_noticeProcessorWithMessage:(NSString* )theMessage {
	if([self delegate] && [[self delegate] respondsToSelector:@selector(connection:notice:)]) {
		[[self delegate] connection:self notice:theMessage];
	}
}

////////////////////////////////////////////////////////////////////////////////
// type handlers

-(void)_registerTypeHandler:(Class)theTypeHandlerClass {
	NSParameterAssert(theTypeHandlerClass);
	NSParameterAssert([theTypeHandlerClass conformsToProtocol:@protocol(FLXPostgresTypeProtocol)]);

	// create an object of this class
	id<FLXPostgresTypeProtocol> theHandler = [[[theTypeHandlerClass alloc] initWithConnection:self] autorelease];
	NSParameterAssert(theHandler);
	
	// add to the type map - for native class
	[m_theTypeMap setObject:theHandler forKey:NSStringFromClass([theHandler nativeClass])];
	// add to the type map - for types
	FLXPostgresOid* theRemoteTypes = [theHandler remoteTypes];
	for(NSUInteger i = 0; theRemoteTypes[i]; i++) {
		NSNumber* theKey = [NSNumber numberWithUnsignedInteger:theRemoteTypes[i]];
		[m_theTypeMap setObject:theHandler forKey:theKey];
	}
}

-(id<FLXPostgresTypeProtocol>)_typeHandlerForClass:(Class)theClass {
	return [m_theTypeMap objectForKey:NSStringFromClass(theClass)];
}

-(id<FLXPostgresTypeProtocol>)_typeHandlerForRemoteType:(FLXPostgresOid)theType {
	return [m_theTypeMap objectForKey:[NSNumber numberWithUnsignedInteger:theType]];
}

-(void)_registerStandardTypeHandlers {
	[self _registerTypeHandler:[FLXPostgresTypeNSString class]];	
	[self _registerTypeHandler:[FLXPostgresTypeNSNumber class]];	
}

@end
