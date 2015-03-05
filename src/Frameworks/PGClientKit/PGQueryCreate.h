
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
	PGQueryOptionRolePrivReplication = 0x01000,        // set replication flag for this role
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
 *  Create a role/user for the connected server
 *
 *  @param roleName The name of the role/user to create
 *  @param options  Option flags:
 *                    * `PGQueryOptionRolePrivSuperuser` should be used to make the role a superuser.
 *                    * `PGQueryOptionRolePrivCreateDatabase`should be used to allow the role to create databases.
 *                    * `PGQueryOptionRolePrivCreateRole` should be used if the role should be allowed to create roles.
 *                    * `PGQueryOptionRolePrivInherit` should be used to inherit options from the role parent.
 *                    * `PGQueryOptionRolePrivLogin` should be used to allow the role to login as a user.
 *                    * `PGQueryOptionSetConnectionLimit` should be used to set a connection limit for the user.
 *                    * `
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

/**
 *  Drop a database from the connected server
 *
 *  @param databaseName The name of the database to drop
 *  @param options      Option flags. `PGQueryOptionIgnoreNotExists` can be set if
 *                      the operation should be silently ignored if the database
 *                      does not exist.
 *
 *  @return Returns the PGQuery object, or nil if the query could not be created.
 */
+(PGQueryCreate* )dropDatabase:(NSString* )databaseName options:(int)options;

/**
 *  Drop a schema from the currently connected database
 *
 *  @param databaseName The name of the schema to drop
 *  @param options      Option flags. `PGQueryOptionIgnoreNotExists` can be set if
 *                      the operation should be silently ignored if the database
 *                      does not exist. `PGQueryOptionDropObjects` can be set to
 *                      also drop all the objects within the schema. If not set,
 *                      then an error is generated if there are any objects in the
 *                      schema.
 *
 *  @return Returns the PGQuery object, or nil if the query could not be created.
 */
+(PGQueryCreate* )dropSchema:(NSString* )schemaName options:(int)options;

/**
 *  Drop a role from the currently connected server
 *
 *  @param roleName The name of the role to drop
 *  @param options  Option flags. `PGQueryOptionIgnoreNotExists` can be set if
 *                      the operation should be silently ignored if the role
 *                      does not exist.
 *
 *  @return Returns the PGQuery object, or nil if the query could not be created.
 */
+(PGQueryCreate* )dropRole:(NSString* )roleName options:(int)options;

/**
 *  Drop multiple tables from the currently connected database
 *
 *  @param tableNames An array of table names
 *  @param schemaName The schema name which contains the tables. Can be set to nil.
 *  @param options    Option flags. `PGQueryOptionIgnoreNotExists` can be set if
 *                    the operation should be silently ignored if any table
 *                    does not exist. `PGQueryOptionDropObjects` can be set to
 *                    also drop all the objects associated with the tables, such as
 *                    views. If not set, then an error is generated if there are
 *                    any objects associated with the tables.
 *
 *  @return Returns the PGQuery object, or nil if the query could not be created.
 */
+(PGQueryCreate* )dropTables:(NSArray* )tableNames schema:(NSString* )schemaName options:(int)options;

/**
 *  Drop a table from the currently connected database
 *
 *  @param tableName  The name of the table to drop
 *  @param schemaName The schema name which contains the table. Can be set to nil.
 *  @param options    Option flags. `PGQueryOptionIgnoreNotExists` can be set if
 *                    the operation should be silently ignored if the table
 *                    does not exist. `PGQueryOptionDropObjects` can be set to
 *                    also drop all the objects associated with the table, such as
 *                    views. If not set, then an error is generated if there are
 *                    any objects associated with the table.
 *
 *  @return Returns the PGQuery object, or nil if the query could not be created.
 */
+(PGQueryCreate* )dropTable:(NSString* )tableName schema:(NSString* )schemaName options:(int)options;

/**
 *  Drop a view from the currently connected database
 *
 *  @param viewName   The name of the view to drop
 *  @param schemaName The schema name which contains the view. Can be set to nil.
 *  @param options    Option flags. `PGQueryOptionIgnoreNotExists` can be set if
 *                    the operation should be silently ignored if the view
 *                    does not exist. `PGQueryOptionDropObjects` can be set to
 *                    also drop all the objects associated with the view. If 
 *                    not set, then an error is generated if there are any 
 *                    objects associated with the view.
 *
 *  @return Returns the PGQuery object, or nil if the query could not be created.
 */
+(PGQueryCreate* )dropView:(NSString* )viewName schema:(NSString* )schemaName options:(int)options;

////////////////////////////////////////////////////////////////////////////////
// properties

/**
 *  The name of the table or view
 */
@property NSString* table;

/**
 *  The name of the schema
 */
@property NSString* schema;

/**
 *  The name of the database
 */
@property NSString* database;

/**
 *  The name of the role
 */
@property NSString* role;

/**
 *  The owner for the database or role
 */
@property NSString* owner;

/**
 *  The template to use when creating a database
 */
@property NSString* template;

/**
 *  The character encoding to use when creating a database
 */
@property NSString* encoding;

/**
 *  The tablespace for the database and/or table
 */
@property NSString* tablespace;

/**
 *  The password to use when creating a role (will automatically be encrypted)
 */
@property NSString* password;

/**
 *  The connection limit to set when creating a database or role. By default,
 *  it is set to -1 which means no connection limit
 */
@property NSInteger connectionLimit;

/**
 *  The expiry date to set for role login, when creating roles. Can be set
 *  to nil which indicates no expiry limit.
 */
@property NSDate* expiry;

@end
