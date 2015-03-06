
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
 *  view or a table join. Table joins are still to be implemented.
 */

@interface PGQuerySource : PGQueryObject

////////////////////////////////////////////////////////////////////////////////
// constructors

/**
 *  Construct a simple data source, which represents a table name without a
 *  named schema. Optionally, refer to an alias for the datasource.
 *
 *  @param tableName The identifer of the table to refer to
 *  @param alias     The alias to use for the data source. Can be nil when not
 *                   using aliases.
 *
 *  @return returns the constructed data source object
 */
+(PGQueryObject* )sourceWithTable:(NSString* )tableName alias:(NSString* )alias;

/**
 *  Construct a simple data source, which represents a table name with a
 *  named schema. Optionally, refer to an alias for the datasource.
 *
 *  @param tableName  The identifer of the table to refer to
 *  @param schemaName The schema that contains the table. Can be nil to use
 *                    the schema search path to locate the table.
 *  @param alias      The alias to use for the data source. Can be nil when not
 *                    using aliases.
 *
 *  @return returns the constructed data source object
 */
+(PGQueryObject* )sourceWithTable:(NSString* )tableName schema:(NSString* )schemaName alias:(NSString* )alias;


////////////////////////////////////////////////////////////////////////////////
// properties

/**
 *  Return the table name
 */
@property (readonly) NSString* table;

/**
 *  Return the schema name, or nil
 */
@property (readonly) NSString* schema;

/**
 *  Return the alias name, or nil
 */
@property (readonly) NSString* alias;

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
