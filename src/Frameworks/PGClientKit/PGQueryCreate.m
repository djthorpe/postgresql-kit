
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
NSString* PQQueryCreateDatabaseNameKey = @"PGQueryCreate_database";
NSString* PQQueryCreateSchemaNameKey = @"PGQueryCreate_schema";
NSString* PQQueryCreateRoleNameKey = @"PGQueryCreate_role";
NSString* PQQueryCreateOwnerNameKey = @"PGQueryCreate_owner";
NSString* PQQueryCreateTableNameKey = @"PGQueryCreate_table";

// additional option flags
enum {
	PGQueryOptionTypeCreateDatabase = 0x0100000,
	PGQueryOptionTypeCreateSchema   = 0x0200000,
	PGQueryOptionTypeCreateRole     = 0x0400000,
	PGQueryOptionTypeDropDatabase   = 0x0800000,
	PGQueryOptionTypeDropSchema     = 0x1000000,
	PGQueryOptionTypeDropRole       = 0x2000000,
	PGQueryOptionTypeDropTable      = 0x4000000
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

+(PGQueryCreate* )dropTables:(NSArray* )tableNames options:(int)options {
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
	return query;
}

+(PGQueryCreate* )dropTable:(NSString* )tableName options:(int)options {
	NSParameterAssert(tableName);
	PGQueryCreate* query = [super queryWithDictionary:@{
		PQQueryCreateTableNameKey: tableName
	} class:NSStringFromClass([self class])];
	[query setOptions:(options | PGQueryOptionTypeDropTable)];
	return query;
}

/////////////////////////////////////////////////
// properties

@dynamic owner;
@dynamic template;
@dynamic encoding;
@dynamic tablespace;
@dynamic password;
@dynamic connectionLimit;
@dynamic expiry;

-(NSString* )owner {
	return [super objectForKey:PQQueryCreateOwnerNameKey];
}

-(void)setOwner:(NSString* )owner {
	[super setObject:owner forKey:PQQueryCreateOwnerNameKey];
}

// TODO: add the other dynamic properties in here

/////////////////////////////////////////////////
// methods

-(NSString* )_createDatabaseStatementForConnection:(PGConnection* )connection options:(int)options error:(NSError** )error {
	NSString* databaseName = [super objectForKey:PQQueryCreateDatabaseNameKey];
	if([databaseName length]==0) {
		return nil;
	}
	// FLAGS
	NSMutableArray* flags = [NSMutableArray array];
	if(options & PGQueryOptionSetOwner) {
		[flags addObject:[NSString stringWithFormat:@"OWNER %@",[connection quoteIdentifier:[self owner]]]];
	}
	if(options & PGQueryOptionSetDatabaseTemplate) {
		[flags addObject:[NSString stringWithFormat:@"TEMPLATE %@",[connection quoteIdentifier:[self template]]]];
	}
	if(options & PGQueryOptionSetEncoding) {
		[flags addObject:[NSString stringWithFormat:@"ENCODING %@",[connection quoteIdentifier:[self encoding]]]];
	}
	if(options & PGQueryOptionSetTablespace) {
		[flags addObject:[NSString stringWithFormat:@"TABLESPACE %@",[connection quoteIdentifier:[self tablespace]]]];
	}
	if((options & PGQueryOptionSetConnectionLimit) && [self connectionLimit] != -1) {
		[flags addObject:[NSString stringWithFormat:@"CONNECTION LIMIT %ld",[self connectionLimit]]];
	}
	return [NSString stringWithFormat:@"CREATE DATABASE %@%@",[connection quoteIdentifier:databaseName],[flags componentsJoinedByString:@" "]];
}

-(NSString* )_dropDatabaseStatementForConnection:(PGConnection* )connection options:(int)options error:(NSError** )error {
	NSString* databaseName = [super objectForKey:PQQueryCreateDatabaseNameKey];
	if([databaseName length]==0) {
		return nil;
	}
	// IF EXISTS
	NSString* flags = @"";
	if(options & PGQueryOptionIgnoreIfExists) {
		flags = @" IF EXISTS";
	}
	return [NSString stringWithFormat:@"DROP DATABASE %@%@",[connection quoteIdentifier:databaseName],flags];
}

-(NSString* )statementForConnection:(PGConnection* )connection error:(NSError** )error {
	NSParameterAssert(connection);
	int options = [super options];
	if(options & PGQueryOptionTypeCreateDatabase) {
		return [self _createDatabaseStatementForConnection:connection options:options error:error];
	} else if(options & PGQueryOptionTypeCreateSchema) {
		return @"-- NOT IMPLEMENTED --";
	} else if(options & PGQueryOptionTypeCreateRole) {
		return @"-- NOT IMPLEMENTED --";
	} else if(options & PGQueryOptionTypeDropDatabase) {
		return [self _dropDatabaseStatementForConnection:connection options:options error:error];
	} else if(options & PGQueryOptionTypeDropSchema) {
		return @"-- NOT IMPLEMENTED --";
	} else if(options & PGQueryOptionTypeDropRole) {
		return @"-- NOT IMPLEMENTED --";
	} else if(options & PGQueryOptionTypeDropTable) {
		return @"-- NOT IMPLEMENTED --";
	}
	return nil;
}

@end
