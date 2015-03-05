
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

#import "PGFoundationApp.h"
#import "Terminal.h"

@interface PGFoundationClient : PGFoundationApp <PGConnectionDelegate> {
	PGConnection* _db;
	PGPasswordStore* _passwordstore;
	Terminal* _term;
}

// properties
@property (readonly) NSURL* url;
@property (retain) NSString* password;
@property (readonly) PGConnection* db;
@property (readonly) PGPasswordStore* passwordstore;
@property (readonly) Terminal* term;
@property (readonly) NSString* prompt;

@end
