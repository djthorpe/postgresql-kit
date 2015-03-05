
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

@interface PGQueryInfo : PGQuery

////////////////////////////////////////////////////////////////////////////////
// constructors

+(PGQueryInfo* )schemasForDatabase:(NSString* )databaseName options:(int)options;
+(PGQueryInfo* )rolesForDatabase:(NSString* )databaseName options:(int)options;
+(PGQueryInfo* )tablesAndViewsForSchema:(NSString* )schemaName options:(int)options;
+(PGQueryInfo* )columnsForTable:(NSString* )tableName schema:(NSString* )schemaName options:(int)options;

////////////////////////////////////////////////////////////////////////////////
// properties

/**
 *  The name of the table or view
 */
@property NSString* table;

/**
 *  The name of the schema
 */
@property NSString* schema;

/**
 *  The name of the database
 */
@property NSString* database;

/**
 *  The name of the role
 */
@property NSString* role;


@end
