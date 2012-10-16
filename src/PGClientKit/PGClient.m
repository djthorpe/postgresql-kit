
#import "PGClientKit.h"
#include <libpq-fe.h>

NSString* PGClientScheme = @"pgsql";
NSString* PGClientSchemeSSL = @"pgsqls";
NSString* PGClientEncoding = @"utf8";

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
	// check URL
	if(theURL==nil) {
		return nil;
	}
	// create a mutable dictionary
	NSMutableDictionary* theParameters = [[NSMutableDictionary alloc] init];
	
	// check scheme
	if([[theURL scheme] isEqualToString:PGClientScheme]) {
		[theParameters setValue:@"prefer" forKey:@"sslmode"];
	} else if([[theURL scheme] isEqualToString:PGClientSchemeSSL]) {
		[theParameters setValue:@"require" forKey:@"sslmode"];
	} else {
		return nil;
	}

	// set username
	if([theURL user]) {
		[theParameters setValue:[theURL user] forKey:@"user"];
	}
	// set password
	if([theURL password]) {
		[theParameters setValue:[theURL password] forKey:@"password"];
	}
	// set host
	if([theURL host]) {
		[theParameters setValue:[theURL host] forKey:@"host"];
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

-(void)_noticeProcessorWithMessage:(NSString* )theMessage {
	NSLog(@"Message: %@",theMessage);
}

void PGConnectionNoticeProcessor(void* arg,const char* theMessage) {
	PGClient* theObject = (__bridge PGClient* )arg;
	if([theObject isKindOfClass:[PGClient class]]) {
		[theObject _noticeProcessorWithMessage:[NSString stringWithUTF8String:theMessage]];
	}
}

////////////////////////////////////////////////////////////////////////////////
// connection

-(BOOL)connectWithURL:(NSURL* )theURL {
	return [self connectWithURL:theURL timeout:0];
}

-(BOOL)connectWithURL:(NSURL* )theURL timeout:(NSUInteger)timeout {
	// check for existing connection
	if(_connection) {
		return NO;
	}
	// extract parameters from the URL
	NSDictionary* theParameters = [PGClient _extractParametersFromURL:theURL];
	if(theParameters==nil) {
		return NO;
	}
	// make new set of parameters
	NSMutableDictionary* theParameters2 = [theParameters mutableCopy];
	NSParameterAssert(theParameters2);
	if(timeout) {
		[theParameters2 setValue:[NSNumber numberWithUnsignedInteger:timeout] forKey:@"connect_timeout"];
	}
	
	// set client encoding and application name
	[theParameters2 setValue:PGClientEncoding forKey:@"client_encoding"];
	[theParameters2 setValue:[[NSProcessInfo processInfo] processName] forKey:@"application_name"];

	// make the connection (with blocking)
	@synchronized(_connection) {
		PGconn* theConnection = [self _connectWithParameters:theParameters2];
		if(theConnection==nil || PQstatus(theConnection) != CONNECTION_OK) {
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

@end
