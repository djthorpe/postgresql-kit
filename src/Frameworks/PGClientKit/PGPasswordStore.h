
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

@interface PGPasswordStore : NSObject {
	NSMutableDictionary* _store;
}

// properties
@property (readonly) NSString* serviceName;

// methods
-(NSString* )passwordForURL:(NSURL* )url;
-(NSString* )passwordForURL:(NSURL* )url error:(NSError** )error;
-(NSString* )passwordForURL:(NSURL* )url readFromKeychain:(BOOL)readFromKeychain error:(NSError** )error;
-(BOOL)setPassword:(NSString* )password forURL:(NSURL* )url saveToKeychain:(BOOL)saveToKeychain;
-(BOOL)setPassword:(NSString* )password forURL:(NSURL* )url saveToKeychain:(BOOL)saveToKeychain error:(NSError** )error;

@end
