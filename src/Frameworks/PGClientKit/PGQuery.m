
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

////////////////////////////////////////////////////////////////////////////////

NSString* PGQueryStatementKey = @"PGQuery_statement";
NSString* PGQueryClassKey = @"PGQuery_class";
NSString* PGQueryOptionsKey = @"PGQuery_options";

////////////////////////////////////////////////////////////////////////////////

@implementation PGQuery

////////////////////////////////////////////////////////////////////////////////
// initialization

-(id)init {
	self = [super init];
	if(self) {
		_dictionary = [NSMutableDictionary new];
		NSParameterAssert(_dictionary);
		// set the class of query
		[_dictionary setObject:NSStringFromClass([self class]) forKey:PGQueryClassKey];
	}
	return self;
}

-(id)initWithDictionary:(NSDictionary* )dictionary {
	NSParameterAssert(dictionary);
	self = [super init];
	if(self) {
		_dictionary = [[NSMutableDictionary alloc] initWithDictionary:dictionary];
		NSParameterAssert(_dictionary);

		// check class is correct
		NSString* className = [dictionary objectForKey:PGQueryClassKey];
		if(className==nil || [className isKindOfClass:[NSString class]]==NO || [className length]==0) {
			return nil;
		}
		if([self isKindOfClass:NSClassFromString(className)]==NO) {
			return nil;
		}
	}
	return self;
}

+(instancetype)queryWithDictionary:(NSDictionary* )dictionary {
	NSParameterAssert(dictionary);
	NSString* className = [dictionary objectForKey:PGQueryClassKey];
	if(className==nil || [className isKindOfClass:[NSString class]]==NO || [className length]==0) {
		return nil;
	}
	PGQuery* query = [[NSClassFromString(className) alloc] initWithDictionary:dictionary];
	if(query==nil) {
		return nil;
	}
	NSParameterAssert([query isKindOfClass:NSClassFromString(className)]);
	return query;
}

+(instancetype)queryWithString:(NSString* )statement {
	PGQuery* query = [PGQuery queryWithDictionary:@{
		PGQueryStatementKey: statement
	}];
	NSParameterAssert(query);
	return query;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize dictionary = _dictionary;
@dynamic className;
@dynamic options;

-(NSString* )className {
	return [_dictionary objectForKey:PGQueryClassKey];
}

-(int)options {
	NSNumber* options = [_dictionary objectForKey:PGQueryOptionsKey];
	if([options isKindOfClass:[NSNumber class]]==NO) {
		return 0;
	}
	return [options intValue];
}

-(void)setOptions:(int)options {
	[_dictionary setObject:[NSNumber numberWithInt:options] forKey:PGQueryOptionsKey];
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(void)setObject:(id)object forKey:(NSString* )key {
	NSParameterAssert(object);
	NSParameterAssert(key);
	[_dictionary setObject:object forKey:key];
}

-(id)objectForKey:(NSString* )key {
	NSParameterAssert(key);
	return [_dictionary objectForKey:key];
}

// generate a statement
// this method should be overridden for different subclasses
// it requires the connection object in order to generate different statements
// for different versions of the remote server, since sometimes the names
// of things changes between server versions
-(NSString* )statementForConnection:(PGConnection* )connection {
	NSString* statement = [self objectForKey:PQQueryStatementKey];
	if(statement==nil || [statement isKindOfClass:[NSString class]]==NO || [statement length]==0) {
		return @"-- EMPTY STATEMENT --";
	}
	return statement;
}

@end
