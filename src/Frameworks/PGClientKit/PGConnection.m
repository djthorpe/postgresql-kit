
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
#include <openssl/ssl.h>

////////////////////////////////////////////////////////////////////////////////
#pragma mark Constants
////////////////////////////////////////////////////////////////////////////////

NSString* PGConnectionSchemes = @"pgsql pgsqls postgresql postgres postgresqls";
NSString* PGConnectionDefaultEncoding = @"utf8";
NSString* PGConnectionBonjourServiceType = @"_postgresql._tcp";
NSString* PGClientErrorDomain = @"PGClient";
NSUInteger PGClientDefaultPort = DEF_PGPORT;
NSUInteger PGClientMaximumPort = 65535;
NSDictionary* PGConnectionStatusDescription = nil;

// parameter keys
NSString* PGConnectionVersionKey = @"Version";
NSString* PGConnectionProtocolVersionKey = @"ProtocolVersion";
NSString* PGConnectionServerVersionKey = @"ServerVersion";
NSString* PGConnectionServerMajorVersionKey = @"ServerVersionMajor";
NSString* PGConnectionServerMinorVersionKey = @"ServerVersionMinor";
NSString* PGConnectionServerRevisionVersionKey = @"ServerVersionRevision";
NSString* PGConnectionSSLVersionKey = @"SSLVersion";
NSString* PGConnectionServerProcessKey = @"ServerProcess";
NSString* PGConnectionUserKey = @"User";
NSString* PGConnectionDatabaseKey = @"Database";
NSString* PGConnectionHostKey = @"Host";

@implementation PGConnection

////////////////////////////////////////////////////////////////////////////////
#pragma mark Static Methods
////////////////////////////////////////////////////////////////////////////////

+(NSArray* )allURLSchemes {
	return [PGConnectionSchemes componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

+(NSString* )defaultURLScheme {
	return [[self allURLSchemes] objectAtIndex:0];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark constructor and destructors
////////////////////////////////////////////////////////////////////////////////

-(instancetype)init {
    self = [super init];
    if(self) {
		_connection = nil;
		_cancel = nil;
		_callback = nil;
		_socket = nil;
		_runloopsource = nil;
		_timeout = 0;
		_state = PGConnectionStateNone;
		_parameters = nil;
		pgdata2obj_init(); // set up cache for translating binary data from server
    }
    return self;
}

-(void)finalize {
	[self disconnect];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

@dynamic status;
@dynamic user;
@dynamic database;
@dynamic serverProcessID;
@dynamic parameters;
@dynamic host;
@synthesize timeout = _timeout;
@synthesize state = _state;

-(PGConnectionStatus)status {
	if(_connection==nil) {
		return PGConnectionStatusDisconnected;
	}
	switch(PQstatus(_connection)) {
		case CONNECTION_OK:
			return [self state]==PGConnectionStateNone ? PGConnectionStatusConnected : PGConnectionStatusBusy;
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

-(NSString* )host {
	if(_connection==nil || PQstatus(_connection) != CONNECTION_OK) {
		return nil;
	}
	const char* host = PQhost(_connection);
	if(host) {
		return [NSString stringWithUTF8String:host];
	} else {
		return nil;
	}
}

-(int)serverProcessID {
	if(_connection==nil || PQstatus(_connection) != CONNECTION_OK) {
		return 0;
	}
	return PQbackendPID(_connection);
}

-(NSDictionary* )parameters {
	if(_parameters != nil) {
		return _parameters;
	}
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	NSParameterAssert(parameters);
	_parameters = parameters;

	// populate parameters from bundle
	NSBundle* bundle = [NSBundle bundleForClass:[self class]];
	for(NSString* key in @[ @"CFBundleIdentifier", @"CFBundleName", @"CFBundleShortVersionString" ]) {
		id value = [[bundle infoDictionary] objectForKey:key];
		if(value) {
			[parameters setObject:value forKey:key];
		}
	}

	// populate parameters from connection
	if(_connection) {

		// server version
		int serverVersion = PQserverVersion(_connection);
		if(serverVersion) {
			[parameters setObject:[NSNumber numberWithInt:serverVersion] forKey:PGConnectionServerVersionKey];
			[parameters setObject:[NSNumber numberWithInt:(serverVersion / 10000) % 10] forKey:PGConnectionServerMajorVersionKey];
			[parameters setObject:[NSNumber numberWithInt:(serverVersion / 100) % 10] forKey:PGConnectionServerMinorVersionKey];
			[parameters setObject:[NSNumber numberWithInt:(serverVersion / 1) % 10] forKey:PGConnectionServerRevisionVersionKey];
		}
	
		// protocol version and pid
		NSNumber* protocol = [NSNumber numberWithInt:PQprotocolVersion(_connection)];
		NSNumber* pid = [NSNumber numberWithInt:[self serverProcessID]];
		if(protocol) {
			[parameters setObject:protocol forKey:PGConnectionProtocolVersionKey];
		}
		if(pid) {
			[parameters setObject:pid forKey:PGConnectionServerProcessKey];
		}

		// user, database & host
		NSString* user = [self user];
		NSString* database = [self database];
		NSString* host = [self host];
		if(user) {
			[parameters setObject:user forKey:PGConnectionUserKey];
		}
		if(database) {
			[parameters setObject:database forKey:PGConnectionDatabaseKey];
		}
		if(host) {
			[parameters setObject:database forKey:PGConnectionHostKey];
		}

		// ssl
		SSL* ssl = PQgetssl(_connection);
		if(ssl) {
			[parameters setObject:[NSNumber numberWithInt:ssl->version] forKey:PGConnectionSSLVersionKey];
		}
		
		// other server parameters
		for(NSString* key in @[ @"server_version", @"server_encoding", @"client_encoding", @"application_name", @"is_superuser", @"session_authorization", @"DateStyle", @"IntervalStyle", @"TimeZone", @"integer_datetimes", @"standard_conforming_strings"]) {
			const char* value = PQparameterStatus(_connection,[key UTF8String]);
			if(value) {
				[parameters setObject:[NSString stringWithUTF8String:value] forKey:key];
			}
		}
	}
	
	// return parameters
	return parameters;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark private methods - status update
////////////////////////////////////////////////////////////////////////////////

-(void)_updateStatusDelayed:(NSArray* )arguments {
	NSParameterAssert(arguments && [arguments count]==2);
	PGConnectionStatus status = [[arguments objectAtIndex:0] intValue];
	NSString* description = [arguments objectAtIndex:1];
	if([[self delegate] respondsToSelector:@selector(connection:statusChange:description:)]) {
		[[self delegate] connection:self statusChange:status description:description];
	}
}

-(void)_updateStatus {
	static PGConnectionStatus oldStatus = PGConnectionStatusDisconnected;
	static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        // Do some work that happens once
		PGConnectionStatusDescription = @{
			[NSNumber numberWithInt:PGConnectionStatusBusy]: @"Busy",
			[NSNumber numberWithInt:PGConnectionStatusConnected]: @"Idle",
			[NSNumber numberWithInt:PGConnectionStatusConnecting]: @"Connecting",
			[NSNumber numberWithInt:PGConnectionStatusDisconnected]: @"Disconnected",
			[NSNumber numberWithInt:PGConnectionStatusRejected]: @"Rejected"
		};
    });
	if([self status] == oldStatus) {
		return;
	}
	// reset oldStatus
	oldStatus = [self status];

	// we call the delegate in a delayed fashion, so as to not stop the callbacks
	// from continuing
	NSNumber* key = [NSNumber numberWithInt:oldStatus];
	NSString* description = [PGConnectionStatusDescription objectForKey:key];
	[self performSelectorOnMainThread:@selector(_updateStatusDelayed:) withObject:@[ key,description ] waitUntilDone:NO];
#ifdef DEBUG2
	NSLog(@"status => %@ %@",key,description);
#endif

	// if connection is rejected, then call disconnect
	if(oldStatus==PGConnectionStatusRejected) {
		[self disconnect];
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark public methods - quoting
////////////////////////////////////////////////////////////////////////////////

-(NSString* )quoteIdentifier:(NSString* )string {
	if(_connection==nil) {
		return nil;
	}
	
	// if identifier only contains alphanumberic characters, return it unmodified
	if([string isAlphanumericOrUnderscore]) {
		return string;
	}
	
	const char* quoted_identifier = PQescapeIdentifier(_connection,[string UTF8String],[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
	if(quoted_identifier==nil) {
		return nil;
	}
	NSString* quoted_identifier2 = [NSString stringWithUTF8String:quoted_identifier];
	NSParameterAssert(quoted_identifier2);
	PQfreemem((void* )quoted_identifier);
	return quoted_identifier2;
}

-(NSString* )quoteString:(NSString* )string {
	if(_connection==nil) {
		return nil;
	}
	const char* quoted_string = PQescapeLiteral(_connection,[string UTF8String],[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
	if(quoted_string==nil) {
		return nil;
	}
	NSString* quoted_string2 = [NSString stringWithUTF8String:quoted_string];
	NSParameterAssert(quoted_string2);
	PQfreemem((void* )quoted_string);
	return quoted_string2;
}

-(NSString* )encryptedPassword:(NSString* )password role:(NSString* )roleName {
	NSParameterAssert(password);
	NSParameterAssert(roleName);
	if(_connection==nil) {
		return nil;
	}
	char* encryptedPassword = PQencryptPassword([password UTF8String],[roleName UTF8String]);
	if(encryptedPassword==nil) {
		return nil;
	}
	NSString* encryptedPassword2 = [NSString stringWithUTF8String:encryptedPassword];
	NSParameterAssert(encryptedPassword2);
	PQfreemem(encryptedPassword);
	return encryptedPassword2;
}

@end
