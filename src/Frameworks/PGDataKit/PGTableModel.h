
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

enum {
	PGTableModelTemporary = 1
} PGTableModelOptions;


@interface PGTableModel : NSObject

// constructors
-(id)initWithName:(NSString* )name;

// properties
@property (copy) NSString* name;
@property (assign) int options;
@property (readonly) NSArray* columns;

// methods
//-(void)appendColumn:(PGTableColumnModel* )column;

@end

@interface PGConnection (PGTableModelAdditions)
-(BOOL)create:(PGTableModel* )model schema:(NSString* )schema options:(int)options whenDone:(void(^)(NSError* error)) callback;
-(PGTableModel* )modelForTable:(NSString* )table schema:(NSString* )schema;
@end

