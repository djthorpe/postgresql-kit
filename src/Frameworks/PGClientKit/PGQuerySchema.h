
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

@interface PGQuerySchema : PGQuery

////////////////////////////////////////////////////////////////////////////////
// constructors

/**
 *  Create a schema within the current database
 *
 *  @param schema     The name of the schema to create
 *  @param options    Option flags. `PGQueryOptionIgnoreIfExists` can be set if
 *                    the operation should be silently ignored if the schema
 *                    already exists.
 *
 *  @return Returns the PGQuerySchema object, or nil if the query could not be created.
 */
+(PGQuerySchema* )create:(NSString* )schema options:(NSUInteger)options;

/**
 *  Drop a schema from the currently connected database
 *
 *  @param schema       The name of the schema to drop
 *  @param options      Option flags. `PGQueryOptionIgnoreNotExists` can be set if
 *                      the operation should be silently ignored if the database
 *                      does not exist. `PGQueryOptionDropObjects` can be set to
 *                      also drop all the objects within the schema. If not set,
 *                      then an error is generated if there are any objects in the
 *                      schema.
 *
 *  @return Returns the PGQuerySchema object, or nil if the query could not be created.
 */
+(PGQuerySchema* )drop:(NSString* )schema options:(NSUInteger)options;

/**
 *  Create a query to rename the schema
 *
 *  @param schema   The name of the schema to rename. Cannot be nil or empty.
 *  @param name     The new name for the schema. Cannot be nil or empty.
 *
 *  @return Returns the PGQuerySchema object, or nil if the query could not be created.
 */
+(PGQuerySchema* )alter:(NSString* )schema name:(NSString* )name;

/**
 *  Create a query to set a new owner for the schema
 *
 *  @param schema   The name of the schema to rename. Cannot be nil or empty.
 *  @param owner    The role who will take ownership of the schema. Cannot be nil or empty.
 *
 *  @return Returns the PGQuerySchema object, or nil if the query could not be created.
 */
+(PGQuerySchema* )alter:(NSString* )schema owner:(NSString* )owner;

/**
 *  Create a query to return the list of schemas in the currently selected database
 *
 *  @param options Options which affect the output of the query
 *
 *  @return Returns the PGQuerySchema object, or nil if the query could not be created.
 */
+(PGQuerySchema* )listWithOptions:(NSUInteger)options;

/**
 *  Create a query to return the list of objects for a particular schema
 *
 *  @param schema  The schema for which to obtain a list of objects
 *  @param options Option flags. Currently unused.
 *
 *  @return Returns the PGQuerySchema object, or nil if the query could not be created.
 */
// TODO: Implement
// +(PGQuerySchema* )objectsForSchema:(NSString* )schema options:(NSUInteger)options;

////////////////////////////////////////////////////////////////////////////////
// properties

/**
 *  Return the name of the schema
 */
@property (readonly) NSString* schema;

/**
 *  Return the new name of the schema when renaming
 */
@property (readonly) NSString* name;

/**
 *  The owner for the schema
 */
@property NSString* owner;

@end
