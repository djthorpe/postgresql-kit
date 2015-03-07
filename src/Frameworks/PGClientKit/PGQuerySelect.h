
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
	PGQuerySelectOptionDistinct = 0x000001            // de-duplicate rows
};

@interface PGQuerySelect : PGQuery

// basic select statement, selects everything (*)
// source is NSString or PGQuerySource

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

// properties
@property (readonly) NSDictionary* columns;
@property (readonly) PGQuerySource* source;
@property (readonly) PGQueryPredicate* where;

// methods to set output columns
/*-(void)setColumns:(NSDictionary* )columns;
-(void)setColumns:(NSDictionary* )columns order:(NSArray* )aliases;
-(void)andWhere:(id)predicate; // NSString or PGPredicate
-(void)orWhere:(id)predicate;  // NSString or PGPredicate
*/

// TODO: GROUP, ORDER, HAVING, LIMIT

@end
