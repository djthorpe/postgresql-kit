
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

@implementation PGQuerySelect

////////////////////////////////////////////////////////////////////////////////
// constructor

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
	[query setOptions:options];
	return query;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic columns;
@dynamic source;
@dynamic where;

-(PGQuerySource* )source {
	return [super objectForKey:PGQuerySourceKey];
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(NSString* )_columnsStringForConnection:(PGConnection* )connection options:(NSUInteger)options error:(NSError** )error {
	return @"";
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

-(NSString* )quoteForConnection:(PGConnection* )connection error:(NSError** )error {
	NSParameterAssert(connection);
	NSUInteger options = [self options];
	NSMutableArray* parts = [NSMutableArray new];

	// add SELECT DISTINCT
	[parts addObject:@"SELECT"];
	if(options & PGQuerySelectOptionDistinct) {
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

	return [parts componentsJoinedByString:@" "];
}


/*
+(PGSelect* )selectTableSource:(NSString* )tableName schema:(NSString* )schemaName options:(int)options {
	NSParameterAssert(tableName);
	PGSelect* query = [super queryWithDictionary:@{
		PQSelectTableNameKey: tableName
	} class:NSStringFromClass([self class])];
	if(query==nil) {
		return nil;
	}
	if(schemaName) {
		[query setObject:schemaName forKey:PQSelectSchemaNameKey];
	}
	[query setOptions:(options | PGSelectTableSource)];
	return query;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic tableName;
@dynamic schemaName;

-(NSString* )tableName {
	return [super objectForKey:PQSelectTableNameKey];
}

-(NSString* )schemaName {
	return [super objectForKey:PQSelectSchemaNameKey];
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(NSString* )distinctPhraseForConnection:(PGConnection* )connection options:(int)options {
	if(options & PGSelectOptionDistinct) {
		return @"DISTINCT";
	} else {
		return @"ALL";
	}
}

-(NSString* )columnsPhraseForConnection:(PGConnection* )connection options:(int)options {
	return @"*";
}

-(NSString* )sourcePhraseForConnection:(PGConnection* )connection options:(int)options {
	if([self schemaName]) {
		return [NSString stringWithFormat:@"FROM %@.%@",[connection quoteIdentifier:[self schemaName]],[connection quoteIdentifier:[self tableName]]];
	} else {
		return [NSString stringWithFormat:@"FROM %@",[connection quoteIdentifier:[self tableName]]];
	}
}

-(NSString* )statementForConnection:(PGConnection* )connection error:(NSError** )error {
	NSParameterAssert(connection);
	int options = [self options];
	NSMutableArray* parts = [NSMutableArray new];
	[parts addObject:@"SELECT"];
	[parts addObject:[self distinctPhraseForConnection:connection options:options]];
	[parts addObject:[self columnsPhraseForConnection:connection options:options]];
	[parts addObject:[self sourcePhraseForConnection:connection options:options]];
	return [parts componentsJoinedByString:@" "];
}

*/


@end
