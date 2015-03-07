
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

// options
enum {
	PGQueryOptionIgnoreIfExists         = 0x00000001, // ignore create option if exists
	PGQueryOptionIgnoreIfNotExists      = 0x00000001, // ignore drop option if doesn't exist
	PGQueryOptionSetOwner               = 0x00000002, // set the owner for database/schema/role
	PGQueryOptionSetDatabaseTemplate    = 0x00000004, // set the template for the new database
	PGQueryOptionSetEncoding            = 0x00000008, // set database encoding
	PGQueryOptionSetTablespace          = 0x00000010, // set database tablespace
	PGQueryOptionSetConnectionLimit     = 0x00000020, // set database/role connection limit
	PGQueryOptionDropObjects            = 0x00000040, // drop objects when schema/table is dropped
	PGQueryOptionRolePrivSuperuser      = 0x00000080, // set role superuser flag
	PGQueryOptionRolePrivCreateDatabase = 0x00000100, // set role createdb flag
	PGQueryOptionRolePrivCreateRole     = 0x00000200, // set role createrole flag
	PGQueryOptionRolePrivInherit        = 0x00000400, // inherit privileges from parent role
	PGQueryOptionRolePrivLogin          = 0x00000800, // allow login for this role
	PGQueryOptionRolePrivReplication    = 0x00001000, // set replication flag for this role
	PGQueryOptionRoleSetPassword        = 0x00002000, // set password for role
	PGQueryOptionRoleSetExpiry          = 0x00004000  // set login expiry for role
};

@interface PGQueryDatabase : PGQuery

/**
 *  Create a database
 *
 *  @param database     The name of the database to create
 *  @param options      Option flags. `PGQueryOptionIgnoreIfExists` can be set if
 *                      the operation should be silently ignored if the database
 *                      already exists.
 *
 *  @return Returns the PGQueryDatabase object, or nil if the query could not be created.
 */
+(PGQueryDatabase* )create:(NSString* )database options:(NSUInteger)options;


/**
 *  Drop a database from the connected server
 *
 *  @param database     The name of the database to drop
 *  @param options      Option flags. `PGQueryOptionIgnoreNotExists` can be set if
 *                      the operation should be silently ignored if the database
 *                      does not exist.
 *
 *  @return Returns the PGQueryDatabase object, or nil if the query could not be created.
 */
+(PGQueryDatabase* )drop:(NSString* )databaseName options:(NSUInteger)options;

/**
 *  Create a query to return the list of databases for the currently selected server
 *
 *  @return Returns the PGQueryDatabase object, or nil if the query could not be created.
 */
+(PGQueryDatabase* )list;

/**
 *  Create a query to rename a database
 *
 *  @param database The name of the database to rename. Cannot be nil or empty.
 *  @param newName  The new name for the database. Cannot be nil or empty.
 *
 *  @return Returns the PGQueryDatabase object, or nil if the query could not be created.
 */
+(PGQueryDatabase* )alter:(NSString* )database name:(NSString* )newName;

/**
 *  Create a query to set a new owner for the database
 *
 *  @param database The name of the database to rename. Cannot be nil or empty.
 *  @param newOwner The role who will take ownership of the database. Cannot be nil or empty.
 *
 *  @return Returns the PGQueryDatabase object, or nil if the query could not be created.
 */
+(PGQueryDatabase* )alter:(NSString* )database owner:(NSString* )newOwner;

/**
 *  Create a query to set a new connection limit for the database
 *
 *  @param database        The name of the database to set the connection limit for. Cannot be nil or empty.
 *  @param connectionLimit New connection limit. Can be 0 for no connections or -1 for unlimited, otherwise
 *                         the new connection limit can be set as a positive integer.
 *
 *  @return Returns the PGQueryDatabase object, or nil if the query could not be created.
 */
+(PGQueryDatabase* )alter:(NSString* )database connectionLimit:(NSInteger)connectionLimit;

/**
 *  Create a query to set a new default tablespace for the database
 *
 *  @param database      The name of the database. Cannot be nil or empty.
 *  @param newTablespace The new tablespace name to use as the default.
 *
 *  @return Returns the PGQueryDatabase object, or nil if the query could not be created.
 */
+(PGQueryDatabase* )alter:(NSString* )database tablespace:(NSString* )newTablespace;

@end


