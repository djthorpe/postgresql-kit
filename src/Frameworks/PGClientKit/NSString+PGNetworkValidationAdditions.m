
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
#include <arpa/inet.h>

@implementation NSString (PGNetworkValidationAdditions)

-(BOOL)isNetworkHostname {
	static NSRegularExpression* regex = nil;
	if([self isNetworkAddressV4]) {
		return NO;
	}
	if(regex==nil) {
		regex = [NSRegularExpression regularExpressionWithPattern:@"^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\\-]*[a-zA-Z0-9])\\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\\-]*[A-Za-z0-9])$" options:0 error:nil];
	}
	NSParameterAssert(regex);
	NSArray* matches = [regex matchesInString:self options:0 range:NSMakeRange(0,[self length])];
	return [matches count] ? YES : NO;
}

-(BOOL)isNetworkAddressV4 {
	struct in_addr dst;
	int success = inet_pton(AF_INET,[self UTF8String],&dst);
	return success == 1 ? YES : NO;
}

-(BOOL)isNetworkAddressV6 {
	struct in6_addr dst6;
	int success = inet_pton(AF_INET6,[self UTF8String],&dst6);
	return success == 1 ? YES : NO;
}


-(BOOL)isNetworkAddress {
	return [self isNetworkAddressV4] || [self isNetworkAddressV6];
}

@end
