
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
NSString* FLXPostgresConnectionEmptyString = @"";

NSString* FLXPostgresParameterServerVersion = @"server_version";
NSString* FLXPostgresParameterServerEncoding = @"server_encoding";
NSString* FLXPostgresParameterClientEncoding = @"client_encoding";
NSString* FLXPostgresParameterSuperUser = @"is_superuser";
NSString* FLXPostgresParameterSessionAuthorization = @"session_authorization";
NSString* FLXPostgresParameterDateStyle = @"DateStyle";
NSString* FLXPostgresParameterTimeZone = @"TimeZone";
NSString* FLXPostgresParameterIntegerDateTimes = @"integer_datetimes";
NSString* FLXPostgresParameterStandardConformingStrings = @"standard_conforming_strings";

@implementation FLXPostgresConnection
@synthesize delegate;
@synthesize parameters = m_theParameters;
@synthesize timeout = m_theTimeout;
@synthesize port = m_thePort;
@synthesize host = m_theHost;
@synthesize user = m_theUser;
@synthesize database = m_theDatabase;
@synthesize types = m_theTypes;

////////////////////////////////////////////////////////////////////////////////
// constructors

-(id)init {
	self = [super init];
	if (self != nil) {
		m_theConnection = nil;
		m_theTypes = nil;
	}
	return self;
}

-(void)dealloc {
	[self disconnect];
	[self setHost:nil];
	[self setUser:nil];
	[self setDatabase:nil];
	[self setParameters:nil];
	[self setTypes:nil];
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

-(PGconn* )connection {
	return (PGconn* )m_theConnection;
}

-(NSString* )scheme {
	return FLXPostgresConnectionScheme;
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(BOOL)connected {
	if([self connection]==nil) return NO;
	ConnStatusType theStatus = PQstatus([self connection]);
	if(theStatus==CONNECTION_OK) return YES;
	return NO;
}

-(void)disconnect {
	if([self connection]==nil) return;
	PQfinish([self connection]);
	m_theConnection = nil;
	[self setParameters:nil];
	[self setTypes:nil];
}

-(void)connect {
	[self connectWithPassword:nil];
}

-(void)connectWithPassword:(NSString* )thePassword {
	if([self connection] != nil) {
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
	
	// read the parameters
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
	// set types and parameters
	[self setParameters:theDictionary];
	[self setTypes:[[[FLXPostgresTypes alloc] initWithParameters:theDictionary] autorelease]];
}

-(void)reset {
	if([self connection]==nil) {
		[FLXPostgresException raise:FLXPostgresConnectionErrorDomain reason:@"Connection cannot be reset"];    
	}	
	// perform the reset
	PQreset([self connection]);	
}

////////////////////////////////////////////////////////////////////////////////
// prepare

-(FLXPostgresStatement* )prepare:(NSString* )theQuery {
	NSParameterAssert(theQuery);
	if([self connection]==nil) {
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
	PGresult* theResult = PQprepare([self connection],[theName UTF8String],[theStatement UTF8Statement],nParams,paramTypes);
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
	if([self connection]==nil) {
		[FLXPostgresException raise:FLXPostgresConnectionErrorDomain reason:@"No Connection"];        
		return nil;
	}

	if([[self delegate] respondsToSelector:@selector(connection:willExecute:values:)]) {
		[[self delegate] connection:self willExecute:theQuery values:theValues];
	}
	
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
		}
	}
	// fill the data structures
	for(NSUInteger i = 0; i < nParams; i++) {
		FLXPostgresOid theType = 0;
		NSObject* theObject = [[self types] boundValueFromObject:[theValues objectAtIndex:i] type:&theType];
		if(theObject==nil) {
			[FLXPostgresException raise:FLXPostgresConnectionErrorDomain reason:[NSString stringWithFormat:@"Parameter $%u cannot be converted into a bound value",(i+1)]];
		}			
		NSParameterAssert(theObject);
		NSParameterAssert([theObject isKindOfClass:[NSString class]] || [theObject isKindOfClass:[NSData class]] || [theObject isKindOfClass:[NSNull class]]);

		const void* theValue = nil;
		NSUInteger theLength = 0;
		BOOL isBinary = NO;

		// assign value and length
		if([theObject isKindOfClass:[NSNull class]]) {
			// NULL value
			theValue = nil;
		} else if([theObject isKindOfClass:[NSString class]]) {
			// convert from string
			theValue = [(NSString* )theObject UTF8String];
			theLength = [(NSString* )theObject lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
		} else if([theObject isKindOfClass:[NSData class]]) {
			// convert from data
			theLength = [(NSData* )theObject length];
			if(theLength==0) {
				// note: if data length is zero, we encode as text instead, as NSData returns 0 for
				// empty data, and it gets encoded as a NULL
				theValue = [FLXPostgresConnectionEmptyString UTF8String];
			} else {			
				theValue = [(NSData* )theObject bytes];
				isBinary = YES;
			}
		} else {
			// Internal error - should not get here
			NSParameterAssert(NO);
		}
		
		// check length of data
		if(theLength > INT_MAX) {
			free(paramValues);
			free(paramTypes);
			free(paramLengths);
			free(paramFormats);
			[FLXPostgresException raise:FLXPostgresConnectionErrorDomain reason:[NSString stringWithFormat:@"Bound value %u exceeds maximum size",i]];			
		}

		// assign data
		paramValues[i] = theValue;
		paramTypes[i] = theType;
		paramLengths[i] = (int)theLength;			
		paramFormats[i] = isBinary ? 1 : 0;		
	}	

	// execute the command - return data in binary
	PGresult* theResult = nil;
	if([theQuery isKindOfClass:[NSString class]]) {
		NSString* theStatement = (NSString* )theQuery;
		theResult = PQexecParams([self connection],[theStatement UTF8String],nParams,paramTypes,(const char** )paramValues,(const int* )paramLengths,(const int* )paramFormats,1);
	} else if([theQuery isKindOfClass:[FLXPostgresStatement class]]) {
		FLXPostgresStatement* theStatement = (FLXPostgresStatement* )theQuery;
		if([theStatement name]==nil) {
			// statement has not been prepared yet, so we prepare the statement with the given parameter types
			[self _prepare:theStatement num:nParams types:paramTypes];
			NSParameterAssert([theStatement name]);
		}
		theResult = PQexecPrepared([self connection],[theStatement UTF8Name],nParams,(const char** )paramValues,(const int* )paramLengths,(const int* )paramFormats,1);		
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
		[FLXPostgresException raise:FLXPostgresConnectionErrorDomain connection:[self connection]];
	}
	if(PQresultStatus(theResult)==PGRES_BAD_RESPONSE || PQresultStatus(theResult)==PGRES_FATAL_ERROR) {
		NSString* theMessage = [NSString stringWithUTF8String:PQresultErrorMessage(theResult)];
		PQclear(theResult);
		[FLXPostgresException raise:FLXPostgresConnectionErrorDomain reason:theMessage];
	}
	
	// return a result object
	return [[[FLXPostgresResult alloc] initWithTypes:[self types] result:theResult] autorelease];
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

-(NSString* )_quoteData:(NSData* )theData {
	size_t theLength = 0;
	unsigned char* theBuffer = PQescapeByteaConn([self connection],[theData bytes],[theData length],&theLength);
	if(theBuffer==nil) {
		[FLXPostgresException raise:FLXPostgresConnectionErrorDomain connection:[self connection]];      
	}
	NSMutableString* theNewString = [[NSMutableString alloc] initWithBytesNoCopy:theBuffer length:(theLength-1) encoding:NSUTF8StringEncoding freeWhenDone:YES];
	// add quotes
	[theNewString appendString:@"'"];
	[theNewString insertString:@"'" atIndex:0];
	// return the string
	return [theNewString autorelease];  
}

-(NSString* )quote:(NSObject* )theObject {
	if(theObject==nil || [theObject isKindOfClass:[NSNull class]]) {
		return @"NULL";
	}
	if([theObject isKindOfClass:[NSData class]]) {
		return [self _quoteData:(NSData* )theObject];
	}
	if([theObject isKindOfClass:[NSNumber class]]) {
		return [(NSNumber* )theObject description];
	}
	if([theObject isKindOfClass:[NSString class]]) {
		return [self _quoteData:[(NSString* )theObject dataUsingEncoding:NSUTF8StringEncoding]];
	}
	// TODO: NSDate and other types that we support
	// we should never get here
	NSParameterAssert(NO);
	return nil;
}

////////////////////////////////////////////////////////////////////////////////
// delegates

-(void)_noticeProcessorWithMessage:(NSString* )theMessage {
	if([self delegate] && [[self delegate] respondsToSelector:@selector(connection:notice:)]) {
		[[self delegate] connection:self notice:theMessage];
	}
}

@end
