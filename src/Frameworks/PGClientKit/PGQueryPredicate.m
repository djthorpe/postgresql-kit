
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

#import <PGClientKit/PGClientKit.h>
#import <PGClientKit/PGClientKit+Private.h>

// options
enum {
	PGQueryPredicateTypeNull = 0x00000001 // NULL
};


@implementation PGQueryPredicate

////////////////////////////////////////////////////////////////////////////////
// constructors

+(PGQueryObject* )nullPredicate {
	NSString* className = NSStringFromClass([self class]);
	PGQueryObject* query = [PGQueryObject queryWithDictionary:@{ } class:className];
	[query setOptions:PGQueryPredicateTypeNull];
	return query;
}

////////////////////////////////////////////////////////////////////////////////
// methods

-(NSString* )quoteForConnection:(PGConnection* )connection error:(NSError** )error {
	NSParameterAssert(connection);
	NSUInteger options = [self options];
	switch(options) {
		case PGQueryPredicateTypeNull:
			return @"NULL";
	}
	
	[connection raiseError:error code:PGClientErrorQuery reason:@"Invalid predicate"];
	return nil;
}

@end
