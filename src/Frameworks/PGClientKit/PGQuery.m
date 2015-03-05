
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

NSString* PGQueryStatementKey = @"PGQuery_statement";
NSString* PGQueryClassKey = @"PGQuery_class";
NSString* PGQueryOptionsKey = @"PGQuery_options";

////////////////////////////////////////////////////////////////////////////////

@implementation PGQuery

////////////////////////////////////////////////////////////////////////////////
// initialization

-(instancetype)init {
	self = [super init];
	if(self) {
		_dictionary = [NSMutableDictionary new];
		NSParameterAssert(_dictionary);
		// set the class of query
		[_dictionary setObject:NSStringFromClass([self class]) forKey:PGQueryClassKey];
	}
	return self;
}

-(instancetype)initWithDictionary:(NSDictionary* )dictionary {
	NSParameterAssert(dictionary);
	self = [self init];
	if(self) {
		// check class is correct
		NSString* className = [dictionary objectForKey:PGQueryClassKey];
		if(className==nil || [className isKindOfClass:[NSString class]]==NO || [className length]==0) {
			return nil;
		}
		if([self isKindOfClass:NSClassFromString(className)]==NO) {
			return nil;
		}
		// add items into dictionary
		[_dictionary addEntriesFromDictionary:dictionary];
	}
	return self;
}

+(instancetype)queryWithDictionary:(NSDictionary* )dictionary class:(NSString* )className {
	NSParameterAssert(dictionary);
	if(className==nil) {
		className = [dictionary objectForKey:PGQueryClassKey];
	}
	if(className==nil || [className isKindOfClass:[NSString class]]==NO || [className length]==0) {
		return nil;
	}
	NSMutableDictionary* dictionary2 = [NSMutableDictionary dictionaryWithDictionary:dictionary];
	[dictionary2 setObject:className forKey:PGQueryClassKey];
	PGQuery* query = [[NSClassFromString(className) alloc] initWithDictionary:dictionary2];
	if(query==nil) {
		return nil;
	}
	NSParameterAssert([query isKindOfClass:NSClassFromString(className)]);
	return query;
}

+(instancetype)queryWithString:(NSString* )statement {
	NSParameterAssert(statement);
	PGQuery* query = [[PGQuery alloc] initWithDictionary:@{
		PGQueryClassKey: NSStringFromClass([self class]),
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

-(void)setObject:(id)object forKey:(NSString* )key {
	NSParameterAssert(object);
	NSParameterAssert(key);
	[_dictionary setObject:object forKey:key];
}

-(id)objectForKey:(NSString* )key {
	NSParameterAssert(key);
	return [_dictionary objectForKey:key];
}

-(void)removeObjectForKey:(NSString* )key {
	NSParameterAssert(key);
	[_dictionary removeObjectForKey:key];
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(NSString* )statementForConnection:(PGConnection* )connection error:(NSError** )error {
	NSParameterAssert(connection);
	NSString* statement = [self objectForKey:PGQueryStatementKey];
	if(statement==nil || [statement isKindOfClass:[NSString class]]==NO || [statement length]==0) {
		[connection raiseError:error code:PGClientErrorQuery reason:@"Empty statement"];
		return nil;
	}
	return statement;
}

////////////////////////////////////////////////////////////////////////////////
// describe query object

-(NSString* )description {
	return [NSString stringWithFormat:@"<%@ %@>",NSStringFromClass([self class]),[self dictionary]];
}

@end
