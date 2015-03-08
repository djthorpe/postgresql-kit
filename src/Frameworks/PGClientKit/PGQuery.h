
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
 *  Dictionary keys which can be used to refer to properties
 */
extern NSString* PGQueryStatementKey;
extern NSString* PGQueryTableKey;
extern NSString* PGQueryViewKey;
extern NSString* PGQuerySchemaKey;
extern NSString* PGQueryDatabaseKey;
extern NSString* PGQueryAliasKey;
extern NSString* PGQuerySourceKey;
extern NSString* PGQueryColumnsKey;
extern NSString* PGQueryWhereKey;
extern NSString* PGQueryHavingKey;
extern NSString* PGQueryOffsetKey;
extern NSString* PGQueryLimitKey;
extern NSString* PGQueryArgumentsKey;
extern NSString* PGQueryValueKey;
extern NSString* PGQueryOwnerKey;
extern NSString* PGQueryEncodingKey;
extern NSString* PGQueryEncodingKey;
extern NSString* PGQueryTemplateKey;
extern NSString* PGQueryTablespaceKey;
extern NSString* PGQueryConnectionLimitKey;
extern NSString* PGQueryNameKey;
extern NSString* PGQueryRoleKey;
extern NSString* PGQueryPasswordKey;
extern NSString* PGQueryExpiryKey;

/**
 * Flags affecting the query generated
 */
enum {
	PGQueryOptionIgnoreIfExists         = 0x00000001, // ignore if exists
	PGQueryOptionIgnoreIfNotExists      = 0x00000001, // ignore if doesn't exist (same flag as above)
	PGQueryOptionReplaceIfExists        = 0x00000001, // replace if exists (same flag as above)
	PGQueryOptionSetOwner               = 0x00000002, // set the owner
	PGQueryOptionSetDatabaseTemplate    = 0x00000004, // set the template for the new database
	PGQueryOptionSetEncoding            = 0x00000008, // set database encoding
	PGQueryOptionSetTablespace          = 0x00000010, // set database tablespace
	PGQueryOptionSetConnectionLimit     = 0x00000020, // set connection limit
	PGQueryOptionDropObjects            = 0x00000040, // drop objects when schema/table is dropped
	PGQueryOptionRolePrivSuperuser      = 0x00000080, // set role superuser flag
	PGQueryOptionRolePrivCreateDatabase = 0x00000100, // set role createdb flag
	PGQueryOptionRolePrivCreateRole     = 0x00000200, // set role createrole flag
	PGQueryOptionRolePrivInherit        = 0x00000400, // inherit privileges from parent role
	PGQueryOptionRolePrivLogin          = 0x00000800, // allow login for this role
	PGQueryOptionRolePrivReplication    = 0x00001000, // set replication flag for this role
	PGQueryOptionSetPassword            = 0x00002000, // set password for role
	PGQueryOptionSetExpiry              = 0x00004000, // set login expiry for role
	PGQueryOptionSetName                = 0x00008000, // set new name
	PGQueryOptionTemporary              = 0x00010000  // temporary object
};

/**
 * Operation type
 */
enum {
	PGQueryOperationCreate             = 0x010000000,
	PGQueryOperationDrop               = 0x020000000,
	PGQueryOperationAlter              = 0x030000000,
	PGQueryOperationList               = 0x040000000,
	PGQueryOperationMask               = 0xFF0000000
};

/**
 *  The PGQuery class represents a query which can be executed by the database
 *  server, or a statement that can be prepared by the SQL server. The basic
 *  PGQuery class can be used to store SQL statements as strings. Subclasses
 *  such as PGSelect can represent more complicated SQL statements, which can
 *  be constructed programmatically.
 *
 *  Query state is stored within a dictionary, which can be read using the
 *  dictionary property. You can also construct a new query object using the
 *  queryWithDictionary method. In this way you can serialize and deserialize
 *  queries.
 */

@interface PGQuery : PGQueryObject

////////////////////////////////////////////////////////////////////////////////
// constructors

/**
 *  Construct a query from a string
 *
 *  @param statement The SQL statement
 *
 *  @return Returns the query object, or nil if the query object could not
 *          be constructed.
 */
+(PGQuery* )queryWithString:(NSString* )statement;

@end
