
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

@interface PGQueryUpdate : PGQuery

////////////////////////////////////////////////////////////////////////////////
// constructors

/**
 *  Construct a PGQueryUpdate instance which updates an existing table with new
 *  data
 *
 *  @param source A PGQuerySource or NSString object which determines which
 *                table to update rows to.  Cannot be nil.
 *  @param values A NSDictionary object, where the keys are NSString objects and
 *                the values are PGPredicate or NSString objects.
 *  @param where  A PGPredicate or NSString object which determines the conditions
 *                for which the rows are updated. Cannot be nil.
 *
 *  @return Returns a PGQueryUpdate object
 */
+(PGQueryUpdate* )into:(id)source values:(NSDictionary* )values where:(id)where;

@end
