
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

#import <PGControlsKit/PGControlsKit.h>
#import <PGControlsKit/PGControlsKit+Private.h>

@interface PGDialogRoleView ()
@property NSUInteger connectionLimitMinValue;
@property NSUInteger connectionLimitMaxValue;
@end

const NSTimeInterval PGDialogRoleConnectionLimitMaxValue = 20;

@implementation PGDialogRoleView

////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

@dynamic query;
@dynamic role;
@dynamic owner;
@dynamic connectionLimit;
@dynamic expiry;
@dynamic password,password2;
@dynamic inherit,createdb,createrole;
@synthesize connectionLimitMinValue;
@synthesize connectionLimitMaxValue;

-(PGQuery* )query {
	PGQueryRole* query = nil;
	if([[self role] length]) {
		query = [PGQueryRole create:[self role] options:0];
		if([self connectionLimit]==(PGDialogRoleConnectionLimitMaxValue + 1)) {
			[query setConnectionLimit:-1];
		} else {
			[query setConnectionLimit:[self connectionLimit]];
		}

		// owner
		[query setOwner:[self owner]];

		// password and login
		if([[self password] length] || [[self password2] length]) {
			if([[self password] isEqualToString:[self password2]]==NO) {
				return nil;
			} else {
				[query setPassword:[self password]];
				[query setOptionFlags:PGQueryOptionPrivLoginSet];
			}
		}
		
		// expiry
		[query setExpiry:[self expiry]];
		if([self expiry]) {
			[query setOptionFlags:PGQueryOptionPrivLoginSet];
		}
		
		// flags
		if([self inherit] != -1) {
			[query setOptionFlags:([self inherit] ? PGQueryOptionPrivInheritSet : PGQueryOptionPrivInheritClear)];
		}
		if([self createdb] != -1) {
			[query setOptionFlags:([self createdb] ? PGQueryOptionPrivCreateDatabaseSet : PGQueryOptionPrivCreateDatabaseClear)];
		}
		if([self createrole] != -1) {
			[query setOptionFlags:([self createrole] ? PGQueryOptionPrivCreateRoleSet : PGQueryOptionPrivCreateRoleClear)];
		}
		
	}
	return query;
}

-(NSString* )role {
	return [[[self parameters] objectForKey:@"role"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(NSString* )owner {
	return [[self parameters] objectForKey:@"owner"];
}

-(NSString* )password {
	return [[self parameters] objectForKey:@"password"];
}

-(NSString* )password2 {
	return [[self parameters] objectForKey:@"password2"];
}

-(NSInteger)inherit {
	NSNumber* value = [[self parameters] objectForKey:@"inherit"];
	if([value isKindOfClass:[NSNumber class]]) {
		return [value integerValue];
	} else {
		return -1;
	}
}

-(NSInteger)createdb {
	NSNumber* value = [[self parameters] objectForKey:@"createdb"];
	if([value isKindOfClass:[NSNumber class]]) {
		return [value integerValue];
	} else {
		return -1;
	}
}

-(NSInteger)createrole {
	NSNumber* value = [[self parameters] objectForKey:@"createrole"];
	if([value isKindOfClass:[NSNumber class]]) {
		return [value integerValue];
	} else {
		return -1;
	}
}

-(NSDate* )expiry {
	NSNumber* expiry_enabled = [[self parameters] objectForKey:@"expiry_enabled"];
	NSDate* expiry = [[self parameters] objectForKey:@"expiry"];
	BOOL expiry_enabled2 = NO;
	if([expiry_enabled isKindOfClass:[NSNumber class]]) {
		expiry_enabled2 = [expiry_enabled boolValue];
	}
	if(expiry_enabled2 && [expiry isKindOfClass:[NSDate class]]) {
		return expiry;
	} else {
		return nil;
	}
}

-(NSString* )comment {
	return [[[self parameters] objectForKey:@"comment"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(NSInteger)connectionLimit {
	NSNumber* connectionLimit = [[self parameters] objectForKey:@"connection_limit"];
	NSInteger connectionLimit2 = (PGDialogRoleConnectionLimitMaxValue + 1);
	if(connectionLimit && [connectionLimit isKindOfClass:[NSNumber class]]) {
		connectionLimit2 = [connectionLimit integerValue];
	}
	if(connectionLimit2 >= 0 && connectionLimit2 <= (PGDialogRoleConnectionLimitMaxValue + 1)) {
		return connectionLimit2;
	}
	return (PGDialogRoleConnectionLimitMaxValue + 1);
}

-(NSArray* )bindings {
	return @[ @"role",@"owner",@"comment",@"connection_limit",@"password",@"password2",@"expiry",@"expiry_enabled",@"inherit",@"createdb",@"createrole" ];
}

-(NSString* )windowTitle {
	return @"Create Role";
}

-(NSString* )windowDescription {
	return @"Create a new role or user";
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Private Methods
////////////////////////////////////////////////////////////////////////////////

/**
 *  Method to message the delegate to enable or disable the OK button
 */
-(void)setEnabled:(BOOL)enabled {
	int flag = enabled ? PGDialogWindowFlagEnabled : PGDialogWindowFlagDisabled;
	if([[self delegate] respondsToSelector:@selector(view:setFlags:description:)]) {
		[[self delegate] view:self setFlags:flag description:nil];
	}
}

-(void)updateConnectionLimitLabel {
	// update the label to reflect the current value
	NSInteger connectionLimit = [self connectionLimit];
	if(connectionLimit==0) {
		[[self parameters] setObject:@"No Login" forKey:@"connection_limit_text"];
	} else if(connectionLimit==(PGDialogRoleConnectionLimitMaxValue + 1)) {
		[[self parameters] setObject:@"Unlimited" forKey:@"connection_limit_text"];
	} else {
		[[self parameters] setObject:[NSNumber numberWithInteger:connectionLimit] forKey:@"connection_limit_text"];
	}
	[[self parameters] setObject:[NSNumber numberWithInteger:connectionLimit] forKey:@"connection_limit"];
}

-(void)resetParameters {
	// expiry
	if([self expiry]==nil) {
		[[self parameters] setObject:[NSDate new] forKey:@"expiry"];
		[[self parameters] setObject:@NO forKey:@"expiry_enabled"];
	} else {
		[[self parameters] setObject:@YES forKey:@"expiry_enabled"];
	}
	
	// set connection limit
	[self setConnectionLimitMinValue:0];
	[self setConnectionLimitMaxValue:(PGDialogRoleConnectionLimitMaxValue + 1)];
	[self updateConnectionLimitLabel];
	
	// set empty list of roles
	[[self parameters] setObject:@[ ] forKey:@"roles"];
	
	// set privs
	[[self parameters] setObject:@-1 forKey:@"inherit"];
	[[self parameters] setObject:@-1 forKey:@"createdb"];
	[[self parameters] setObject:@-1 forKey:@"createrole"];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Public Methods
////////////////////////////////////////////////////////////////////////////////

-(void)setRoles:(NSArray* )roles {
	NSParameterAssert(roles);

	NSString* owner = [self owner];

	// set the roles which can be chosen
	[[self parameters] setObject:roles forKey:@"roles"];

	// reset the owner name
	if(owner && [roles containsObject:owner]) {
		[[self parameters] setObject:owner forKey:@"owner"];
	} else if([roles count]) {
		[[self parameters] setObject:[roles objectAtIndex:0] forKey:@"owner"];
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark PGDialogView overrides
////////////////////////////////////////////////////////////////////////////////

-(void)valueChangedWithKey:(NSString* )key oldValue:(id)oldValue newValue:(id)newValue {
	[super valueChangedWithKey:key oldValue:oldValue newValue:newValue];

	NSLog(@"%@ %@ => %@",key,oldValue,newValue);

	// connection limit
	if([key isEqualToString:@"connection_limit"]) {
		[self updateConnectionLimitLabel];
	}

	// check role length
	if([[self role] length]==0) {
		[self setEnabled:NO];
		return;
	}
	
	// check passwords
	if([[self password] length] || [[self password2] length]) {
		if([[self password] isEqualToString:[self password2]]==NO) {
			[self setEnabled:NO];
			return;
		}
	}
	
	[self setEnabled:YES];
}

-(void)setViewParameters:(NSDictionary* )parameters {
	[super setViewParameters:parameters];
	
	// reset parameters
	[self resetParameters];
}

@end
