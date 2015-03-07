
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

@implementation NSURL (PGAdditions)

/////////////////////////////////////////////////////////////////////////////
// PRIVATE METHODS

+(NSString* )_pg_urlencode:(NSString* )string {
	return (NSString* )CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(__bridge CFStringRef)string,NULL,(__bridge CFStringRef)@"!*'();:@&=+$,/?%#[]",kCFStringEncodingUTF8));
}

+(NSString* )_pg_urlencode_params:(NSDictionary* )params {
	if(params==nil || [params count]==0) {
		return @"";
	}	
	NSMutableArray* parts = [NSMutableArray arrayWithCapacity:[params count]];
	for(id key in [params allKeys]) {
		if([key isKindOfClass:[NSString class]]==NO) {
			return nil;
		}
		id value = [params objectForKey:key];
		if([value isKindOfClass:[NSObject class]]==NO) {
			return nil;
		}
		NSString* keyenc = [self _pg_urlencode:(NSString* )key];
		NSString* valueenc = [self _pg_urlencode:[(NSObject* )value description]];
		if(keyenc==nil || valueenc==nil) {
			return nil;
		}
		NSString* pair = [NSString stringWithFormat:@"%@=%@",keyenc,valueenc];
		[parts addObject:pair];
	}
	return [@"?" stringByAppendingString:[parts componentsJoinedByString:@"&"]];
}

+(NSString* )_pg_urlencode_database:(NSString* )db {
	if(db==nil || [db length]==0) {
		return @"";
	}
	return [self _pg_urlencode:db];
}

+(NSString* )_pg_urlencode_user:(NSString* )user {
	if(user==nil || [user length]==0) {
		return @"";
	}
	return [[self _pg_urlencode:user] stringByAppendingString:@"@"];
}

+(NSString* )_pg_urlencode_host:(NSString* )host {
	if(host==nil || [host length]==0) {
		return @"localhost";
	}
	NSCharacterSet* _addressChars = [NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF.:"];
	NSRange foundNonAddress = [host rangeOfCharacterFromSet:[_addressChars invertedSet]];
	if(foundNonAddress.location==NSNotFound) {
		// is likely an address
		return [NSString stringWithFormat:@"[%@]",host];
	} else {
		// is likely a hostname
		return [self _pg_urlencode:host];
	}
}

+(NSString* )_pg_urlencode_path:(NSString* )path {
	if(path==nil || [path length]==0) {
		return @"";
	}
	return [self _pg_urlencode:path];
}

+(NSString* )_pg_urlencode_port:(NSUInteger)port {
	if(port==0) {
		return @"";
	} else {
		return [NSString stringWithFormat:@":%ld",(unsigned long)port];
	}
}

+(NSNumber* )_pg_port_fromstring:(NSString* )string {
	if(string==nil) {
		return nil;
	}
	NSCharacterSet* notNumericCharacters = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
	NSRange foundDigits = [string rangeOfCharacterFromSet:notNumericCharacters];
	if(foundDigits.location != NSNotFound) {
		return nil;
	}
	NSInteger portSigned = [string integerValue];
	if(portSigned < 1 || portSigned > PGClientMaximumPort) {
		return nil;
	}
	return [NSNumber numberWithInteger:portSigned];
}

/////////////////////////////////////////////////////////////////////////////
// CONSTRUCTORS

+(id)URLWithSocketPath:(NSString* )path port:(NSUInteger)port database:(NSString* )database username:(NSString* )username params:(NSDictionary* )params {
	return [[NSURL alloc] initWithSocketPath:path port:port database:database username:username params:params];
}

+(id)URLWithLocalDatabase:(NSString* )database username:(NSString* )username params:(NSDictionary* )params {
	return [[NSURL alloc] initWithLocalDatabase:database username:username params:params];
}

+(id)URLWithHost:(NSString* )host ssl:(BOOL)ssl username:(NSString* )username database:(NSString* )database params:(NSDictionary* )params {
	return [[NSURL alloc] initWithHost:host ssl:ssl username:username database:database params:params];
}

+(id)URLWithHost:(NSString* )host port:(NSUInteger)port ssl:(BOOL)ssl username:(NSString* )username database:(NSString* )database params:(NSDictionary* )params {
	return [[NSURL alloc] initWithHost:host port:port ssl:ssl username:username database:database params:params];
}

+(id)URLWithPostgresqlParams:(NSDictionary* )params {
	return [[NSURL alloc] initWithPostgresqlParams:params];
}

-(id)initWithSocketPath:(NSString* )path port:(NSUInteger)port database:(NSString* )database username:(NSString* )username params:(NSDictionary* )params {
	NSString* method = [PGConnection defaultURLScheme];
	NSString* pathenc = [NSURL _pg_urlencode_path:[path stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	NSString* portenc = [NSURL _pg_urlencode_port:port];
	NSString* dbenc = [NSURL _pg_urlencode_database:[database stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	NSString* queryenc = [NSURL _pg_urlencode_params:params];
	NSString* userenc = [NSURL _pg_urlencode_user:[username stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	NSParameterAssert(method && dbenc && queryenc && userenc);
	return [self initWithString:[NSString stringWithFormat:@"%@://%@%@%@/%@%@",method,userenc,pathenc,portenc,dbenc,queryenc]];
}

-(id)initWithLocalDatabase:(NSString* )database username:(NSString* )username params:(NSDictionary* )params {
	return [self initWithSocketPath:nil port:0 database:database username:username params:params];
}

-(id)initWithHost:(NSString* )host port:(NSUInteger)port ssl:(BOOL)ssl username:(NSString* )username database:(NSString* )database params:(NSDictionary* )params {
	NSString* method = [PGConnection defaultURLScheme];
	NSString* sslenc = ssl ? @"s" : @"";
	NSString* dbenc = [NSURL _pg_urlencode_database:[database stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	NSString* hostenc = [NSURL _pg_urlencode_host:[host stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	NSString* portenc = [NSURL _pg_urlencode_port:port];
	NSString* queryenc = [NSURL _pg_urlencode_params:params];
	NSString* userenc = [NSURL _pg_urlencode_user:[username stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	NSParameterAssert(method && dbenc && queryenc && sslenc && hostenc && portenc && userenc);
	return [self initWithString:[NSString stringWithFormat:@"%@%@://%@%@%@/%@%@",method,sslenc,userenc,hostenc,portenc,dbenc,queryenc]];
}

-(id)initWithHost:(NSString* )host ssl:(BOOL)ssl username:(NSString* )username database:(NSString* )database params:(NSDictionary* )params {
	return [self initWithHost:host port:0 ssl:ssl username:username database:database params:params];
}

-(id)initWithPostgresqlParams:(NSDictionary* )params {
	NSMutableDictionary* params2 = [params mutableCopy];
	NSString* sslmode = [[[params2 objectForKey:@"sslmode"] description] lowercaseString];
	BOOL ssl = NO;
	if([sslmode isEqual:@"require"] || [sslmode isEqual:@"verify-ca"] || [sslmode isEqual:@"verify-full"]) {
		ssl = YES;
	}
	// host, hostaddr or local socket
	NSString* host = [[params2 objectForKey:@"host"] description];
	NSString* socket = nil;
	if([host rangeOfString:@"/"].location != NSNotFound) {
		socket = host;
	}
	NSString* hostaddr = [[params2 objectForKey:@"hostaddr"] description];
	if(hostaddr) {
		host = [NSString stringWithFormat:@"[%@]",hostaddr];
	}
	// user
	NSString* user = [[params2 objectForKey:@"user"] description];
	if(user==nil) {
		return nil;
	}
	// dbname
	NSString* dbname = [[params2 objectForKey:@"dbname"] description];
	// port
	NSString* portString = [params2 objectForKey:@"port"];
	NSNumber* port = nil;
	if(portString) {
		port = [NSURL _pg_port_fromstring:[portString description]];
		if(port==nil) {
			return nil;
		}
	}

	// remove parameters
	[params2 removeObjectForKey:@"host"];
	[params2 removeObjectForKey:@"hostaddr"];
	[params2 removeObjectForKey:@"user"];
	[params2 removeObjectForKey:@"dbname"];
	[params2 removeObjectForKey:@"port"];

	// return string
	if(socket) {
		return [self initWithSocketPath:socket port:[port unsignedIntegerValue] database:dbname username:user params:params2];
	} else {
		return [self initWithHost:host port:[port unsignedIntegerValue] ssl:ssl username:user database:dbname params:params2];
	}
}

/////////////////////////////////////////////////////////////////////////////
// Methods

-(NSDictionary* )postgresqlParameters {
	// extract parameters
	// see here for format of URI
	// http://www.postgresql.org/docs/9.2/static/libpq-connect.html#LIBPQ-CONNSTRING

	// create a mutable dictionary
	NSMutableDictionary* theParameters = [[NSMutableDictionary alloc] init];

	// check possible schemes. if ends in an 's' then require SSL mode
	if([[PGConnection allURLSchemes] containsObject:[self scheme]] != YES) {
		return nil;
	}
	if([[self scheme] hasSuffix:@"s"]) {
		[theParameters setValue:@"require" forKey:@"sslmode"];
	} else {
		[theParameters setValue:@"prefer" forKey:@"sslmode"];
	}
	
	// set username
	if([self user]) {
		[theParameters setValue:[self user] forKey:@"user"];
	} else {
		return nil;
	}

	// set password
	if([self password]) {
		[theParameters setValue:[self password] forKey:@"password"];
	}
	
	// set host or hostaddr
	if([self host]) {
		// if host contains only digits, period or colon, then it's likely to be a hostaddr
		if([[self host] hasPrefix:@"["] && [[self host] hasSuffix:@"]"]) {
			NSString* theAddress = [[self host] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]];
			[theParameters setValue:theAddress forKey:@"hostaddr"];
		} else {
			NSCharacterSet* _addressChars = [NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF.:"];
			NSRange foundHostAddress = [[self host] rangeOfCharacterFromSet:[_addressChars invertedSet]];
			if(foundHostAddress.location != NSNotFound) {
				[theParameters setValue:[self host] forKey:@"host"];
			} else {
				[theParameters setValue:[self host] forKey:@"hostaddr"];
			}
		}
	} else {
		[theParameters setValue:@"localhost" forKey:@"host"];
	}
	
	// set port
	if([self port]) {
		NSUInteger port = [[self port] unsignedIntegerValue];
		if(port < 1 || port > PGClientMaximumPort) {
			return nil;
		}
		[theParameters setValue:[self port] forKey:@"port"];
	}
	
	// set database name
	if([self path]) {
		NSString* thePath = [[self path] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
		if([thePath length]) {
			[theParameters setValue:thePath forKey:@"dbname"];
		}
	}
	
	// extract other parameters from URI
	NSArray* additionalParameters = [[self query] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&;"]];
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

-(BOOL)isSocketPathURL {
	NSDictionary* parameters = [self postgresqlParameters];
	if(parameters==nil) {
		return NO;
	}
	if([[parameters objectForKey:@"host"] hasPrefix:@"/"]) {
		return YES;
	}
	return NO;
}

-(BOOL)isRemoteHostURL {
	NSDictionary* parameters = [self postgresqlParameters];
	if(parameters==nil) {
		return NO;
	}
	if([[parameters objectForKey:@"hostaddr"] count]) {
		return YES;
	}
	if([[parameters objectForKey:@"host"] hasPrefix:@"/"]==NO) {
		return YES;
	}
	return NO;
}

@end
