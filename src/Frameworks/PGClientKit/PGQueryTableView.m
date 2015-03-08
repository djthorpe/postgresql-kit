
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

@implementation PGQueryTableView

+(PGQueryTableView* )createTable:(NSString* )table schema:(NSString* )schema columns:(NSArray* )columns options:(NSUInteger)options {
	NSParameterAssert(table);
	if([table length]==0) {
		return nil;
	}
	NSString* className = NSStringFromClass([self class]);
	PGQueryTableView* query = (PGQueryTableView* )[PGQueryObject queryWithDictionary:@{
		PGQueryTableKey: table
	} class:className];
	NSParameterAssert(query && [query isKindOfClass:[PGQueryTableView class]]);

	// set schema
	if([schema length]) {
		[query setObject:schema forKey:PGQuerySchemaKey];
	}

	// TODO: set columns

	[query setOptions:(options | PGQueryOperationCreate)];
	return query;
}

+(PGQueryTableView* )createView:(NSString* )view schema:(NSString* )schema select:(id)select options:(NSUInteger)options {
	NSParameterAssert(view);
	NSParameterAssert(select);
	NSParameterAssert([select isKindOfClass:[NSString class]] || [select isKindOfClass:[PGQuerySelect class]]);

	if([view length]==0) {
		return nil;
	}

	NSString* className = NSStringFromClass([self class]);
	PGQueryTableView* object = (PGQueryTableView* )[PGQueryObject queryWithDictionary:@{
		PGQueryViewKey: view
	} class:className];
	NSParameterAssert(object && [object isKindOfClass:[PGQueryTableView class]]);

	// set schema
	if([schema length]) {
		[object setObject:schema forKey:PGQuerySchemaKey];
	}

	// set query
	if([select isKindOfClass:[NSString class]]) {
		[object setObject:[PGQuery queryWithString:select] forKey:PGQuerySourceKey];
	} else if([select isKindOfClass:[PGQuerySelect class]]) {
		[object setObject:select forKey:PGQuerySourceKey];
	} else {
		return nil;
	}

	[object setOptions:(options | PGQueryOperationCreate)];
	return object;
}

+(PGQueryTableView* )dropTable:(NSString* )table schema:(NSString* )schema options:(NSUInteger)options {
	NSParameterAssert(table);

	if([table length]==0) {
		return nil;
	}

	NSString* className = NSStringFromClass([self class]);
	PGQueryTableView* object = (PGQueryTableView* )[PGQueryObject queryWithDictionary:@{
		PGQueryTableKey: table
	} class:className];
	NSParameterAssert(object && [object isKindOfClass:[PGQueryTableView class]]);

	// set schema
	if([schema length]) {
		[object setObject:schema forKey:PGQuerySchemaKey];
	}

	// set options
	[object setOptions:(options | PGQueryOperationDrop)];
	
	// return object
	return object;
}

+(PGQueryTableView* )dropView:(NSString* )view schema:(NSString* )schema options:(NSUInteger)options {
	NSParameterAssert(view);

	if([view length]==0) {
		return nil;
	}

	NSString* className = NSStringFromClass([self class]);
	PGQueryTableView* object = (PGQueryTableView* )[PGQueryObject queryWithDictionary:@{
		PGQueryViewKey: view
	} class:className];
	NSParameterAssert(object && [object isKindOfClass:[PGQueryTableView class]]);

	// set schema
	if([schema length]) {
		[object setObject:schema forKey:PGQuerySchemaKey];
	}

	// set options
	[object setOptions:(options | PGQueryOperationDrop)];
	
	// return object
	return object;
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

@dynamic schema;
@dynamic table;
@dynamic view;
@dynamic columns;
@dynamic select;

-(NSString* )schema {
	NSString* schema = [super objectForKey:PGQuerySchemaKey];
	return ([schema length]==0) ? nil : schema;
}

-(NSString* )name {
	NSString* name = [super objectForKey:PGQueryNameKey];
	return ([name length]==0) ? nil : name;
}

@end
