
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
#pragma mark constant declarations
////////////////////////////////////////////////////////////////////////////////

// options
enum {
	PGQueryPredicateTypeNull = 0x00000001,       // NULL
	PGQueryPredicateTypeExpression = 0x00000002, // Expression
	PGQueryPredicateTypeAnd = 0x00000003,        // AND
	PGQueryPredicateTypeOr = 0x00000004,         // OR
	PGQueryPredicateTypeNot = 0x000005,          // NOT
	PGQueryPredicateTypeBoolean = 0x000006,      // Boolean
	PGQueryPredicateTypeString = 0x000007        // String
};

@implementation PGQueryPredicate

////////////////////////////////////////////////////////////////////////////////
#pragma mark private static methods
////////////////////////////////////////////////////////////////////////////////

+(PGQueryPredicate* )predicateOrExpression:(id)expression {
	if(expression==nil) {
		return nil;
	}
	if([expression isKindOfClass:[NSString class]]) {
		if([expression length]) {
			return [PGQueryPredicate expression:expression];
		} else {
			return [PGQueryPredicate nullPredicate];
		}
	} else if([expression isKindOfClass:[PGQueryPredicate class]]) {
		return expression;
	} else {
		return nil;
	}
}

+(NSArray* )_argumentArray:(va_list)args first:(id)expression {
	NSMutableArray* returnValue = [NSMutableArray array];
	for(id argument = expression; argument != nil; argument = va_arg(args,id)) {
		PGQueryPredicate* predicate = [self predicateOrExpression:argument];
		if(predicate==nil) {
			return nil;
		}
		[returnValue addObject:predicate];
	}
	return returnValue;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark constructors
////////////////////////////////////////////////////////////////////////////////

+(PGQueryPredicate* )nullPredicate {
	NSString* className = NSStringFromClass([self class]);
	PGQueryPredicate* query = (PGQueryPredicate* )[PGQueryObject queryWithDictionary:@{ } class:className];
	NSParameterAssert(query);
	[query setOptions:PGQueryPredicateTypeNull];
	return query;
}

+(PGQueryPredicate* )expression:(NSString* )expression {
	NSParameterAssert(expression);
	NSString* className = NSStringFromClass([self class]);
	PGQueryPredicate* query = (PGQueryPredicate* )[PGQueryObject queryWithDictionary:@{
		PGQueryStatementKey: expression
	} class:className];
	NSParameterAssert(query);
	[query setOptions:PGQueryPredicateTypeExpression];
	return query;
}

+(PGQueryPredicate* )and:(id)expression,... {
	NSParameterAssert(expression);
	va_list args;
	va_start(args,expression);
	NSArray* arguments = [self _argumentArray:args first:expression];
	va_end(args);
	if([arguments count]==0) {
		return nil;
	}
	NSString* className = NSStringFromClass([self class]);
	PGQueryPredicate* query = (PGQueryPredicate* )[PGQueryObject queryWithDictionary:@{
		PGQueryArgumentsKey: arguments
	} class:className];
	NSParameterAssert(query);
	[query setOptions:PGQueryPredicateTypeAnd];
	return query;
}

+(PGQueryPredicate* )or:(id)expression,... {
	NSParameterAssert(expression);
	va_list args;
	va_start(args,expression);
	NSArray* arguments = [self _argumentArray:args first:expression];
	va_end(args);
	if([arguments count]==0) {
		return nil;
	}
	NSString* className = NSStringFromClass([self class]);
	PGQueryPredicate* query = (PGQueryPredicate* )[PGQueryObject queryWithDictionary:@{
		PGQueryArgumentsKey: arguments
	} class:className];
	NSParameterAssert(query);
	[query setOptions:PGQueryPredicateTypeOr];
	return query;
}

+(PGQueryPredicate* )not:(id)expression {
	NSParameterAssert(expression);
	PGQueryPredicate* argument = [[self class] predicateOrExpression:expression];
	if(argument==nil) {
		return nil;
	}
	NSString* className = NSStringFromClass([self class]);
	PGQueryPredicate* query = (PGQueryPredicate* )[PGQueryObject queryWithDictionary:@{
		PGQueryArgumentsKey: @[ argument ]
	} class:className];
	NSParameterAssert(query);
	[query setOptions:PGQueryPredicateTypeNot];
	return query;
}

+(PGQueryPredicate* )boolean:(BOOL)boolean {
	NSString* className = NSStringFromClass([self class]);
	PGQueryPredicate* query = (PGQueryPredicate* )[PGQueryObject queryWithDictionary:@{
		PGQueryValueKey: [NSNumber numberWithBool:boolean]
	} class:className];
	NSParameterAssert(query);
	[query setOptions:PGQueryPredicateTypeBoolean];
	return query;
}

+(PGQueryPredicate* )string:(NSString* )string {
	NSParameterAssert(string);
	NSString* className = NSStringFromClass([self class]);
	PGQueryPredicate* query = (PGQueryPredicate* )[PGQueryObject queryWithDictionary:@{
		PGQueryValueKey: string
	} class:className];
	NSParameterAssert(query);
	[query setOptions:PGQueryPredicateTypeString];
	return query;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

@dynamic isAND;
@dynamic isOR;
@dynamic isNOT;

-(BOOL)isAND {
	return [self options]==PGQueryPredicateTypeAnd;
}

-(BOOL)isOR {
	return [self options]==PGQueryPredicateTypeOr;
}

-(BOOL)isNOT {
	return [self options]==PGQueryPredicateTypeNot;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark private methods
////////////////////////////////////////////////////////////////////////////////

-(NSString* )logicalOperatorQuoteFor:(NSString* )operator brackets:(BOOL)brackets connection:(PGConnection* )connection error:(NSError** )error {
	NSArray* arguments = [super objectForKey:PGQueryArgumentsKey];
	if([arguments count] == 0) {
		[connection raiseError:error code:PGClientErrorQuery reason:@"Invalid number of arguments for %@",operator];
		return nil;
	}
	if([arguments count] == 1) {
		PGQueryPredicate* predicate = [arguments objectAtIndex:0];
		NSParameterAssert([predicate isKindOfClass:[PGQueryPredicate class]]);
		return [predicate quoteForConnection:connection error:error];
	}
	NSMutableArray* returnValue = [NSMutableArray arrayWithCapacity:[arguments count]];
	for(PGQueryPredicate* predicate in arguments) {
		NSParameterAssert([predicate isKindOfClass:[PGQueryPredicate class]]);
		NSString* quoted = [predicate quoteForConnection:connection error:error];
		if(quoted==nil) {
			return nil;
		}
		[returnValue addObject:quoted];
	}
	return [NSString stringWithFormat:@"%@%@%@",brackets ? @"(" : @"",[returnValue componentsJoinedByString:operator],brackets ? @")" : @""];
}

-(NSString* )notOperatorQuoteForConnection:(PGConnection* )connection error:(NSError** )error {
	NSArray* arguments = [super objectForKey:PGQueryArgumentsKey];
	if([arguments count] != 1) {
		[connection raiseError:error code:PGClientErrorQuery reason:@"Invalid number of arguments for NOT"];
		return nil;
	}
	PGQueryPredicate* predicate = [arguments objectAtIndex:0];
	NSParameterAssert([predicate isKindOfClass:[PGQueryPredicate class]]);
	NSString* quoted = [predicate quoteForConnection:connection error:error];
	if(quoted==nil) {
		return nil;
	} else {
		return [NSString stringWithFormat:@"NOT %@",quoted];
	}
}

-(NSString* )booleanOperatorQuoteForConnection:(PGConnection* )connection error:(NSError** )error {
	NSNumber* number = [super objectForKey:PGQueryValueKey];
	if(number==nil || [number isKindOfClass:[NSNumber class]]==NO) {
		[connection raiseError:error code:PGClientErrorQuery reason:@"Invalid boolean value"];
		return nil;
	}
	if([number boolValue]) {
		return @"TRUE";
	} else {
		return @"FALSE";
	}
}

-(NSString* )stringOperatorQuoteForConnection:(PGConnection* )connection error:(NSError** )error {
	NSString* string = [super objectForKey:PGQueryValueKey];
	if(string==nil || [string isKindOfClass:[NSString class]]==NO) {
		[connection raiseError:error code:PGClientErrorQuery reason:@"Invalid string value"];
		return nil;
	}
	NSString* quoted = [connection quoteString:string];
	if(quoted==nil) {
		[connection raiseError:error code:PGClientErrorQuery reason:@"Unable to quote string value"];
		return nil;
	}
	return quoted;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark public methods
////////////////////////////////////////////////////////////////////////////////

-(void)addArguments:(id)expression,... {
	NSParameterAssert(expression);
	NSUInteger options = [self options];

	// ensure the predicate is AND or OR logical predicate
	NSParameterAssert(options==PGQueryPredicateTypeAnd || options==PGQueryPredicateTypeOr);

	// obtain the array of new arguments
	va_list args;
	va_start(args,expression);
	NSArray* new_arguments = [[self class] _argumentArray:args first:expression];
	va_end(args);
	if([new_arguments count]==0) {
		return;
	}

	// obtain the array of existing arguments
	NSArray* existing_arguments = [super objectForKey:PGQueryArgumentsKey];
	NSParameterAssert([existing_arguments isKindOfClass:[NSArray class]]);
	
	// make new array
	NSArray* result_arguments = [existing_arguments arrayByAddingObjectsFromArray:new_arguments];
	NSParameterAssert(result_arguments);
	NSParameterAssert([result_arguments count]==([existing_arguments count] + [new_arguments count]));
	
	// set in dictionary
	[super setObject:result_arguments forKey:PGQueryArgumentsKey];
}

-(NSString* )quoteForConnection:(PGConnection* )connection error:(NSError** )error {
	NSParameterAssert(connection);
	NSUInteger options = [self options];
	switch(options) {
		case PGQueryPredicateTypeNull:
			return @"NULL";
		case PGQueryPredicateTypeExpression:
			return [self objectForKey:PGQueryStatementKey];
		case PGQueryPredicateTypeAnd:
			return [self logicalOperatorQuoteFor:@" AND " brackets:NO connection:connection error:error];
		case PGQueryPredicateTypeOr:
			return [self logicalOperatorQuoteFor:@" OR " brackets:YES connection:connection error:error];
		case PGQueryPredicateTypeNot:
			return [self notOperatorQuoteForConnection:connection error:error];
		case PGQueryPredicateTypeBoolean:
			return [self booleanOperatorQuoteForConnection:connection error:error];
		case PGQueryPredicateTypeString:
			return [self stringOperatorQuoteForConnection:connection error:error];
	}
	
	[connection raiseError:error code:PGClientErrorQuery reason:@"Invalid predicate"];
	return nil;
}

@end
