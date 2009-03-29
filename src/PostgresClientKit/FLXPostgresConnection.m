
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"

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

-(FLXPostgresResult* )execute:(NSString* )theQuery {
	NSParameterAssert(theQuery);
	if([self connection]==nil) {
		[FLXPostgresException raise:@"FLXPostgresConnectionError" reason:@"No Connection"];        
	}
	// execute the command - we always use the binding version so we can get the data
	// back as binary
	PGresult* theResult = PQexecParams([self connection],[theQuery UTF8String],0,nil,nil,nil,nil,1);
	if(theResult==nil) {
		[FLXPostgresException raise:@"FLXPostgresConnectionError" connection:[self connection]];
	}
	// check returned result
	if(PQresultStatus(theResult)==PGRES_BAD_RESPONSE || PQresultStatus(theResult)==PGRES_FATAL_ERROR) {
		NSString* theMessage = [NSString stringWithUTF8String:PQresultErrorMessage(theResult)];
		PQclear(theResult);
		[FLXPostgresException raise:@"FLXPostgresConnectionError" reason:theMessage];
	}
	// return a result object
	return [[[FLXPostgresResult alloc] initWithResult:theResult types:[self types]] autorelease];
}

-(FLXPostgresResult* )executeWithFormat:(NSString* )theQuery,... {
	va_list argumentList;
	va_start(argumentList,theQuery);
	NSMutableString* theString = [[NSMutableString alloc] init];
	CFStringAppendFormatAndArguments((CFMutableStringRef)theString,(CFDictionaryRef)nil,(CFStringRef)theQuery,argumentList);
	va_end(argumentList);   
	FLXPostgresResult* theResult = [self execute:theString];
	[theString release];
	return theResult;
}

-(FLXPostgresResult* )executePrepared:(FLXPostgresStatement* )theStatement {
	NSParameterAssert(theStatement);
	if([self connection]==nil) {
		[FLXPostgresException raise:@"FLXPostgresConnectionError" reason:@"No Connection"];        
	}
	// execute the command - we always use the binding version so we can get the data
	// back as binary
	PGresult* theResult = PQexecPrepared([self connection],[[theStatement name] UTF8String],0,nil,nil,nil,1);
	if(theResult==nil) {
		[FLXPostgresException raise:@"FLXPostgresConnectionError" connection:[self connection]];
	}
	// check returned result
	if(PQresultStatus(theResult)==PGRES_BAD_RESPONSE || PQresultStatus(theResult)==PGRES_FATAL_ERROR) {
		NSString* theMessage = [NSString stringWithUTF8String:PQresultErrorMessage(theResult)];
		PQclear(theResult);
		[FLXPostgresException raise:@"FLXPostgresConnectionError" reason:theMessage];
	}
	// return a result object
	return [[[FLXPostgresResult alloc] initWithResult:theResult types:[self types]] autorelease];	
}

/*
-(FLXPostgresResult* )execute:(NSString* )theQuery values:(NSArray* )theValues {
	NSParameterAssert(theQuery && theValues && theTypes && [theValues count]==[theTypes count]);
	if([self connection]==nil) {
		[FLXPostgresException raise:@"FLXPostgresConnectionError" reason:@"No Connection"];        
	}
	// if no bound values, try the normal version
	if([theValues count]==0) {
		return [self execute:theQuery];
	}
	// construct the arrays
	const char** paramValue = malloc(sizeof(const char* ) * [theValues count]);
	NSUInteger* paramLength = malloc(sizeof(NSUInteger) * [theValues count]);
	NSUInteger* paramFormat = malloc(sizeof(NSUInteger) * [theValues count]);
	for(NSUInteger i = 0; i < [theValues count]; i++) {
		NSObject* theValue = [theValues objectAtIndex:i];
		NSNumber* theType = [theTypes objectAtIndex:i];
		NSParameterAssert([theType isKindOfClass:[NSNumber class]]);
		// special case where value is NULL
		if([theValue isKindOfClass:[NSNull class]]) {
			paramValue[i] = nil;
			paramLength[i] = 0; // not used
			paramFormat[i] = 0; // not used
			continue;
		}
		switch([theType integerValue]) {
			case FLXPostgresTypeString:
				NSParameterAssert([theValue isKindOfClass:[NSString class]]);
				paramValue[i] = [(NSString* )theValue UTF8String];
				paramLength[i] = 0; // not used
				paramFormat[i] = 0; // text
				break;
			case FLXPostgresTypeInteger:
			case FLXPostgresTypeReal:
				NSParameterAssert([theValue isKindOfClass:[NSNumber class]]);
				paramValue[i] = [[(NSNumber* )theValue stringValue] UTF8String];
				paramLength[i] = 0; // no used
				paramFormat[i] = 0; // text
				break;
			case FLXPostgresTypeBool:
				NSParameterAssert([theValue isKindOfClass:[NSNumber class]]);
				paramValue[i] = [(NSNumber* )theValue boolValue] ? "t" : "f";
				paramLength[i] = 0; // not used
				paramFormat[i] = 0; // text
				break;
			case FLXPostgresTypeData:
				NSParameterAssert([theValue isKindOfClass:[NSData class]]);
				paramValue[i] = [(NSData* )theValue bytes];
				paramLength[i] = (NSUInteger)[(NSData* )theValue length];
				paramFormat[i] = 1; // binary
				break;        
			case FLXPostgresTypeDate: {
					NSParameterAssert([theValue isKindOfClass:[NSDate class]]);
					NSString* theDateAsString = [(NSDate* )theValue descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:nil locale:nil];
					paramValue[i] = [theDateAsString UTF8String];
					paramLength[i] = (NSUInteger)[theDateAsString length];
					paramFormat[i] = 0; // text
				}
				break;        				
			case FLXPostgresTypeDatetime:
				// TODO
				free(paramValue);
				free(paramLength);
				free(paramFormat);
				[FLXPostgresException raise:@"FLXPostgresConnectionError" reason:@"Unsupported date/time bound value type"];
			default:
				free(paramValue);
				free(paramLength);   
				free(paramFormat);
				[FLXPostgresException raise:@"FLXPostgresConnectionError" reason:@"Unsupported bound value type"];
		}
	}  
	// execute the command
	PGresult* theResult = PQexecParams([self connection],[theQuery UTF8String],[theValues count],nil,paramValue,(const int* )paramLength,(const int* )paramFormat,1);
	// free the bound values
	free(paramValue);
	free(paramLength); 
	free(paramFormat);
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
*/

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

@end
