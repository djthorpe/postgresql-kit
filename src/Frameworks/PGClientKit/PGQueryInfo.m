
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
NSString* PQQueryInfoTableNameKey = @"PGQueryInfo_table";
NSString* PQQueryInfoSchemaNameKey = @"PGQueryInfo_schema";
NSString* PQQueryInfoRoleNameKey = @"PGQueryInfo_role";

// additional option flags
enum {
	PGQueryOptionTypeInfoSchemas     = 0x0100000,
	PGQueryOptionTypeInfoRoles       = 0x0200000,
	PGQueryOptionTypeInfoTablesViews = 0x0400000,
	PGQueryOptionTypeInfoColumns     = 0x0400000
};

@implementation PGQueryInfo

////////////////////////////////////////////////////////////////////////////////
// constructors

+(PGQueryInfo* )schemas {
	PGQueryInfo* query = [super queryWithDictionary:@{ } class:NSStringFromClass([self class])];
	[query setOptions:PGQueryOptionTypeInfoSchemas];
	return query;
}

+(PGQueryInfo* )roles {
	PGQueryInfo* query = [super queryWithDictionary:@{ } class:NSStringFromClass([self class])];
	[query setOptions:PGQueryOptionTypeInfoRoles];
	return query;
}

+(PGQueryInfo* )tablesAndViewsForSchema:(NSString* )schemaName options:(int)options {
	PGQueryInfo* query = [super queryWithDictionary:@{ } class:NSStringFromClass([self class])];
	[query setSchema:schemaName];
	[query setOptions:(options | PGQueryOptionTypeInfoTablesViews)];
	return query;
}

+(PGQueryInfo* )columnsForTable:(NSString* )tableName schema:(NSString* )schemaName options:(int)options {
	NSParameterAssert(tableName);
	PGQueryInfo* query = [super queryWithDictionary:@{
		PQQueryInfoTableNameKey: tableName
	} class:NSStringFromClass([self class])];
	[query setSchema:schemaName];
	[query setOptions:(options | PGQueryOptionTypeInfoTablesViews)];
	return query;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic table;
@dynamic schema;
@dynamic role;

-(NSString* )schema {
	NSString* schema = [super objectForKey:PQQueryInfoSchemaNameKey];
	return ([schema length]==0) ? nil : schema;
}

-(void)setSchema:(NSString* )schema {
	if([schema length]==0) {
		[super removeObjectForKey:PQQueryInfoSchemaNameKey];
	} else {
		[super setObject:schema forKey:PQQueryInfoSchemaNameKey];
	}
}

-(NSString* )table {
	NSString* table = [super objectForKey:PQQueryInfoTableNameKey];
	return ([table length]==0) ? nil : table;
}

-(void)setTable:(NSString* )table {
	if([table length]==0) {
		[super removeObjectForKey:PQQueryInfoTableNameKey];
	} else {
		[super setObject:table forKey:PQQueryInfoTableNameKey];
	}
}

-(NSString* )role {
	NSString* role = [super objectForKey:PQQueryInfoRoleNameKey];
	return ([role length]==0) ? nil : role;
}

-(void)setRole:(NSString* )role {
	if([role length]==0) {
		[super removeObjectForKey:PQQueryInfoRoleNameKey];
	} else {
		[super setObject:role forKey:PQQueryInfoRoleNameKey];
	}
}

////////////////////////////////////////////////////////////////////////////////
// methods

-(NSString* )_schemasForConnection:(PGConnection* )connection options:(int)options error:(NSError** )error {

	NSMutableArray* columns = [NSMutableArray new];
	[columns addObject:@"n.nspname AS schema"];
	[columns addObject:@"pg_catalog.pg_get_userbyid(n.nspowner) AS owner"];
	[columns addObject:@"n.nspacl AS access_privileges"];
	[columns addObject:@"pg_catalog.obj_description(n.oid, 'pg_namespace') AS description"];

	NSMutableArray* parts = [NSMutableArray new];
	[parts addObject:@"SELECT"];
	[parts addObject:[columns componentsJoinedByString:@","]];
	[parts addObject:@"FROM pg_catalog.pg_namespace n"];
	[parts addObject:@"WHERE n.nspname !~ '^pg_'"];
	[parts addObject:@"AND n.nspname <> 'information_schema'"];
	[parts addObject:@"ORDER BY 1"];

	return [parts componentsJoinedByString:@" "];
}

-(NSString* )_rolesForConnection:(PGConnection* )connection options:(int)options error:(NSError** )error {
	NSMutableArray* columns = [NSMutableArray new];
	[columns addObject:@"r.rolname AS role"];
	[columns addObject:@"r.rolsuper AS superuser"];
	[columns addObject:@"r.rolinherit AS inherit"];
	[columns addObject:@"r.rolcreaterole AS createrole"];
	[columns addObject:@"r.rolcreatedb AS createdb"];
	[columns addObject:@"r.rolcanlogin AS login"];
	[columns addObject:@"r.rolconnlimit AS connection_limit"];
	[columns addObject:@"r.rolvaliduntil AS expiry"];
	[columns addObject:@"r.rolreplication AS replication"];
	[columns addObject:@"ARRAY(SELECT b.rolname FROM pg_catalog.pg_auth_members m JOIN pg_catalog.pg_roles b ON (m.roleid = b.oid) WHERE m.member = r.oid) as memberof"];
	[columns addObject:@"pg_catalog.shobj_description(r.oid, 'pg_authid') AS description"];

	NSMutableArray* parts = [NSMutableArray new];
	[parts addObject:@"SELECT"];
	[parts addObject:[columns componentsJoinedByString:@","]];
	[parts addObject:@"FROM pg_catalog.pg_roles r"];
	[parts addObject:@"ORDER BY 1"];

	return [parts componentsJoinedByString:@" "];
}

-(NSString* )_tablesForConnection:(PGConnection* )connection options:(int)options error:(NSError** )error {
//SELECT n.nspname as "schema",c.relname as "table",CASE c.relkind WHEN 'r' THEN 'table' WHEN 'v' THEN 'view' WHEN 'i' THEN 'index' WHEN 'S' THEN 'sequence' WHEN 's' THEN 'special' WHEN 'f' THEN 'foreign_table' END as "type",pg_catalog.pg_get_userbyid(c.relowner) as "owner" FROM pg_catalog.pg_class c LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE c.relkind IN ('r','') AND n.nspname <> 'pg_catalog' AND n.nspname <> 'information_schema' AND n.nspname !~ '^pg_toast' AND pg_catalog.pg_table_is_visible(c.oid) ORDER BY 1,2;
	return @"--NOT IMPLEMENTED--";
}

-(NSString* )_columnsForConnection:(PGConnection* )connection options:(int)options error:(NSError** )error {
	return @"--NOT IMPLEMENTED--";
}

-(NSString* )statementForConnection:(PGConnection* )connection error:(NSError** )error {
	NSParameterAssert(connection);
	int options = [super options];
	if(options & PGQueryOptionTypeInfoSchemas) {
		return [self _schemasForConnection:connection options:options error:error];
	} else if(options & PGQueryOptionTypeInfoRoles) {
		return [self _rolesForConnection:connection options:options error:error];
	} else if(options & PGQueryOptionTypeInfoTablesViews) {
		return [self _tablesForConnection:connection options:options error:error];
	} else if(options & PGQueryOptionTypeInfoColumns) {
		return [self _columnsForConnection:connection options:options error:error];
	} else {
		NSLog(@"TODO: RAISE ERROR");
		return nil;
	}
}



@end
