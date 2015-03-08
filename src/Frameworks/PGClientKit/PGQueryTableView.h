
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

@interface PGQueryTableView : PGQuery

////////////////////////////////////////////////////////////////////////////////
// constructors

/**
 *  Create a query which can create a table with a set of columns.
 *
 *  @param table   The name of the table to create. Cannot be nil or empty.
 *  @param schema  The name of the schema in which to create the table. If nil, creates in the current schema.
 *  @param columns An array of column specifications
 *  @param options Additional options which affect the creation of the table.
 *
 *  @return Returns a PGQueryTableView object which can be used to create a table
 */
+(PGQueryTableView* )createTable:(NSString* )table schema:(NSString* )schema columns:(NSArray* )columns options:(NSUInteger)options;

/**
 *  Create a query which can create a view based on a query.
 *
 *  @param view     The name of the view to create. Cannot be nil or empty.
 *  @param schema   The name of the schema in which to create the view. If nil, creates in the current schema.
 *  @param select   The query on which to base the view. Can be a PGQuerySelect object or an NSString
 *  @param options  Additional options which affect the creation of the view.
 *
 *  @return Returns a PGQueryTableView object which can be used to create a view
 */
+(PGQueryTableView* )createView:(NSString* )view schema:(NSString* )schema select:(id)select options:(NSUInteger)options;

/**
 *  Drop a table from the currently connected database
 *
 *  @param table      The name of the table to drop
 *  @param schema     The schema name which contains the table. Can be set to nil.
 *  @param options    Option flags. `PGQueryOptionIgnoreNotExists` can be set if
 *                    the operation should be silently ignored if the table
 *                    does not exist. `PGQueryOptionDropObjects` can be set to
 *                    also drop all the objects associated with the table, such as
 *                    views. If not set, then an error is generated if there are
 *                    any objects associated with the table.
 *
 *  @return Returns the PGQueryTableView object, or nil if the query could not be created.
 */
+(PGQueryTableView* )dropTable:(NSString* )table schema:(NSString* )schema options:(NSUInteger)options;

/**
 *  Drop a view from the currently connected database
 *
 *  @param view       The name of the view to drop
 *  @param schema     The schema name which contains the view. Can be set to nil.
 *  @param options    Option flags. `PGQueryOptionIgnoreNotExists` can be set if
 *                    the operation should be silently ignored if the view
 *                    does not exist. `PGQueryOptionDropObjects` can be set to
 *                    also drop all the objects associated with the view. If 
 *                    not set, then an error is generated if there are any 
 *                    objects associated with the view.
 *
 *  @return Returns the PGQueryTableView object, or nil if the query could not be created.
 */
+(PGQueryTableView* )dropView:(NSString* )view schema:(NSString* )schema options:(NSUInteger)options;

////////////////////////////////////////////////////////////////////////////////
// properties

/**
 *  Return the name of the table
 */
@property (readonly) NSString* table;

/**
 *  Return the name of the view
 */
@property (readonly) NSString* view;

/**
 *  Return the name of the schema
 */
@property (readonly) NSString* schema;

/**
 *  Return the select statement used for the view when creating views
 */
@property (readonly) PGQuery* select;

/**
 *  The default tablespace for the database
 */
@property NSString* tablespace;

@end
