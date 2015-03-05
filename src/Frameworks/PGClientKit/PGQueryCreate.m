
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
// properties

@dynamic table;
@dynamic database;
@dynamic schema;
@dynamic role;
@dynamic owner;
@dynamic expiry;
@dynamic connectionLimit;
@dynamic password;
@dynamic encoding;
@dynamic template;
@dynamic tablespace;

-(NSString* )owner {
	return [super objectForKey:PQQueryCreateOwnerNameKey];
}

-(void)setOwner:(NSString* )owner {
	if([owner length]==0) {
		[super removeObjectForKey:PQQueryCreateOwnerNameKey];
	} else {
		[super setObject:owner forKey:PQQueryCreateOwnerNameKey];
	}
}

-(NSString* )schema {
	NSString* schema = [super objectForKey:PQQueryCreateSchemaNameKey];
	return ([schema length]==0) ? nil : schema;
}

-(void)setSchema:(NSString* )schema {
	if([schema length]==0) {
		[super removeObjectForKey:PQQueryCreateSchemaNameKey];
	} else {
		[super setObject:schema forKey:PQQueryCreateSchemaNameKey];
	}
}

-(NSString* )table {
	NSString* table = [super objectForKey:PQQueryCreateTableNameKey];
	return ([table length]==0) ? nil : table;
}

-(void)setTable:(NSString* )table {
	if([table length]==0) {
		[super removeObjectForKey:PQQueryCreateTableNameKey];
	} else {
		[super setObject:table forKey:PQQueryCreateTableNameKey];
	}
}

-(NSString* )database {
	NSString* database = [super objectForKey:PQQueryCreateDatabaseNameKey];
	return ([database length]==0) ? nil : database;
}

-(void)setDatabase:(NSString* )database {
	if([database length]==0) {
		[super removeObjectForKey:PQQueryCreateDatabaseNameKey];
	} else {
		[super setObject:database forKey:PQQueryCreateDatabaseNameKey];
	}
}

-(NSString* )role {
	NSString* role = [super objectForKey:PQQueryCreateRoleNameKey];
	return ([role length]==0) ? nil : role;
}

-(void)setRole:(NSString* )role {
	if([role length]==0) {
		[super removeObjectForKey:PQQueryCreateRoleNameKey];
	} else {
		[super setObject:role forKey:PQQueryCreateRoleNameKey];
	}
}

-(NSDate* )expiry {
	return [super objectForKey:PQQueryCreateExpiryKey];
}

-(void)setExpiry:(NSDate* )date {
	if(date==nil) {
		[super removeObjectForKey:PQQueryCreateExpiryKey];
	} else {
		[super setObject:date forKey:PQQueryCreateExpiryKey];
	}
}

-(NSString* )encoding {
	NSString* encoding = [super objectForKey:PQQueryCreateEncodingKey];
	return ([encoding length]==0) ? nil : encoding;
}

-(void)setEncoding:(NSString* )encoding {
	if([encoding length]==0) {
		[super removeObjectForKey:PQQueryCreateEncodingKey];
	} else {
		[super setObject:encoding forKey:PQQueryCreateEncodingKey];
	}
}

-(NSInteger)connectionLimit {
	NSNumber* connectionLimit = [super objectForKey:PQQueryCreateConnectionLimitKey];
	if(connectionLimit==nil || [connectionLimit isKindOfClass:[NSNumber class]]==NO) {
		return -1;
	}
	return [connectionLimit integerValue];
}

-(void)setConnectionLimit:(NSInteger)connectionLimit {
	if(connectionLimit < 0) {
		[super removeObjectForKey:PQQueryCreateConnectionLimitKey];
	} else {
		[super setObject:[NSNumber numberWithInteger:connectionLimit] forKey:PQQueryCreateConnectionLimitKey];
	}
}

-(NSString* )password {
	NSString* password = [super objectForKey:PQQueryCreatePasswordKey];
	return ([password length]==0) ? nil : password;
}

/**
 *  Store password in the dictionary. Note that passwords are not stored
 *  encrypted. It might be better to store the encrypted password and implement
 *  a method setPassword:role: instead
 */
-(void)setPassword:(NSString* )password {
	if([password length]==0) {
		[super removeObjectForKey:PQQueryCreatePasswordKey];
	} else {
		[super setObject:password forKey:PQQueryCreatePasswordKey];
	}
}

-(NSString* )tablespace {
	NSString* tablespace = [super objectForKey:PQQueryCreateTablespaceKey];
	return ([tablespace length]==0) ? nil : tablespace;
}

-(void)setTablespace:(NSString* )tablespace {
	if([tablespace length]==0) {
		[super removeObjectForKey:PQQueryCreateTablespaceKey];
	} else {
		[super setObject:tablespace forKey:PQQueryCreateTablespaceKey];
	}
}

-(NSString* )template {
	NSString* template = [super objectForKey:PQQueryCreateTemplateKey];
	return ([template length]==0) ? nil : template;
}

-(void)setTemplate:(NSString* )template {
	if([template length]==0) {
		[super removeObjectForKey:PQQueryCreateTemplateKey];
	} else {
		[super setObject:template forKey:PQQueryCreateTemplateKey];
	}
}

/////////////////////////////////////////////////
// methods

-(NSString* )_createDatabaseStatementForConnection:(PGConnection* )connection options:(int)options error:(NSError** )error {
	NSString* databaseName = [super objectForKey:PQQueryCreateDatabaseNameKey];
	if([databaseName length]==0) {
		return nil;
	}
	// FLAGS
	NSMutableArray* flags = [NSMutableArray array];
	if(options & PGQueryOptionSetOwner && [self owner]) {
		[flags addObject:[NSString stringWithFormat:@"OWNER %@",[connection quoteIdentifier:[self owner]]]];
	}
	if(options & PGQueryOptionSetDatabaseTemplate && [self template]) {
		[flags addObject:[NSString stringWithFormat:@"TEMPLATE %@",[connection quoteIdentifier:[self template]]]];
	}
	if(options & PGQueryOptionSetEncoding && [self encoding]) {
		[flags addObject:[NSString stringWithFormat:@"ENCODING %@",[connection quoteString:[self encoding]]]];
	}
	if(options & PGQueryOptionSetTablespace && [self tablespace]) {
		[flags addObject:[NSString stringWithFormat:@"TABLESPACE %@",[connection quoteIdentifier:[self tablespace]]]];
	} else {
		[flags addObject:@"TABLESPACE DEFAULT"];
	}
	if((options & PGQueryOptionSetConnectionLimit) && [self connectionLimit] != -1) {
		[flags addObject:[NSString stringWithFormat:@"CONNECTION LIMIT %ld",[self connectionLimit]]];
	}
	return [NSString stringWithFormat:@"CREATE DATABASE %@%@",[connection quoteIdentifier:databaseName],[flags componentsJoinedByString:@" "]];
}

-(NSString* )_createRoleStatementForConnection:(PGConnection* )connection options:(int)options error:(NSError** )error {
	NSString* roleName = [self role];
	if(roleName==nil) {
		return nil;
	}
	NSMutableArray* flags = [NSMutableArray new];
	if(options & PGQueryOptionRolePrivSuperuser) {
		[flags addObject:@"SUPERUSER"];
	} else {
		[flags addObject:@"NOSUPERUSER"];
	}
	if(options & PGQueryOptionRolePrivCreateDatabase) {
		[flags addObject:@"CREATEDB"];
	} else {
		[flags addObject:@"NOCREATEDB"];
	}
	if(options & PGQueryOptionRolePrivCreateRole) {
		[flags addObject:@"CREATEROLE"];
	} else {
		[flags addObject:@"NOCREATEROLE"];
	}
	if(options & PGQueryOptionRolePrivInherit) {
		[flags addObject:@"INHERIT"];
	} else {
		[flags addObject:@"NOINHERIT"];
	}
	if(options & PGQueryOptionRolePrivLogin) {
		[flags addObject:@"LOGIN"];
	} else {
		[flags addObject:@"NOLOGIN"];
	}
	if(options & PGQueryOptionRolePrivReplication) {
		[flags addObject:@"REPLICATION"];
	} else {
		[flags addObject:@"NOREPLICATION"];
	}
	if((options & PGQueryOptionSetConnectionLimit) && [self connectionLimit] != -1) {
		[flags addObject:[NSString stringWithFormat:@"CONNECTION LIMIT %ld",[self connectionLimit]]];
	}
	if(options & PGQueryOptionRoleSetPassword && [self password]) {
		NSString* encryptedPassword = [connection encryptedPassword:[self password] role:roleName];
		[flags addObject:[NSString stringWithFormat:@"ENCRYPTED PASSWORD %@",[connection quoteString:encryptedPassword]]];
	}
	if(options & PGQueryOptionRoleSetExpiry && [self expiry]) {
		NSString* expiryDate = [[self expiry] description];
		[flags addObject:[NSString stringWithFormat:@"VALID UNTIL %@",[connection quoteString:expiryDate]]];
	}
	if(options & PGQueryOptionSetOwner && [self owner]) {
		[flags addObject:[NSString stringWithFormat:@"IN ROLE %@",[connection quoteIdentifier:[self owner]]]];
	}
	NSString* q = [connection quoteIdentifier:roleName];
	NSString* f = [flags componentsJoinedByString:@" "];
	return [NSString stringWithFormat:@"CREATE ROLE %@ %@",q,f];
}

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

-(NSString* )_dropDatabaseStatementForConnection:(PGConnection* )connection options:(int)options error:(NSError** )error {
	NSString* databaseName = [self database];
	if(databaseName==nil) {
		return nil;
	}
	NSMutableArray* flags = [NSMutableArray new];
	// IF EXISTS
	if(options & PGQueryOptionIgnoreIfExists) {
		[flags addObject:@"IF EXISTS"];
	}
	return [NSString stringWithFormat:@"DROP DATABASE %@%@",[connection quoteIdentifier:databaseName],[flags componentsJoinedByString:@" "]];
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

-(NSString* )statementForConnection:(PGConnection* )connection error:(NSError** )error {
	NSParameterAssert(connection);
	int options = [super options];
	if(options & PGQueryOptionTypeCreateDatabase) {
		return [self _createDatabaseStatementForConnection:connection options:options error:error];
	} else if(options & PGQueryOptionTypeCreateSchema) {
		return [self _createSchemaStatementForConnection:connection options:options error:error];
	} else if(options & PGQueryOptionTypeCreateRole) {
		return [self _createRoleStatementForConnection:connection options:options error:error];
	} else if(options & PGQueryOptionTypeDropDatabase) {
		return [self _dropDatabaseStatementForConnection:connection options:options error:error];
	} else if(options & PGQueryOptionTypeDropSchema) {
		return [self _dropSchemaStatementForConnection:connection options:options error:error];
	} else if(options & PGQueryOptionTypeDropRole) {
		return [self _dropRoleStatementForConnection:connection options:options error:error];
	} else if(options & PGQueryOptionTypeDropTable) {
		return [self _dropTableStatementForConnection:connection options:options error:error];
	} else if(options & PGQueryOptionTypeDropView) {
		return [self _dropViewStatementForConnection:connection options:options error:error];
	} else {
		NSLog(@"TODO: RAISE ERROR");
		return nil;
	}
}

@end
