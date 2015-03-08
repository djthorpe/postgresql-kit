
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

// keys
NSString* PQQueryCreateTableNameKey = @"PGQueryCreate_table";
NSString* PQQueryCreateDatabaseNameKey = @"PGQueryCreate_database";
NSString* PQQueryCreateSchemaNameKey = @"PGQueryCreate_schema";
NSString* PQQueryCreateRoleNameKey = @"PGQueryCreate_role";
NSString* PQQueryCreateOwnerNameKey = @"PGQueryCreate_owner";
NSString* PQQueryCreateExpiryKey = @"PGQueryCreate_expiry";
NSString* PQQueryCreateEncodingKey = @"PGQueryCreate_encoding";
NSString* PQQueryCreatePasswordKey = @"PGQueryCreate_password";
NSString* PQQueryCreateConnectionLimitKey = @"PGQueryCreate_connectionlimit";
NSString* PQQueryCreateTablespaceKey = @"PGQueryCreate_tablespace";
NSString* PQQueryCreateTemplateKey = @"PGQueryCreate_template";

// additional option flags
enum {
	PGQueryOptionTypeCreateDatabase = 0x0100000,
	PGQueryOptionTypeCreateSchema   = 0x0200000,
	PGQueryOptionTypeCreateRole     = 0x0400000,
	PGQueryOptionTypeDropDatabase   = 0x0800000,
	PGQueryOptionTypeDropSchema     = 0x1000000,
	PGQueryOptionTypeDropRole       = 0x2000000,
	PGQueryOptionTypeDropTable      = 0x4000000,
	PGQueryOptionTypeDropView       = 0x4000000
};

@implementation PGQueryCreate

-(instancetype)init {
	self = [super init];
	if(self) {
		[self setConnectionLimit:-1]; // -1 is default
	}
	return self;
}

+(PGQueryCreate* )createDatabase:(NSString* )databaseName options:(int)options {
	NSParameterAssert(databaseName);
	PGQueryCreate* query = [super queryWithDictionary:@{
		PQQueryCreateDatabaseNameKey: databaseName
	} class:NSStringFromClass([self class])];
	[query setOptions:(options | PGQueryOptionTypeCreateDatabase)];
	return query;
}

+(PGQueryCreate* )createSchema:(NSString* )schemaName options:(int)options {
	NSParameterAssert(schemaName);
	PGQueryCreate* query = [super queryWithDictionary:@{
		PQQueryCreateSchemaNameKey: schemaName
	} class:NSStringFromClass([self class])];
	[query setOptions:(options | PGQueryOptionTypeCreateSchema)];
	return query;
}

+(PGQueryCreate* )createRole:(NSString* )roleName options:(int)options {
	NSParameterAssert(roleName);
	PGQueryCreate* query = [super queryWithDictionary:@{
		PQQueryCreateRoleNameKey: roleName
	} class:NSStringFromClass([self class])];
	[query setOptions:(options | PGQueryOptionTypeCreateRole)];
	return query;
}

+(PGQueryCreate* )dropDatabase:(NSString* )databaseName options:(int)options {
	NSParameterAssert(databaseName);
	PGQueryCreate* query = [super queryWithDictionary:@{
		PQQueryCreateDatabaseNameKey: databaseName
	} class:NSStringFromClass([self class])];
	[query setOptions:(options | PGQueryOptionTypeDropDatabase)];
	return query;
}

+(PGQueryCreate* )dropSchema:(NSString* )schemaName options:(int)options {
	NSParameterAssert(schemaName);
	PGQueryCreate* query = [super queryWithDictionary:@{
		PQQueryCreateSchemaNameKey: schemaName
	} class:NSStringFromClass([self class])];
	[query setOptions:(options | PGQueryOptionTypeDropSchema)];
	return query;
}

+(PGQueryCreate* )dropRole:(NSString* )roleName options:(int)options {
	NSParameterAssert(roleName);
	PGQueryCreate* query = [super queryWithDictionary:@{
		PQQueryCreateRoleNameKey: roleName
	} class:NSStringFromClass([self class])];
	[query setOptions:(options | PGQueryOptionTypeDropRole)];
	return query;
}

+(PGQueryCreate* )dropTables:(NSArray* )tableNames schema:(NSString* )schemaName options:(int)options {
	NSParameterAssert(tableNames);
	// check for non-string table names
	if([tableNames count]==0) {
		return nil;
	}
	for(NSString* tableName in tableNames) {
		if([tableName isKindOfClass:[NSString class]]==NO) {
			return nil;
		}
		if([tableName length]==0) {
			return nil;
		}
	}
	// create the query
	PGQueryCreate* query = [super queryWithDictionary:@{
		PQQueryCreateTableNameKey: tableNames
	} class:NSStringFromClass([self class])];
	[query setOptions:(options | PGQueryOptionTypeDropTable)];
	[query setSchema:schemaName];
	return query;
}

+(PGQueryCreate* )dropTable:(NSString* )tableName schema:(NSString* )schemaName options:(int)options {
	NSParameterAssert(tableName);
	PGQueryCreate* query = [super queryWithDictionary:@{
		PQQueryCreateTableNameKey: tableName
	} class:NSStringFromClass([self class])];
	[query setOptions:(options | PGQueryOptionTypeDropTable)];
	[query setSchema:schemaName];
	return query;
}

+(PGQueryCreate* )dropView:(NSString* )viewName schema:(NSString* )schemaName options:(int)options {
	NSParameterAssert(viewName);
	PGQueryCreate* query = [super queryWithDictionary:@{
		PQQueryCreateTableNameKey: viewName
	} class:NSStringFromClass([self class])];
	[query setOptions:(options | PGQueryOptionTypeDropView)];
	[query setSchema:schemaName];
	return query;
}

/////////////////////////////////////////////////
// methods

-(NSString* )_createSchemaStatementForConnection:(PGConnection* )connection options:(int)options error:(NSError** )error {
	NSString* schemaName = [self schema];
	if(schemaName==nil) {
		return nil;
	}
	NSMutableArray* flags = [NSMutableArray new];
	// schema owner
	if(options & PGQueryOptionSetOwner && [self owner]) {
		[flags addObject:[NSString stringWithFormat:@"AUTHORIZATION %@",[connection quoteIdentifier:[self owner]]]];
	}
	return [NSString stringWithFormat:@"CREATE SCHEMA %@ %@",[connection quoteIdentifier:schemaName],[flags componentsJoinedByString:@" "]];
}

-(NSString* )_dropSchemaStatementForConnection:(PGConnection* )connection options:(int)options error:(NSError** )error {
	NSString* schemaName = [self schema];
	if(schemaName==nil) {
		return nil;
	}
	NSMutableArray* flags = [NSMutableArray new];
	// IF EXISTS
	if(options & PGQueryOptionIgnoreIfExists) {
		[flags addObject:@"IF EXISTS"];
	}
	// CASCADE
	if(options & PGQueryOptionDropObjects) {
		[flags addObject:@"CASCADE"];
	} else {
		[flags addObject:@"RESTRICT"];
	}
	return [NSString stringWithFormat:@"DROP SCHEMA %@%@",[connection quoteIdentifier:schemaName],[flags componentsJoinedByString:@" "]];
}

-(NSString* )_dropRoleStatementForConnection:(PGConnection* )connection options:(int)options error:(NSError** )error {
	NSString* roleName = [self role];
	if(roleName==nil) {
		return nil;
	}
	NSMutableArray* flags = [NSMutableArray new];
	// IF EXISTS
	if(options & PGQueryOptionIgnoreIfExists) {
		[flags addObject:@"IF EXISTS"];
	}
	return [NSString stringWithFormat:@"DROP ROLE %@%@",[connection quoteIdentifier:roleName],[flags componentsJoinedByString:@" "]];
}

/* TODO
-(NSString* )_dropRolesStatementForConnection:(PGConnection* )connection options:(int)options error:(NSError** )error {
	NSArray* roleNames = [super objectForKey:PQQueryCreateRoleNameKey];
	if([roleNames count]==0) {
		return nil;
	}
	NSMutableArray* flags = [NSMutableArray new];
	// IF EXISTS
	if(options & PGQueryOptionIgnoreIfExists) {
		[flags addObject:@"IF EXISTS"];
	}
	return [NSString stringWithFormat:@"DROP ROLE %@%@",[connection quoteIdentifier:roleNames],[flags componentsJoinedByString:@" "]];
}
*/

-(NSString* )_dropTableStatementForConnection:(PGConnection* )connection options:(int)options error:(NSError** )error {
	NSString* tableName = [self table];
	if(tableName==nil) {
		return nil;
	}
	NSMutableArray* flags = [NSMutableArray new];
	// IF EXISTS
	if(options & PGQueryOptionIgnoreIfExists) {
		[flags addObject:@"IF EXISTS"];
	}
	// CASCADE
	if(options & PGQueryOptionDropObjects) {
		[flags addObject:@"CASCADE"];
	} else {
		[flags addObject:@"RESTRICT"];
	}
	// construct tableName from schemaName
	NSString* quotedTableName = nil;
	if([self schema]) {
		quotedTableName = [NSString stringWithFormat:@"%@.%@",[connection quoteIdentifier:tableName],[connection quoteIdentifier:[self schema]]];
	} else {
		quotedTableName = [connection quoteIdentifier:tableName];
	}
	return [NSString stringWithFormat:@"DROP TABLE %@%@",quotedTableName,[flags componentsJoinedByString:@" "]];
}

-(NSString* )_dropViewStatementForConnection:(PGConnection* )connection options:(int)options error:(NSError** )error {
	NSString* tableName = [self table];
	if(tableName==nil) {
		return nil;
	}
	NSMutableArray* flags = [NSMutableArray new];
	// IF EXISTS
	if(options & PGQueryOptionIgnoreIfExists) {
		[flags addObject:@"IF EXISTS"];
	}
	// CASCADE
	if(options & PGQueryOptionDropObjects) {
		[flags addObject:@"CASCADE"];
	} else {
		[flags addObject:@"RESTRICT"];
	}
	// construct tableName from schemaName
	NSString* quotedTableName = nil;
	if([self schema]) {
		quotedTableName = [NSString stringWithFormat:@"%@.%@",[connection quoteIdentifier:tableName],[connection quoteIdentifier:[self schema]]];
	} else {
		quotedTableName = [connection quoteIdentifier:tableName];
	}
	return [NSString stringWithFormat:@"DROP VIEW %@%@",quotedTableName,[flags componentsJoinedByString:@" "]];
}

@end
