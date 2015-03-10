
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

NSString* PGQueryClassKey = @"class";
NSString* PGQueryOptionsKey = @"options";

////////////////////////////////////////////////////////////////////////////////

@implementation PGQueryObject

////////////////////////////////////////////////////////////////////////////////
#pragma mark constructors
////////////////////////////////////////////////////////////////////////////////

-(instancetype)init {
	return nil;
}

-(instancetype)initWithDictionary:(NSDictionary* )dictionary class:(NSString* )className {
	NSParameterAssert(dictionary);
	NSParameterAssert(className);
	self = [super init];
	if(self) {
		_dictionary = [NSMutableDictionary dictionaryWithDictionary:dictionary];
		[_dictionary setObject:className forKey:PGQueryClassKey];
	}
	return self;
}

+(instancetype)queryWithDictionary:(NSDictionary* )dictionary class:(NSString* )className {
	NSParameterAssert(dictionary);

	// check the className argument, from arguments or dictionary
	if(className==nil) {
		className = [dictionary objectForKey:PGQueryClassKey];
	}
	if([className isKindOfClass:[NSString class]]==NO || [className length]==0) {
		return nil;
	}

	// create the query object
	Class theClass = NSClassFromString(className);
	PGQueryObject* query = [[theClass alloc] initWithDictionary:dictionary class:className];
	if(query==nil) {
		return nil;
	}
	NSParameterAssert([query isKindOfClass:theClass]);
	
	// reset options
	[query setOptions:0];
	
	// return the query object
	return query;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

@synthesize dictionary = _dictionary;
@dynamic options;

-(NSUInteger)options {
	NSNumber* options = [_dictionary objectForKey:PGQueryOptionsKey];
	if([options isKindOfClass:[NSNumber class]]==NO) {
		return 0;
	}
	return [options unsignedIntegerValue];
}

-(void)setOptions:(NSUInteger)options {
	[_dictionary setObject:[NSNumber numberWithUnsignedInteger:options] forKey:PGQueryOptionsKey];
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
#pragma mark  methods
////////////////////////////////////////////////////////////////////////////////

-(NSString* )quoteForConnection:(PGConnection* )connection error:(NSError** )error {
	NSParameterAssert(connection);
	return @"-- NOT IMPLEMENTED --";
}

-(NSString* )description {
	return [NSString stringWithFormat:@"<%@ options=%08lX dictionary=%@>",NSStringFromClass([self class]),[self options],[self dictionary]];
}

-(BOOL)isEqual:(id)object {
	if([object isKindOfClass:[PGQueryObject class]]==NO) {
		return [self isEqual:object];
	}
	return [[self dictionary] isEqual:[object dictionary]];
}

-(void)setOptionFlags:(NSUInteger)flag {
	[self setOptions:([self options]  | flag)];
}

-(void)clearOptionFlags:(NSUInteger)flag {
	[self setOptions:([self options] & ~flag)];
}

@end



