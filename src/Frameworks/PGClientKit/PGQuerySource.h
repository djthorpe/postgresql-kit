
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

@interface PGQuerySource : NSObject

// constructors
-(instancetype)initWithDictionary:(NSDictionary* )dictionary;
+(instancetype)sourceWithTable:(NSString* )tableName alias:(NSString* )alias;
+(instancetype)sourceWithTable:(NSString* )tableName schema:(NSString* )schemaName alias:(NSString* )alias;
+(instancetype)joinWithTable:(id)tableSourceL table:(id)tableSourceR on:(id)predicate options:(int)options;

// properties
@property NSDictionary* dictionary;
@property NSString* table;
@property NSString* schema;
@property NSString* alias;

// methods
-(NSString* )quoteForConnection:(PGConnection* )connection withAlias:(BOOL)withAlias;

@end
