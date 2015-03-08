
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

@interface PGQueryDatabase : PGQuery

////////////////////////////////////////////////////////////////////////////////
// constructors

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
+(PGQueryDatabase* )drop:(NSString* )database options:(NSUInteger)options;

/**
 *  Create a query to return the list of databases for the currently selected server
 *
 *  @return Returns the PGQueryDatabase object, or nil if the query could not be created.
 */
+(PGQueryDatabase* )listWithOptions:(NSUInteger)options;

/**
 *  Create a query to rename a database
 *
 *  @param database The name of the database to rename. Cannot be nil or empty.
 *  @param name     The new name for the database. Cannot be nil or empty.
 *
 *  @return Returns the PGQueryDatabase object, or nil if the query could not be created.
 */
+(PGQueryDatabase* )alter:(NSString* )database name:(NSString* )name;

/**
 *  Create a query to set a new owner for the database
 *
 *  @param database The name of the database to rename. Cannot be nil or empty.
 *  @param owner    The role who will take ownership of the database. Cannot be nil or empty.
 *
 *  @return Returns the PGQueryDatabase object, or nil if the query could not be created.
 */
+(PGQueryDatabase* )alter:(NSString* )database owner:(NSString* )owner;

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
 *  @param tablespace    The new tablespace name to use as the default.
 *
 *  @return Returns the PGQueryDatabase object, or nil if the query could not be created.
 */
+(PGQueryDatabase* )alter:(NSString* )database tablespace:(NSString* )tablespace;

////////////////////////////////////////////////////////////////////////////////
// properties

/**
 *  Return the name of the database
 */
@property (readonly) NSString* database;

/**
 *  Return the new name of the dabase when renaming
 */
@property (readonly) NSString* name;

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
 *  The default tablespace for the database
 */
@property NSString* tablespace;

/**
 *  The connection limit to set when creating a database or role. By default,
 *  it is set to -1 which means no connection limit
 */
@property NSInteger connectionLimit;

@end


