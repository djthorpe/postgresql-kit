
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

@implementation PGQueryInsert

////////////////////////////////////////////////////////////////////////////////
#pragma mark constructor
////////////////////////////////////////////////////////////////////////////////

+(PGQueryInsert* )into:(id)source values:(id)values options:(NSUInteger)options {
	NSParameterAssert(source);
	NSParameterAssert([source isKindOfClass:[NSString class]] || [source isKindOfClass:[PGQuerySource class]]);
	NSString* className = NSStringFromClass([self class]);
	PGQueryInsert* query = (PGQueryInsert* )[PGQueryObject queryWithDictionary:@{ } class:className];
	NSParameterAssert(query && [query isKindOfClass:[PGQueryInsert class]]);
	
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
	
	// TODO: values
	
	// set other options
	[query setOptions:options];
	return query;
}

+(PGQueryInsert* )into:(id)source values:(id)values {
	return [PGQueryInsert into:source values:values options:0];
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

@dynamic source;
@dynamic columns;
@dynamic values;

-(PGQuerySource* )source {
	return [super objectForKey:PGQuerySourceKey];
}

-(NSArray* )columns {
	// TODO: columns
	return nil;
}

-(NSArray* )values {
	// TODO: values
	return nil;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark PGQuery overrides
////////////////////////////////////////////////////////////////////////////////

-(NSString* )quoteForConnection:(PGConnection* )connection error:(NSError** )error {
	NSParameterAssert(connection);
//	NSUInteger options = [self options]; // currently unused
	NSMutableArray* parts = [NSMutableArray new];

	// add INSERT
	[parts addObject:@"INSERT"];

	// data source
	NSString* dataSource = [[self source] quoteForConnection:connection error:error];
	if(dataSource==nil) {
		return nil;
	}
	// TODO: Do NOT allow AS <alias> for the data source name
	NSParameterAssert([dataSource length]);
	[parts addObject:@"INTO"];
	[parts addObject:dataSource];
	
	// columns
	NSArray* columns = [self columns];
	if([columns count]) {
		// TODO: Add columns
	}
	
	// values
	NSArray* values = [self values];
	if([values count]==0) {
		[parts addObject:@"DEFAULT VALUES"];
	} else {
		[parts addObject:@"VALUES"];
		// TODO: Add values
	}

	return [parts componentsJoinedByString:@" "];
}

@end
