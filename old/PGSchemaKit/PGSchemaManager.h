
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

@interface PGSchemaManager : NSObject {
	PGConnection* _connection;
	NSString* _sysschema;
	NSString* _usrschema;
	NSMutableArray* _searchpath;
	NSMutableDictionary* _products;
}

// constructor
-(id)initWithConnection:(PGConnection* )connection userSchema:(NSString* )usrschema systemSchema:(NSString* )sysschema;
-(id)initWithConnection:(PGConnection* )connection userSchema:(NSString* )usrschema;

// properties
@property (readonly) NSString* systemSchema;
@property (readonly) NSString* userSchema;
@property (readonly) NSArray* products;
@property (readonly) PGConnection* connection;

// methods
+(NSArray* )defaultSearchPath;
-(BOOL)addSearchPath:(NSString* )path error:(NSError** )error;
-(BOOL)addSearchPath:(NSString* )path recursive:(BOOL)isRecursive error:(NSError** )error;
-(BOOL)create:(PGSchemaProduct* )product dryrun:(BOOL)isDryrun error:(NSError** )error;
-(BOOL)update:(PGSchemaProduct* )product dryrun:(BOOL)isDryrun error:(NSError** )error;
-(BOOL)drop:(PGSchemaProduct* )product dryrun:(BOOL)isDryrun error:(NSError** )error;
@end
