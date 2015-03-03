
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

extern NSString* PQQueryClassKey;
NSString* PQQueryCreateDatabaseNameKey = @"PGQueryCreate_database";
NSString* PQQueryCreateSchemaNameKey = @"PGQueryCreate_schema";
NSString* PQQueryCreateRoleNameKey = @"PGQueryCreate_role";
NSString* PQQueryCreateOwnerNameKey = @"PGQueryCreate_owner";

enum {
	PGQueryOptionTypeCreateDatabase = 0x0100000,
	PGQueryOptionTypeCreateSchema   = 0x0200000,
	PGQueryOptionTypeCreateRole     = 0x0400000,
	PGQueryOptionTypeDropDatabase   = 0x0800000,
	PGQueryOptionTypeDropSchema     = 0x1000000,
	PGQueryOptionTypeDropRole       = 0x2000000
};

@implementation PGQueryCreate

+(PGQueryCreate* )createDatabase:(NSString* )databaseName options:(int)options {
	NSParameterAssert(databaseName);
	PGQueryCreate* query = [super queryWithDictionary:@{
		PQQueryClassKey: NSStringFromClass([self class]),
		PQQueryCreateDatabaseNameKey: databaseName
	}];
	[query setOptions:(options | PGQueryOptionTypeCreateDatabase)];
	return query;
}

+(PGQueryCreate* )createSchema:(NSString* )schemaName options:(int)options {
	NSParameterAssert(schemaName);
	PGQueryCreate* query = [super queryWithDictionary:@{
		PQQueryClassKey: NSStringFromClass([self class]),
		PQQueryCreateSchemaNameKey: schemaName
	}];
	[query setOptions:(options | PGQueryOptionTypeCreateSchema)];
	return query;
}

+(PGQueryCreate* )createRole:(NSString* )roleName options:(int)options {
	NSParameterAssert(roleName);
	PGQueryCreate* query = [super queryWithDictionary:@{
		PQQueryClassKey: NSStringFromClass([self class]),
		PQQueryCreateRoleNameKey: roleName
	}];
	[query setOptions:(options | PGQueryOptionTypeCreateRole)];
	return query;
}

+(PGQueryCreate* )dropDatabase:(NSString* )databaseName options:(int)options {
	NSParameterAssert(databaseName);
	PGQueryCreate* query = [super queryWithDictionary:@{
		PQQueryClassKey: NSStringFromClass([self class]),
		PQQueryCreateDatabaseNameKey: databaseName
	}];
	[query setOptions:(options | PGQueryOptionTypeDropDatabase)];
	return query;
}

+(PGQueryCreate* )dropSchema:(NSString* )schemaName options:(int)options {
	NSParameterAssert(schemaName);
	PGQueryCreate* query = [super queryWithDictionary:@{
		PQQueryClassKey: NSStringFromClass([self class]),
		PQQueryCreateSchemaNameKey: schemaName
	}];
	[query setOptions:(options | PGQueryOptionTypeDropSchema)];
	return query;
}

+(PGQueryCreate* )dropRole:(NSString* )roleName options:(int)options {
	NSParameterAssert(roleName);
	PGQueryCreate* query = [super queryWithDictionary:@{
		PQQueryClassKey: NSStringFromClass([self class]),
		PQQueryCreateRoleNameKey: roleName
	}];
	[query setOptions:(options | PGQueryOptionTypeDropRole)];
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

/////////////////////////////////////////////////
// methods

-(NSString* )_createDatabaseStatementForConnection:(PGConnection2* )connection options:(int)options error:(NSError** )error {
	NSString* databaseName = [super objectForKey:PQQueryCreateDatabaseNameKey];
	if([databaseName length]==0) {
		return nil;
	}
	// OWNER
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
	if(options & PGQueryOptionSetConnectionLimit) {
		[flags addObject:[NSString stringWithFormat:@"TABLESPACE %ld",[connection quoteIdentifier:[self connectionLimit]]]];
	}
	return [NSString stringWithFormat:@"CREATE DATABASE %@%@",[connection quoteIdentifier:databaseName],flags];
}

-(NSString* )_dropDatabaseStatementForConnection:(PGConnection2* )connection options:(int)options error:(NSError** )error {
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
	}
	return nil;
}

@end
