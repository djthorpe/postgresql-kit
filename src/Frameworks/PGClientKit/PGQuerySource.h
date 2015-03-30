
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
 *  @param options   The type of join to make. The join can be one of 
 *                   PGQueryOptionJoinCross (the default), PGQueryOptionJoinInner, 
 *                   PGQueryOptionJoinLeftOuter, PGQueryOptionJoinRightOuter,
 *                   PGQueryOptionJoinFullOuter
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
// properties

/**
 *  Returns YES if the source is a single table or view source
 */
@property (readonly) BOOL isTableSource;

/**
 *  Returns YES if the source is a join between two tables, joins, etc.
 */
@property (readonly) BOOL isJoinSource;

@end
