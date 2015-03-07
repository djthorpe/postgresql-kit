
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
  *  This class represents any expression which can be used within SQL
  *  statements
  */

@interface PGQueryPredicate : PGQueryObject

////////////////////////////////////////////////////////////////////////////////
#pragma mark constructors
////////////////////////////////////////////////////////////////////////////////

/**
 *  Construct a NULL predicate object
 *
 *  @return Returns the PGQueryPredicate object
 */
+(PGQueryPredicate* )nullPredicate;

/**
 *  Construct a free-form expression predicate object, which isn't quoted when
 *  using within a PGQuery object.
 *
 *  @param expression The expression string. Cannot be nil.
 *
 *  @return Returns the PGQueryPredicate object
 */
+(PGQueryPredicate* )expression:(NSString* )expression;

/**
 *  Construct a logical AND expression, with one or more arguments.
 *
 *  @param expression The first expression. Can be an NSString or PGQueryPredicate
 *                    object. Cannot be nil. Subsequent expressions can be appended
 *                    by separating each expression by a comma, the last argument
 *                    must always be nil
 *
 *  @return Returns the PGQueryPredicate object
 */
+(PGQueryPredicate* )and:(id)expression,...;

/**
 *  Construct a logical OR expression, with one or more arguments.
 *
 *  @param expression The first expression. Can be an NSString or PGQueryPredicate
 *                    object. Cannot be nil. Subsequent expressions can be appended
 *                    by separating each expression by a comma, the last argument
 *                    must always be nil
 *
 *  @return Returns the PGQueryPredicate object
 */
+(PGQueryPredicate* )or:(id)expression,...;

/**
 *  Construct a logical NOT expression, with one arguments.
 *
 *  @param expression The expression to negate. Can be an NSString or PGQueryPredicate
 *                    object. Cannot be nil.
 *
 *  @return Returns the PGQueryPredicate object
 */
+(PGQueryPredicate* )not:(id)expression;

/**
 *  Construct a boolean value
 *
 *  @param boolean The value, either YES (true) or NO (false)
 *
 *  @return Returns the PGQueryPredicate object
 */
+(PGQueryPredicate* )boolean:(BOOL)boolean;

/**
 *  Construct a string value
 *
 *  @param string The value, which must not be nil
 *
 *  @return Returns the PGQueryPredicate object
 */
+(PGQueryPredicate* )string:(NSString* )string;

////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

/**
 *  Returns YES if the pedicate is a Logical AND predicate
 */
@property (readonly) BOOL isAND;

/**
 *  Returns YES if the pedicate is a Logical OR predicate
 */
@property (readonly) BOOL isOR;

/**
 *  Returns YES if the pedicate is a Logical NOT predicate
 */
@property (readonly) BOOL isNOT;

////////////////////////////////////////////////////////////////////////////////
#pragma mark methods
////////////////////////////////////////////////////////////////////////////////

/**
 *  Add arguments to an AND or OR predicate. The arguments can be NSString or
 *  which are converted to expressions, or PGQueryPredicate. If the predicate
 *  is not an AND or OR type, then an exception is raised.
 *
 *  @param expression The first expression to be appended to the arguments,
 *                    either an NSString object or a PGQueryPredicate object.
 *                    The last expression must always be nil.
 */
-(void)addArguments:(id)expression,...;

@end
