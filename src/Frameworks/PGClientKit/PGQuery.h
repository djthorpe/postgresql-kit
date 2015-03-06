
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
extern NSString* PGQuerySchemaKey;
extern NSString* PGQueryDatabaseKey;
extern NSString* PGQueryAliasKey;

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
+(PGQueryObject* )queryWithString:(NSString* )statement;

@end
