
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
 *  The PGQuerySource class represents a source of data, either a single table,
 *  view or a table join.
 */

@interface PGQuerySource : PGQueryObject

////////////////////////////////////////////////////////////////////////////////
// constructors

/**
 *  Construct a simple data source, which represents a table name without a
 *  named schema. Optionally, refer to an alias for the datasource.
 *
 *  @param table     The identifer of the table to refer to
 *  @param alias     The alias to use for the data source. Can be nil when not
 *                   using aliases.
 *
 *  @return returns the constructed data source object
 */
+(PGQuerySource* )table:(NSString* )table alias:(NSString* )alias;

/**
 *  Construct a simple data source, which represents a table name with a
 *  named schema. Optionally, refer to an alias for the datasource.
 *
 *  @param table      The identifer of the table to refer to
 *  @param schema     The schema that contains the table. Can be nil to use
 *                    the schema search path to locate the table.
 *  @param alias      The alias to use for the data source. Can be nil when not
 *                    using aliases.
 *
 *  @return returns the constructed data source object
 */
+(PGQuerySource* )table:(NSString* )table schema:(NSString* )schema alias:(NSString* )alias;

/**
 *  Construct a joined data source, between two other sources. Optionally, a 
 *  predicate provides the expression on which to make the join. If excluded,
 *  the join is a full cross join.
 *
 *  @param lhs       A PGQuerySource object for the left hand side of the join
 *  @param rhs       A PGQuerySource object for the right hand side of the join
 *  @param predicate An optional NSString or PGQueryPredicate object used for the join
 *  @param options   The type of join to make, or 0
 *
 *  @return returns the constructed data source object
 */
+(PGQuerySource* )join:(PGQuerySource* )lhs with:(PGQuerySource* )rhs on:(id)predicate options:(NSUInteger)options;


/**
 *  Construct a joined data source, between two other sources. Optionally, a 
 *  predicate provides the expression on which to make the join. If excluded,
 *  the join is a full cross join.
 *
 *  @param lhs       A PGQuerySource object for the left hand side of the join
 *  @param rhs       A PGQuerySource object for the right hand side of the join
 *  @param predicate An optional NSString or PGQueryPredicate object used for the join
 *
 *  @return returns the constructed data source object
 */
+(PGQuerySource* )join:(PGQuerySource* )lhs with:(PGQuerySource* )rhs on:(id)predicate;

////////////////////////////////////////////////////////////////////////////////
// methods

/**
 *  This method generates a quoted string suitable for using within an SQL 
 *  statement. On error, this method will return nil and set the error object.
 *
 *  @param connection The connection for which the statement should be
 *                    generated. Due to differing versions of the connected
 *                    server, the statement generated might differ depending
 *                    on the server version.
 *  @param withAlias  If YES then the alias is quoted after the datasource names
 *  @param error      On statement generation error, the error parameter is
 *                    set to describe why a statement cannot be generated.
 *
 *  @return Returns the statement on success, or nil on error.
 */
-(NSString* )quoteForConnection:(PGConnection* )connection withAlias:(BOOL)withAlias error:(NSError** )error;

@end
