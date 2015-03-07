
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

-(int)serverProcessID {
	if(_connection==nil || PQstatus(_connection) != CONNECTION_OK) {
		return 0;
	}
	return PQbackendPID(_connection);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark private methods - status update
////////////////////////////////////////////////////////////////////////////////

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
	oldStatus = [self status];
	if([[self delegate] respondsToSelector:@selector(connection:statusChange:description:)]) {
		[[self delegate] connection:self statusChange:[self status] description:[PGConnectionStatusDescription objectForKey:[NSNumber numberWithInt:[self status]]]];
	}
	
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
	if([string isAlphanumeric]) {
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
