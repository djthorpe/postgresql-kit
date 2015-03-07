
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

////////////////////////////////////////////////////////////////////////////////

NSString* PGQueryStatementKey = @"statement";
NSString* PGQueryTableKey = @"table";
NSString* PGQuerySchemaKey = @"schema";
NSString* PGQueryDatabaseKey = @"database";
NSString* PGQueryAliasKey = @"alias";
NSString* PGQuerySourceKey = @"from";

////////////////////////////////////////////////////////////////////////////////

@implementation PGQuery

////////////////////////////////////////////////////////////////////////////////
// initialization

+(PGQuery* )queryWithString:(NSString* )statement {
	NSParameterAssert(statement);
	NSString* className = NSStringFromClass([self class]);
	return (PGQuery* )[PGQuery queryWithDictionary:@{ PGQueryStatementKey: statement } class:className];	
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(NSString* )quoteForConnection:(PGConnection* )connection error:(NSError** )error {
	NSParameterAssert(connection);
	NSString* statement = [self objectForKey:PGQueryStatementKey];
	if(statement==nil || [statement isKindOfClass:[NSString class]]==NO || [statement length]==0) {
		[connection raiseError:error code:PGClientErrorQuery reason:@"Empty statement"];
		return nil;
	}
	return statement;
}

@end
