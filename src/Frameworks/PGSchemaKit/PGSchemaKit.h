
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
#import <PGClientKit/PGClientKit.h>

// externs
extern NSString* PGSchemaErrorDomain;
extern NSString* PGSchemaFileExtension;

// typedefs
typedef enum {
	PGSchemaErrorMissingDTD = 100,
	PGSchemaErrorParse = 101,
	PGSchemaErrorSearchPath = 102,
	PGSchemaErrorDependency = 103,
	PGSchemaErrorDatabase = 104,
	PGSchemaErrorInternal = 105
} PGSchemaErrorType;

// forward class declarations
@class PGSchemaProduct;
@class PGSchemaManager;

// header includes
#import "PGSchemaManager.h"
#import "PGSchemaProduct.h"

