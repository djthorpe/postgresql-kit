
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

#import <PGClientKit/PGClientKit.h>

@interface PGQueryInsert : PGQuery

////////////////////////////////////////////////////////////////////////////////
// constructors

/**
 *  Construct a PGQueryInsert instance which inserts one or more rows of data
 *  into a single table
 *
 *  @param source A PGQuerySource or NSString object which determines which
 *                table to remove rows from.  Cannot be nil.
 *
 *  @param values Either an NSArray or NSDictionary object, which are the
 *                values to insert. Each value can be a PGPredicate object or a
 *                string. To insert a DEFAULT value, use a [PGPredicate defaultPredicate]
 *                object.
 *
 *  @return Returns a PGQueryInsert object
 */
+(PGQueryInsert* )into:(id)source values:(id)values;

////////////////////////////////////////////////////////////////////////////////
// properties

/**
 *  Return the PGQuerySource for the INSERT statement.
 */
@property (readonly) PGQuerySource* source;

/**
 *  Return array of columns, or nil.
 */
@property (readonly) NSArray* columns;

/**
 *  Return array of values, or nil.
 */
@property (readonly) NSArray* values;

@end

