
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
 *  This class implements the DELETE query
 */

@implementation PGQueryDelete

////////////////////////////////////////////////////////////////////////////////
#pragma mark constructor
////////////////////////////////////////////////////////////////////////////////

+(PGQueryDelete* )from:(id)source where:(id)where options:(NSUInteger)options {
	NSParameterAssert(source);
	NSParameterAssert([source isKindOfClass:[NSString class]] || [source isKindOfClass:[PGQuerySource class]]);
	NSParameterAssert(where);
	NSParameterAssert([where isKindOfClass:[NSString class]] || [where isKindOfClass:[PGQueryPredicate class]]);
	NSString* className = NSStringFromClass([self class]);
	PGQueryDelete* query = (PGQueryDelete* )[PGQueryObject queryWithDictionary:@{ } class:className];
	NSParameterAssert(query && [query isKindOfClass:[PGQueryDelete class]]);
	
	// query source
	PGQuerySource* querySource = nil;
	if([source isKindOfClass:[NSString class]]) {
		querySource = (PGQuerySource* )[PGQuerySource table:source alias:nil];
	} else if([source isKindOfClass:[PGQuerySource class]]) {
		querySource = (PGQuerySource* )source;
	}
	if(querySource==nil || [querySource isTableSource]==NO) {
		return nil;
	}
	[query setObject:querySource forKey:PGQuerySourceKey];
	
	// query predicate
	PGQueryPredicate* predicate = [PGQueryPredicate predicateOrExpression:where];
	if(predicate==nil) {
		return nil;
	}
	[query setObject:predicate forKey:PGQueryWhereKey];

	// set other options
	[query setOptions:options];
	return query;
}

+(PGQueryDelete* )from:(id)source where:(id)where {
	return [PGQueryDelete from:source where:where options:0];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

@dynamic source;
@dynamic where;

-(PGQuerySource* )source {
	return [super objectForKey:PGQuerySourceKey];
}

-(PGQueryPredicate* )where {
	return [super objectForKey:PGQueryWhereKey];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark PGQuery overrides
////////////////////////////////////////////////////////////////////////////////

-(NSString* )quoteForConnection:(PGConnection* )connection error:(NSError** )error {
	NSParameterAssert(connection);
//	NSUInteger options = [self options]; // currently unused
	NSMutableArray* parts = [NSMutableArray new];

	// add DELETE FROM
	[parts addObject:@"DELETE FROM"];

	// data source
	NSString* dataSource = [[self source] quoteForConnection:connection error:error];
	if(dataSource==nil) {
		return nil;
	}
	NSParameterAssert([dataSource length]);
	[parts addObject:dataSource];
	
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

	return [parts componentsJoinedByString:@" "];
}


@end
