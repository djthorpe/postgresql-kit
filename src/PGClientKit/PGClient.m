
#import "PGClientKit.h"
#include <libpq-fe.h>

NSString* PGClientSchemes = @"pgsql pgsqls postgresql postgresqls";
NSString* PGClientDefaultEncoding = @"utf8";
NSString* PGClientErrorDomain = @"PGClientDomain";

typedef enum {
	PGClientErrorConnectionStateMismatch = 1,
	PGClientErrorParameterError,
	PGClientErrorConnectionError
} PGClientErrorDomainCode;

////////////////////////////////////////////////////////////////////////////////

@implementation PGClient

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
	if(_connection) {
		PQfinish(_connection);
	}
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
	NSArray* allowedSchemes = [PGClientSchemes componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
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

void PGConnectionNoticeProcessor(void* arg,const char* theMessage) {
	NSLog(@"Arg: %p Message: %s",arg,theMessage);
}

////////////////////////////////////////////////////////////////////////////////
// connection

-(BOOL)connectWithURL:(NSURL* )theURL error:(NSError** )theError {
	return [self connectWithURL:theURL timeout:0 error:theError];
}

-(BOOL)connectWithURL:(NSURL* )theURL timeout:(NSUInteger)timeout error:(NSError** )theError {
	// set empty error
	(*theError) = nil;
	
	// check for existing connection
	if(_connection) {
		(*theError) = [NSError errorWithDomain:PGClientErrorDomain code:PGClientErrorConnectionStateMismatch userInfo:nil];
		return NO;
	}
	// make parameters from the URL
	NSMutableDictionary* theParameters = [[PGClient _extractParametersFromURL:theURL] mutableCopy];
	if(theParameters==nil) {
		(*theError) = [NSError errorWithDomain:PGClientErrorDomain code:PGClientErrorParameterError userInfo:nil];
		return NO;
	}
	if(timeout) {
		[theParameters setValue:[NSNumber numberWithUnsignedInteger:timeout] forKey:@"connect_timeout"];
	}
	
	// set client encoding and application name if not already set
	if([theParameters objectForKey:@"client_encoding"]==nil) {
		[theParameters setValue:PGClientDefaultEncoding forKey:@"client_encoding"];
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
			(*theError) = [NSError errorWithDomain:PGClientErrorDomain code:PGClientErrorConnectionError userInfo:nil];
			return NO;
		}
		_connection = theConnection;
	}

	// set the notice processor
	PQsetNoticeProcessor(_connection,PGConnectionNoticeProcessor,(__bridge void* )self);

	// return success
	return YES;
}

-(BOOL)disconnect {
	if(_connection==nil) {
		return NO;
	}
	PQfinish(_connection);
	_connection = nil;
	return YES;
}

-(BOOL)reset {
	if(_connection==nil) {
		return NO;
	}
	
}

////////////////////////////////////////////////////////////////////////////////
// process notices

-(void)_noticeProcess:(const char* )cString {
	if([[self delegate] respondsToSelector:@selector(connection:notice:)]) {
		[[self delegate] connection:self notice:[NSString stringWithUTF8String:cString]];
	}
}

////////////////////////////////////////////////////////////////////////////////
// prepare statement



@end
