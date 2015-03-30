
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
#pragma mark forward declarations
////////////////////////////////////////////////////////////////////////////////

@class PGQuerySource;
  @class PGQueryTableSource;
  @class PGQueryJoinSource;

@implementation PGQuerySource

////////////////////////////////////////////////////////////////////////////////
#pragma mark constructors
////////////////////////////////////////////////////////////////////////////////

+(PGQuerySource* )table:(NSString* )table schema:(NSString* )schema alias:(NSString* )alias {
	NSParameterAssert(table);
	NSString* className = @"PGQueryTableSource";
	PGQuerySource* query = (PGQuerySource* )[PGQueryObject queryWithDictionary:@{
		PGQueryTableKey: table
	} class:className];
	NSParameterAssert(query && [query isKindOfClass:[PGQuerySource class]]);
	if(schema) {
		[query setObject:schema forKey:PGQuerySchemaKey];
	}
	if(alias) {
		[query setObject:alias forKey:PGQueryAliasKey];
	}
	return query;
}

+(PGQuerySource* )table:(NSString* )table alias:(NSString* )alias {
	return (PGQuerySource* )[PGQuerySource table:table schema:nil alias:alias];
}

+(PGQuerySource* )join:(PGQuerySource* )lhs with:(PGQuerySource* )rhs on:(id)predicate options:(NSUInteger)options {
	NSParameterAssert(lhs && [lhs isKindOfClass:[PGQuerySource class]]);
	NSParameterAssert(rhs && [rhs isKindOfClass:[PGQuerySource class]]);
	NSString* className = @"PGQuerySourceJoin";
	PGQuerySource* query = (PGQuerySource* )[PGQueryObject queryWithDictionary:@{
		PGQueryJoinLeftKey: lhs,
		PGQueryJoinRightKey: rhs
	} class:className];
	if(predicate) {
		// TODO: set predicate
	}
	[query setOptions:options];
	return query;
}

+(PGQuerySource* )join:(PGQuerySource* )lhs with:(PGQuerySource* )rhs on:(id)predicate {
	return [PGQuerySource join:lhs with:rhs on:predicate options:0];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark public methods
////////////////////////////////////////////////////////////////////////////////

-(NSString* )quoteForConnection:(PGConnection* )connection withAlias:(BOOL)withAlias error:(NSError** )error {
	[connection raiseError:error code:PGClientErrorQuery reason:@"Virtual method cannot be called"];
	return nil;
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark PGQuerySourceTable interface
////////////////////////////////////////////////////////////////////////////////

@interface PGQuerySourceTable: PGQuerySource
@property (readonly) NSString* table;
@property (readonly) NSString* schema;
@property (readonly) NSString* alias;
@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark PGQuerySourceTable implementation
////////////////////////////////////////////////////////////////////////////////

@implementation PGQuerySourceTable

////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

@dynamic table;
@dynamic schema;
@dynamic alias;

-(NSString* )table {
	return [super objectForKey:PGQueryTableKey];
}

-(NSString* )schema {
	return [super objectForKey:PGQuerySchemaKey];
}

-(NSString* )alias {
	return [super objectForKey:PGQueryAliasKey];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark public methods
////////////////////////////////////////////////////////////////////////////////

-(NSString* )quoteForConnection:(PGConnection* )connection withAlias:(BOOL)withAlias error:(NSError** )error {
	NSParameterAssert(connection);
	NSString* aliasName = [self alias];
	NSString* aliasQuoted = (withAlias && [aliasName length]) ? [NSString stringWithFormat:@" %@",[connection quoteIdentifier:[self alias]]] : @"";
	NSString* schemaName = [self schema];
	NSString* tableName = [self table];
	if([tableName length]==0) {
		[connection raiseError:error code:PGClientErrorQuery reason:@"Missing table name"];
		return nil;
	}
	NSString* tableQuoted = [connection quoteIdentifier:tableName];
	if([schemaName length]) {
		NSString* schemaQuoted = [connection quoteIdentifier:schemaName];
		return [NSString stringWithFormat:@"%@.%@%@",schemaQuoted,tableQuoted,aliasQuoted];
	} else {
		return [NSString stringWithFormat:@"%@%@",tableQuoted,aliasQuoted];
	}
}

-(NSString* )quoteForConnection:(PGConnection* )connection error:(NSError** )error {
	return [self quoteForConnection:connection withAlias:YES error:error];
}

@end


////////////////////////////////////////////////////////////////////////////////
#pragma mark PGQuerySourceJoin interface
////////////////////////////////////////////////////////////////////////////////

@interface PGQuerySourceJoin: PGQuerySource
@property (readonly) PGQuerySource* lhs;
@property (readonly) PGQuerySource* rhs;
@property (readonly) PGQueryPredicate* expression;
@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark PGQuerySourceJoin implementation
////////////////////////////////////////////////////////////////////////////////

@implementation PGQuerySourceJoin

////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

@dynamic lhs;
@dynamic rhs;
@dynamic expression;

-(PGQuerySource* )lhs {
	return [super objectForKey:PGQueryJoinLeftKey];
}

-(PGQuerySource* )rhs {
	return [super objectForKey:PGQueryJoinRightKey];
}

-(PGQueryPredicate* )expression {
	return [super objectForKey:PGQueryJoinExpressionKey];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark private methods
////////////////////////////////////////////////////////////////////////////////

-(NSString* )quoteJoinTypeForConnection:(PGConnection* )connection error:(NSError** )error {
	NSUInteger type = [self options] & PGQueryOptionJoinMask;
	switch(type) {
	case PGQueryOptionJoinCross:
		return [self expression] ? @"JOIN" : @"CROSS JOIN";
	case PGQueryOptionJoinInner:
		return [self expression] ? @"INNER JOIN" : @"NATURAL INNER JOIN";
	case PGQueryOptionJoinLeftOuter:
		return [self expression] ? @"LEFT OUTER JOIN" : @"NATURAL LEFT OUTER JOIN";
	case PGQueryOptionJoinRightOuter:
		return [self expression] ? @"RIGHT OUTER JOIN" : @"NATURAL RIGHT OUTER JOIN";
	case PGQueryOptionJoinFullOuter:
		return [self expression] ? @"FULL OUTER JOIN" : @"NATURAL FULL OUTER JOIN";
	default:
		[connection raiseError:error code:PGClientErrorQuery reason:@"Invalid join type"];
		return nil;
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark public methods
////////////////////////////////////////////////////////////////////////////////

-(NSString* )quoteForConnection:(PGConnection* )connection error:(NSError** )error {
	NSParameterAssert(connection);
	NSMutableArray* parts = [NSMutableArray new];
	
	NSString* lhs = [[self lhs] quoteForConnection:connection error:error];
	if(lhs==nil) {
		return nil;
	}
	NSString* joinType = [self quoteForConnection:connection error:error];
	if(joinType==nil) {
		return nil;
	}
	NSString* rhs = [[self rhs] quoteForConnection:connection error:error];
	if(rhs==nil) {
		return nil;
	}
	NSString* expression = nil;
	if([self expression]) {
		expression = [[self expression] quoteForConnection:connection error:error];
		if(expression==nil) {
			return nil;
		}
	}
	[parts addObjectsFromArray:@[ lhs,joinType, rhs ]];
	if(expression) {
		[parts addObjectsFromArray:@[ @"ON", expression ]];
	}
	return [parts componentsJoinedByString:@" "];
}

@end

