
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

@implementation FLXPostgresConnection

////////////////////////////////////////////////////////////////////////////////
// constructors

-(id)init {
	self = [super init];
	if (self != nil) {
		m_theConnection = nil;
		m_theHost = nil;
		m_thePort = 0;
		m_theUser = nil;
		m_theDatabase = nil;
		m_theTimeout = 0;   
		m_theTypes = nil;
	}
	return self;
}

-(void)dealloc {
	[self disconnect];
	[m_theHost release];
	[m_theUser release];
	[m_theDatabase release];
	[m_theTypes release];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// properties

-(PGconn* )connection {
	return (PGconn* )m_theConnection;
}

-(NSString* )host {
	return m_theHost;
}

-(void)setHost:(NSString* )theHost {
	[theHost retain];
	[m_theHost release];
	m_theHost = theHost;
}

-(NSString* )user {
	return m_theUser;
}

-(void)setUser:(NSString* )theUser {
	[theUser retain];
	[m_theUser release];
	m_theUser = theUser;
}

-(NSString* )database {
	return m_theDatabase;
}

-(void)setDatabase:(NSString* )theDatabase {
	[theDatabase retain];
	[m_theDatabase release];
	m_theDatabase = theDatabase;
}

-(int)port {
	return m_thePort;
}

-(void)setPort:(int)thePort {
	NSParameterAssert(thePort >= 0);
	m_thePort = thePort;
}

-(int)timeout {
	return m_theTimeout;
}

-(void)setTimeout:(int)theTimeout {
	NSParameterAssert(theTimeout >= 0);
	m_theTimeout = theTimeout;
}

-(void)setTypes:(FLXPostgresTypes* )theTypes {
	[theTypes retain];
	[m_theTypes release];
	m_theTypes = theTypes;
}

-(FLXPostgresTypes* )types {
	return m_theTypes;
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(BOOL)reloadTypes {
	// retrieve the types from the database
	NSString* theQuery = @"SELECT oid,typname FROM pg_catalog.pg_type WHERE SUBSTRING(typname FROM 1 FOR 1) != '_'";
	PGresult* theResult = PQexec([self connection],[theQuery UTF8String]);
	if(theResult==nil || PQresultStatus(theResult)==PGRES_BAD_RESPONSE || PQresultStatus(theResult)==PGRES_FATAL_ERROR) {
		PQclear(theResult);
		return NO;
	}
	// create a types array
	FLXPostgresTypes* theTypes = [FLXPostgresTypes array];
	// insert values into the types array	
	NSParameterAssert(PQnfields(theResult)==2);
	NSInteger theNumberOfRows = PQntuples(theResult);	
	for(NSInteger i = 0; i < theNumberOfRows; i++) {
		NSString* theOid = [NSString stringWithUTF8String:PQgetvalue(theResult,i,0)];
		// TODO NSString* theType = [NSString stringWithUTF8String:PQgetvalue(theResult,i,1)];
		// convert Oid to unsigned int
		int theOidInteger = atoi([theOid UTF8String]);
		NSParameterAssert(theOidInteger >= 0);		
		// insert into array
		// TODO: [theTypes insertString:theType atIndex:theOidInteger];    
	}	
	PQclear(theResult);
	// set the types, return success
	[self setTypes:theTypes];  
	return YES;
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
}

-(void)connect {
	[self connectWithPassword:nil];
}

-(void)connectWithPassword:(NSString* )thePassword {
	if([self connection] != nil) {
		[FLXPostgresException raise:@"FLXPostgresConnectionError" reason:@"Connection is already made"];    
	}
	
	// construct the parameters
	NSMutableString* theParameters = [NSMutableString string];
	if([[self host] length]) {
		[theParameters appendFormat:@"host='%@' ",[self host]];
	}
	if([self port]) {
		[theParameters appendFormat:@"port=%d ",[self port]];
	}
	if([[self database] length]) {
		[theParameters appendFormat:@"dbname='%@' ",[self database]];
	}
	if([[self user] length]) {
		[theParameters appendFormat:@"user='%@' ",[self user]];
	}
	if(thePassword != nil) {
		[theParameters appendFormat:@"password='%@' ",thePassword];
	}
	if([self timeout]) {
		[theParameters appendFormat:@"connect_timeout=%d ",[self timeout]];    
	}
	
	// perform the connection
	PGconn* theConnection = PQconnectdb([theParameters UTF8String]);
	if(theConnection==nil || PQstatus(theConnection) != CONNECTION_OK) {
		[FLXPostgresException raise:@"FLXPostgresConnectionError" connection:theConnection];
	}
	
	// set the internal connection structure
	m_theConnection = theConnection;

	// set the notice processor
	PQsetNoticeProcessor(theConnection,FLXPostgresConnectionNoticeProcessor,self);
	
	// load the types
	if([self reloadTypes]==NO) {
		[FLXPostgresException raise:@"FLXPostgresConnectionError" reason:@"Unable to load the types"];
	}
}

-(void)reset {
	if([self connection]==nil) {
		[FLXPostgresException raise:@"FLXPostgresConnectionError" reason:@"Connection cannot be reset"];    
	}	
	// perform the reset
	PQreset([self connection]);	
	// reload the types
	if([self reloadTypes]==NO) {
		[FLXPostgresException raise:@"FLXPostgresConnectionError" reason:@"Unable to reload the types"];
	}
}

////////////////////////////////////////////////////////////////////////////////
// prepare

-(FLXPostgresStatement* )prepare:(NSString* )theQuery {
	NSParameterAssert(theQuery);
	if([self connection]==nil) {
		[FLXPostgresException raise:@"FLXPostgresConnectionError" reason:@"No Connection"];        
	}
	// generate a staement name
	NSString* theStatementName = [[NSProcessInfo processInfo] globallyUniqueString];
	// prepare the statement
	PGresult* theResult = PQprepare([self connection],[theStatementName UTF8String],[theQuery UTF8String],0,nil);
	if(theResult==nil) {
		[FLXPostgresException raise:@"FLXPostgresConnectionError" connection:[self connection]];
	}
	// check returned result
	if(PQresultStatus(theResult)==PGRES_BAD_RESPONSE || PQresultStatus(theResult)==PGRES_FATAL_ERROR) {
		NSString* theMessage = [NSString stringWithUTF8String:PQresultErrorMessage(theResult)];
		PQclear(theResult);
		[FLXPostgresException raise:@"FLXPostgresConnectionError" reason:theMessage];
	}
	// free the result object
	PQclear(theResult);
	// return a statement object
	FLXPostgresStatement* theStatement = [[[FLXPostgresStatement alloc] initWithName:theStatementName] autorelease];
	return theStatement;	
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

////////////////////////////////////////////////////////////////////////////////
// execute

-(FLXPostgresResult* )_execute:(NSObject* )theQuery values:(NSArray* )theValues {
	NSParameterAssert(theQuery);
	NSParameterAssert([theQuery isKindOfClass:[NSString class]] || [theQuery isKindOfClass:[FLXPostgresStatement class]]);
	if([self connection]==nil) {
		[FLXPostgresException raise:@"FLXPostgresConnectionError" reason:@"No Connection"];        
		return nil;
	}

	if(theValues) {
		NSLog(@"execute: %@ => %@",theQuery,theValues);
	} else {
		NSLog(@"execute: %@",theQuery);
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
			[FLXPostgresException raise:@"FLXPostgresConnectionError" reason:@"Memory allocation error"];
		}
	}
	// fill the data structures
	for(NSUInteger i = 0; i < nParams; i++) {
		FLXPostgresOid theType = 0;
		NSObject* theObject = [[self types] boundValueFromObject:[theValues objectAtIndex:i] type:&theType];
		if(theObject==nil) {
			[FLXPostgresException raise:@"FLXPostgresConnectionError" reason:[NSString stringWithFormat:@"Parameter $%u cannot be converted into a bound value",(i+1)]];
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
			theValue = [(NSData* )theObject bytes];
			theLength = [(NSData* )theObject length];
			isBinary = YES;
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
			[FLXPostgresException raise:@"FLXPostgresConnectionError" reason:[NSString stringWithFormat:@"Bound value %u exceeds maximum size",i]];			
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
	} else {
		FLXPostgresStatement* theStatement = (FLXPostgresStatement* )theQuery;
		theResult = PQexecPrepared([self connection],[theStatement UTF8String],nParams,(const char** )paramValues,(const int* )paramLengths,(const int* )paramFormats,1);
	}		
		
	// free the data structures
	free(paramValues);
	free(paramTypes);
	free(paramLengths);
	free(paramFormats);	
	
	// check returned result
	if(theResult==nil) {
		[FLXPostgresException raise:@"FLXPostgresConnectionError" connection:[self connection]];
	}
	if(PQresultStatus(theResult)==PGRES_BAD_RESPONSE || PQresultStatus(theResult)==PGRES_FATAL_ERROR) {
		NSString* theMessage = [NSString stringWithUTF8String:PQresultErrorMessage(theResult)];
		PQclear(theResult);
		[FLXPostgresException raise:@"FLXPostgresConnectionError" reason:theMessage];
	}
	
	// return a result object
	return [[[FLXPostgresResult alloc] initWithResult:theResult types:[self types]] autorelease];
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
		[FLXPostgresException raise:@"FLXPostgresConnectionError" connection:[self connection]];      
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
	// TODO: NSDate
	// we should never get here
	NSParameterAssert(NO);
	return nil;
}

////////////////////////////////////////////////////////////////////////////////
// notice processor

-(void)_noticeProcessorWithMessage:(NSString* )theMessage {
	// TODO: send to delegate
	NSLog(@"NOTICE....%@",theMessage);
}

@end
