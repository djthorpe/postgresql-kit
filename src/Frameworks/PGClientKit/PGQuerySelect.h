
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

/**
 *  Constant value used to indicate there is no limit to the number of
 *  results returned
 */
extern const NSUInteger PGQuerySelectNoLimit;

@interface PGQuerySelect : PGQuery

////////////////////////////////////////////////////////////////////////////////
// constructors

/**
 *  Construct a SELECT query from a table, view or other data source
 *
 *  @param source  A NSString object representing the table or view name, or
 *                 a PGQuerySource object representing a table, view or other
 *                 data source.
 *  @param options Options can be set to modify the statement. The
 *                 PGQuerySelectOptionDistinct flag can be set within options
 *                 in order to return a distinct set of rows.
 *
 *  @return Returns a PGQueryObject representing the SELECT query
 */
+(PGQuerySelect* )select:(id)source options:(NSUInteger)options;

////////////////////////////////////////////////////////////////////////////////
// properties

/**
 *  Return an array of the columns of type PGQueryPredicate
 */
@property (readonly) NSArray* columns;

/**
 *  Return an array of the column aliases of type NSString. An empty string
 *  indicates there is no alias set for a particular column.
 */
@property (readonly) NSArray* aliases;

/**
 *  Return the PGQuerySource for the select statement. Can be a simple table
 *  or view, or something more complicated like a join
 */
@property (readonly) PGQuerySource* source;

/**
 *  The WHERE predicate, or nil if no where predicate has been set
 */
@property PGQueryPredicate* where;

/**
 *  The HAVING predicate, or nil if no HAVING clause is to be included
 */
@property PGQueryPredicate* having;

/**
 *  The value for the select OFFSET keyword
 */
@property NSUInteger offset;

/**
 *  The value for the select LIMIT keyword. When set to PGQuerySelectNoLimit,
 *  indicates there is no limit to the number of results returned.
 */
@property NSUInteger limit;


////////////////////////////////////////////////////////////////////////////////
// methods

/**
 *  Add a column to the select statement
 *
 *  @param column    A PGQueryPredicate object, or expression as an NSString
 *                   object, required
 *  @param aliasName The alias name used when returning the column data. If set
 *                   to nil, the server will automatically generate an alias
 *                   name
 */
-(void)addColumn:(id)column alias:(NSString* )aliasName;

/**
 *  AND the existing WHERE expression with an additional predicate. If there
 *  is no existing expression, then this predicate becomes the WHERE expression.
 *  If the existing expression is already an AND predicate, then the predicate
 *  is appended to the existing expression as part of the AND arguments.
 *
 *  @param predicate Either an NSString expression or a PGQueryPredicate. Cannot
 *                   be nil.
 */
-(void)andWhere:(id)predicate;

/**
 *  OR the existing WHERE expression with an additional predicate. If there
 *  is no existing expression, then this predicate becomes the WHERE expression.
 *  If the existing expression is already an OR predicate, then the predicate
 *  is appended to the existing expression as part of the OR arguments.
 *
 *  @param predicate Either an NSString expression or a PGQueryPredicate. Cannot
 *                   be nil.
 */
-(void)orWhere:(id)predicate;

/**
 *  Add a OFFSET and LIMIT phrase to the select statement to limit results
 *  to a portion of the results.
 *
 *  @param offset The number of rows to skip. Zero means no rows are skipped,
 *                and that means the OFFSET phase is omitted from the statement.
 *  @param limit  The maximum number of rows to return. When Zero means no rows are skipped,
 *                and that means the OFFSET phase is omitted from the statement. When set
 *                to the PGQuerySelectNoLimit constant, the LIMIT phrase is omitted.
 */
-(void)setOffset:(NSUInteger)offset limit:(NSUInteger)limit;

// TODO: The following phrases need implemented: GROUP, ORDER
// TODO: The following modification is needed: DISTINCT IN (xxxx)

@end
