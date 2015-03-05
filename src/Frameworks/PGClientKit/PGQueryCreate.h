
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

#import <Foundation/Foundation.h>


/**

 The PGCreateQuery class defines a set of queries to create, drop and alter
 different object types, such as databases, schemas, tables, schemas,
 indexes, views, sequences and constraints. Firstly, you need to create an
 instance of the appropriate type for the operation you're trying to perform,
 and then set the parameter properties necessary (for example, the owner role,
 etc).

 */

enum {
	PGQueryOptionIgnoreIfExists = 0x000001,            // ignore create option if exists
	PGQueryOptionIgnoreIfNotExists = 0x000001,         // ignore drop option if doesn't exist
	PGQueryOptionSetOwner = 0x000002,                  // set the owner for database/schema/role
	PGQueryOptionSetDatabaseTemplate = 0x000004,       // set the template for the new database
	PGQueryOptionSetEncoding = 0x000008,               // set database encoding
	PGQueryOptionSetTablespace = 0x000010,             // set database tablespace
	PGQueryOptionSetConnectionLimit = 0x000020,        // set database/role connection limit
	PGQueryOptionDropObjects = 0x000040,               // drop objects when schema/table is dropped
	PGQueryOptionRolePrivSuperuser = 0x000080,         // set role superuser flag
	PGQueryOptionRolePrivCreateDatabase = 0x000100,    // set role createdb flag
	PGQueryOptionRolePrivCreateRole = 0x000200,        // set role createrole flag
	PGQueryOptionRolePrivInherit = 0x000400,           // inherit privileges from parent role
	PGQueryOptionRolePrivLogin = 0x000800,             // allow login for this role
	PGQueryOptionRolePrivReplication = 0x01000,       // set replication flag for this role
	PGQueryOptionRoleSetPassword = 0x002000,           // set password for role
	PGQueryOptionRoleSetExpiry = 0x004000              // set login expiry for role
};

@interface PGQueryCreate : PGQuery

////////////////////////////////////////////////////////////////////////////////
// create statements

/**
 *  Create a database
 *
 *  @param databaseName The name of the database to create
 *  @param options      Option flags. `PGQueryOptionIgnoreIfExists` can be set if
 *                      the operation should be silently ignored if the database
 *                      already exists.
 *
 *  @return Returns the PGQuery object, or nil if the query could not be created.
 */
+(PGQueryCreate* )createDatabase:(NSString* )databaseName options:(int)options;

/**
 *  Create a schema within the current database
 *
 *  @param schemaName The name of the schema to create
 *  @param options    Option flags. `PGQueryOptionIgnoreIfExists` can be set if
 *                    the operation should be silently ignored if the schema
 *                    already exists.
 *
 *  @return Returns the PGQuery object, or nil if the query could not be created.
 */
+(PGQueryCreate* )createSchema:(NSString* )schemaName options:(int)options;

/**
 *  Create a role/user for the database server
 *
 *  @param roleName The name of the role/user to create
 *  @param options  Option flags. `PGQueryOptionRolePrivSuperuser` should be used
 *                  to make the role a superuser. `PGQueryOptionRolePrivCreateDatabase`
 *                  should be used to allow the role to create databases.
 *                  `PGQueryOptionRolePrivCreateRole` should be used if the role
 *                  should be allowed to create roles. `PGQueryOptionRolePrivInherit`
 *                  should be used to inherit options from the role parent.
 *                  `PGQueryOptionRolePrivLogin` should be used to allow the role
 *                  to login as a user. `PGQueryOptionSetConnectionLimit`
 *                  should be used to set a connection limit for the user.
 *                  TODO
 *
 *  @return Returns the PGQuery object, or nil if the query could not be created.
 */
+(PGQueryCreate* )createRole:(NSString* )roleName options:(int)options;

/*
+(PGQueryCreate* )createTable:(NSString* )tableName schema:(NSString* )schemaName columns:(NSArray* )columns options:(int)options;
+(PGQueryCreate* )createTable:(NSString* )tableName columns:(NSArray* )columns options:(int)options;
+(PGQueryCreate* )createView:(NSString* )viewName query:(PGSelect* )query options:(int)options;
+(PGQueryCreate* )createView:(NSString* )viewName columnNames:(NSArray* )columns query:(PGSelect* )query options:(int)options;
*/

////////////////////////////////////////////////////////////////////////////////
// drop statements

+(PGQueryCreate* )dropDatabase:(NSString* )databaseName options:(int)options;
+(PGQueryCreate* )dropSchema:(NSString* )schemaName options:(int)options;
+(PGQueryCreate* )dropRole:(NSString* )roleName options:(int)options;
+(PGQueryCreate* )dropTables:(NSArray* )tableNames options:(int)options;
+(PGQueryCreate* )dropTable:(NSString* )tableName options:(int)options;

// properties
@property NSString* owner;
@property NSString* template;
@property NSString* encoding;
@property NSString* tablespace;
@property NSString* password;
@property NSInteger connectionLimit;
@property NSDate* expiry;

@end
