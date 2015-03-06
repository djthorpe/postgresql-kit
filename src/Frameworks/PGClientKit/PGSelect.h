
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

// options
enum {
	PGSelectOptionDistinct = 0x000001            // de-duplicate rows
};

@interface PGSelect : PGQuery

// basic select statement, selects everything (*)
// source is NSString or PGQuerySource
+(PGSelect* )select:(id)source options:(int)options;

// properties
@property (readonly) NSDictionary* columns;
@property (readonly) PGQuerySource* source;
@property (readonly) PGQueryPredicate* where;

// methods to set output columns
-(void)setColumns:(NSDictionary* )columns order:(NSArray* )aliases;
-(void)andWhere:(id)predicate; // NSString or PGPredicate
-(void)orWhere:(id)predicate;  // NSString or PGPredicate

// TODO: GROUP, ORDER, HAVING, LIMIT

@end
