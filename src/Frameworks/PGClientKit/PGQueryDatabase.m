
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

@implementation PGQueryDatabase

////////////////////////////////////////////////////////////////////////////////
#pragma mark constructor
////////////////////////////////////////////////////////////////////////////////

+(PGQueryDatabase* )create:(NSString* )database options:(NSUInteger)options {
	NSParameterAssert(database);
	NSString* className = NSStringFromClass([self class]);
	if([database length]==0) {
		return nil;
	}
	PGQueryDatabase* query = (PGQueryDatabase* )[PGQueryObject queryWithDictionary:@{
		PGQueryDatabaseKey: database
	} class:className];
	NSParameterAssert(query && [query isKindOfClass:[PGQueryDatabase class]]);
	[query setOptions:(options | PGQueryOperationCreate)];
	return query;
}

+(PGQueryDatabase* )drop:(NSString* )database options:(NSUInteger)options {
	NSParameterAssert(database);
	NSString* className = NSStringFromClass([self class]);
	if([database length]==0) {
		return nil;
	}
	PGQueryDatabase* query = (PGQueryDatabase* )[PGQueryObject queryWithDictionary:@{
		PGQueryDatabaseKey: database
	} class:className];
	NSParameterAssert(query && [query isKindOfClass:[PGQueryDatabase class]]);
	[query setOptions:(options | PGQueryOperationDrop)];
	return query;
}

+(PGQueryDatabase* )listWithOptions:(NSUInteger)options {
	NSString* className = NSStringFromClass([self class]);
	PGQueryDatabase* query = (PGQueryDatabase* )[PGQueryObject queryWithDictionary:@{ } class:className];
	NSParameterAssert(query && [query isKindOfClass:[PGQueryDatabase class]]);
	[query setOptions:(options | PGQueryOperationList)];
	return query;
}

+(PGQueryDatabase* )alter:(NSString* )database name:(NSString* )name {
	NSParameterAssert(database);
	NSParameterAssert(name);
	NSString* className = NSStringFromClass([self class]);
	PGQueryDatabase* query = (PGQueryDatabase* )[PGQueryObject queryWithDictionary:@{
		PGQueryDatabaseKey: database,
		PGQueryNameKey: name
	} class:className];
	NSParameterAssert(query && [query isKindOfClass:[PGQueryDatabase class]]);
	[query setOptions:(PGQueryOperationAlter | PGQueryOptionSetName)];
	return query;
}

+(PGQueryDatabase* )alter:(NSString* )database owner:(NSString* )owner {
	NSParameterAssert(database);
	NSParameterAssert(owner);
	NSString* className = NSStringFromClass([self class]);
	PGQueryDatabase* query = (PGQueryDatabase* )[PGQueryObject queryWithDictionary:@{
		PGQueryDatabaseKey: database,
		PGQueryOwnerKey: owner
	} class:className];
	NSParameterAssert(query && [query isKindOfClass:[PGQueryDatabase class]]);
	[query setOptions:(PGQueryOperationAlter | PGQueryOptionSetOwner)];
	return query;
}

+(PGQueryDatabase* )alter:(NSString* )database connectionLimit:(NSInteger)connectionLimit {
	NSParameterAssert(database);
	NSParameterAssert(connectionLimit >= -1);
	NSString* className = NSStringFromClass([self class]);
	PGQueryDatabase* query = (PGQueryDatabase* )[PGQueryObject queryWithDictionary:@{
		PGQueryDatabaseKey: database,
		PGQueryConnectionLimitKey: [NSNumber numberWithInteger:connectionLimit]
	} class:className];
	NSParameterAssert(query && [query isKindOfClass:[PGQueryDatabase class]]);
	[query setOptions:(PGQueryOperationAlter | PGQueryOptionSetConnectionLimit)];
	return query;
}

+(PGQueryDatabase* )alter:(NSString* )database tablespace:(NSString* )tablespace {
	NSParameterAssert(database);
	NSParameterAssert(tablespace);
	NSString* className = NSStringFromClass([self class]);
	PGQueryDatabase* query = (PGQueryDatabase* )[PGQueryObject queryWithDictionary:@{
		PGQueryDatabaseKey: database,
		PGQueryTablespaceKey: tablespace
	} class:className];
	NSParameterAssert(query && [query isKindOfClass:[PGQueryDatabase class]]);
	[query setOptions:(PGQueryOperationAlter | PGQueryOptionSetTablespace)];
	return query;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

@dynamic database;
@dynamic name;
@dynamic owner;
@dynamic template;
@dynamic encoding;
@dynamic tablespace;
@dynamic connectionLimit;

-(NSString* )database {
	NSString* database = [super objectForKey:PGQueryDatabaseKey];
	return ([database length]==0) ? nil : database;
}

-(NSString* )name {
	NSString* name = [super objectForKey:PGQueryNameKey];
	return ([name length]==0) ? nil : name;
}

-(NSString* )owner {
	return [super objectForKey:PGQueryOwnerKey];
}

-(void)setOwner:(NSString* )owner {
	if([owner length]==0) {
		[super removeObjectForKey:PGQueryOwnerKey];
		[super setOptions:([self options] & ~PGQueryOptionSetOwner)];
	} else {
		[super setObject:owner forKey:PGQueryOwnerKey];
		[super setOptions:([self options] | PGQueryOptionSetOwner)];
	}
}

-(NSString* )encoding {
	NSString* encoding = [super objectForKey:PGQueryEncodingKey];
	return ([encoding length]==0) ? nil : encoding;
}

-(void)setEncoding:(NSString* )encoding {
	if([encoding length]==0) {
		[super removeObjectForKey:PGQueryEncodingKey];
		[super setOptions:([self options] & ~PGQueryOptionSetEncoding)];
	} else {
		[super setObject:encoding forKey:PGQueryEncodingKey];
		[super setOptions:([self options] | PGQueryOptionSetEncoding)];
	}
}

-(NSInteger)connectionLimit {
	NSNumber* connectionLimit = [super objectForKey:PGQueryConnectionLimitKey];
	if(connectionLimit==nil || [connectionLimit isKindOfClass:[NSNumber class]]==NO) {
		// return default value
		return -1;
	} else {
		// return actual value
		return [connectionLimit integerValue];
	}
}

-(void)setConnectionLimit:(NSInteger)connectionLimit {
	if(connectionLimit < 0) {
		[super removeObjectForKey:PGQueryConnectionLimitKey];
		[super setOptions:([self options] & ~PGQueryOptionSetConnectionLimit)];
	} else {
		[super setObject:[NSNumber numberWithInteger:connectionLimit] forKey:PGQueryConnectionLimitKey];
		[super setOptions:([self options] | PGQueryOptionSetConnectionLimit)];
	}
}

-(NSString* )tablespace {
	NSString* tablespace = [super objectForKey:PGQueryTablespaceKey];
	return ([tablespace length]==0) ? nil : tablespace;
}

-(void)setTablespace:(NSString* )tablespace {
	if([tablespace length]==0) {
		[super removeObjectForKey:PGQueryTablespaceKey];
		[super setOptions:([self options] & ~PGQueryOptionSetTablespace)];
	} else {
		[super setObject:tablespace forKey:PGQueryTablespaceKey];
		[super setOptions:([self options] | PGQueryOptionSetTablespace)];
	}
}

-(NSString* )template {
	NSString* template = [super objectForKey:PGQueryTemplateKey];
	return ([template length]==0) ? nil : template;
}

-(void)setTemplate:(NSString* )template {
	if([template length]==0) {
		[super removeObjectForKey:PGQueryTemplateKey];
		[super setOptions:([self options] & ~PGQueryOptionSetDatabaseTemplate)];
	} else {
		[super setObject:template forKey:PGQueryTemplateKey];
		[super setOptions:([self options] | PGQueryOptionSetDatabaseTemplate)];
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark private methods
////////////////////////////////////////////////////////////////////////////////

-(NSString* )quoteCreateForConnection:(PGConnection* )connection options:(NSUInteger)options error:(NSError** )error {
	NSParameterAssert(connection);

	// create flags container
	NSMutableArray* flags = [NSMutableArray new];
	NSParameterAssert(flags);

	// database identifier
	NSString* databaseName = [self database];
	if([databaseName length]==0) {
		[connection raiseError:error code:PGClientErrorQuery reason:@"CREATE DATABASE: Missing database name"];
		return nil;
	}
	[flags addObject:[connection quoteIdentifier:databaseName]];

	// owner
	if((options & PGQueryOptionSetOwner)) {
		NSString* owner = [self owner];
		if([owner length]==0) {
			[connection raiseError:error code:PGClientErrorQuery reason:@"CREATE DATABASE: Missing owner property"];
			return nil;
		}
		[flags addObject:[NSString stringWithFormat:@"OWNER %@",[connection quoteIdentifier:owner]]];
	}
	
	// template
	if((options & PGQueryOptionSetDatabaseTemplate)) {
		NSString* template = [self template];
		if([template length]==0) {
			[connection raiseError:error code:PGClientErrorQuery reason:@"CREATE DATABASE: Missing template property"];
			return nil;
		}
		[flags addObject:[NSString stringWithFormat:@"TEMPLATE %@",[connection quoteIdentifier:template]]];
	}
	
	// encoding
	if((options & PGQueryOptionSetEncoding)) {
		NSString* encoding = [self encoding];
		if([encoding length]==0) {
			[flags addObject:@"ENCODING DEFAULT"];
		} else {
			[flags addObject:[NSString stringWithFormat:@"ENCODING %@",[connection quoteString:encoding]]];
		}
	}
	
	// tablespace
	if((options & PGQueryOptionSetTablespace)) {
		NSString* tablespace = [self tablespace];
		if([tablespace length]==0) {
			[flags addObject:@"TABLESPACE DEFAULT"];
		} else {
			[flags addObject:[NSString stringWithFormat:@"TABLESPACE %@",[connection quoteIdentifier:tablespace]]];
		}
	}
	
	// connection limit
	if((options & PGQueryOptionSetConnectionLimit)) {
		NSInteger connectionLimit = [self connectionLimit];
		if(connectionLimit < -1) {
			[connection raiseError:error code:PGClientErrorQuery reason:@"CREATE DATABASE: Invalid connection limit property"];
			return nil;
		}
		[flags addObject:[NSString stringWithFormat:@"CONNECTION LIMIT %ld",connectionLimit]];
	}

	// add WITH in
	if([flags count] > 1) {
		[flags insertObject:@"WITH" atIndex:1];
	}

	// return statement
	return [NSString stringWithFormat:@"CREATE DATABASE %@",[flags componentsJoinedByString:@" "]];
}

-(NSString* )quoteDropForConnection:(PGConnection* )connection options:(NSUInteger)options error:(NSError** )error {
	NSParameterAssert(connection);
	
	// create flags container
	NSMutableArray* flags = [NSMutableArray new];
	NSParameterAssert(flags);

	// if exists
	if(options & PGQueryOptionIgnoreIfExists) {
		[flags addObject:@"IF EXISTS"];
	}

	// database identifier
	NSString* databaseName = [self database];
	if([databaseName length]==0) {
		[connection raiseError:error code:PGClientErrorQuery reason:@"DROP DATABASE: Missing database name"];
		return nil;
	}
	[flags addObject:[connection quoteIdentifier:databaseName]];

	// return statement
	return [NSString stringWithFormat:@"DROP DATABASE %@",[flags componentsJoinedByString:@" "]];
}

-(NSString* )quoteAlterForConnection:(PGConnection* )connection options:(NSUInteger)options error:(NSError** )error {
	NSParameterAssert(connection);
	
	// create flags container
	NSMutableArray* flags = [NSMutableArray new];
	NSParameterAssert(flags);

	// database identifier
	NSString* databaseName = [self database];
	if([databaseName length]==0) {
		[connection raiseError:error code:PGClientErrorQuery reason:@"ALTER DATABASE: Missing database name"];
		return nil;
	}
	[flags addObject:[connection quoteIdentifier:databaseName]];

	// rename to
	if(options & PGQueryOptionSetName) {
		NSString* name = [self name];
		if([name length]==0) {
			[connection raiseError:error code:PGClientErrorQuery reason:@"ALTER DATABASE: Missing name property"];
			return nil;
		}
		[flags addObject:[NSString stringWithFormat:@"RENAME TO %@",[connection quoteIdentifier:name]]];
	}

	// owner to
	if(options & PGQueryOptionSetOwner) {
		NSString* owner = [self owner];
		if([owner length]==0) {
			[connection raiseError:error code:PGClientErrorQuery reason:@"ALTER DATABASE: Missing owner property"];
			return nil;
		}
		[flags addObject:[NSString stringWithFormat:@"OWNER TO %@",[connection quoteIdentifier:owner]]];
	}
	
	// set tablespace
	if(options & PGQueryOptionSetTablespace) {
		NSString* tablespace = [self tablespace];
		if([tablespace length]==0) {
			[connection raiseError:error code:PGClientErrorQuery reason:@"ALTER DATABASE: Missing tablespace property"];
			return nil;
		}
		[flags addObject:[NSString stringWithFormat:@"SET TABLESPACE %@",[connection quoteIdentifier:tablespace]]];
	}
	
	// with connection limit
	if(options & PGQueryOptionSetConnectionLimit) {
		NSInteger connectionLimit = [self connectionLimit];
		[flags addObject:[NSString stringWithFormat:@"WITH CONNECTION LIMIT %ld",connectionLimit]];
	}

	// return statement
	return [NSString stringWithFormat:@"ALTER DATABASE %@",[flags componentsJoinedByString:@" "]];
}

-(NSString* )quoteListForConnection:(PGConnection* )connection options:(NSUInteger)options error:(NSError** )error {
	PGQuerySelect* query = [PGQuerySelect select:@"pg_catalog.pg_database d LEFT JOIN pg_catalog.pg_user u ON d.datdba = u.usesysid" options:0];
	[query addColumn:@"d.datname" alias:@"database"];
	[query addColumn:@"u.usename" alias:@"owner"];
	[query addColumn:@"pg_catalog.pg_encoding_to_char(d.encoding)" alias:@"encoding"];
	[query addColumn:@"d.dattablespace" alias:@"tablespace"];
	[query addColumn:@"d.datconnlimit" alias:@"connection_limit"];
	[query andWhere:@"NOT d.datistemplate"];
	return [query quoteForConnection:connection error:error];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark public methods
////////////////////////////////////////////////////////////////////////////////

-(NSString* )quoteForConnection:(PGConnection* )connection error:(NSError** )error {
	NSUInteger options = [self options];
	NSUInteger operation = (options & PGQueryOperationMask);
	switch(operation) {
	case PGQueryOperationCreate:
		return [self quoteCreateForConnection:connection options:options error:error];
	case PGQueryOperationDrop:
		return [self quoteDropForConnection:connection options:options error:error];
	case PGQueryOperationAlter:
		return [self quoteAlterForConnection:connection options:options error:error];
	case PGQueryOperationList:
		return [self quoteListForConnection:connection options:options error:error];
	}

	[connection raiseError:error code:PGClientErrorQuery reason:@"DATABASE: Invalid operation"];
	return nil;

}

@end
