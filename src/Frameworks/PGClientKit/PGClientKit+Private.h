
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

#import "PGClientParams.h"
#import "PGConverters.h"

@interface PGConnection (Private)
+(NSError* )createError:(NSError** )error code:(PGClientErrorDomainCode)code url:(NSURL* )url reason:(NSString* )format,...;
@end

@interface PGResult (Private)
-(NSError* )raiseError:(NSError** )error code:(PGClientErrorDomainCode)code url:(NSURL* )url reason:(NSString* )format,...;
-(NSError* )raiseError:(NSError** )error code:(PGClientErrorDomainCode)code reason:(NSString* )format,...;
-(id)initWithResult:(PGresult* )theResult format:(PGClientTupleFormat)format;
@end

typedef struct {
	const char** keywords;
	const char** values;
} PGKVPairs;

PGKVPairs* makeKVPairs(NSDictionary* dict);
void freeKVPairs(PGKVPairs* pairs);
