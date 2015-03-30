
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

@implementation PGQuerySchema

////////////////////////////////////////////////////////////////////////////////
#pragma mark constructors
////////////////////////////////////////////////////////////////////////////////

+(PGQuerySchema* )create:(NSString* )schema options:(NSUInteger)options {
	NSParameterAssert(schema);
	NSString* className = NSStringFromClass([self class]);
	if([schema length]==0) {
		return nil;
	}
	PGQuerySchema* query = (PGQuerySchema* )[PGQueryObject queryWithDictionary:@{
		PGQuerySchemaKey: schema
	} class:className];
	NSParameterAssert(query && [query isKindOfClass:[PGQuerySchema class]]);
	[query setOptions:(options | PGQueryOperationCreate)];
	return query;
}


+(PGQuerySchema* )drop:(NSString* )schema options:(NSUInteger)options {
	NSParameterAssert(schema);
	NSString* className = NSStringFromClass([self class]);
	if([schema length]==0) {
		return nil;
	}
	PGQuerySchema* query = (PGQuerySchema* )[PGQueryObject queryWithDictionary:@{
		PGQuerySchemaKey: schema
	} class:className];
	NSParameterAssert(query && [query isKindOfClass:[PGQuerySchema class]]);
	[query setOptions:(options | PGQueryOperationDrop)];
	return query;
}

+(PGQuerySchema* )alter:(NSString* )schema name:(NSString* )name {
	NSParameterAssert(schema);
	NSParameterAssert(name);
	NSString* className = NSStringFromClass([self class]);
	PGQuerySchema* query = (PGQuerySchema* )[PGQueryObject queryWithDictionary:@{
		PGQuerySchemaKey: schema,
		PGQueryNameKey: name
	} class:className];
	NSParameterAssert(query && [query isKindOfClass:[PGQuerySchema class]]);
	[query setOptions:(PGQueryOperationAlter | PGQueryOptionSetName)];
	return query;
}

+(PGQuerySchema* )alter:(NSString* )schema owner:(NSString* )owner {
	NSParameterAssert(schema);
	NSParameterAssert(owner);
	NSString* className = NSStringFromClass([self class]);
	PGQuerySchema* query = (PGQuerySchema* )[PGQueryObject queryWithDictionary:@{
		PGQuerySchemaKey: schema,
		PGQueryOwnerKey: owner
	} class:className];
	NSParameterAssert(query && [query isKindOfClass:[PGQuerySchema class]]);
	[query setOptions:(PGQueryOperationAlter | PGQueryOptionSetOwner)];
	return query;
}

+(PGQuerySchema* )comment:(NSString* )comment schema:(NSString* )schema {
	NSParameterAssert(schema);
	NSString* className = NSStringFromClass([self class]);
	PGQuerySchema* query = (PGQuerySchema* )[PGQueryObject queryWithDictionary:@{
		PGQuerySchemaKey: schema
	} class:className];
	NSParameterAssert(query && [query isKindOfClass:[PGQuerySchema class]]);
	if(comment) {
		[query setObject:comment forKey:PGQueryCommentKey];
	}
	[query setOptions:PGQueryOperationComment];
	return query;
}

+(PGQuerySchema* )listWithOptions:(NSUInteger)options {
	NSString* className = NSStringFromClass([self class]);
	PGQuerySchema* query = (PGQuerySchema* )[PGQueryObject queryWithDictionary:@{ } class:className];
	NSParameterAssert(query && [query isKindOfClass:[PGQuerySchema class]]);
	[query setOptions:(options | PGQueryOperationList)];
	return query;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

@dynamic schema;
@dynamic name;
@dynamic owner;
@dynamic comment;

-(NSString* )schema {
	NSString* schema = [super objectForKey:PGQuerySchemaKey];
	return ([schema length]==0) ? nil : schema;
}

-(NSString* )name {
	NSString* name = [super objectForKey:PGQueryNameKey];
	return ([name length]==0) ? nil : name;
}

-(NSString* )owner {
	return [super objectForKey:PGQueryOwnerKey];
}

-(NSString* )comment {
	return [super objectForKey:PGQueryCommentKey];
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

////////////////////////////////////////////////////////////////////////////////
#pragma mark private methods
////////////////////////////////////////////////////////////////////////////////

-(NSString* )quoteCreateForConnection:(PGConnection* )connection options:(NSUInteger)options error:(NSError** )error {
	NSParameterAssert(connection);

	// create flags container
	NSMutableArray* flags = [NSMutableArray new];
	NSParameterAssert(flags);

	// if not exists
	if(options & PGQueryOptionIgnoreIfNotExists) {
		[flags addObject:@"IF NOT EXISTS"];
	}

	// schema identifier
	NSString* schemaName = [self schema];
	if([schemaName length]==0) {
		[connection raiseError:error code:PGClientErrorQuery reason:@"CREATE SCHEMA: Missing schema name"];
		return nil;
	}
	[flags addObject:[connection quoteIdentifier:schemaName]];

	// owner
	if((options & PGQueryOptionSetOwner)) {
		NSString* owner = [self owner];
		if([owner length]==0) {
			[connection raiseError:error code:PGClientErrorQuery reason:@"CREATE SCHEMA: Missing owner property"];
			return nil;
		}
		[flags addObject:[NSString stringWithFormat:@"AUTHORIZATION %@",[connection quoteIdentifier:owner]]];
	}

	// return statement
	return [NSString stringWithFormat:@"CREATE SCHEMA %@",[flags componentsJoinedByString:@" "]];
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

	// schema identifier
	NSString* schemaName = [self schema];
	if([schemaName length]==0) {
		[connection raiseError:error code:PGClientErrorQuery reason:@"CREATE SCHEMA: Missing schema name"];
		return nil;
	}
	[flags addObject:[connection quoteIdentifier:schemaName]];

	// cascade or restrict
	if(options & PGQueryOptionDropObjects) {
		[flags addObject:@"CASCADE"];
	} else {
		[flags addObject:@"RESTRICT"];
	}

	// return statement
	return [NSString stringWithFormat:@"DROP SCHEMA %@",[flags componentsJoinedByString:@" "]];
}

-(NSString* )quoteAlterForConnection:(PGConnection* )connection options:(NSUInteger)options error:(NSError** )error {
	NSParameterAssert(connection);
	
	// create flags container
	NSMutableArray* flags = [NSMutableArray new];
	NSParameterAssert(flags);

	// schema identifier
	NSString* schemaName = [self schema];
	if([schemaName length]==0) {
		[connection raiseError:error code:PGClientErrorQuery reason:@"ALTER SCHEMA: Missing schema name"];
		return nil;
	}
	[flags addObject:[connection quoteIdentifier:schemaName]];

	// rename to
	if(options & PGQueryOptionSetName) {
		NSString* name = [self name];
		if([name length]==0) {
			[connection raiseError:error code:PGClientErrorQuery reason:@"ALTER SCHEMA: Missing name property"];
			return nil;
		}
		[flags addObject:[NSString stringWithFormat:@"RENAME TO %@",[connection quoteIdentifier:name]]];
	}

	// owner to
	if(options & PGQueryOptionSetOwner) {
		NSString* owner = [self owner];
		if([owner length]==0) {
			[connection raiseError:error code:PGClientErrorQuery reason:@"ALTER SCHEMA: Missing owner property"];
			return nil;
		}
		[flags addObject:[NSString stringWithFormat:@"OWNER TO %@",[connection quoteIdentifier:owner]]];
	}

	// return statement
	return [NSString stringWithFormat:@"ALTER SCHEMA %@",[flags componentsJoinedByString:@" "]];
}

-(NSString* )quoteCommentForConnection:(PGConnection* )connection options:(NSUInteger)options error:(NSError** )error {
	NSParameterAssert(connection);
	
	// create flags container
	NSMutableArray* flags = [NSMutableArray new];
	NSParameterAssert(flags);

	// database identifier
	NSString* schema = [self schema];
	if([schema length]==0) {
		[connection raiseError:error code:PGClientErrorQuery reason:@"COMMENT ON SCHEMA: Missing schema name"];
		return nil;
	}
	[flags addObject:[connection quoteIdentifier:schema]];
	[flags addObject:@"IS"];

	// add comment
	NSString* comment= [self comment];
	if(comment==nil) {
		[flags addObject:@"NULL"];
	} else {
		[flags addObject:[connection quoteString:comment]];
	}

	// return statement
	return [NSString stringWithFormat:@"COMMENT ON SCHEMA %@",[flags componentsJoinedByString:@" "]];
}


-(NSString* )quoteListForConnection:(PGConnection* )connection options:(NSUInteger)options error:(NSError** )error {
	PGQuerySelect* query = [PGQuerySelect select:[PGQuerySource table:@"pg_namespace" schema:@"pg_catalog" alias:@"n"] options:0];
	[query addColumn:@"n.nspname" alias:@"schema"];
	
	if(options & PGQueryOptionListExtended) {
		[query addColumn:@"pg_get_userbyid(n.nspowner)" alias:@"owner"];
		[query addColumn:@"obj_description(n.oid,'pg_namespace')" alias:@"comment"];
	}
	[query andWhere:@"n.nspname !~ '^pg_'"];
	[query andWhere:@"n.nspname <> 'information_schema'"];

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
	case PGQueryOperationComment:
		return [self quoteCommentForConnection:connection options:options error:error];
	case PGQueryOperationList:
		return [self quoteListForConnection:connection options:options error:error];
	}

	[connection raiseError:error code:PGClientErrorQuery reason:@"SCHEMA: Invalid operation"];
	return nil;

}

@end
