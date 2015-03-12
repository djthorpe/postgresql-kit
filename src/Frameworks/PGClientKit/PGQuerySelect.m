
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

/**
 *  Constant to indicate there is no limit
 */
const NSUInteger PGQuerySelectNoLimit = NSUIntegerMax;

@implementation PGQuerySelect

////////////////////////////////////////////////////////////////////////////////
#pragma mark constructor
////////////////////////////////////////////////////////////////////////////////

+(PGQuerySelect* )select:(id)source options:(NSUInteger)options {
	NSParameterAssert(source);
	NSParameterAssert([source isKindOfClass:[NSString class]] || [source isKindOfClass:[PGQuerySource class]]);
	NSString* className = NSStringFromClass([self class]);
	PGQuerySelect* query = (PGQuerySelect* )[PGQueryObject queryWithDictionary:@{ } class:className];
	NSParameterAssert(query && [query isKindOfClass:[PGQuerySelect class]]);
	PGQuerySource* querySource = nil;
	if([source isKindOfClass:[NSString class]]) {
		querySource = (PGQuerySource* )[PGQuerySource sourceWithTable:source alias:nil];
	} else if([source isKindOfClass:[PGQuerySource class]]) {
		querySource = (PGQuerySource* )source;
	}
	if(querySource==nil) {
		return nil;
	}
	[query setObject:querySource forKey:PGQuerySourceKey];
	[query setObject:[NSMutableArray array] forKey:PGQueryColumnsKey];
	[query setOptions:options];
	return query;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic columns;
@dynamic aliases;
@dynamic source;
@dynamic where;
@dynamic having;
@dynamic offset;
@dynamic limit;

-(PGQuerySource* )source {
	return [super objectForKey:PGQuerySourceKey];
}

-(PGQueryPredicate* )where {
	return [super objectForKey:PGQueryWhereKey];
}

-(PGQueryPredicate* )having {
	return [super objectForKey:PGQueryHavingKey];
}

-(void)setWhere:(PGQueryPredicate* )where {
	if(where==nil) {
		// in the case where we need to have no WHERE statement
		[super removeObjectForKey:PGQueryWhereKey];
	} else {
		[super setObject:where forKey:PGQueryWhereKey];
	}
}

-(void)setHaving:(PGQueryPredicate* )having {
	if(having==nil) {
		// in the case where we need to have no HAVING statement
		[super removeObjectForKey:PGQueryHavingKey];
	} else {
		[super setObject:having forKey:PGQueryHavingKey];
	}
}

-(NSUInteger)offset {
	NSNumber* offset = [super objectForKey:PGQueryOffsetKey];
	if(offset==nil) {
		return 0;
	}
	NSParameterAssert([offset isKindOfClass:[NSNumber class]]);
	return [offset unsignedIntegerValue];
}

-(NSUInteger)limit {
	NSNumber* limit = [super objectForKey:PGQueryLimitKey];
	if(limit==nil) {
		return PGQuerySelectNoLimit;
	}
	NSParameterAssert([limit isKindOfClass:[NSNumber class]]);
	return [limit unsignedIntegerValue];
}

-(void)setOffset:(NSUInteger)offset {
	[super setObject:[NSNumber numberWithUnsignedInteger:offset] forKey:PGQueryOffsetKey];
}

-(void)setLimit:(NSUInteger)limit {
	[super setObject:[NSNumber numberWithUnsignedInteger:limit] forKey:PGQueryLimitKey];
}

-(NSArray* )columns {
	NSArray* columns = [super objectForKey:PGQueryColumnsKey];
	if(columns==nil || [columns count]==0) {
		// return empty array of columns
		return [NSArray array];
	}
	/**
	 *  the column elements are of form [ predicate, alias ] where the
	 *  predicate is of type PGQueryPredicate and the alias is an NSString.
	 *  Where the NSString is an empty string, no alias is set.
	 */
	NSMutableArray* returnValue = [NSMutableArray arrayWithCapacity:[columns count]];
	for(NSArray* column in columns) {
		NSParameterAssert([columns isKindOfClass:[NSArray class]]);
		NSParameterAssert([column count]==2);
		PGQueryPredicate* value = [column objectAtIndex:0];
		NSParameterAssert([value isKindOfClass:[PGQueryPredicate class]]);
		[returnValue addObject:value];
	}
	return returnValue;
}

-(NSArray* )aliases {
	NSArray* columns = [super objectForKey:PGQueryColumnsKey];
	if(columns==nil || [columns count]==0) {
		// return empty array of columns
		return [NSArray array];
	}
	/**
	 *  the column elements are of form [ predicate, alias ] where the
	 *  predicate is of type PGQueryPredicate and the alias is an NSString.
	 *  Where the NSString is an empty string, no alias is set.
	 */
	NSMutableArray* returnValue = [NSMutableArray arrayWithCapacity:[columns count]];
	for(NSArray* column in columns) {
		NSParameterAssert([columns isKindOfClass:[NSArray class]]);
		NSParameterAssert([column count]==2);
		NSString* value = [column objectAtIndex:1];
		NSParameterAssert([value isKindOfClass:[NSString class]]);
		[returnValue addObject:value];
	}
	return returnValue;
}

-(void)addColumn:(id)column alias:(NSString* )aliasName {
	NSParameterAssert(column);
	NSParameterAssert([column isKindOfClass:[PGQueryPredicate class]] || [column isKindOfClass:[NSString class]]);
	if(aliasName==nil) {
		aliasName = @"";
	}
	PGQueryPredicate* expression = [PGQueryPredicate predicateOrExpression:column];
	NSParameterAssert(expression);
	NSMutableArray* columns = [super objectForKey:PGQueryColumnsKey];
	NSParameterAssert([columns isKindOfClass:[NSMutableArray class]]);
	[columns addObject:@[ expression, aliasName ]];
}

-(void)andWhere:(id)predicate {
	NSParameterAssert(predicate);
	NSParameterAssert([predicate isKindOfClass:[NSString class]] || [predicate isKindOfClass:[PGQueryPredicate class]]);
	PGQueryPredicate* new = [PGQueryPredicate predicateOrExpression:predicate];
	NSParameterAssert(new);
	PGQueryPredicate* where = [self where];
	if(where==nil) {
		where = new;
	} else if([where isAND]) {
		[where addArguments:new];
	} else {
		where = [PGQueryPredicate and:where,new,nil];
	}
	NSParameterAssert(where);
	[self setObject:where forKey:PGQueryWhereKey];
}

-(void)orWhere:(id)predicate {
	NSParameterAssert(predicate);
	NSParameterAssert([predicate isKindOfClass:[NSString class]] || [predicate isKindOfClass:[PGQueryPredicate class]]);
	PGQueryPredicate* new = [predicate isKindOfClass:[PGQueryPredicate class]] ? predicate : [PGQueryPredicate expression:predicate];
	PGQueryPredicate* where = [self where];
	if(where==nil) {
		where = new;
	} else if([where isOR]) {
		[where addArguments:new,nil];
	} else {
		where = [PGQueryPredicate or:where,new,nil];
	}
	NSParameterAssert(where);
	[self setObject:where forKey:PGQueryWhereKey];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(NSString* )_columnsStringForConnection:(PGConnection* )connection options:(NSUInteger)options error:(NSError** )error {
	NSArray* columns = [super objectForKey:PGQueryColumnsKey];
	if([columns count]==0) {
		return @"";
	}
	NSMutableArray* returnValue = [NSMutableArray arrayWithCapacity:[columns count]];
	for(NSArray* column in columns) {
		NSParameterAssert([columns isKindOfClass:[NSArray class]]);
		NSParameterAssert([column count]==2);
		PGQueryPredicate* value = [column objectAtIndex:0];
		NSParameterAssert([value isKindOfClass:[PGQueryPredicate class]]);
		NSString* alias = [column objectAtIndex:1];
		NSParameterAssert([alias isKindOfClass:[NSString class]]);
		NSString* quotedValue = [value quoteForConnection:connection error:error];
		NSString* quotedAlias = [alias length] ? [connection quoteIdentifier:alias] : alias;
		if(quotedValue==nil || quotedAlias==nil) {
			return nil;
		}
		if([quotedAlias length]) {
			[returnValue addObject:[NSString stringWithFormat:@"%@ AS %@",quotedValue,quotedAlias]];
		} else {
			[returnValue addObject:quotedValue];
		}
	}
	return [returnValue componentsJoinedByString:@","];
}

-(NSString* )_sourceStringForConnection:(PGConnection* )connection options:(NSUInteger)options error:(NSError** )error {
	if([self source]==nil) {
		// if there is no source, then return empty string
		return @"";
	} else {
		// else return the source
		return [[self source] quoteForConnection:connection withAlias:YES error:error];
	}
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(void)setOffset:(NSUInteger)offset limit:(NSUInteger)limit {
	[self setOffset:offset];
	[self setLimit:limit];
}

-(NSString* )quoteForConnection:(PGConnection* )connection error:(NSError** )error {
	NSParameterAssert(connection);
	NSUInteger options = [self options];
	NSMutableArray* parts = [NSMutableArray new];

	// add SELECT DISTINCT
	[parts addObject:@"SELECT"];
	if(options & PGQueryOptionDistinct) {
		[parts addObject:@"DISTINCT"];
	}

	// columns
	NSString* columns = [self _columnsStringForConnection:connection options:options error:error];
	if(columns==nil) {
		return nil;
	} else if([columns length]) {
		[parts addObject:columns];
	} else {
		[parts addObject:@"*"];
	}

	// dataSource
	NSString* dataSource = [self _sourceStringForConnection:connection options:options error:error];
	if(dataSource==nil) {
		return nil;
	} else if([dataSource length]) {
		[parts addObject:@"FROM"];
		[parts addObject:dataSource];
	}
	
	// where
	PGQueryPredicate* where = [self where];
	if(where) {
		NSString* quotedWhere = [where quoteForConnection:connection error:error];
		if(quotedWhere==nil) {
			return nil;
		}
		[parts addObject:@"WHERE"];
		[parts addObject:quotedWhere];
	}

	// having
	PGQueryPredicate* having = [self having];
	if(having) {
		NSString* quotedHaving = [having quoteForConnection:connection error:error];
		if(quotedHaving==nil) {
			return nil;
		}
		[parts addObject:@"HAVING"];
		[parts addObject:quotedHaving];
	}
	
	// offset and limit
	NSUInteger offset = [self offset];
	if(offset) {
		[parts addObject:[NSString stringWithFormat:@"OFFSET %lu",offset]];
	}
	NSUInteger limit = [self limit];
	if(limit != PGQuerySelectNoLimit) {
		[parts addObject:[NSString stringWithFormat:@"LIMIT %lu",limit]];
	}

	return [parts componentsJoinedByString:@" "];
}

@end
