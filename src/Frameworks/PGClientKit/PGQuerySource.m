
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

@implementation PGQuerySource

////////////////////////////////////////////////////////////////////////////////
// constructors

+(PGQueryObject* )sourceWithTable:(NSString* )tableName schema:(NSString* )schemaName alias:(NSString* )aliasName {
	NSParameterAssert(tableName);
	NSString* className = NSStringFromClass([self class]);
	PGQueryObject* query = [PGQueryObject queryWithDictionary:@{
		PGQueryTableKey: tableName
	} class:className];
	if(schemaName) {
		[query setObject:schemaName forKey:PGQuerySchemaKey];
	}
	if(aliasName) {
		[query setObject:aliasName forKey:PGQueryAliasKey];
	}
	return query;
}

+(PGQueryObject* )sourceWithTable:(NSString* )tableName alias:(NSString* )alias {
	return [PGQuerySource sourceWithTable:tableName schema:nil alias:alias];
}

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic table;
@dynamic schema;

-(NSString* )table {
	return [super objectForKey:PGQueryTableKey];
}

-(NSString* )schema {
	return [super objectForKey:PGQuerySchemaKey];
}

-(NSString* )alias {
	return [super objectForKey:PGQueryAliasKey];
}

////////////////////////////////////////////////////////////////////////////////
// methods

-(NSString* )quoteForConnection:(PGConnection* )connection withAlias:(BOOL)withAlias error:(NSError** )error {
	NSParameterAssert(connection);
	NSString* aliasName = [self alias];
	NSString* aliasQuoted = (withAlias && [aliasName length]) ? [NSString stringWithFormat:@" %@",[connection quoteIdentifier:[self alias]]] : @"";
	NSString* schemaName = [self schema];
	NSString* tableName = [self table];
	if([tableName length]==0) {
		// TODO SET ERROR (*error) = [NSError err]
		return nil;
	}
	NSString* tableQuoted = [connection quoteIdentifier:tableName];
	if([schemaName length]) {
		NSString* schemaQuoted = [connection quoteIdentifier:schemaName];
		return [NSString stringWithFormat:@"%@.%@%@",schemaQuoted,tableQuoted,aliasQuoted];
	} else {
		return [NSString stringWithFormat:@"%@%@",tableQuoted,aliasQuoted];
	}
}

-(NSString* )quoteForConnection:(PGConnection* )connection error:(NSError** )error {
	return [self quoteForConnection:connection withAlias:YES error:error];
}

@end
