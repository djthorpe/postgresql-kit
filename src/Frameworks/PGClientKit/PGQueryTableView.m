
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

	// set columns
	if([columns count]) {
		for(id column in columns) {
			[query _addColumn:column];
		}
	}

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
@dynamic select;
@dynamic tablespace;

-(NSString* )schema {
	NSString* schema = [super objectForKey:PGQuerySchemaKey];
	return ([schema length]==0) ? nil : schema;
}

-(NSString* )table {
	NSString* table = [super objectForKey:PGQueryTableKey];
	return ([table length]==0) ? nil : table;
}

-(NSString* )view {
	NSString* view = [super objectForKey:PGQueryViewKey];
	return ([view length]==0) ? nil : view;
}

-(PGQuery* )select {
	return [super objectForKey:PGQuerySourceKey];
}

-(NSString* )tablespace {
	NSString* tablespace = [super objectForKey:PGQueryTablespaceKey];
	return ([tablespace length]==0) ? nil : tablespace;
}

-(void)setTablespace:(NSString* )tablespace {
	if([tablespace length]==0) {
		[super removeObjectForKey:PGQueryTablespaceKey];
		[super setOptions:([self options] & ~PGQueryOptionSetTablespace)];
	} else {
		[super setObject:tablespace forKey:PGQueryTablespaceKey];
		[super setOptions:([self options] | PGQueryOptionSetTablespace)];
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark private methods
////////////////////////////////////////////////////////////////////////////////

-(void)_addColumn:(id)column {
	NSParameterAssert(column);
	NSParameterAssert([column isKindOfClass:[NSString class]]);
	// TODO: accept more than just NSString as a column
	NSLog(@"TODO: _addColumn %@",column);
}

-(NSString* )quoteCreateTable:(NSString* )tableName connection:(PGConnection* )connection options:(NSUInteger)options error:(NSError** )error {
	NSParameterAssert(connection);
	NSParameterAssert(tableName);

	// create flags container
	NSMutableArray* flags = [NSMutableArray new];
	NSParameterAssert(flags);

	// temporary
	if(options & PGQueryOptionTemporary) {
		[flags addObject:@"TEMPORARY"];
	}

	// table
	[flags addObject:@"TABLE"];
	
	// if not exists
	if(options & PGQueryOptionIgnoreIfNotExists) {
		[flags addObject:@"IF NOT EXISTS"];
	}
	
	// table identifier
	if([tableName length]==0) {
		[connection raiseError:error code:PGClientErrorQuery reason:@"CREATE TABLE: Missing table name"];
		return nil;
	}
	NSString* quotedName = nil;
	NSString* schemaName = [self schema];
	if(schemaName) {
		quotedName = [NSString stringWithFormat:@"%@.%@",[connection quoteIdentifier:schemaName],[connection quoteIdentifier:tableName]];
	} else {
		quotedName = [connection quoteIdentifier:tableName];
	}
	NSParameterAssert(quotedName);
	[flags addObject:quotedName];

	// columns
	[flags addObject:@"()"];

	// tablespace
	if((options & PGQueryOptionSetTablespace)) {
		NSString* tablespace = [self tablespace];
		if([tablespace length]==0) {
			[flags addObject:@"TABLESPACE DEFAULT"];
		} else {
			[flags addObject:[NSString stringWithFormat:@"TABLESPACE %@",[connection quoteIdentifier:tablespace]]];
		}
	}
	
	// return statement
	return [NSString stringWithFormat:@"CREATE %@",[flags componentsJoinedByString:@" "]];
}

-(NSString* )quoteCreateView:(NSString* )viewName connection:(PGConnection* )connection options:(NSUInteger)options error:(NSError** )error {
	NSParameterAssert(connection);
	NSParameterAssert(viewName);

	// create flags container
	NSMutableArray* flags = [NSMutableArray new];
	NSParameterAssert(flags);

	// if exists
	if(options & PGQueryOptionReplaceIfExists) {
		[flags addObject:@"OR REPLACE"];
	}

	// temporary
	if(options & PGQueryOptionTemporary) {
		[flags addObject:@"TEMPORARY"];
	}

	// view identifier
	if([viewName length]==0) {
		[connection raiseError:error code:PGClientErrorQuery reason:@"CREATE VIEW: Missing view name"];
		return nil;
	}
	NSString* schemaName = [self schema];
	NSString* quotedName = nil;
	if(schemaName) {
		quotedName = [NSString stringWithFormat:@"%@.%@",[connection quoteIdentifier:schemaName],[connection quoteIdentifier:viewName]];
	} else {
		quotedName = [connection quoteIdentifier:viewName];
	}
	NSParameterAssert(quotedName);
	[flags addObject:@"VIEW"];
	[flags addObject:quotedName];

	// select
	PGQuery* select = [self select];
	if(select==nil) {
		[connection raiseError:error code:PGClientErrorQuery reason:@"CREATE VIEW: Missing select property"];
		return nil;
	}
	NSString* quotedSelect = [select quoteForConnection:connection error:error];
	if(quotedSelect==nil) {
		return nil;
	}
	[flags addObject:@"AS"];
	[flags addObject:quotedSelect];
	
	// return statement
	return [NSString stringWithFormat:@"CREATE %@",[flags componentsJoinedByString:@" "]];
}

-(NSString* )quoteDrop:(NSString* )type name:(NSString* )name connection:(PGConnection* )connection options:(NSUInteger)options error:(NSError** )error {
	NSParameterAssert(type && name);
	NSParameterAssert(connection);
	
	// create flags container
	NSMutableArray* flags = [NSMutableArray new];
	NSParameterAssert(flags);

	// if exists
	if(options & PGQueryOptionIgnoreIfExists) {
		[flags addObject:@"IF EXISTS"];
	}

	// drop identifier
	if([name length]==0) {
		[connection raiseError:error code:PGClientErrorQuery reason:@"DROP %@: Missing name",type];
		return nil;
	}
	NSString* schemaName = [self schema];
	NSString* quotedName = nil;
	if(schemaName) {
		quotedName = [NSString stringWithFormat:@"%@.%@",[connection quoteIdentifier:schemaName],[connection quoteIdentifier:name]];
	} else {
		quotedName = [connection quoteIdentifier:name];
	}
	NSParameterAssert(quotedName);
	[flags addObject:quotedName];

	// CASCADE
	if(options & PGQueryOptionDropObjects) {
		[flags addObject:@"CASCADE"];
	} else {
		[flags addObject:@"RESTRICT"];
	}

	// return statement
	return [NSString stringWithFormat:@"DROP %@ %@",type,[flags componentsJoinedByString:@" "]];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark public methods
////////////////////////////////////////////////////////////////////////////////

-(NSString* )quoteForConnection:(PGConnection* )connection error:(NSError** )error {
	NSUInteger options = [self options];
	NSUInteger operation = (options & PGQueryOperationMask);
	NSString* tableName = [self table];
	NSString* viewName = [self view];

	switch(operation) {
	case PGQueryOperationCreate:
		if(tableName) {
			return [self quoteCreateTable:tableName connection:connection options:options error:error];
		} else if(viewName) {
			return [self quoteCreateView:viewName connection:connection options:options error:error];
		}
		break;
	case PGQueryOperationDrop:
		if(tableName) {
			return [self quoteDrop:@"TABLE" name:tableName connection:connection options:options error:error];
		} else if(viewName) {
			return [self quoteDrop:@"VIEW" name:viewName connection:connection options:options error:error];
		}
		break;
	}

	[connection raiseError:error code:PGClientErrorQuery reason:@"TABLE/VIEW: Invalid operation"];
	return nil;

}

@end
