
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

@interface PGSchemaProduct : NSObject {
	id _productnv; // returns PGSchemaProductNV*
	NSString* _comment;
	NSMutableArray* _requires; // array of PGSchemaProductNV*
	NSMutableArray* _create; // array of PGSchemaProductOp*
	NSMutableArray* _update; // array of PGSchemaProductOp*
	NSMutableArray* _drop; // array of PGSchemaProductOp*
}

// constructors
-(id)initWithPath:(NSString* )path error:(NSError** )error;
+(PGSchemaProduct* )schemaWithPath:(NSString* )path error:(NSError** )error;

// properties
@property (readonly) NSString* name;
@property (readonly) NSUInteger version;
@property (readonly) NSString* comment;
@property (readonly) NSArray* requires;
@property (readonly) NSString* key;

// methods
-(BOOL)createWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error;
-(BOOL)updateWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error;
-(BOOL)dropWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error;

@end
