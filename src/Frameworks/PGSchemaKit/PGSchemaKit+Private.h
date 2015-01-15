
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

#import "PGSchemaProductNV.h"
#import "PGSchemaProductOp.h"
#import "PGSchemaProductOpTable.h"

@interface PGSchemaManager (Private)
// generate error objects
+(NSError* )errorWithCode:(PGSchemaErrorType)code path:(NSString* )path description:(NSString* )description,...;
+(NSError* )errorWithCode:(PGSchemaErrorType)code description:(NSString* )description,...;

+(NSString* )sqlWithFormatFromStringTable:(NSString* )key attributes:(NSDictionary* )attr error:(NSError** )error;

-(BOOL)_addSearchPath:(NSString* )path;
-(NSArray* )_subpathsAtPath:(NSString* )path;
-(NSArray* )_productsAtPath:(NSString* )path error:(NSError** )error;
-(BOOL)_hasProductTableWithError:(NSError** )error;
-(BOOL)_hasProductInstalled:(PGSchemaProduct* )product error:(NSError** )error;
-(NSArray* )_checkDependentProductsNV:(PGSchemaProductNV* )productnv error:(NSError** )error;
@end

@interface PGSchemaProduct (Private)
-(BOOL)_initWithPath:(NSString* )path error:(NSError** )error;
@property (readonly) PGSchemaProductNV* productnv;
@end
