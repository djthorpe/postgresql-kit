
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

// initialize and destroy lookup cache
void pgdata2obj_init();
void pgdata2obj_destroy();

// public methods to convert
id pgdata_bin2obj(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding);
id pgdata_text2obj(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding);

// protocol for conversion
@protocol PGObjectConverter <NSObject>
+(NSData* )obj2bin;
+(NSData* )obj2text;
@end