
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
#import "SSKeychain.h"

@implementation PGPasswordStore

////////////////////////////////////////////////////////////////////////////////
// initialization

-(id)init {
	self = [super init];
	if(self) {
		_store = [[NSMutableDictionary alloc] init];
		
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic serviceName;

-(NSString* )serviceName {
	return [PGConnection defaultURLScheme];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(NSString* )_accountForURL:(NSURL* )url {
	NSParameterAssert(url);
	if([[PGConnection allURLSchemes] containsObject:[url scheme]]==NO) {
		return nil;
	}
	// extract parameters
	NSDictionary* parameters = [url postgresqlParameters];
	if(parameters==nil) {
		return nil;
	}
	NSMutableArray* parts = [NSMutableArray arrayWithCapacity:[parameters count]];
	for(NSString* key in @[ @"host", @"hostaddr", @"user", @"port", @"dbname" ]) {
		NSString* value = [parameters objectForKey:key];
		// special case for port
		if([key isEqualToString:@"port"] && value==nil) {
			value = [NSString stringWithFormat:@"%lu",(unsigned long)PGClientDefaultPort];
		}
		if(value) {
			[parts addObject:[NSString stringWithFormat:@"%@=%@",key,[[value description] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
		}
	}
	return [parts componentsJoinedByString:@";"];
}

////////////////////////////////////////////////////////////////////////////////
// retrieve password

-(NSString* )passwordForURL:(NSURL* )url readFromKeychain:(BOOL)readFromKeychain error:(NSError** )error {
	// get password from the URL
	NSString* password = [url password];
	if(password && [password length]) {
		return password;
	}
	// get password from the store
	NSString* account = [self _accountForURL:url];
	if(account==nil) {
		// TODO [PGConnection createError:error code:PGClientErrorParameters];
		return nil;
	}
	password = [_store objectForKey:account];
	if(password && [password length]) {
		return password;
	}
	if(readFromKeychain) {
		// get password from the keychain
		password = [SSKeychain passwordForService:[self serviceName] account:account error:error];
		if(password && [password length]) {
			return password;
		}
	}
	return nil;
}

-(NSString* )passwordForURL:(NSURL* )url error:(NSError** )error {
	return [self passwordForURL:url readFromKeychain:YES error:error];
}

-(NSString* )passwordForURL:(NSURL* )url {
	return [self passwordForURL:url error:nil];
}

-(BOOL)setPassword:(NSString* )password forURL:(NSURL* )url saveToKeychain:(BOOL)saveToKeychain {
	return [self setPassword:password forURL:url saveToKeychain:saveToKeychain error:nil];
}

-(BOOL)setPassword:(NSString* )password forURL:(NSURL* )url saveToKeychain:(BOOL)saveToKeychain error:(NSError** )error {
	NSString* account = [self _accountForURL:url];
	if(account==nil) {
		// TODO [PGConnection createError:error code:PGClientErrorParameters];
		return NO;
	}

	// store password against account
	[_store setObject:password forKey:account];

	// if we save to keychain
	BOOL returnValue = YES;
	if(saveToKeychain) {
		returnValue = [SSKeychain setPassword:password forService:[self serviceName] account:account error:error];
	}
	
	return returnValue;
}

@end
