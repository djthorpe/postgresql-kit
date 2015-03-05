
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

@interface PGQuery : NSObject {
	NSMutableDictionary* _dictionary;
}


////////////////////////////////////////////////////////////////////////////////
// constructors

/**
 *  Construct a query from a dictionary, which was previously archived
 *
 *  @param dictionary The dictionary of values
 *  @param className  The class name to use to construct the query. If the
 *                    parameter is nil, the class name is expected to be
 *                    already in the dictionary.
 *
 *  @return Returns a query object or nil if the query object could not be
 *          constructed, likely because the query class could not be found.
 */
+(instancetype)queryWithDictionary:(NSDictionary* )dictionary class:(NSString* )className;

/**
 *  Construct a query from a string
 *
 *  @param statement The SQL statement
 *
 *  @return Returns the query object, or nil if the query object could not
 *          be constructed.
 */
+(instancetype)queryWithString:(NSString* )statement;

////////////////////////////////////////////////////////////////////////////////
// properties

/**
 *  Returns a dictionary representing the query
 */
@property (readonly) NSDictionary* dictionary;

/**
 *  Return the query class name
 */
@property (readonly) NSString* className;

/**
 *  Return the options flags, which can be used to construct the query
 */
@property int options;

/**
 *  Set an object in the dictionary
 *
 *  @param object The object to store in the dictionary. Cannot be nil.
 *  @param key    The unique key for the object
 */
-(void)setObject:(id)object forKey:(NSString* )key;

/**
 *  Return an object from the dictionary
 *
 *  @param key The key used to refer to the object
 *
 *  @return Returns an object, or nil if the object is not in the dictionary
 */
-(id)objectForKey:(NSString* )key;

/**
 *  This method generates an SQL statement string which can be sent to the
 *  server. In general, you wouldn't call this method yourself, since the
 *  connection object would use it as part of the execute chain. On error,
 *  this method will return nil and set the error object.
 *
 *  @param connection The connection for which the statement should be
 *                    generated. Due to differing versions of the connected
 *                    server, the statement generated might differ depending
 *                    on the server version.
 *  @param error      On statement generation error, the error parameter is
 *                    set to describe why a statement cannot be generated.
 *
 *  @return Returns the statement on success, or nil on error.
 */
-(NSString* )statementForConnection:(PGConnection* )connection error:(NSError** )error;

@end
