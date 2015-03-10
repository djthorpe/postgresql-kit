
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


@interface PGQueryObject : NSObject {
	NSMutableDictionary* _dictionary;
}

/**
 *  Create a new query instance from a dictionary, which has a particular class
 *  type.
 *
 *  @param dictionary The dictionary of values to create the query
 *  @param class      The name of the class which needs to match the class. If
 *                    set to nil, then the class name is inferred from the
 *                    dictionary contents
 *
 *  @return Returns the query object or nil if the query object could not be
 *          constructed, likely because the dictionary is not compatible
 */
+(instancetype)queryWithDictionary:(NSDictionary* )dictionary class:(NSString* )className;

////////////////////////////////////////////////////////////////////////////////
// properties

/**
 *  Returns a dictionary representing the query object
 */
@property (readonly) NSDictionary* dictionary;

/**
 *  Return option flags
 */
@property NSUInteger options;

////////////////////////////////////////////////////////////////////////////////
// methods

/**
 *  Adds additional flags to the options
 *
 *  @param flag The flag or OR'd flags to set
 */
-(void)setOptionFlags:(NSUInteger)flag;

/**
 *  Removes flags from the options
 *
 *  @param flag The flag or OR'd flags to clear
 */
-(void)clearOptionFlags:(NSUInteger)flag;

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
 *  Remove an object from the dictionary
 *
 *  @param key he key used to refer to the object to be removed
 */
-(void)removeObjectForKey:(NSString* )key;

/**
 *  This method generates a quoted string suitable for using within an SQL 
 *  statement. On error, this method will return nil and set the error object.
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
-(NSString* )quoteForConnection:(PGConnection* )connection error:(NSError** )error;

@end
