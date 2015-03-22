
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
 *  PGTransaction represents one or more queries to be executed by the server
 *  within a block. The transaction queries are executed sequentially, and
 *  on failure of any sequentially executed query, the actions are rolled
 *  back. If no errors occur, the transaction is committed.
 *
 *  To use PGTransaction, call [connection queue:transaction]
 */

@interface PGTransaction : NSObject {
	NSMutableArray* _queries;
	BOOL _transactional;
}

////////////////////////////////////////////////////////////////////////////////
// constructors

/**
 *  Create a transaction with a single query
 *
 *  @param query The query which should be executed within an execution block
 *
 *  @return Returns the PGTransaction object
 */
+(instancetype)transactionWithQuery:(PGQuery* )query;

////////////////////////////////////////////////////////////////////////////////
// properties

/**
 *  Returns the number of queries which are in the transaction block
 */
@property (readonly) NSUInteger count;

/**
 *  Returns YES is the block is transactional (wrapped around BEGIN/COMMIT)
 *  and NO if not (the queries are executed without BEGIN/COMMIT)
 */
@property BOOL transactional;

////////////////////////////////////////////////////////////////////////////////
// methods

/**
 *  Appends a new query to the transaction block
 *
 *  @param query The query which should be appended to the block of transactions
 */
-(void)add:(PGQuery* )query;

/**
 *  Return a query from the block of queries
 *
 *  @param index The index of the query to return
 *
 *  @return Returns a PGQuery object
 */
-(PGQuery* )queryAtIndex:(NSUInteger)index;

@end
