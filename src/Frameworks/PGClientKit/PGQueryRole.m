
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

@implementation PGQueryRole

////////////////////////////////////////////////////////////////////////////////
#pragma mark constructors
////////////////////////////////////////////////////////////////////////////////

+(PGQueryRole* )create:(NSString* )role options:(NSUInteger)options {
	NSParameterAssert(role);
	NSString* className = NSStringFromClass([self class]);
	if([role length]==0) {
		return nil;
	}
	PGQueryRole* query = (PGQueryRole* )[PGQueryObject queryWithDictionary:@{
		PGQueryRoleKey: role
	} class:className];
	NSParameterAssert(query && [query isKindOfClass:[PGQueryRole class]]);
	[query setOptions:(options | PGQueryOperationCreate)];
	return query;
}

+(PGQueryRole* )dropRole:(NSString* )role options:(NSUInteger)options {
	NSParameterAssert(role);
	NSString* className = NSStringFromClass([self class]);
	if([role length]==0) {
		return nil;
	}
	PGQueryRole* query = (PGQueryRole* )[PGQueryObject queryWithDictionary:@{
		PGQueryRoleKey: role
	} class:className];
	NSParameterAssert(query && [query isKindOfClass:[PGQueryRole class]]);
	[query setOptions:(options | PGQueryOperationDrop)];
	return query;
}

+(PGQueryRole* )alter:(NSString* )role name:(NSString* )name {
	NSParameterAssert(role);
	NSParameterAssert(name);
	NSString* className = NSStringFromClass([self class]);
	PGQueryRole* query = (PGQueryRole* )[PGQueryObject queryWithDictionary:@{
		PGQueryRoleKey: role,
		PGQueryNameKey: name
	} class:className];
	NSParameterAssert(query && [query isKindOfClass:[PGQueryRole class]]);
	[query setOptions:(PGQueryOperationAlter | PGQueryOptionSetName)];
	return query;
}

+(PGQueryRole* )listWithOptions:(NSUInteger)options {
	NSString* className = NSStringFromClass([self class]);
	PGQueryRole* query = (PGQueryRole* )[PGQueryObject queryWithDictionary:@{ } class:className];
	NSParameterAssert(query && [query isKindOfClass:[PGQueryRole class]]);
	[query setOptions:(options | PGQueryOperationList)];
	return query;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

@dynamic role;
@dynamic name;
@dynamic owner;
@dynamic connectionLimit;
@dynamic password;
@dynamic expiry;

-(NSString* )role {
	NSString* role = [super objectForKey:PGQueryRoleKey];
	return ([role length]==0) ? nil : role;
}

-(NSString* )name {
	NSString* name = [super objectForKey:PGQueryNameKey];
	return ([name length]==0) ? nil : name;
}

-(NSString* )owner {
	NSString* owner = [super objectForKey:PGQueryOwnerKey];
	return ([owner length]==0) ? nil : owner;
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

-(NSString* )password {
	NSString* password = [super objectForKey:PGQueryPasswordKey];
	return ([password length]==0) ? nil : password;
}

/**
 *  TODO: Store password in the dictionary. Note that passwords are not stored
 *  encrypted
 */
-(void)setPassword:(NSString* )password {
	if([password length]==0) {
		[super removeObjectForKey:PGQueryPasswordKey];
		[super setOptions:([self options] & ~PGQueryOptionSetPassword)];
	} else {
		[super setObject:password forKey:PGQueryPasswordKey];
		[super setOptions:([self options] | PGQueryOptionSetPassword)];
	}
}

-(NSDate* )expiry {
	return [super objectForKey:PGQueryExpiryKey];
}

-(void)setExpiry:(NSDate* )date {
	if(date==nil) {
		[super removeObjectForKey:PGQueryExpiryKey];
		[super setOptions:([self options] & ~PGQueryOptionSetExpiry)];
	} else {
		[super setObject:date forKey:PGQueryExpiryKey];
		[super setOptions:([self options] | PGQueryOptionSetExpiry)];
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

	// role identifier
	NSString* roleName = [self role];
	if([roleName length]==0) {
		[connection raiseError:error code:PGClientErrorQuery reason:@"CREATE ROLE: Missing role name"];
		return nil;
	}
	[flags addObject:[connection quoteIdentifier:roleName]];

	// superuser privilege
	if(options & PGQueryOptionRolePrivSuperuser) {
		[flags addObject:@"SUPERUSER"];
	} else {
		[flags addObject:@"NOSUPERUSER"];
	}
	
	// createdb privilege
	if(options & PGQueryOptionRolePrivCreateDatabase) {
		[flags addObject:@"CREATEDB"];
	} else {
		[flags addObject:@"NOCREATEDB"];
	}
	
	// createroleb privilege
	if(options & PGQueryOptionRolePrivCreateRole) {
		[flags addObject:@"CREATEROLE"];
	} else {
		[flags addObject:@"NOCREATEROLE"];
	}

	// inherit privilege
	if(options & PGQueryOptionRolePrivInherit) {
		[flags addObject:@"INHERIT"];
	} else {
		[flags addObject:@"NOINHERIT"];
	}

	// login privilege
	if(options & PGQueryOptionRolePrivLogin) {
		[flags addObject:@"LOGIN"];
	} else {
		[flags addObject:@"NOLOGIN"];
	}
	
	// replication privilege
	if(options & PGQueryOptionRolePrivReplication) {
		[flags addObject:@"REPLICATION"];
	} else {
		[flags addObject:@"NOREPLICATION"];
	}
	
	// password
	if(options & PGQueryOptionSetPassword) {
		NSString* password = [self password];
		if([password length]==0) {
			[flags addObject:@"PASSWORD NULL"];
		} else {
			NSString* encryptedPassword = [connection encryptedPassword:password role:roleName];
			NSParameterAssert(encryptedPassword);
			[flags addObject:[NSString stringWithFormat:@"ENCRYPTED PASSWORD %@",[connection quoteIdentifier:encryptedPassword]]];
		}
	}
	
	// expiry
	if(options & PGQueryOptionSetExpiry) {
		NSDate* expiry = [self expiry];
		if(expiry==nil) {
			[connection raiseError:error code:PGClientErrorQuery reason:@"CREATE ROLE: Missing expiry property"];
			return nil;
		}
		NSString* quotedExpiry = [connection quoteString:[expiry description]];
		NSParameterAssert(quotedExpiry);
		[flags addObject:[NSString stringWithFormat:@"VALID UNTIL %@",quotedExpiry]];
	}

	// owner
	if((options & PGQueryOptionSetOwner)) {
		NSString* owner = [self owner];
		if([owner length]==0) {
			[connection raiseError:error code:PGClientErrorQuery reason:@"CREATE ROLE: Missing owner property"];
			return nil;
		}
		[flags addObject:[NSString stringWithFormat:@"IN ROLE %@",[connection quoteIdentifier:owner]]];
	}
	
	// connection limit
	if((options & PGQueryOptionSetConnectionLimit)) {
		NSInteger connectionLimit = [self connectionLimit];
		if(connectionLimit < -1) {
			[connection raiseError:error code:PGClientErrorQuery reason:@"CREATE ROLE: Invalid connection limit property"];
			return nil;
		}
		[flags addObject:[NSString stringWithFormat:@"CONNECTION LIMIT %ld",connectionLimit]];
	}

	// WITH
	if([flags count] > 1) {
		// add a "WITH" phrase if there are any options
		[flags insertObject:@"WITH" atIndex:1];
	}

	// return statement
	return [NSString stringWithFormat:@"CREATE ROLE %@",[flags componentsJoinedByString:@" "]];
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

	// role identifier
	NSString* roleName = [self role];
	if([roleName length]==0) {
		[connection raiseError:error code:PGClientErrorQuery reason:@"DROP ROLE: Missing role name"];
		return nil;
	}
	[flags addObject:[connection quoteIdentifier:roleName]];

	// return statement
	return [NSString stringWithFormat:@"DROP ROLE %@",[flags componentsJoinedByString:@" "]];
}

-(NSString* )quoteAlterForConnection:(PGConnection* )connection options:(NSUInteger)options error:(NSError** )error {
	NSParameterAssert(connection);
	
	// create flags container
	NSMutableArray* flags = [NSMutableArray new];
	NSParameterAssert(flags);

	// role identifier
	NSString* roleName = [self role];
	if([roleName length]==0) {
		[connection raiseError:error code:PGClientErrorQuery reason:@"ALTER ROLE: Missing role name"];
		return nil;
	}
	[flags addObject:[connection quoteIdentifier:roleName]];

	// rename to
	if(options & PGQueryOptionSetName) {
		NSString* name = [self name];
		if([name length]==0) {
			[connection raiseError:error code:PGClientErrorQuery reason:@"ALTER ROLE: Missing name property"];
			return nil;
		}
		[flags addObject:[NSString stringWithFormat:@"RENAME TO %@",[connection quoteIdentifier:name]]];
	}

	// return statement
	return [NSString stringWithFormat:@"ALTER SCHEMA %@",[flags componentsJoinedByString:@" "]];
}

/*
TODO: implement
-(NSString* )quoteListForConnection:(PGConnection* )connection options:(NSUInteger)options error:(NSError** )error {
	return nil;
}
*/

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
	}

	[connection raiseError:error code:PGClientErrorQuery reason:@"SCHEMA: Invalid operation"];
	return nil;

}

@end
